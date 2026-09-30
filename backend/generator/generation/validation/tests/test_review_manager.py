"""Unit and integration tests for ReviewManager and review workflow."""
import copy
import hashlib
import json
import os
import shutil
import sys
import tempfile
import unittest

# Ensure generation package and review package are in sys.path
HERE = os.path.dirname(os.path.abspath(__file__))
GEN_DIR = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, GEN_DIR)
sys.path.insert(0, os.path.join(GEN_DIR, "review"))
sys.path.insert(0, os.path.join(GEN_DIR, "validation"))

from review_manager import (
    ReviewManager,
    ReviewRecordError,
    ReviewValidationError,
    ReviewRecordNotFoundError,
    STATUS_PENDING,
    STATUS_IN_REVIEW,
    STATUS_CHANGES_REQUESTED,
    STATUS_APPROVED,
    STATUS_REJECTED,
    GATE_PENDING,
    GATE_PASS,
    GATE_FAIL,
    GATE_NOT_APPLICABLE,
)
from orchestrator import GenerationOrchestrator
from providers.mock import MockProvider


class TestReviewManager(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp(prefix="test_rev_")
        self.records_dir = os.path.join(self.test_dir, "records")
        self.content_dir = os.path.join(self.test_dir, "content")
        os.makedirs(self.records_dir, exist_ok=True)
        os.makedirs(self.content_dir, exist_ok=True)

        self.mgr = ReviewManager(records_dir=self.records_dir)

        # Load valid test fixtures from generation/validation/tests/fixtures
        self.fixtures_dir = os.path.join(HERE, "fixtures")
        self.valid_num_path = os.path.join(self.fixtures_dir, "valid_numeracy_bilingual.json")
        with open(self.valid_num_path, "r", encoding="utf-8") as f:
            self.valid_num_data = json.load(f)

        self.valid_lit_path = os.path.join(self.fixtures_dir, "valid_literacy_parallel_hi.json")
        with open(self.valid_lit_path, "r", encoding="utf-8") as f:
            self.valid_lit_data = json.load(f)

    def tearDown(self):
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_01_valid_artifact_produces_needs_review_record(self):
        """Rule 1: A valid generated artifact can produce a needs_review (pending) record."""
        rec = self.mgr.create_review_record(self.valid_num_path)

        self.assertIsNotNone(rec)
        self.assertEqual(rec["schema_version"], "review_v1")
        self.assertEqual(rec["content_id"], "GC-G1-NUM-032-01-bi-v1")
        self.assertEqual(rec["review_status"], STATUS_PENDING)
        self.assertTrue(self.mgr.is_needs_review(rec))
        self.assertEqual(len(rec["reviewer_notes"]), 0)

        # File exists on disk
        rec_path = self.mgr.get_record_path(rec["content_id"])
        self.assertTrue(os.path.exists(rec_path))

        # Schema validation succeeds
        errs = self.mgr.validate_review_record(rec)
        self.assertEqual(errs, [])

    def test_02_schema_validation_rejection(self):
        """Rule 2: A review record is rejected if it violates review_schema.json."""
        rec = self.mgr.create_review_record(self.valid_num_path)

        # 1. Tamper with required field
        bad_rec1 = copy.deepcopy(rec)
        del bad_rec1["content_sha256"]
        errs1 = self.mgr.validate_review_record(bad_rec1)
        self.assertTrue(any("'content_sha256' is a required property" in e for e in errs1))

        # 2. Tamper with additionalProperties
        bad_rec2 = copy.deepcopy(rec)
        bad_rec2["unauthorized_extra_field"] = "bad"
        errs2 = self.mgr.validate_review_record(bad_rec2)
        self.assertTrue(any("unauthorized_extra_field" in e for e in errs2))

        # 3. Invalid gate value
        bad_rec3 = copy.deepcopy(rec)
        bad_rec3["gates"]["hindi"] = "invalid_gate_status"
        errs3 = self.mgr.validate_review_record(bad_rec3)
        self.assertTrue(any("invalid_gate_status" in e for e in errs3))

    def test_03_approved_requires_explicit_reviewer_decision(self):
        """Rule 3: 'approved' cannot be created without an explicit reviewer decision."""
        rec = self.mgr.create_review_record(self.valid_num_path)
        cid = rec["content_id"]

        # Attempting to approve without reviewer_id must fail
        with self.assertRaises(ReviewValidationError):
            self.mgr.approve(content_id=cid, reviewer_id="")

        # Attempting to approve without Santali script when Santali is applicable must fail
        with self.assertRaises(ReviewValidationError) as ctx:
            self.mgr.approve(content_id=cid, reviewer_id="rev-01")
        self.assertIn("santali_script_confirmed", str(ctx.exception))

        # Explicit approval with required reviewer info and Santali confirmation succeeds
        approved_rec = self.mgr.approve(
            content_id=cid,
            reviewer_id="rev-01",
            santali_script_confirmed="Olck",
            note="Reviewed and approved for pilot.",
        )
        self.assertEqual(approved_rec["review_status"], STATUS_APPROVED)
        self.assertEqual(approved_rec["approved_by"], ["rev-01"])
        self.assertEqual(approved_rec["santali_script_confirmed"], "Olck")
        self.assertTrue(self.mgr.is_approved(approved_rec))
        self.assertEqual(self.mgr.validate_review_record(approved_rec), [])

    def test_04_rejected_requires_information(self):
        """Rule 4: 'rejected' requires the appropriate rejection information required by the schema."""
        rec = self.mgr.create_review_record(self.valid_num_path)
        cid = rec["content_id"]

        # Rejection without reason must fail
        with self.assertRaises(ReviewValidationError):
            self.mgr.reject(content_id=cid, reviewer_id="rev-01", reason="")

        # Rejection without reviewer must fail
        with self.assertRaises(ReviewValidationError):
            self.mgr.reject(content_id=cid, reviewer_id="", reason="Syntax error")

        # Proper rejection records reason and failing gate
        rej_rec = self.mgr.reject(
            content_id=cid,
            reviewer_id="rev-01",
            reason="Unnatural Hindi wording in word problem.",
            gate="hindi",
        )
        self.assertEqual(rej_rec["review_status"], STATUS_REJECTED)
        self.assertEqual(rej_rec["gates"]["hindi"], GATE_FAIL)
        self.assertEqual(len(rej_rec["reviewer_notes"]), 1)
        self.assertEqual(rej_rec["reviewer_notes"][0]["gate"], "hindi")
        self.assertEqual(rej_rec["reviewer_notes"][0]["reviewer"], "rev-01")
        self.assertEqual(self.mgr.validate_review_record(rej_rec), [])

    def test_05_review_history_preserved(self):
        """Rule 5: Review history is preserved across transitions."""
        rec = self.mgr.create_review_record(self.valid_num_path)
        cid = rec["content_id"]

        # 1. Reject first
        rej_rec = self.mgr.reject(
            content_id=cid,
            reviewer_id="rev-01",
            reason="Initial rejection note.",
            gate="hindi",
        )
        self.assertEqual(len(rej_rec["reviewer_notes"]), 1)

        # 2. Re-open for review
        reopen_rec = self.mgr.reopen_for_review(
            content_id=cid,
            reviewer_id="rev-lead",
            note="Reopened after team discussion.",
        )
        self.assertEqual(reopen_rec["review_status"], STATUS_PENDING)
        self.assertEqual(reopen_rec["gates"]["hindi"], GATE_PENDING)
        self.assertEqual(len(reopen_rec["reviewer_notes"]), 2)
        self.assertEqual(reopen_rec["reviewer_notes"][0]["note"], "Initial rejection note.")
        self.assertEqual(reopen_rec["reviewer_notes"][1]["note"], "Reopened after team discussion.")

        # 3. Request changes
        chg_rec = self.mgr.request_changes(
            content_id=cid,
            reviewer_id="rev-02",
            note="Please clarify the question text.",
        )
        self.assertEqual(chg_rec["review_status"], STATUS_CHANGES_REQUESTED)
        self.assertEqual(len(chg_rec["reviewer_notes"]), 3)

        # 4. Finally approve
        app_rec = self.mgr.approve(
            content_id=cid,
            reviewer_id="rev-lead",
            santali_script_confirmed="Olck",
            note="Final approval granted.",
        )
        self.assertEqual(app_rec["review_status"], STATUS_APPROVED)
        self.assertEqual(len(app_rec["reviewer_notes"]), 4)

    def test_06_invalid_generated_content_cannot_be_approved(self):
        """Rule 6: Invalid generated content cannot be approved through the review manager."""
        # Create record with failed machine validation
        rec = self.mgr.create_review_record(
            content=self.valid_num_data,
            validation_report={"validator_version": "1.0.0", "passed": False, "warnings": 0},
        )
        cid = rec["content_id"]

        # Calling approve on a unit with passed=False must fail
        with self.assertRaises(ReviewValidationError) as ctx:
            self.mgr.approve(
                content_id=cid,
                reviewer_id="rev-01",
                santali_script_confirmed="Olck",
            )
        self.assertIn("failed machine validation", str(ctx.exception))

    def test_07_santali_content_flagged_for_human_review(self):
        """Rule 7: A generated artifact with Santali content is flagged for human review."""
        sat_data = copy.deepcopy(self.valid_num_data)
        sat_data["content_id"] = "GC-G1-LIT-001-01-sat-v1"
        sat_data["blueprint_id"] = "BP-G1-LIT-001-01"
        sat_data["curriculum_id"] = "G1-LIT-001"
        sat_data["languages"] = ["sat"]

        rec = self.mgr.create_review_record(sat_data)
        # Hindi should be not applicable, Santali must be pending
        self.assertEqual(rec["gates"]["hindi"], GATE_NOT_APPLICABLE)
        self.assertEqual(rec["gates"]["santali"], GATE_PENDING)
        self.assertIsNone(rec["santali_script_confirmed"])

    def test_08_bilingual_artifact_flagged_for_both_languages(self):
        """Rule 8: A bilingual Hindi/Santali artifact is flagged for linguistic review on both."""
        rec = self.mgr.create_review_record(self.valid_num_path)
        self.assertEqual(rec["gates"]["hindi"], GATE_PENDING)
        self.assertEqual(rec["gates"]["santali"], GATE_PENDING)
        self.assertEqual(rec["gates"]["curriculum"], GATE_PENDING)
        self.assertEqual(rec["gates"]["answer_key"], GATE_PENDING)

    def test_09_parallel_monolingual_literacy_flagged_correctly(self):
        """Rule 9: Parallel monolingual literacy content is flagged for language/script review."""
        rec = self.mgr.create_review_record(self.valid_lit_path)
        # valid_literacy_parallel_hi.json is Hindi-only
        self.assertEqual(rec["gates"]["hindi"], GATE_PENDING)
        self.assertEqual(rec["gates"]["santali"], GATE_NOT_APPLICABLE)
        self.assertIsNone(rec["santali_script_confirmed"])

        # Approving Hindi-only unit does not require santali_script_confirmed
        app_rec = self.mgr.approve(content_id=rec["content_id"], reviewer_id="rev-hi")
        self.assertEqual(app_rec["review_status"], STATUS_APPROVED)
        self.assertIsNone(app_rec["santali_script_confirmed"])

    def test_10_provisional_curriculum_choices_carried(self):
        """Rule 10: Provisional curriculum choices are carried into review requirements."""
        # 1. Provisional unit
        rec_prov = self.mgr.create_review_record(self.valid_num_path)
        self.assertTrue(self.valid_num_data["provisional"])
        self.assertEqual(rec_prov["gates"]["provisional_range"], GATE_PENDING)

        # 2. Non-provisional unit
        rec_non_prov = self.mgr.create_review_record(self.valid_lit_path)
        self.assertFalse(self.valid_lit_data["provisional"])
        self.assertEqual(rec_non_prov["gates"]["provisional_range"], GATE_NOT_APPLICABLE)

    def test_11_atomic_writes(self):
        """Rule 11: Review records are written atomically."""
        rec = self.mgr.create_review_record(self.valid_num_path)
        rec_path = self.mgr.get_record_path(rec["content_id"])
        self.assertTrue(os.path.exists(rec_path))

        # Check that no temporary files are left in records directory
        files = os.listdir(self.records_dir)
        self.assertTrue(all(not f.startswith(".tmp_rev_") for f in files))
        self.assertIn(f"{rec['content_id']}.json", files)

    def test_12_determinism_and_no_duplicates(self):
        """Rule 12: Repeated processing is deterministic and does not duplicate records."""
        rec1 = self.mgr.create_review_record(self.valid_num_path)
        rec2 = self.mgr.create_review_record(self.valid_num_path)

        self.assertEqual(rec1, rec2)
        files = [f for f in os.listdir(self.records_dir) if f.endswith(".json")]
        self.assertEqual(len(files), 1)

    def test_13_orchestrator_integration(self):
        """Rule 13: Orchestrator integrates with review manager to produce pending review records."""
        provider = MockProvider(mode="valid")
        orchestrator = GenerationOrchestrator(
            provider=provider,
            output_dir=self.content_dir,
            review_manager=self.mgr,
        )

        res = orchestrator.generate("BP-G1-NUM-032-01")
        self.assertTrue(res.is_success)
        self.assertEqual(res.review_status, STATUS_PENDING)
        self.assertIsNotNone(res.review_record_path)
        self.assertTrue(os.path.exists(res.review_record_path))

        # Check loaded record
        rec = self.mgr.load_review_record(res.content_id)
        self.assertIsNotNone(rec)
        self.assertEqual(rec["review_status"], STATUS_PENDING)
        self.assertTrue(self.mgr.is_needs_review(rec))

    def test_14_content_integrity_verification(self):
        """Rule 14: Tampering with content file invalidates review integrity."""
        # Create content file in content_dir
        content_file = os.path.join(self.content_dir, "test_content.json")
        with open(content_file, "w", encoding="utf-8") as f:
            json.dump(self.valid_num_data, f, indent=2)

        rec = self.mgr.create_review_record(content_file)
        self.assertTrue(self.mgr.verify_content_integrity(content_file, rec))

        # Tamper with the content file
        tampered_data = copy.deepcopy(self.valid_num_data)
        tampered_data["title"] = {"hi": "संशोधित शीर्षक", "sat": "ᱵᱚᱫᱚᱞ ᱧᱩᱛᱩᱢ"}
        with open(content_file, "w", encoding="utf-8") as f:
            json.dump(tampered_data, f, indent=2)

        # Integrity verification must now fail
        self.assertFalse(self.mgr.verify_content_integrity(content_file, rec))


if __name__ == "__main__":
    unittest.main()
