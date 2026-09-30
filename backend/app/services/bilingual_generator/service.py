"""Bilingual Generator Service bridging FastAPI backend with the modular Bilingual Generator."""
import datetime
import json
import logging
import os
import sys
import uuid
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union

logger = logging.getLogger(__name__)


def _ensure_generator_paths() -> Path:
    """Ensure all required generator subdirectories are in sys.path."""
    gen_dir = os.getenv("BILINGUAL_GENERATOR_DIR")
    if gen_dir:
        gen_path = Path(gen_dir).resolve()
        if not gen_path.is_absolute():
            # Check relative to backend root
            backend_root = Path(__file__).resolve().parents[3]
            candidate = (backend_root / gen_dir).resolve()
            if candidate.exists():
                gen_path = candidate
    else:
        # Canonical location: backend/generator
        gen_path = (Path(__file__).resolve().parents[3] / "generator").resolve()

    if not gen_path.exists():
        for candidate in [
            (Path(__file__).resolve().parents[3] / "generator").resolve(),
            Path("generator").resolve(),
            (Path.cwd() / "generator").resolve(),
            (Path.cwd() / "backend" / "generator").resolve(),
            (Path.cwd().parent / "generator").resolve(),
        ]:
            if candidate.exists():
                gen_path = candidate
                break

    paths_to_add = [
        str(gen_path),
        str(gen_path / "generation"),
        str(gen_path / "generation" / "validation"),
        str(gen_path / "generation" / "review"),
        str(gen_path / "generation" / "publishing"),
    ]
    for p in paths_to_add:
        if p not in sys.path:
            sys.path.insert(0, p)

    return gen_path


# Configure paths on import
_GEN_PATH = _ensure_generator_paths()


def _is_mock_supabase(url: Optional[str]) -> bool:
    """Determine whether to use in-memory mock repository/storage."""
    if not url:
        return True
    url_lower = url.lower()
    return (
        "example" in url_lower
        or "your-project" in url_lower
        or "dummy" in url_lower
        or os.getenv("PUBLISHER_MOCK_MODE", "").lower() in ("true", "1")
    )

