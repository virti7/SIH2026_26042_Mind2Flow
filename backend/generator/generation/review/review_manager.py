"""Human review manager for bilingual FLN content."""
import argparse
import datetime
import hashlib
import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

import jsonschema

# Path configuration
HERE = os.path.dirname(os.path.abspath(__file__))
GEN_DIR = os.path.dirname(HERE)
PROJECT_DIR = os.path.dirname(GEN_DIR)

DEFAULT_SCHEMA_PATH = os.path.join(HERE, "review_schema.json")
DEFAULT_RECORDS_DIR = os.path.join(HERE, "records")
DEFAULT_CONTENT_DIR = os.path.join(GEN_DIR, "generated", "pilot_v1")

# Review statuses as defined in review_schema.json
STATUS_PENDING = "pending"
STATUS_IN_REVIEW = "in_review"
STATUS_CHANGES_REQUESTED = "changes_requested"
STATUS_APPROVED = "approved"
STATUS_REJECTED = "rejected"

# Conceptual alias for newly created records awaiting review
STATUS_NEEDS_REVIEW = STATUS_PENDING

# Review gates
GATE_PENDING = "pending"
GATE_PASS = "pass"
GATE_FAIL = "fail"
GATE_NOT_APPLICABLE = "not_applicable"

VALID_GATES = {"hindi", "santali", "curriculum", "answer_key", "provisional_range"}
VALID_NOTES_GATES = VALID_GATES | {"general"}
VALID_SANTALI_SCRIPTS = {"Olck", "Deva", "Beng", "Orya", "Latn"}


class ReviewRecordError(Exception):
    """Base exception for review record operations."""
    pass


class ReviewValidationError(ReviewRecordError):
    """Raised when a review record fails schema or semantic validation."""
    def __init__(self, message: str, errors: Optional[List[str]] = None):
        super().__init__(message)
        self.errors = errors or []


class ReviewRecordNotFoundError(ReviewRecordError):
    """Raised when a review record cannot be found on disk."""
    pass


