"""Supabase Publisher orchestrating validation, review verification, storage upload, and database persistence."""
import argparse
import hashlib
import json
import logging
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

# Path configuration
HERE = os.path.dirname(os.path.abspath(__file__))
GEN_DIR = os.path.dirname(HERE)
PROJECT_DIR = os.path.dirname(GEN_DIR)
for p in [PROJECT_DIR, GEN_DIR, HERE]:
    if p not in sys.path:
        sys.path.insert(0, p)

from review.review_manager import (
    GATE_FAIL,
    GATE_PENDING,
    STATUS_APPROVED,
    VALID_SANTALI_SCRIPTS,
    ReviewManager,
    compute_data_sha256,
    compute_file_sha256,
)
from .models import (
    ConflictingPublicationError,
    DatabaseOperationError,
    IntegrityVerificationError,
    PublicationResult,
    PublicationState,
    PublishConfig,
    PublishError,
    StorageUploadError,
    UnapprovedContentError,
    ValidationFailureError,
)
from .repository import SupabaseRepository, deterministic_uuid
from .storage import (
    SupabaseStorageClient,
    build_flashcard_storage_path,
    build_worksheet_storage_path,
)

logger = logging.getLogger(__name__)
DEFAULT_CONTENT_DIR = os.path.join(GEN_DIR, "generated", "pilot_v1")


