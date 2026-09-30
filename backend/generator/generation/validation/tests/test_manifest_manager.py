"""Unit and integration tests for ManifestManager."""
import copy
import json
import os
import shutil
import sys
import tempfile
import unittest

# Ensure generation package and submodules are in sys.path
HERE = os.path.dirname(os.path.abspath(__file__))
GEN_DIR = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, GEN_DIR)
sys.path.insert(0, os.path.join(GEN_DIR, "manifest"))
sys.path.insert(0, os.path.join(GEN_DIR, "review"))
sys.path.insert(0, os.path.join(GEN_DIR, "validation"))

from manifest_manager import (
    ManifestManager,
    ManifestError,
    ManifestEntryNotFoundError,
    ManifestValidationError,
    ManifestConsistencyError,
)
from review_manager import ReviewManager
from orchestrator import GenerationOrchestrator
from providers.mock import MockProvider


class TestManifestManager(unittest.TestCase):
    def setUp(self):
        # Create an isolated temporary directory
        self.test_dir = tempfile.mkdtemp(prefix="test_manifest_")
        self.temp_manifest_path = os.path.join(self.test_dir, "generation_manifest.json")
        self.records_dir = os.path.join(self.test_dir, "records")
        self.output_dir = os.path.join(self.test_dir, "output")
        os.makedirs(self.records_dir, exist_ok=True)
        os.makedirs(self.output_dir, exist_ok=True)

        # Copy original manifest into temp directory so tests don't mutate repo file
        self.orig_manifest_path = os.path.join(GEN_DIR, "manifest", "generation_manifest.json")
        shutil.copy2(self.orig_manifest_path, self.temp_manifest_path)

        # Review manager pointing to isolated test records
        self.rev_mgr = ReviewManager(records_dir=self.records_dir)
        self.mgr = ManifestManager(
            manifest_path=self.temp_manifest_path,
            review_manager=self.rev_mgr,
        )

        # Pre-create a dummy generated artifact for GC-G1-NUM-032-01-bi-v1
        self.test_cid = "GC-G1-NUM-032-01-bi-v1"
        self.test_artifact_path = os.path.join(self.output_dir, f"{self.test_cid}.json")
        self.fixtures_dir = os.path.join(HERE, "fixtures")
        self.valid_num_path = os.path.join(self.fixtures_dir, "valid_numeracy_bilingual.json")
        shutil.copy2(self.valid_num_path, self.test_artifact_path)

    def tearDown(self):
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_01_load_and_structure(self):
        """Verify initial manifest loading and structural contract."""
        self.assertEqual(len(self.mgr._manifest["entries"]), 46)
        entry = self.mgr.get_entry(self.test_cid)
        self.assertIsNotNone(entry)
        self.assertEqual(entry["blueprint_id"], "BP-G1-NUM-032-01")
        self.assertEqual(entry["generation_status"], "planned")
        self.assertEqual(entry["review_status"], "pending")
        self.assertIsNone(entry["content_sha256"])

    def test_02_register_successful_generation(self):
        """Verify registering a successful generation retains provenance and marks validated."""
        entry = self.mgr.register_generation(
            content_id=self.test_cid,
            model="MockProvider",
            output_path=self.test_artifact_path,
            validation_passed=True,
            validator_version="1.0.0",
            model_parameters={"temperature": 0.0},
        )

        self.assertEqual(entry["generation_status"], "validated")
        self.assertTrue(entry["validation_passed"])
        self.assertEqual(entry["model"], "MockProvider")
        self.assertEqual(entry["model_parameters"], {"temperature": 0.0})
        self.assertIsNotNone(entry["generation_timestamp"])
        self.assertIsNotNone(entry["content_sha256"])
        self.assertEqual(entry["review_status"], "pending")

    def test_03_register_failed_generation(self):
        """Verify failed generation is marked failed and cannot be registered as usable."""
        entry = self.mgr.register_generation(
            content_id=self.test_cid,
            model="MockProvider",
            output_path="generation/generated/pilot_v1/failed.json",
            validation_passed=False,
            notes=["NUM_MAX_SUM: Sum 21 exceeds 18"],
            check_file_exists=False,
        )

        self.assertEqual(entry["generation_status"], "failed")
        self.assertFalse(entry["validation_passed"])
        self.assertIn("NUM_MAX_SUM: Sum 21 exceeds 18", entry["notes"])

    def test_04_idempotency_no_duplicate_entries(self):
        """Verify repeated registration of the same content_id updates in place without duplicates."""
        initial_count = len(self.mgr._manifest["entries"])

        self.mgr.register_generation(
            content_id=self.test_cid,
            model="MockProvider",
            output_path=self.test_artifact_path,
            validation_passed=True,
        )
        self.mgr.register_generation(
            content_id=self.test_cid,
            model="MockProvider",
            output_path=self.test_artifact_path,
            validation_passed=True,
        )

        self.assertEqual(len(self.mgr._manifest["entries"]), initial_count)

    def test_05_review_linkage_pending_approved_rejected(self):
        """Verify review status synchronization reflects ReviewManager decisions."""
        # 1. Register generation
        self.mgr.register_generation(
            content_id=self.test_cid,
            model="MockProvider",
            output_path=self.test_artifact_path,
            validation_passed=True,
        )

        # 2. Create pending review record in ReviewManager
        rev_rec = self.rev_mgr.create_review_record(self.test_artifact_path)
        self.assertEqual(rev_rec["review_status"], "pending")

        # Sync with manifest
        entry = self.mgr.sync_review(self.test_cid, rev_rec)
        self.assertEqual(entry["review_status"], "pending")
        self.assertEqual(entry["generation_status"], "validated")

        # 3. Explicitly approve in ReviewManager
        app_rec = self.rev_mgr.approve(
            content_id=self.test_cid,
            reviewer_id="rev-santali-01",
            santali_script_confirmed="Olck",
            note="Approved for pilot",
        )
        entry_app = self.mgr.sync_review(self.test_cid, app_rec)
        self.assertEqual(entry_app["review_status"], "approved")

        # 4. Invariant: machine-valid != approved
        # A new unit with machine_validation=True cannot become approved without review record
        test_cid2 = "GC-G1-LIT-011-01-hi-v1"
        self.mgr.register_generation(
            content_id=test_cid2,
            model="MockProvider",
            output_path="generation/generated/pilot_v1/GC-G1-LIT-011-01-hi-v1.json",
            validation_passed=True,
            check_file_exists=False,
        )
        with self.assertRaises(ManifestConsistencyError):
            # Attempt to set approved directly without review record proof
            self.mgr.update_review_status(test_cid2, "approved")

    def test_06_review_rejection_linkage(self):
        """Verify rejected review sets review_status and generation_status to rejected."""
        self.mgr.register_generation(
            content_id=self.test_cid,
            model="MockProvider",
            output_path=self.test_artifact_path,
            validation_passed=True,
        )
        self.rev_mgr.create_review_record(self.test_artifact_path)

        rej_rec = self.rev_mgr.reject(
            content_id=self.test_cid,
            reviewer_id="rev-hi-01",
            reason="Unnatural Hindi phrasing in instruction",
            gate="hindi",
        )

        entry = self.mgr.sync_review(self.test_cid, rej_rec)
        self.assertEqual(entry["review_status"], "rejected")
        self.assertEqual(entry["generation_status"], "rejected")
        self.assertTrue(any("Unnatural Hindi phrasing" in n for n in entry["notes"]))

    def test_07_safety_and_error_handling(self):
        """Verify error handling on unknown content IDs, missing files, and invalid data."""
        # Unknown content_id
        with self.assertRaises(ManifestEntryNotFoundError):
            self.mgr.require_entry("NON_EXISTENT_ID")

        # Missing file when check_file_exists=True
        with self.assertRaises(ManifestConsistencyError):
            self.mgr.register_generation(
                content_id=self.test_cid,
                model="MockProvider",
                output_path="non/existent/path.json",
                validation_passed=True,
                check_file_exists=True,
            )

        # Invalid review status enum
        with self.assertRaises(ManifestValidationError):
            self.mgr.update_review_status(self.test_cid, "invalid_status_enum")

    def test_08_mark_stale_by_conflicts(self):
        """Verify changing a provisional conflict marks all dependent units as stale."""
        # G1-NUM-032 has conflict_refs: ["X_G1_ADDSUB_RANGE"]
        affected = self.mgr.mark_stale_by_conflicts(
            ["X_G1_ADDSUB_RANGE"],
            reason="Upper addition cap adjusted from 18 to 20.",
        )

        self.assertIn(self.test_cid, affected)
        entry = self.mgr.get_entry(self.test_cid)
        self.assertEqual(entry["generation_status"], "stale")
        self.assertTrue(any("Upper addition cap adjusted" in n for n in entry["notes"]))

    def test_09_create_revision_and_superseded_by(self):
        """Verify create_revision creates -v2, sets superseded_by on -v1, and adds new planned entry."""
        initial_count = len(self.mgr._manifest["entries"])

        new_entry = self.mgr.create_revision(self.test_cid)
        self.assertEqual(new_entry["content_id"], "GC-G1-NUM-032-01-bi-v2")
        self.assertEqual(new_entry["generation_status"], "planned")
        self.assertEqual(new_entry["review_status"], "pending")

        old_entry = self.mgr.get_entry(self.test_cid)
        self.assertEqual(old_entry["superseded_by"], "GC-G1-NUM-032-01-bi-v2")
        self.assertEqual(len(self.mgr._manifest["entries"]), initial_count + 1)

    def test_10_atomic_save_and_recompute_summary(self):
        """Verify atomic saving and determinism across reload."""
        self.mgr.register_generation(
            content_id=self.test_cid,
            model="MockProvider",
            output_path=self.test_artifact_path,
            validation_passed=True,
        )
        self.mgr.save()

        # Check no temporary files left
        manifest_dir = os.path.dirname(self.temp_manifest_path)
        files = os.listdir(manifest_dir)
        self.assertTrue(all(not f.startswith(".tmp_manifest_") for f in files))

        # Reload and verify
        mgr2 = ManifestManager(manifest_path=self.temp_manifest_path)
        entry = mgr2.get_entry(self.test_cid)
        self.assertEqual(entry["generation_status"], "validated")
        self.assertEqual(mgr2._manifest["summary"]["validated_units"], 1)

    def test_11_orchestrator_integration_flow(self):
        """End-to-end integration test with orchestrator, review manager, and manifest."""
        provider = MockProvider(mode="valid")
        orchestrator = GenerationOrchestrator(
            provider=provider,
            output_dir=self.output_dir,
            review_manager=self.rev_mgr,
        )

        # 1. Run generation
        gen_res = orchestrator.generate("BP-G1-NUM-032-01", force=True)
        self.assertTrue(gen_res.is_success)

        # 2. Register with manifest
        entry = self.mgr.register_from_orchestrator(gen_res)
        self.assertEqual(entry["generation_status"], "validated")
        self.assertTrue(entry["validation_passed"])

        # 3. Synchronize review from ReviewManager (initially pending)
        entry = self.mgr.sync_review(self.test_cid)
        self.assertEqual(entry["review_status"], "pending")

        # 4. Approve via ReviewManager
        self.rev_mgr.approve(
            content_id=self.test_cid,
            reviewer_id="lead-rev-01",
            santali_script_confirmed="Olck",
            note="E2E test approval",
        )

        # 5. Synchronize review with manifest
        entry_app = self.mgr.sync_review(self.test_cid)
        self.assertEqual(entry_app["review_status"], "approved")


if __name__ == "__main__":
    unittest.main()