def compute_file_sha256(path: str) -> str:
    """Compute hex SHA-256 hash of a file."""
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def compute_data_sha256(data: Dict[str, Any]) -> str:
    """Compute hex SHA-256 hash of JSON-serializable dictionary."""
    encoded = json.dumps(data, indent=2, ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


class ReviewManager:
    """Manages the human review workflow and review records for generated content."""

    def __init__(
        self,
        records_dir: Optional[str] = None,
        schema_path: Optional[str] = None,
    ):
        self.records_dir = os.path.abspath(records_dir or DEFAULT_RECORDS_DIR)
        self.schema_path = os.path.abspath(schema_path or DEFAULT_SCHEMA_PATH)
        
        with open(self.schema_path, "r", encoding="utf-8") as f:
            self._schema = json.load(f)
        self._validator = jsonschema.Draft202012Validator(self._schema)

    def get_record_path(self, content_id: str) -> str:
        """Get the filesystem path for a content unit's review record."""
        return os.path.join(self.records_dir, f"{content_id}.json")

    def validate_review_record(self, record: Dict[str, Any]) -> List[str]:
        """Validate a review record dictionary against review_schema.json.

        Returns:
            List of formatted validation error strings (empty if valid).
        """
        errors = list(self._validator.iter_errors(record))
        return [
            f"Schema error at $.{'.'.join(str(p) for p in err.path)}: {err.message}"
            for err in sorted(errors, key=lambda e: list(e.path))
        ]

    def _atomic_write_json(self, target_path: str, data: Dict[str, Any]) -> None:
        """Write JSON data to a temporary file and atomically replace target."""
        dir_name = os.path.dirname(os.path.abspath(target_path))
        os.makedirs(dir_name, exist_ok=True)
        fd, temp_path = tempfile.mkstemp(dir=dir_name, prefix=".tmp_rev_")
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
                f.flush()
                os.fsync(f.fileno())
            os.replace(temp_path, target_path)
        except Exception:
            if os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except OSError:
                    pass
            raise

    def load_review_record(self, content_id: str) -> Optional[Dict[str, Any]]:
        """Load a review record by content_id. Returns None if not found."""
        target_path = self.get_record_path(content_id)
        if not os.path.exists(target_path):
            # Check alternative filename {content_id}.review.json
            alt_path = os.path.join(self.records_dir, f"{content_id}.review.json")
            if os.path.exists(alt_path):
                target_path = alt_path
            else:
                return None

        with open(target_path, "r", encoding="utf-8") as f:
            return json.load(f)

    def create_review_record(
        self,
        content: Union[str, Path, Dict[str, Any]],
        content_path: Optional[str] = None,
        validation_report: Optional[Dict[str, Any]] = None,
        content_sha256: Optional[str] = None,
        overwrite: bool = False,
    ) -> Dict[str, Any]:
        """Create and persist an initial review record for generated content.

        Args:
            content: File path to generated JSON or in-memory dictionary.
            content_path: Optional path to content file if content is dict.
            validation_report: Optional validator report dictionary.
            content_sha256: Optional SHA-256 hash if content is dict without file.
            overwrite: If True, overwrite an existing record rather than reusing notes.

        Returns:
            The created review record dictionary with review_status="pending".
        """
        if isinstance(content, (str, Path)):
            resolved_path = str(content)
            if not os.path.exists(resolved_path):
                raise FileNotFoundError(f"Content file not found at: {resolved_path}")
            content_sha = compute_file_sha256(resolved_path)
            with open(resolved_path, "r", encoding="utf-8") as f:
                content_dict = json.load(f)
            if content_path is None:
                content_path = resolved_path
        elif isinstance(content, dict):
            content_dict = content
            if content_path and os.path.exists(content_path):
                content_sha = compute_file_sha256(content_path)
            elif content_sha256:
                content_sha = content_sha256
            else:
                content_sha = compute_data_sha256(content_dict)
        else:
            raise TypeError(f"content must be path (str/Path) or dict; got {type(content)}")

        content_id = content_dict.get("content_id")
        blueprint_id = content_dict.get("blueprint_id")
        curriculum_id = content_dict.get("curriculum_id")

        if not content_id or not blueprint_id or not curriculum_id:
            raise ReviewValidationError(
                f"Content missing required metadata: content_id={content_id}, "
                f"blueprint_id={blueprint_id}, curriculum_id={curriculum_id}"
            )

        # Inspect languages and flags to determine required human review gates
        languages = content_dict.get("languages", [])
        if not languages:
            # Infer from content_id suffix or language field
            if "-bi-" in content_id:
                languages = ["hi", "sat"]
            elif "-hi-" in content_id:
                languages = ["hi"]
            elif "-sat-" in content_id:
                languages = ["sat"]
            elif "language" in content_dict:
                lang = content_dict["language"]
                languages = ["hi", "sat"] if lang == "bi" else [lang]

        # 1. Hindi gate
        if "hi" in languages or "-bi-" in content_id or "-hi-" in content_id:
            hindi_gate = GATE_PENDING
        else:
            hindi_gate = GATE_NOT_APPLICABLE

        # 2. Santali gate
        if "sat" in languages or "-bi-" in content_id or "-sat-" in content_id:
            santali_gate = GATE_PENDING
        else:
            santali_gate = GATE_NOT_APPLICABLE

        # 3. Curriculum and answer key gates are always pending initially
        curriculum_gate = GATE_PENDING
        answer_key_gate = GATE_PENDING

        # 4. Provisional range gate
        is_provisional = (
            content_dict.get("provisional") is True
            or "provisional_range" in content_dict.get("review_gates", [])
        )
        if is_provisional:
            provisional_gate = GATE_PENDING
        else:
            provisional_gate = GATE_NOT_APPLICABLE

        # Validator report
        if validation_report is None:
            val_report = {
                "validator_version": "1.0.0",
                "passed": True,
                "warnings": 0,
            }
        else:
            val_report = {
                "validator_version": str(validation_report.get("validator_version", "1.0.0")),
                "passed": bool(validation_report.get("passed", True)),
            }
            if "warnings" in validation_report:
                val_report["warnings"] = int(validation_report["warnings"])
            if "report_path" in validation_report and validation_report["report_path"]:
                val_report["report_path"] = str(validation_report["report_path"])

        # Check existing record to preserve review history and ensure determinism
        record_path = self.get_record_path(content_id)
        existing_record = self.load_review_record(content_id)
        
        reviewer_notes = []
        if existing_record and not overwrite:
            # If the exact content file is already reviewed and matches SHA, return it deterministically
            if existing_record.get("content_sha256") == content_sha:
                return existing_record
            # If SHA differs, preserve existing review notes as history
            reviewer_notes = list(existing_record.get("reviewer_notes", []))

        record = {
            "schema_version": "review_v1",
            "content_id": content_id,
            "blueprint_id": blueprint_id,
            "curriculum_id": curriculum_id,
            "content_sha256": content_sha,
            "validator_report": val_report,
            "review_status": STATUS_PENDING,
            "gates": {
                "hindi": hindi_gate,
                "santali": santali_gate,
                "curriculum": curriculum_gate,
                "answer_key": answer_key_gate,
                "provisional_range": provisional_gate,
            },
            "santali_script_confirmed": None,
            "reviewer_notes": reviewer_notes,
        }

        # Validate against review_schema.json
        errs = self.validate_review_record(record)
        if errs:
            raise ReviewValidationError(
                f"Generated review record violates review_schema.json:\n" + "\n".join(errs),
                errors=errs,
            )

        self._atomic_write_json(record_path, record)
        return record

    def approve(
        self,
        content_id: str,
        reviewer_id: Union[str, List[str]],
        date: Optional[str] = None,
        santali_script_confirmed: Optional[str] = None,
        note: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Explicitly approve a content unit by human reviewer(s).

        Args:
            content_id: The content unit ID to approve.
            reviewer_id: Reviewer identifier or list of reviewer identifiers.
            date: Approval date string YYYY-MM-DD (defaults to today).
            santali_script_confirmed: Confirmed script if Santali is applicable ('Olck', etc.).
            note: Optional note summarizing review.

        Returns:
            The updated review record.
        """
        record = self.load_review_record(content_id)
        if not record:
            raise ReviewRecordNotFoundError(f"No review record found for content ID: {content_id}")

        # Rule: Machine validation must have passed; cannot approve failed content
        if not record["validator_report"].get("passed"):
            raise ReviewValidationError(
                f"Cannot approve {content_id}: content failed machine validation."
            )

        # Normalize reviewers
        if isinstance(reviewer_id, str):
            reviewers = [reviewer_id.strip()] if reviewer_id.strip() else []
        elif isinstance(reviewer_id, list):
            reviewers = [r.strip() for r in reviewer_id if isinstance(r, str) and r.strip()]
        else:
            reviewers = []

        if not reviewers:
            raise ReviewValidationError("Human approval requires at least one reviewer ID.")

        approval_date = date or datetime.date.today().isoformat()

        # Check gates
        gates = record.get("gates", {})
        for gate_name in VALID_GATES:
            current_val = gates.get(gate_name)
            if current_val == GATE_FAIL:
                raise ReviewValidationError(
                    f"Cannot approve {content_id}: gate '{gate_name}' is marked 'fail'."
                )
            if current_val == GATE_PENDING:
                gates[gate_name] = GATE_PASS

        # Santali gate script confirmation check
        if gates.get("santali") == GATE_PASS:
            confirmed_script = santali_script_confirmed or record.get("santali_script_confirmed")
            if not confirmed_script or confirmed_script not in VALID_SANTALI_SCRIPTS:
                raise ReviewValidationError(
                    f"Santali gate is passing: santali_script_confirmed must be one of {sorted(VALID_SANTALI_SCRIPTS)}; got {confirmed_script}"
                )
            record["santali_script_confirmed"] = confirmed_script
        else:
            record["santali_script_confirmed"] = None

        record["review_status"] = STATUS_APPROVED
        record["approved_by"] = reviewers
        record["approved_at"] = approval_date

        if note:
            record.setdefault("reviewer_notes", []).append({
                "gate": "general",
                "reviewer": reviewers[0],
                "date": approval_date,
                "note": note.strip(),
            })

        errs = self.validate_review_record(record)
        if errs:
            raise ReviewValidationError(
                f"Approved record violates review_schema.json:\n" + "\n".join(errs),
                errors=errs,
            )

        self._atomic_write_json(self.get_record_path(content_id), record)
        return record

    def reject(
        self,
        content_id: str,
        reviewer_id: str,
        reason: str,
        gate: Optional[str] = None,
        date: Optional[str] = None,
        item_ids: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """Explicitly reject a content unit with recorded evidence and failing gate.

        Args:
            content_id: The content unit ID to reject.
            reviewer_id: Reviewer identifier.
            reason: Explanation of rejection.
            gate: Failing gate name ('hindi', 'santali', 'curriculum', 'answer_key', 'provisional_range', 'general').
            date: Rejection date string YYYY-MM-DD (defaults to today).
            item_ids: Optional list of question/card item IDs with errors.

        Returns:
            The updated review record.
        """
        record = self.load_review_record(content_id)
        if not record:
            raise ReviewRecordNotFoundError(f"No review record found for content ID: {content_id}")

        if not reviewer_id or not reviewer_id.strip():
            raise ReviewValidationError("Rejection requires a non-empty reviewer ID.")
        if not reason or not reason.strip():
            raise ReviewValidationError("Rejection requires a non-empty reason/note.")

        chosen_gate = gate or "general"
        if chosen_gate not in VALID_NOTES_GATES:
            raise ReviewValidationError(
                f"Invalid gate '{chosen_gate}'. Must be one of {sorted(VALID_NOTES_GATES)}"
            )

        rejection_date = date or datetime.date.today().isoformat()

        # Update failing gate if applicable
        if chosen_gate in VALID_GATES:
            record["gates"][chosen_gate] = GATE_FAIL

        record["review_status"] = STATUS_REJECTED
        record.pop("approved_by", None)
        record.pop("approved_at", None)

        note_entry: Dict[str, Any] = {
            "gate": chosen_gate,
            "reviewer": reviewer_id.strip(),
            "date": rejection_date,
            "note": reason.strip(),
        }
        if item_ids:
            note_entry["item_ids"] = item_ids

        record.setdefault("reviewer_notes", []).append(note_entry)

        errs = self.validate_review_record(record)
        if errs:
            raise ReviewValidationError(
                f"Rejected record violates review_schema.json:\n" + "\n".join(errs),
                errors=errs,
            )

        self._atomic_write_json(self.get_record_path(content_id), record)
        return record

    def request_changes(
        self,
        content_id: str,
        reviewer_id: str,
        note: str,
        gate: Optional[str] = None,
        date: Optional[str] = None,
        item_ids: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """Request changes for a content unit with notes for revision."""
        record = self.load_review_record(content_id)
        if not record:
            raise ReviewRecordNotFoundError(f"No review record found for content ID: {content_id}")

        if not reviewer_id or not reviewer_id.strip():
            raise ReviewValidationError("Requesting changes requires a reviewer ID.")
        if not note or not note.strip():
            raise ReviewValidationError("Requesting changes requires a note.")

        chosen_gate = gate or "general"
        if chosen_gate not in VALID_NOTES_GATES:
            raise ReviewValidationError(
                f"Invalid gate '{chosen_gate}'. Must be one of {sorted(VALID_NOTES_GATES)}"
            )

        change_date = date or datetime.date.today().isoformat()

        record["review_status"] = STATUS_CHANGES_REQUESTED
        record.pop("approved_by", None)
        record.pop("approved_at", None)

        note_entry: Dict[str, Any] = {
            "gate": chosen_gate,
            "reviewer": reviewer_id.strip(),
            "date": change_date,
            "note": note.strip(),
        }
        if item_ids:
            note_entry["item_ids"] = item_ids

        record.setdefault("reviewer_notes", []).append(note_entry)

        errs = self.validate_review_record(record)
        if errs:
            raise ReviewValidationError(
                f"Changes requested record violates review_schema.json:\n" + "\n".join(errs),
                errors=errs,
            )

        self._atomic_write_json(self.get_record_path(content_id), record)
        return record

    def reopen_for_review(
        self,
        content_id: str,
        reviewer_id: str,
        note: Optional[str] = None,
        date: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Transition a rejected or changes_requested record back to pending review."""
        record = self.load_review_record(content_id)
        if not record:
            raise ReviewRecordNotFoundError(f"No review record found for content ID: {content_id}")

        reopen_date = date or datetime.date.today().isoformat()
        record["review_status"] = STATUS_PENDING
        record.pop("approved_by", None)
        record.pop("approved_at", None)

        # Reset failed gates back to pending
        for gate_name, val in record.get("gates", {}).items():
            if val == GATE_FAIL:
                record["gates"][gate_name] = GATE_PENDING

        if note:
            record.setdefault("reviewer_notes", []).append({
                "gate": "general",
                "reviewer": reviewer_id.strip(),
                "date": reopen_date,
                "note": note.strip(),
            })

        errs = self.validate_review_record(record)
        if errs:
            raise ReviewValidationError(
                f"Reopened record violates review_schema.json:\n" + "\n".join(errs),
                errors=errs,
            )

        self._atomic_write_json(self.get_record_path(content_id), record)
        return record

    def is_needs_review(self, content_id_or_record: Union[str, Dict[str, Any]]) -> bool:
        """Check if a record is in a state requiring human review."""
        if isinstance(content_id_or_record, str):
            record = self.load_review_record(content_id_or_record)
            if not record:
                return False
        else:
            record = content_id_or_record
        return record.get("review_status") in (STATUS_PENDING, STATUS_IN_REVIEW, STATUS_CHANGES_REQUESTED)

    def is_approved(self, content_id_or_record: Union[str, Dict[str, Any]]) -> bool:
        """Check if a record is approved."""
        if isinstance(content_id_or_record, str):
            record = self.load_review_record(content_id_or_record)
            if not record:
                return False
        else:
            record = content_id_or_record
        return record.get("review_status") == STATUS_APPROVED

    def is_rejected(self, content_id_or_record: Union[str, Dict[str, Any]]) -> bool:
        """Check if a record is rejected."""
        if isinstance(content_id_or_record, str):
            record = self.load_review_record(content_id_or_record)
            if not record:
                return False
        else:
            record = content_id_or_record
        return record.get("review_status") == STATUS_REJECTED

    def verify_content_integrity(
        self,
        content_path: str,
        record: Optional[Dict[str, Any]] = None,
    ) -> bool:
        """Verify that the content file on disk matches the SHA-256 recorded during review."""
        if not os.path.exists(content_path):
            return False
        current_sha = compute_file_sha256(content_path)
        if record is None:
            with open(content_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            cid = data.get("content_id")
            if not cid:
                return False
            record = self.load_review_record(cid)
            if not record:
                return False
        return current_sha == record.get("content_sha256")


def main():
    ap = argparse.ArgumentParser(description="Human Review Manager for Bilingual FLN Content.")
    sub = ap.add_subparsers(dest="command", required=True)

    # create
    p_create = sub.add_parser("create", help="Create a review record for generated content.")
    p_create.add_argument("--content-id", "-c", required=True, help="Content ID")
    p_create.add_argument("--content-path", "-p", help="Path to content JSON file")
    p_create.add_argument("--records-dir", "-r", help="Directory to store review records")
    p_create.add_argument("--force", action="store_true", help="Overwrite existing review record")

    # approve
    p_app = sub.add_parser("approve", help="Approve a content unit after human review.")
    p_app.add_argument("--content-id", "-c", required=True, help="Content ID")
    p_app.add_argument("--reviewer", "-u", required=True, help="Reviewer ID/name")
    p_app.add_argument("--santali-script", "-s", choices=["Olck", "Deva", "Beng", "Orya", "Latn"], help="Confirmed Santali script")
    p_app.add_argument("--date", "-d", help="Approval date (YYYY-MM-DD)")
    p_app.add_argument("--note", "-n", help="Reviewer note")
    p_app.add_argument("--records-dir", "-r", help="Directory for review records")

    # reject
    p_rej = sub.add_parser("reject", help="Reject a content unit.")
    p_rej.add_argument("--content-id", "-c", required=True, help="Content ID")
    p_rej.add_argument("--reviewer", "-u", required=True, help="Reviewer ID/name")
    p_rej.add_argument("--reason", "-m", required=True, help="Rejection reason")
    p_rej.add_argument(
        "--gate",
        "-g",
        choices=["hindi", "santali", "curriculum", "answer_key", "provisional_range", "general"],
        default="general",
        help="Failing gate",
    )
    p_rej.add_argument("--date", "-d", help="Date (YYYY-MM-DD)")
    p_rej.add_argument("--records-dir", "-r", help="Directory for review records")

    # request-changes
    p_chg = sub.add_parser("request-changes", help="Request changes for a content unit.")
    p_chg.add_argument("--content-id", "-c", required=True, help="Content ID")
    p_chg.add_argument("--reviewer", "-u", required=True, help="Reviewer ID/name")
    p_chg.add_argument("--note", "-n", required=True, help="Change request note")
    p_chg.add_argument(
        "--gate",
        "-g",
        choices=["hindi", "santali", "curriculum", "answer_key", "provisional_range", "general"],
        default="general",
    )
    p_chg.add_argument("--date", "-d", help="Date (YYYY-MM-DD)")
    p_chg.add_argument("--records-dir", "-r", help="Directory for review records")

    # show
    p_show = sub.add_parser("show", help="Show a review record.")
    p_show.add_argument("--content-id", "-c", required=True, help="Content ID")
    p_show.add_argument("--records-dir", "-r", help="Directory for review records")
    p_show.add_argument("--json", action="store_true", help="Print as raw JSON")

    args = ap.parse_args()
    mgr = ReviewManager(records_dir=args.records_dir)

    if args.command == "create":
        content_path = args.content_path
        if not content_path:
            content_path = os.path.join(DEFAULT_CONTENT_DIR, f"{args.content_id}.json")
        rec = mgr.create_review_record(content_path, overwrite=args.force)
        print(f"[CREATED] Review record for {rec['content_id']}")
        print(f"  Status: {rec['review_status']}")
        print(f"  Gates: {rec['gates']}")
        print(f"  Path: {mgr.get_record_path(rec['content_id'])}")

    elif args.command == "approve":
        rec = mgr.approve(
            content_id=args.content_id,
            reviewer_id=args.reviewer,
            date=args.date,
            santali_script_confirmed=args.santali_script,
            note=args.note,
        )
        print(f"[APPROVED] {rec['content_id']}")
        print(f"  Approved by: {rec['approved_by']}")
        print(f"  Approved at: {rec['approved_at']}")
        print(f"  Santali script: {rec.get('santali_script_confirmed')}")

    elif args.command == "reject":
        rec = mgr.reject(
            content_id=args.content_id,
            reviewer_id=args.reviewer,
            reason=args.reason,
            gate=args.gate,
            date=args.date,
        )
        print(f"[REJECTED] {rec['content_id']}")
        print(f"  Gate: {args.gate}")
        print(f"  Reason: {args.reason}")

    elif args.command == "request-changes":
        rec = mgr.request_changes(
            content_id=args.content_id,
            reviewer_id=args.reviewer,
            note=args.note,
            gate=args.gate,
            date=args.date,
        )
        print(f"[CHANGES REQUESTED] {rec['content_id']}")
        print(f"  Note: {args.note}")

    elif args.command == "show":
        rec = mgr.load_review_record(args.content_id)
        if not rec:
            sys.stderr.write(f"No review record found for {args.content_id}\n")
            sys.exit(1)
        if args.json:
            print(json.dumps(rec, indent=2, ensure_ascii=False))
        else:
            print(f"Content ID: {rec['content_id']}")
            print(f"Status: {rec['review_status']}")
            print(f"Blueprint ID: {rec['blueprint_id']}")
            print(f"Curriculum ID: {rec['curriculum_id']}")
            print(f"Content SHA: {rec['content_sha256']}")
            print(f"Gates: {json.dumps(rec['gates'], indent=2)}")
            if rec.get("santali_script_confirmed"):
                print(f"Santali Script Confirmed: {rec['santali_script_confirmed']}")
            if rec.get("approved_by"):
                print(f"Approved by: {rec['approved_by']} at {rec['approved_at']}")
            if rec.get("reviewer_notes"):
                print(f"Notes ({len(rec['reviewer_notes'])}):")
                for n in rec["reviewer_notes"]:
                    print(f"  - [{n['date']}] {n['reviewer']} ({n['gate']}): {n['note']}")


if __name__ == "__main__":
    main()