class SupabasePublisher:
    """Publishes human-approved bilingual educational content to Supabase."""

    def __init__(
        self,
        storage_client: Optional[SupabaseStorageClient] = None,
        repository: Optional[SupabaseRepository] = None,
        review_manager: Optional[ReviewManager] = None,
        content_dir: Optional[str] = None,
        config: Optional[PublishConfig] = None,
    ):
        self.config = config or PublishConfig.from_env()
        self.content_dir = os.path.abspath(content_dir or DEFAULT_CONTENT_DIR)
        self.review_manager = review_manager or ReviewManager()
        self.storage = storage_client or SupabaseStorageClient(
            supabase_url=self.config.supabase_url,
            service_role_key=self.config.supabase_service_role_key,
            bucket=self.config.content_bucket,
            mock=self.config.mock,
        )
        self.repository = repository or SupabaseRepository(
            supabase_url=self.config.supabase_url,
            service_role_key=self.config.supabase_service_role_key,
            mock=self.config.mock,
        )

    def _resolve_content_and_hash(
        self, content: Union[str, Path, Dict[str, Any]]
    ) -> tuple[Dict[str, Any], str, Optional[str]]:
        """Resolve content dictionary, SHA-256 hash, and optional file path."""
        if isinstance(content, (str, Path)):
            content_str = str(content)
            # If given a content_id, resolve to content_dir
            if not os.path.exists(content_str):
                candidate = os.path.join(self.content_dir, f"{content_str}.json")
                if os.path.exists(candidate):
                    content_str = candidate
                else:
                    raise FileNotFoundError(f"Content file not found for: {content_str}")

            resolved_path = os.path.abspath(content_str)
            content_sha = compute_file_sha256(resolved_path)
            with open(resolved_path, "r", encoding="utf-8") as f:
                content_dict = json.load(f)
            return content_dict, content_sha, resolved_path
        elif isinstance(content, dict):
            content_sha = compute_data_sha256(content)
            return content, content_sha, None
        else:
            raise TypeError(f"content must be path (str/Path) or dict; got {type(content)}")

    def publish(
        self,
        content: Union[str, Path, Dict[str, Any]],
        pdf_bytes: Optional[bytes] = None,
        dry_run: bool = False,
    ) -> PublicationResult:
        """Publish an approved content unit to Supabase PostgreSQL and Storage.

        Args:
            content: Content ID string, path to content JSON, or in-memory dict.
            pdf_bytes: Optional rendered PDF binary data (for worksheets).
            dry_run: If True, validates and maps everything without writing to Supabase.

        Returns:
            PublicationResult describing the outcome.
        """
        is_dry_run = dry_run or self.config.dry_run

        # 1. Load content and compute hash
        content_dict, content_sha, content_path = self._resolve_content_and_hash(content)
        content_id = content_dict.get("content_id")
        content_type = content_dict.get("content_type")

        if not content_id:
            raise PublishError("Content is missing required field 'content_id'.")
        if content_type not in ("worksheet", "flashcard"):
            raise PublishError(
                f"Unsupported content_type '{content_type}'. Publisher supports 'worksheet' and 'flashcard'."
            )

        # 2. Load and verify review record
        review_record = self.review_manager.load_review_record(content_id)
        if not review_record:
            raise UnapprovedContentError(f"No review record found for content_id: {content_id}")

        # 3. Verify machine validation passed
        val_report = review_record.get("validator_report", {})
        if not val_report.get("passed", False):
            raise ValidationFailureError(
                f"Content '{content_id}' failed machine validation and cannot be published."
            )

        # 4. Verify human review status is APPROVED
        review_status = review_record.get("review_status")
        if review_status != STATUS_APPROVED:
            raise UnapprovedContentError(
                f"Content '{content_id}' review status is '{review_status}'. Only '{STATUS_APPROVED}' content can be published."
            )

        # 5. Verify review integrity/hash
        expected_sha = review_record.get("content_sha256")
        if expected_sha and expected_sha != content_sha:
            raise IntegrityVerificationError(
                f"Content integrity mismatch for '{content_id}'. Review record SHA256: {expected_sha}, content file SHA256: {content_sha}"
            )

        # 6. Verify review gates
        gates = review_record.get("gates", {})
        for gate_name, gate_status in gates.items():
            if gate_status == GATE_FAIL:
                raise UnapprovedContentError(
                    f"Cannot publish '{content_id}': review gate '{gate_name}' failed."
                )
            if gate_status == GATE_PENDING:
                raise UnapprovedContentError(
                    f"Cannot publish '{content_id}': review gate '{gate_name}' is still pending."
                )

        # Santali script confirmation check
        if gates.get("santali") == "pass":
            confirmed_script = review_record.get("santali_script_confirmed")
            if not confirmed_script or confirmed_script not in VALID_SANTALI_SCRIPTS:
                raise UnapprovedContentError(
                    f"Cannot publish '{content_id}': Santali gate is passing but confirmed script '{confirmed_script}' is invalid."
                )

        # 7. Check Idempotency & Conflict
        existing_gen = self.repository.get_generated_content_by_content_id(content_id)
        if existing_gen:
            existing_output = existing_gen.get("validated_output") or existing_gen.get("raw_output") or {}
            import re
            m = re.search(r"SHA256:([a-f0-9]{64})", existing_gen.get("review_notes") or "")
            existing_sha = m.group(1) if m else None

            is_match = False
            if existing_sha and existing_sha == content_sha:
                is_match = True
            elif isinstance(existing_output, dict) and compute_data_sha256(existing_output) == compute_data_sha256(content_dict):
                is_match = True

            if is_match:
                logger.info("Content '%s' is already published with identical SHA256. Returning idempotent success.", content_id)
                return PublicationResult(
                    content_id=content_id,
                    content_type=content_type,
                    status=PublicationState.ALREADY_PUBLISHED.value,
                    is_idempotent=True,
                    published_at=existing_gen.get("updated_at") or existing_gen.get("created_at"),
                    record_ids={"generated_content_id": existing_gen.get("id")},
                )
            else:
                raise ConflictingPublicationError(
                    f"Content '{content_id}' is already published with different content hash. "
                    f"Existing SHA256: {existing_sha or 'unknown'}, New SHA256: {content_sha}. "
                    "Increment the version (e.g. -v2) before publishing updates."
                )

        # 8. Plan Storage Paths and Database Payloads
        grade = int(content_dict.get("grade", 1))
        curriculum_id = content_dict.get("curriculum_id", "UNKNOWN")
        languages = content_dict.get("languages", ["hi"])
        primary_lang = languages[0] if languages else "hi"

        storage_paths: List[str] = []
        uploaded_paths: List[str] = []
        created_records: Dict[str, Any] = {}

        # Resolve foreign keys
        lang_id = self.repository.get_language_id(primary_lang)
        lo_id = self.repository.get_learning_outcome_id(curriculum_id)

        # Deterministic IDs
        gen_content_id = deterministic_uuid("generated_content", content_id)

        if content_type == "worksheet":
            # Structured JSON path in storage
            json_storage_path = build_worksheet_storage_path(grade, curriculum_id, content_id, ext="json")
            storage_paths.append(json_storage_path)

            # Optional PDF path in storage
            pdf_storage_path = build_worksheet_storage_path(grade, curriculum_id, content_id, ext="pdf")
            if pdf_bytes is not None:
                storage_paths.append(pdf_storage_path)
                canonical_file_path = pdf_storage_path
                file_size = len(pdf_bytes)
                file_format = "pdf"
            else:
                canonical_file_path = json_storage_path
                file_size = len(json.dumps(content_dict).encode("utf-8"))
                file_format = "json"

            worksheet_id = deterministic_uuid("worksheets", content_id)
            title_text = content_dict.get("title", {}).get("hi") or content_dict.get("title", {}).get("sat") or content_id

            worksheet_record = {
                "id": worksheet_id,
                "title": title_text[:255],
                "grade": grade,
                "subject": content_dict.get("domain", "Mathematics").title(),
                "file_path": canonical_file_path,
                "file_size": file_size,
                "format": file_format,
                "learning_outcome_id": lo_id,
                "language_id": lang_id,
            }
            created_records["worksheet"] = worksheet_record

        elif content_type == "flashcard":
            deck_name = f"{content_id} - {content_dict.get('title', {}).get('hi', '')}".strip()
            flashcard_records: List[Dict[str, Any]] = []
            items = content_dict.get("items", [])

            for item in items:
                item_id = item.get("item_id", "card")
                fc_id = deterministic_uuid("flashcards", f"{content_id}_{item_id}")
                
                # Bilingual text mapping
                prompt = item.get("prompt", {})
                front_text = prompt.get("hi") or (prompt if isinstance(prompt, str) else "")
                
                # Back text: check options, answer, or sat prompt
                back_text = prompt.get("sat") or ""
                if not back_text and "options" in item:
                    # Collect options
                    back_text = " / ".join(
                        opt.get("text", {}).get("sat") or opt.get("text", {}).get("hi") or str(opt.get("value", ""))
                        for opt in item["options"]
                    )
                if not back_text:
                    back_text = str(item.get("answer") or front_text)

                fc_record = {
                    "id": fc_id,
                    "deck_name": deck_name[:100],
                    "front_text": front_text,
                    "back_text": back_text,
                    "image_url": None,
                    "audio_url": None,
                    "grade": grade,
                    "language_id": lang_id,
                }
                flashcard_records.append(fc_record)
            created_records["flashcards"] = flashcard_records

        # Generated content record (Provenance ledger)
        reviewers = review_record.get("approved_by", [])
        reviewed_by_str = ", ".join(reviewers) if isinstance(reviewers, list) else str(reviewers)
        review_notes_list = [n.get("note", "") for n in review_record.get("reviewer_notes", []) if isinstance(n, dict)]
        review_notes_str = f"SHA256:{content_sha}; " + ("; ".join(filter(None, review_notes_list)) or f"Approved with gates: {gates}")

        gen_record = {
            "id": gen_content_id,
            "learning_outcome_id": lo_id,
            "content_type": content_type,
            "prompt_used": "+".join(content_dict.get("prompt_stack", ["base_prompt"])),
            "raw_output": content_dict,
            "validated_output": content_dict,
            "status": "PUBLISHED",
            "created_by": "bilingual_generator",
            "reviewed_by": reviewed_by_str[:100],
            "review_notes": review_notes_str,
        }
        created_records["generated_content"] = gen_record

        # 9. Dry Run Output
        if is_dry_run:
            logger.info("Dry-run execution for '%s'. Zero mutations performed.", content_id)
            return PublicationResult(
                content_id=content_id,
                content_type=content_type,
                status="dry_run",
                dry_run=True,
                storage_paths=storage_paths,
                record_ids={
                    "generated_content_id": gen_content_id,
                    "entity_id": created_records.get("worksheet", {}).get("id") or [f["id"] for f in created_records.get("flashcards", [])],
                },
                details={
                    "storage_paths_planned": storage_paths,
                    "database_records_planned": {
                        "generated_content": gen_record["id"],
                        "target_entity": content_type,
                        "count": len(created_records.get("flashcards", [])) if content_type == "flashcard" else 1,
                    },
                },
            )

        # 10. Live Storage Uploads
        try:
            # Upload structured JSON
            content_bytes = json.dumps(content_dict, indent=2, ensure_ascii=False).encode("utf-8")
            if content_type == "worksheet":
                p = self.storage.upload_bytes(json_storage_path, content_bytes, content_type="application/json")
                uploaded_paths.append(p)
                if pdf_bytes is not None:
                    p_pdf = self.storage.upload_bytes(pdf_storage_path, pdf_bytes, content_type="application/pdf")
                    uploaded_paths.append(p_pdf)
        except Exception as e:
            # Cleanup any partial uploads
            self.storage.delete_objects(uploaded_paths)
            raise StorageUploadError(f"Storage upload failed during publication of '{content_id}': {e}") from e

        # 11. Live Database Persistence (with rollback of storage on failure)
        try:
            # Save generated_content
            self.repository.save_generated_content(gen_record)

            # Save entity record (worksheet or flashcards)
            if content_type == "worksheet":
                self.repository.save_worksheet(created_records["worksheet"])
            elif content_type == "flashcard":
                for fc in created_records["flashcards"]:
                    self.repository.save_flashcard(fc)

        except Exception as e:
            # Clean up storage assets to prevent orphaned files
            logger.error("Database persistence failed. Rolling back uploaded storage assets: %s", uploaded_paths)
            self.storage.delete_objects(uploaded_paths)
            raise DatabaseOperationError(f"Database operation failed for '{content_id}': {e}") from e

        now_iso = datetime.now(timezone.utc).isoformat()
        return PublicationResult(
            content_id=content_id,
            content_type=content_type,
            status=PublicationState.PUBLISHED.value,
            storage_paths=uploaded_paths,
            record_ids={
                "generated_content_id": gen_content_id,
                "entity_id": created_records.get("worksheet", {}).get("id") or [f["id"] for f in created_records.get("flashcards", [])],
            },
            published_at=now_iso,
        )


