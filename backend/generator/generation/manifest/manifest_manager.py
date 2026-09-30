"""Manifest manager for tracking content generation, validation, and review lifecycle."""
import argparse
import copy
import datetime
import hashlib
import json
import os
import re
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Union

# Path configuration
HERE = os.path.dirname(os.path.abspath(__file__))
GEN_DIR = os.path.dirname(HERE)
PROJECT_DIR = os.path.dirname(GEN_DIR)

DEFAULT_MANIFEST_PATH = os.path.join(HERE, "generation_manifest.json")
DEFAULT_GENERATED_DIR = os.path.join(GEN_DIR, "generated", "pilot_v1")

# Valid status enums from generation_manifest.json
VALID_GENERATION_STATUSES = {"planned", "generated", "failed", "validated", "rejected", "stale"}
VALID_REVIEW_STATUSES = {"pending", "in_review", "changes_requested", "approved", "rejected"}


class ManifestError(Exception):
    """Base exception for manifest operations."""
    pass


class ManifestEntryNotFoundError(ManifestError):
    """Raised when an entry with the given content_id does not exist in the manifest."""
    pass


class ManifestValidationError(ManifestError):
    """Raised when manifest structure or entry data fails validation."""
    def __init__(self, message: str, errors: Optional[List[str]] = None):
        super().__init__(message)
        self.errors = errors or []


class ManifestConsistencyError(ManifestError):
    """Raised when state across artifacts, review, and manifest is inconsistent."""
    pass


def compute_file_sha256(path: str) -> str:
    """Compute hex SHA-256 hash of a file."""
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