# Import generator components directly without duplicating logic
from compose_prompt import (  # noqa: E402
    BlueprintNotFoundError,
    ComposedPrompt,
    CurriculumNotFoundError,
    PromptComposer,
)
from content_validator import schema_validator, validate_unit  # noqa: E402
from orchestrator import GenerationOrchestrator, GenerationResult  # noqa: E402
from providers.base import LLMProvider  # noqa: E402
from providers.mock import MockProvider  # noqa: E402
from publishing.models import (  # noqa: E402
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
from publishing.publisher import SupabasePublisher  # noqa: E402
from publishing.repository import SupabaseRepository, deterministic_uuid  # noqa: E402
from publishing.storage import SupabaseStorageClient  # noqa: E402
from review.review_manager import (  # noqa: E402
    GATE_FAIL,
    GATE_PASS,
    GATE_PENDING,
    STATUS_APPROVED,
    STATUS_CHANGES_REQUESTED,
    STATUS_IN_REVIEW,
    STATUS_NEEDS_REVIEW,
    STATUS_PENDING,
    STATUS_REJECTED,
    VALID_GATES,
    VALID_SANTALI_SCRIPTS,
    ReviewManager,
    compute_data_sha256,
    compute_file_sha256,
)


class BilingualGeneratorService:
    """Service abstraction exposing the Bilingual Generator to FastAPI and backend services.

    Responsibilities:
    - Invoke PromptComposer to resolve blueprints and curriculum
    - Invoke configured content-generation providers (offline Mock only)
    - Run JSON Schema and pedagogical content validation
    - Manage human review workflow, review records, and gate approvals
    - Publish approved content to Supabase Storage and PostgreSQL
    """

    def __init__(
        self,
        generator_dir: Optional[str] = None,
        output_dir: Optional[str] = None,
        records_dir: Optional[str] = None,
    ):
        self.gen_dir = Path(generator_dir).resolve() if generator_dir else _ensure_generator_paths()
        self.generation_dir = self.gen_dir / "generation"
        self.output_dir = Path(output_dir).resolve() if output_dir else (self.generation_dir / "generated" / "pilot_v1")
        self.records_dir = Path(records_dir).resolve() if records_dir else (self.generation_dir / "review" / "records")

        # Initialize ReviewManager
        schema_path = self.generation_dir / "review" / "review_schema.json"
        self.review_manager = ReviewManager(
            records_dir=str(self.records_dir),
            schema_path=str(schema_path) if schema_path.exists() else None,
        )

        # Initialize PromptComposer with canonical data
        master_path = self.gen_dir / "canonical" / "curriculum_master_v1.json"
        blueprint_path = self.gen_dir / "blueprint" / "content_blueprint_v1.json"
        schema_path = self.generation_dir / "schema" / "generated_content.schema.json"
        prompts_dir = self.generation_dir / "prompts"
        self.composer = PromptComposer(
            master_path=str(master_path),
            blueprint_path=str(blueprint_path),
            schema_path=str(schema_path),
            prompts_dir=str(prompts_dir),
        )
        # Initialize storage client and repository
        from app.core.config import settings

        is_mock = _is_mock_supabase(settings.SUPABASE_URL)
        self.storage_client = SupabaseStorageClient(
            supabase_url=settings.SUPABASE_URL,
            service_role_key=settings.SUPABASE_SERVICE_ROLE_KEY,
            bucket=settings.STORAGE_BUCKET_CONTENT,
            mock=is_mock,
        )
        self.repository = SupabaseRepository(
            supabase_url=settings.SUPABASE_URL,
            service_role_key=settings.SUPABASE_SERVICE_ROLE_KEY,
            mock=is_mock,
        )

    def get_provider(self, provider_name: str = "mock", mock_mode: bool = False) -> LLMProvider:
        """Resolve the content-generation provider.

        Only the offline ``mock`` provider remains. Cloud generators were
        removed with the rest of the external AI stack, so any other name fails
        with a clear message instead of silently producing fabricated content.
        """
        name = (provider_name or "mock").strip().lower()
        if mock_mode or name == "mock":
            return MockProvider()

        from app.core.config import settings

        raise RuntimeError(
            f"Content generation provider '{provider_name}' is not available. "
            + settings.CONTENT_GENERATION_UNAVAILABLE_REASON
        )

    def generate_content(
        self,
        blueprint_id: str,
        target_language: str = "sat",
        provider_name: str = "mock",
        mock_mode: bool = False,
        force: bool = False,
        output_dir: Optional[str] = None,
    ) -> GenerationResult:
        """Execute the complete generation pipeline for a given blueprint."""
        provider = self.get_provider(provider_name=provider_name, mock_mode=mock_mode)
        out_dir = str(output_dir or self.output_dir)

        orchestrator = GenerationOrchestrator(
            provider=provider,
            output_dir=out_dir,
            composer=self.composer,
            review_manager=self.review_manager,
        )

        return orchestrator.generate(
            blueprint_id=blueprint_id,
            target_language=target_language,
            force=force,
        )

    def validate_content(self, content: Dict[str, Any]) -> Tuple[bool, List[str], List[str]]:
        """Validate content against JSON schema and pedagogical rules.

        Returns:
            (is_valid, errors, warnings)
        """
        v = schema_validator()
        schema_errors = [e.message for e in v.iter_errors(content)]
        if schema_errors:
            return False, schema_errors, []

        rep = validate_unit(content)
        errors = [f"[{e.get('code', 'ERR')}] {e.get('message', str(e))}" for e in rep.errors]
        warnings = [f"[{w.get('code', 'WARN')}] {w.get('message', str(w))}" for w in rep.warnings]
        return rep.ok, errors, warnings


    def get_review_status(self, content_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve review record for a given content_id."""
        record_path = self.review_manager.get_record_path(content_id)
        if not os.path.exists(record_path):
            return None

        with open(record_path, "r", encoding="utf-8") as f:
            return json.load(f)

    def update_review(
        self,
        content_id: str,
        reviewer_id: str,
        status: Optional[str] = None,
        gate_updates: Optional[Dict[str, str]] = None,
        notes: Optional[str] = None,
        santali_script_confirmed: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Update review record with reviewer decisions and gate updates."""
        record_path = self.review_manager.get_record_path(content_id)
        if not os.path.exists(record_path):
            raise FileNotFoundError(f"No review record found for content ID: '{content_id}'")

        with open(record_path, "r", encoding="utf-8") as f:
            record = json.load(f)

        now_date = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")

        if gate_updates:
            gates = record.setdefault("gates", {})
            for gate, val in gate_updates.items():
                if gate not in VALID_GATES:
                    raise ValueError(f"Invalid review gate: '{gate}'. Valid gates: {VALID_GATES}")
                gates[gate] = val

        if santali_script_confirmed:
            if santali_script_confirmed not in VALID_SANTALI_SCRIPTS:
                raise ValueError(
                    f"Invalid santali_script_confirmed: '{santali_script_confirmed}'. Valid: {VALID_SANTALI_SCRIPTS}"
                )
            record["santali_script_confirmed"] = santali_script_confirmed

        if notes:
            notes_list = record.setdefault("reviewer_notes", [])
            notes_list.append({
                "gate": "general",
                "reviewer": reviewer_id,
                "date": now_date,
                "note": notes,
            })

        if status:
            target_status = status.lower()
            valid_statuses = {
                STATUS_PENDING,
                STATUS_IN_REVIEW,
                STATUS_CHANGES_REQUESTED,
                STATUS_APPROVED,
                STATUS_REJECTED,
            }
            if target_status not in valid_statuses:
                raise ValueError(
                    f"Invalid review status: '{status}'. Valid statuses: {valid_statuses}"
                )
            record["review_status"] = target_status

            if target_status == STATUS_APPROVED:
                approved_by = record.setdefault("approved_by", [])
                if reviewer_id not in approved_by:
                    approved_by.append(reviewer_id)
                record["approved_at"] = now_date

        # Validate against schema
        errors = self.review_manager.validate_review_record(record)
        if errors:
            raise ValueError(f"Updated review record failed schema validation: {errors}")

        # Atomic save
        temp_path = f"{record_path}.tmp_{uuid.uuid4().hex[:8]}"
        with open(temp_path, "w", encoding="utf-8") as f:
            json.dump(record, f, indent=2, ensure_ascii=False)
        os.replace(temp_path, record_path)

        return record

    def publish_content(
        self,
        content_id: str,
        pdf_bytes: Optional[bytes] = None,
        dry_run: bool = False,
        storage_client: Optional[SupabaseStorageClient] = None,
        repository: Optional[SupabaseRepository] = None,
    ) -> PublicationResult:
        """Publish approved bilingual content to Supabase."""
        from app.core.config import settings

        is_mock = _is_mock_supabase(settings.SUPABASE_URL)
        config = PublishConfig(
            supabase_url=settings.SUPABASE_URL or "https://example.supabase.co",
            supabase_service_role_key=settings.SUPABASE_SERVICE_ROLE_KEY or "dummy-key",
            content_bucket=settings.STORAGE_BUCKET_CONTENT,
            mock=is_mock,
        )

        publisher = SupabasePublisher(
            storage_client=storage_client or self.storage_client,
            repository=repository or self.repository,
            review_manager=self.review_manager,
            content_dir=str(self.output_dir),
            config=config,
        )

        return publisher.publish(content=content_id, pdf_bytes=pdf_bytes, dry_run=dry_run)


bilingual_generator_service = BilingualGeneratorService()