def main():
    parser = argparse.ArgumentParser(description="Publish approved bilingual content to Supabase.")
    parser.add_argument("--content-id", required=True, help="Content ID to publish (e.g. GC-G1-NUM-032-01-bi-v1)")
    parser.add_argument("--dry-run", action="store_true", help="Perform validation and dry-run without mutations")
    parser.add_argument("--content-dir", help="Directory containing generated content files")
    parser.add_argument("--mock", action="store_true", help="Run with in-memory mock storage and repository")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

    publisher = SupabasePublisher(
        content_dir=args.content_dir,
        config=PublishConfig.from_env(dry_run=args.dry_run, mock=args.mock),
    )

    try:
        res = publisher.publish(content=args.content_id, dry_run=args.dry_run)
        print("\n" + "=" * 60)
        print("PUBLICATION RESULT:")
        print(f"Content ID:     {res.content_id}")
        print(f"Content Type:   {res.content_type}")
        print(f"Status:         {res.status}")
        print(f"Idempotent:     {res.is_idempotent}")
        print(f"Storage Paths:  {res.storage_paths}")
        print(f"Record IDs:     {res.record_ids}")
        if res.published_at:
            print(f"Published At:   {res.published_at}")
        print("=" * 60)
        sys.exit(0)
    except PublishError as e:
        print(f"\n[ERROR] Publication failed: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