class ManifestManager:
    """Manages the generation manifest as the authoritative inventory and lifecycle ledger."""

    def __init__(
        self,
        manifest_path: Optional[str] = None,
        review_manager: Optional[Any] = None,
    ):
        self.manifest_path = os.path.abspath(manifest_path or DEFAULT_MANIFEST_PATH)
        self.review_manager = review_manager
        self._manifest: Dict[str, Any] = {}
        self._entries_by_id: Dict[str, Dict[str, Any]] = {}
        self.load(self.manifest_path)

    def load(self, path: Optional[str] = None) -> Dict[str, Any]:
        """Load manifest from JSON file and index its entries."""
        target_path = os.path.abspath(path or self.manifest_path)
        if not os.path.exists(target_path):
            raise FileNotFoundError(f"Manifest file not found at: {target_path}")

        with open(target_path, "r", encoding="utf-8") as f:
            try:
                data = json.load(f)
            except json.JSONDecodeError as e:
                raise ManifestValidationError(f"Malformed JSON in manifest: {e}")

        self._manifest = data
        self.manifest_path = target_path

        # Validate structural contract
        errors = self.validate_structure()
        if errors:
            raise ManifestValidationError(
                f"Manifest failed structural validation:\n" + "\n".join(errors),
                errors=errors,
            )

        # Index entries by content_id
        self._entries_by_id = {}
        for entry in self._manifest.get("entries", []):
            cid = entry.get("content_id")
            if cid:
                self._entries_by_id[cid] = entry

        return self._manifest

    def validate_structure(self) -> List[str]:
        """Validate that the manifest complies with its structural contract."""
        errors: List[str] = []
        required_top_keys = {"manifest_version", "batch", "inputs", "status_values", "rules", "summary", "entries"}
        missing_top = required_top_keys - set(self._manifest.keys())
        if missing_top:
            errors.append(f"Missing required top-level keys: {sorted(missing_top)}")

        entries = self._manifest.get("entries")
        if not isinstance(entries, list):
            errors.append("Top-level 'entries' must be a list.")
            return errors

        seen_ids: Set[str] = set()
        required_entry_keys = {
            "content_id", "blueprint_id", "curriculum_id", "grade", "domain",
            "content_type", "languages", "curriculum_version", "blueprint_version",
            "prompt_stack", "prompt_version", "generation_status", "review_status",
            "output_path", "provisional", "conflict_refs", "superseded_by", "notes"
        }

        for idx, entry in enumerate(entries):
            if not isinstance(entry, dict):
                errors.append(f"Entry at index {idx} is not a dictionary.")
                continue

            cid = entry.get("content_id")
            if not cid:
                errors.append(f"Entry at index {idx} missing 'content_id'.")
                continue

            if cid in seen_ids:
                errors.append(f"Duplicate content_id '{cid}' found at index {idx}.")
            seen_ids.add(cid)

            missing_keys = required_entry_keys - set(entry.keys())
            if missing_keys:
                errors.append(f"Entry '{cid}' missing required keys: {sorted(missing_keys)}")

            gen_status = entry.get("generation_status")
            if gen_status not in VALID_GENERATION_STATUSES:
                errors.append(
                    f"Entry '{cid}' has invalid generation_status '{gen_status}'. Must be one of {sorted(VALID_GENERATION_STATUSES)}"
                )

            rev_status = entry.get("review_status")
            if rev_status not in VALID_REVIEW_STATUSES:
                errors.append(
                    f"Entry '{cid}' has invalid review_status '{rev_status}'. Must be one of {sorted(VALID_REVIEW_STATUSES)}"
                )

        return errors

    def _atomic_write_json(self, target_path: str, data: Dict[str, Any]) -> None:
        """Atomically write JSON to file via temporary file and replace."""
        dir_name = os.path.dirname(os.path.abspath(target_path))
        os.makedirs(dir_name, exist_ok=True)
        fd, temp_path = tempfile.mkstemp(dir=dir_name, prefix=".tmp_manifest_")
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

    def get_entry(self, content_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve an entry by content_id. Returns None if not found."""
        return self._entries_by_id.get(content_id)

    def require_entry(self, content_id: str) -> Dict[str, Any]:
        """Retrieve an entry by content_id. Raises ManifestEntryNotFoundError if not found."""
        entry = self.get_entry(content_id)
        if not entry:
            raise ManifestEntryNotFoundError(f"Content unit '{content_id}' not found in manifest.")
        return entry

    def list_entries(
        self,
        blueprint_id: Optional[str] = None,
        curriculum_id: Optional[str] = None,
        generation_status: Optional[str] = None,
        review_status: Optional[str] = None,
        domain: Optional[str] = None,
        grade: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """List and filter manifest entries."""
        results = []
        for entry in self._manifest.get("entries", []):
            if blueprint_id and entry.get("blueprint_id") != blueprint_id:
                continue
            if curriculum_id and entry.get("curriculum_id") != curriculum_id:
                continue
            if generation_status and entry.get("generation_status") != generation_status:
                continue
            if review_status and entry.get("review_status") != review_status:
                continue
            if domain and entry.get("domain") != domain:
                continue
            if grade is not None and entry.get("grade") != grade:
                continue
            results.append(entry)
        return results

    def register_generation(
        self,
        content_id: str,
        model: str,
        output_path: str,
        content_sha256: Optional[str] = None,
        validation_passed: bool = True,
        validator_version: str = "1.0.0",
        validation_report_path: Optional[str] = None,
        model_parameters: Optional[Dict[str, Any]] = None,
        timestamp: Optional[str] = None,
        notes: Optional[List[str]] = None,
        check_file_exists: bool = True,
    ) -> Dict[str, Any]:
        """Record the outcome of content generation and machine validation.

        Args:
            content_id: The unique content unit ID.
            model: Name/identifier of the model/provider used.
            output_path: Path to the generated JSON artifact.
            content_sha256: Hex SHA-256 of the generated artifact.
            validation_passed: True if schema and content validation passed; False otherwise.
            validator_version: Version string of the validator suite.
            validation_report_path: Optional path to validator report.
            model_parameters: Optional dictionary of generation parameters.
            timestamp: ISO timestamp (defaults to current UTC time).
            notes: Optional list of note strings to append.
            check_file_exists: If True and validation_passed=True, verify file exists.

        Returns:
            The updated manifest entry.
        """
        entry = self.require_entry(content_id)

        # Normalize output path relative to project root or preserve existing style
        rel_output_path = output_path
        if os.path.isabs(output_path):
            try:
                rel_output_path = os.path.relpath(output_path, PROJECT_DIR).replace("\\", "/")
            except ValueError:
                rel_output_path = output_path.replace("\\", "/")

        # Check artifact presence and compute SHA if passing
        actual_sha = content_sha256
        if validation_passed:
            if os.path.isabs(output_path):
                abs_path = output_path
            else:
                abs_path = os.path.join(PROJECT_DIR, rel_output_path)
            if check_file_exists and not os.path.exists(abs_path):
                raise ManifestConsistencyError(
                    f"Cannot register successful generation for '{content_id}': output artifact not found at {abs_path}"
                )
            if os.path.exists(abs_path) and not actual_sha:
                actual_sha = compute_file_sha256(abs_path)

        # Invariant: Failed validation must never be marked as validated or approved
        if validation_passed:
            entry["generation_status"] = "validated"
            entry["validation_passed"] = True
        else:
            entry["generation_status"] = "failed"
            entry["validation_passed"] = False

        entry["model"] = model
        entry["model_parameters"] = model_parameters
        entry["generation_timestamp"] = timestamp or datetime.datetime.now(datetime.timezone.utc).isoformat()
        entry["output_path"] = rel_output_path
        entry["content_sha256"] = actual_sha
        entry["validator_version"] = validator_version
        entry["validation_report_path"] = validation_report_path

        if notes:
            for n in notes:
                if n not in entry.setdefault("notes", []):
                    entry["notes"].append(n)

        return entry

    def register_from_orchestrator(
        self,
        result: Any,
        model_parameters: Optional[Dict[str, Any]] = None,
        check_file_exists: bool = True,
    ) -> Dict[str, Any]:
        """Convenience helper to register an orchestrator GenerationResult."""
        content_id = getattr(result, "content_id", None)
        if not content_id:
            raise ManifestValidationError("GenerationResult missing content_id.")

        output_path = getattr(result, "output_path", None) or f"generation/generated/pilot_v1/{content_id}.json"
        validation_passed = getattr(result, "is_success", False)
        provider_used = getattr(result, "provider_used", "unknown")
        errors = getattr(result, "errors", [])

        note_strings = [str(err) for err in errors] if not validation_passed else None

        return self.register_generation(
            content_id=content_id,
            model=provider_used,
            output_path=output_path,
            validation_passed=validation_passed,
            model_parameters=model_parameters,
            notes=note_strings,
            check_file_exists=check_file_exists,
        )

    def sync_review(
        self,
        content_id: str,
        review_record: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Synchronize review state from ReviewManager into the manifest.

        Args:
            content_id: Content unit ID to synchronize.
            review_record: Optional review record dict; if None, loads from review_manager.

        Returns:
            The updated manifest entry.
        """
        entry = self.require_entry(content_id)

        if review_record is None:
            if self.review_manager is None:
                # Lazy import if not injected
                from review.review_manager import ReviewManager
                self.review_manager = ReviewManager()
            review_record = self.review_manager.load_review_record(content_id)
            if not review_record:
                raise ManifestConsistencyError(f"No review record found for content ID '{content_id}'.")

        if review_record.get("content_id") != content_id:
            raise ManifestValidationError(
                f"Review record content_id '{review_record.get('content_id')}' does not match requested '{content_id}'."
            )

        # Integrity verification: review record SHA must match manifest content SHA if generated
        rev_sha = review_record.get("content_sha256")
        manifest_sha = entry.get("content_sha256")
        if manifest_sha and rev_sha and manifest_sha != rev_sha:
            raise ManifestConsistencyError(
                f"Hash mismatch for '{content_id}': manifest has {manifest_sha}, review record has {rev_sha}."
            )

        new_review_status = review_record.get("review_status")
        if new_review_status not in VALID_REVIEW_STATUSES:
            raise ManifestValidationError(f"Invalid review_status in review record: {new_review_status}")

        # Invariant: Manifest cannot claim approved if machine validation failed
        if new_review_status == "approved" and not entry.get("validation_passed"):
            raise ManifestConsistencyError(
                f"Cannot mark '{content_id}' as approved: machine validation has not passed in manifest."
            )

        entry["review_status"] = new_review_status

        # If rejected, record rejection note if present
        if new_review_status == "rejected":
            entry["generation_status"] = "rejected"
            notes = review_record.get("reviewer_notes", [])
            if notes:
                latest = notes[-1]
                note_str = f"Rejected by {latest.get('reviewer')} on {latest.get('date')} ({latest.get('gate')}): {latest.get('note')}"
                if note_str not in entry.setdefault("notes", []):
                    entry["notes"].append(note_str)

        return entry

    def update_review_status(
        self,
        content_id: str,
        review_status: str,
        note: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Update review status directly with safety checks.

        Args:
            content_id: Content unit ID.
            review_status: Target status ('pending', 'in_review', 'changes_requested', 'approved', 'rejected').
            note: Optional note string to append.

        Returns:
            The updated manifest entry.
        """
        entry = self.require_entry(content_id)
        if review_status not in VALID_REVIEW_STATUSES:
            raise ManifestValidationError(
                f"Invalid review_status '{review_status}'. Must be one of {sorted(VALID_REVIEW_STATUSES)}"
            )

        # Invariant: Cannot claim approved without review substantiate check
        if review_status == "approved":
            if not entry.get("validation_passed"):
                raise ManifestConsistencyError(f"Cannot approve '{content_id}': machine validation has not passed.")
            # Verify review manager record exists and is approved
            if self.review_manager is not None:
                rev_rec = self.review_manager.load_review_record(content_id)
                if not rev_rec or rev_rec.get("review_status") != "approved":
                    raise ManifestConsistencyError(
                        f"Cannot mark '{content_id}' as approved: no approved review record in ReviewManager."
                    )

        entry["review_status"] = review_status
        if review_status == "rejected":
            entry["generation_status"] = "rejected"

        if note and note not in entry.setdefault("notes", []):
            entry["notes"].append(note)

        return entry

    def mark_stale_by_conflicts(
        self,
        conflict_refs: List[str],
        reason: Optional[str] = None,
    ) -> List[str]:
        """Find all entries dependent on specified conflict_refs and mark them 'stale'.

        Args:
            conflict_refs: List of conflict reference IDs that have changed.
            reason: Optional explanation for why the conflict changed.

        Returns:
            List of content IDs that were marked stale.
        """
        affected_cids: List[str] = []
        conflict_set = set(conflict_refs)

        for entry in self._manifest.get("entries", []):
            entry_conflicts = set(entry.get("conflict_refs", []))
            if entry_conflicts & conflict_set:
                entry["generation_status"] = "stale"
                cid = entry["content_id"]
                affected_cids.append(cid)
                note_str = f"Marked stale: provisional decision changed for {sorted(entry_conflicts & conflict_set)}."
                if reason:
                    note_str += f" Reason: {reason}"
                if note_str not in entry.setdefault("notes", []):
                    entry["notes"].append(note_str)

        return affected_cids

    def create_revision(self, content_id: str) -> Dict[str, Any]:
        """Create a new version (-v2, etc.) of an existing content unit, marking the old one superseded.

        Enforces: 'Regenerating a unit creates -v2 and sets superseded_by on the old entry;
                   never overwrite a generated file.'

        Args:
            content_id: Current content unit ID (e.g. 'GC-G1-NUM-032-01-bi-v1').

        Returns:
            The newly created planned revision entry.
        """
        old_entry = self.require_entry(content_id)

        # Parse version number from content_id suffix: -v<N>
        m = re.search(r"-v([0-9]+)$", content_id)
        if not m:
            raise ManifestValidationError(f"Cannot parse version number from content_id '{content_id}'.")

        current_ver = int(m.group(1))
        next_ver = current_ver + 1
        new_content_id = f"{content_id[:m.start()]}-v{next_ver}"

        if new_content_id in self._entries_by_id:
            raise ManifestConsistencyError(f"Revision entry '{new_content_id}' already exists in manifest.")

        # Mark old entry as superseded
        old_entry["superseded_by"] = new_content_id

        # Clone and reset generation fields for the new planned version
        new_entry = copy.deepcopy(old_entry)
        new_entry["content_id"] = new_content_id
        new_entry["generation_status"] = "planned"
        new_entry["model"] = None
        new_entry["model_parameters"] = None
        new_entry["generation_timestamp"] = None
        new_entry["content_sha256"] = None
        new_entry["validator_version"] = None
        new_entry["validation_passed"] = None
        new_entry["validation_report_path"] = None
        new_entry["review_status"] = "pending"
        new_entry["output_path"] = f"generation/generated/pilot_v1/{new_content_id}.json"
        new_entry["superseded_by"] = None
        new_entry["notes"] = [f"Created revision v{next_ver} to supersede {content_id}."]

        # Add to manifest entries and index
        self._manifest.setdefault("entries", []).append(new_entry)
        self._entries_by_id[new_content_id] = new_entry

        return new_entry

    def recompute_summary(self) -> Dict[str, Any]:
        """Recompute manifest summary statistics."""
        entries = self._manifest.get("entries", [])
        blueprints = set(e.get("blueprint_id") for e in entries if e.get("blueprint_id"))

        summary = {
            "blueprints": len(blueprints),
            "planned_units": len(entries),
            "bilingual_units": sum(1 for e in entries if "-bi-" in e.get("content_id", "")),
            "parallel_units": sum(1 for e in entries if "-bi-" not in e.get("content_id", "")),
            "validated_units": sum(1 for e in entries if e.get("generation_status") == "validated"),
            "failed_units": sum(1 for e in entries if e.get("generation_status") == "failed"),
            "approved_units": sum(1 for e in entries if e.get("review_status") == "approved"),
            "rejected_units": sum(1 for e in entries if e.get("review_status") == "rejected"),
            "stale_units": sum(1 for e in entries if e.get("generation_status") == "stale"),
        }
        self._manifest["summary"] = summary
        return summary

    def save(self, path: Optional[str] = None) -> None:
        """Atomically persist manifest to disk after recomputing summary."""
        target_path = os.path.abspath(path or self.manifest_path)
        self.recompute_summary()
        self._atomic_write_json(target_path, self._manifest)


def main():
    ap = argparse.ArgumentParser(description="Manifest Manager for Bilingual FLN Content Generation.")
    ap.add_argument("--manifest", "-m", help="Path to generation_manifest.json")
    sub = ap.add_subparsers(dest="command", required=True)

    # show
    p_show = sub.add_parser("show", help="Show details for a content unit.")
    p_show.add_argument("--content-id", "-c", required=True, help="Content ID")
    p_show.add_argument("--json", action="store_true", help="Output as raw JSON")

    # list
    p_list = sub.add_parser("list", help="List manifest entries with optional filters.")
    p_list.add_argument("--blueprint-id", "-b", help="Filter by blueprint ID")
    p_list.add_argument("--generation-status", "-g", choices=list(VALID_GENERATION_STATUSES), help="Filter by generation status")
    p_list.add_argument("--review-status", "-r", choices=list(VALID_REVIEW_STATUSES), help="Filter by review status")
    p_list.add_argument("--domain", "-d", choices=["literacy", "numeracy"], help="Filter by domain")
    p_list.add_argument("--grade", type=int, choices=[1, 2], help="Filter by grade")

    # summary
    sub.add_parser("summary", help="Show manifest summary statistics.")

    # sync-review
    p_sync = sub.add_parser("sync-review", help="Synchronize review status from ReviewManager.")
    p_sync.add_argument("--content-id", "-c", required=True, help="Content ID")

    # mark-stale
    p_stale = sub.add_parser("mark-stale", help="Mark units dependent on a conflict_ref as stale.")
    p_stale.add_argument("--conflict-ref", "-r", required=True, help="Conflict reference ID")
    p_stale.add_argument("--reason", help="Reason for marking stale")

    args = ap.parse_args()
    mgr = ManifestManager(manifest_path=args.manifest)

    if args.command == "show":
        entry = mgr.require_entry(args.content_id)
        if args.json:
            print(json.dumps(entry, indent=2, ensure_ascii=False))
        else:
            print(f"Content ID:          {entry['content_id']}")
            print(f"Blueprint ID:        {entry['blueprint_id']}")
            print(f"Curriculum ID:       {entry['curriculum_id']}")
            print(f"Grade / Domain:      Grade {entry['grade']} / {entry['domain']}")
            print(f"Languages:           {', '.join(entry['languages'])}")
            print(f"Generation Status:   {entry['generation_status']}")
            print(f"Review Status:       {entry['review_status']}")
            print(f"Model / Provider:    {entry.get('model') or 'None'}")
            print(f"Output Path:         {entry['output_path']}")
            print(f"Content SHA-256:     {entry.get('content_sha256') or 'None'}")
            print(f"Validation Passed:   {entry.get('validation_passed')}")
            if entry.get("conflict_refs"):
                print(f"Conflict Refs:       {', '.join(entry['conflict_refs'])}")
            if entry.get("superseded_by"):
                print(f"Superseded By:       {entry['superseded_by']}")
            if entry.get("notes"):
                print("Notes:")
                for n in entry["notes"]:
                    print(f"  - {n}")

    elif args.command == "list":
        entries = mgr.list_entries(
            blueprint_id=args.blueprint_id,
            generation_status=args.generation_status,
            review_status=args.review_status,
            domain=args.domain,
            grade=args.grade,
        )
        print(f"Found {len(entries)} matching entries:")
        for e in entries:
            gen_s = e['generation_status']
            rev_s = e['review_status']
            print(f"  [{gen_s:<10}] [{rev_s:<15}] {e['content_id']} ({e['blueprint_id']})")

    elif args.command == "summary":
        summary = mgr.recompute_summary()
        print("Manifest Summary:")
        for k, v in summary.items():
            print(f"  {k:<20}: {v}")

    elif args.command == "sync-review":
        entry = mgr.sync_review(args.content_id)
        mgr.save()
        print(f"Synchronized review for {args.content_id}: review_status={entry['review_status']}")

    elif args.command == "mark-stale":
        affected = mgr.mark_stale_by_conflicts([args.conflict_ref], reason=args.reason)
        mgr.save()
        print(f"Marked {len(affected)} units as stale for conflict '{args.conflict_ref}':")
        for cid in affected:
            print(f"  - {cid}")


if __name__ == "__main__":
    main()
