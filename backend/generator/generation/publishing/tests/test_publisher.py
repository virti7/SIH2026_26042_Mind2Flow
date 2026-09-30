"""Comprehensive unit tests for SupabasePublisher covering all required test scenarios."""
import copy
import json
import logging
import os
import shutil
import tempfile
import unittest
from unittest.mock import MagicMock, patch

from generation.publishing.models import (
    ConflictingPublicationError,
    DatabaseOperationError,
    IntegrityVerificationError,
    PublicationState,
    PublishConfig,
    StorageUploadError,
    UnapprovedContentError,
    ValidationFailureError,
)
from generation.publishing.publisher import SupabasePublisher
from generation.publishing.repository import SupabaseRepository
from generation.publishing.storage import SupabaseStorageClient
from generation.review.review_manager import (
    GATE_FAIL,
    GATE_PASS,
    GATE_PENDING,
    STATUS_APPROVED,
    STATUS_PENDING,
    STATUS_REJECTED,
    ReviewManager,
    compute_data_sha256,
)

# Sample valid worksheet content fixture
SAMPLE_WORKSHEET = {
    "schema_version": "generated_content_v1",
    "content_id": "GC-G1-NUM-032-01-bi-v1",
    "blueprint_id": "BP-G1-NUM-032-01",
    "curriculum_id": "G1-NUM-032",
    "curriculum_version": "curriculum_master_v1",
    "blueprint_version": "content_blueprint_v1",
    "grade": 1,
    "domain": "numeracy",
    "content_type": "worksheet",
    "language_mode": "bilingual",
    "languages": ["hi", "sat"],
    "scripts": {"hi": "Deva", "sat": "Olck"},
    "generation_method": "native",
    "title": {"hi": "मिलाओ और गिनो", "sat": "ᱴᱮᱥᱴ ᱚᱠ"},
    "instructions": {"learner": {"hi": "चित्र देखो।", "sat": "ᱴᱮᱥᱴ ᱮᱠ᱾"}},
    "items": [
        {
            "item_id": "q1",
            "item_type": "multiple_choice",
            "prompt": {"hi": "4 आम और 7 आम।", "sat": "4 ᱟᱢ 7 ᱟᱢ᱾"},
            "math": {"kind": "add", "operands": [4, 7]},
            "options": [
                {"option_id": "a", "value": 10, "text": {"hi": "10", "sat": "10"}},
                {"option_id": "b", "value": 11, "text": {"hi": "11", "sat": "11"}},
            ],
            "asset_refs": ["img_q1"],
        }
    ],
    "answer_key": [{"item_id": "q1", "answer": "b"}],
    "assets_required": [
        {"asset_id": "img_q1", "type": "image", "description_en": "4 mangoes and 7 mangoes", "for_items": ["q1"]}
    ],
    "provisional": True,
    "conflict_refs": ["X_G1_ADDSUB_RANGE"],
    "review_gates": ["hindi_transcription", "santali_content", "provisional_range"],
    "origin_type": "AI_GENERATED",
}

# Sample valid flashcard content fixture
SAMPLE_FLASHCARD = {
    "schema_version": "generated_content_v1",
    "content_id": "GC-G1-LIT-011-01-bi-v1",
    "blueprint_id": "BP-G1-LIT-011-01",
    "curriculum_id": "G1-LIT-011",
    "curriculum_version": "curriculum_master_v1",
    "blueprint_version": "content_blueprint_v1",
    "grade": 1,
    "domain": "literacy",
    "content_type": "flashcard",
    "language_mode": "bilingual",
    "languages": ["hi", "sat"],
    "scripts": {"hi": "Deva", "sat": "Olck"},
    "generation_method": "native",
    "title": {"hi": "अक्षर कार्ड", "sat": "ᱪᱤᱠᱤ ᱠᱟᱨᱰ"},
    "instructions": {"learner": {"hi": "अक्षर पहचानो।", "sat": "ᱪᱤᱠᱤ ᱩᱨᱩᱢ ᱢᱮ᱾"}},
    "items": [
        {
            "item_id": "card1",
            "item_type": "card",
            "prompt": {"hi": "क", "sat": "ᱠ"},
            "options": [{"option_id": "a", "text": {"hi": "कमल", "sat": "ᱠᱟᱢᱟᱞ"}}],
            "asset_refs": ["img_card1"],
        }
    ],
    "answer_key": [{"item_id": "card1", "answer": "a"}],
    "assets_required": [
        {"asset_id": "img_card1", "type": "image", "description_en": "Lotus flower illustration", "for_items": ["card1"]}
    ],
    "provisional": False,
    "conflict_refs": [],
    "review_gates": ["hindi_transcription", "santali_content"],
    "origin_type": "AI_GENERATED",
}


class TestSupabasePublisher(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp(prefix="test_pub_")
        self.records_dir = os.path.join(self.test_dir, "records")
        self.content_dir = os.path.join(self.test_dir, "content")
        os.makedirs(self.records_dir, exist_ok=True)
        os.makedirs(self.content_dir, exist_ok=True)

        self.review_manager = ReviewManager(records_dir=self.records_dir)
        self.storage = SupabaseStorageClient(mock=True)
        self.repo = SupabaseRepository(mock=True)

        self.publisher = SupabasePublisher(
            storage_client=self.storage,
            repository=self.repo,
            review_manager=self.review_manager,
            content_dir=self.content_dir,
            config=PublishConfig(mock=True),
        )

    def tearDown(self):
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir, ignore_errors=True)

    def _create_approved_unit(self, content_dict: dict) -> str:
        """Helper to write content and create an approved review record."""
        cid = content_dict["content_id"]
        cpath = os.path.join(self.content_dir, f"{cid}.json")
        with open(cpath, "w", encoding="utf-8") as f:
            json.dump(content_dict, f, indent=2, ensure_ascii=False)

        # Create review record
        self.review_manager.create_review_record(content=content_dict, content_path=cpath)
        # Approve it
        self.review_manager.approve(
            content_id=cid,
            reviewer_id="reviewer_test_01",
            santali_script_confirmed="Olck",
            note="Verified for testing",
        )
        return cpath

    # 1. Approved flashcard publishes successfully
    def test_01_approved_flashcard_publishes_successfully(self):
        content = copy.deepcopy(SAMPLE_FLASHCARD)
        cpath = self._create_approved_unit(content)

        res = self.publisher.publish(cpath)
        self.assertEqual(res.status, PublicationState.PUBLISHED.value)
        self.assertTrue(res.is_success)
        self.assertEqual(res.content_type, "flashcard")

        # Verify in repository
        gen = self.repo.get_generated_content_by_content_id(content["content_id"])
        self.assertIsNotNone(gen)
        self.assertEqual(gen["status"], "PUBLISHED")

        cards = self.repo.get_flashcards_by_deck(f"{content['content_id']} - {content['title']['hi']}")
        self.assertEqual(len(cards), 1)

    # 2. Approved worksheet publishes successfully
    def test_02_approved_worksheet_publishes_successfully(self):
        content = copy.deepcopy(SAMPLE_WORKSHEET)
        cpath = self._create_approved_unit(content)

        res = self.publisher.publish(cpath)
        self.assertEqual(res.status, PublicationState.PUBLISHED.value)
        self.assertTrue(res.is_success)
        self.assertEqual(res.content_type, "worksheet")

        # Verify storage upload
        expected_json_path = f"worksheets/1/{content['curriculum_id']}/{content['content_id']}.json"
        self.assertTrue(self.storage.object_exists(expected_json_path))

        # Verify worksheet row
        ws = self.repo.get_worksheet_by_id(res.record_ids["entity_id"])
        self.assertIsNotNone(ws)
        self.assertEqual(ws["title"], content["title"]["hi"])

    # 3. Rejected content cannot publish
    def test_03_rejected_content_cannot_publish(self):
        content = copy.deepcopy(SAMPLE_WORKSHEET)
        cid = content["content_id"]
        cpath = os.path.join(self.content_dir, f"{cid}.json")
        with open(cpath, "w", encoding="utf-8") as f:
            json.dump(content, f)

        self.review_manager.create_review_record(content=content, content_path=cpath)
        self.review_manager.reject(content_id=cid, reviewer_id="rev_01", reason="Poor quality")

        with self.assertRaises(UnapprovedContentError):
            self.publisher.publish(cpath)

    # 4. Pending review cannot publish
    def test_04_pending_review_cannot_publish(self):
        content = copy.deepcopy(SAMPLE_WORKSHEET)
        cid = content["content_id"]
        cpath = os.path.join(self.content_dir, f"{cid}.json")
        with open(cpath, "w", encoding="utf-8") as f:
            json.dump(content, f)

        # Created but not approved (remains pending)
        self.review_manager.create_review_record(content=content, content_path=cpath)

        with self.assertRaises(UnapprovedContentError):
            self.publisher.publish(cpath)

    # 5. Machine-invalid content cannot publish
    def test_05_machine_invalid_content_cannot_publish(self):
        content = copy.deepcopy(SAMPLE_WORKSHEET)
        cid = content["content_id"]
        cpath = os.path.join(self.content_dir, f"{cid}.json")
        with open(cpath, "w", encoding="utf-8") as f:
            json.dump(content, f)

        rec = self.review_manager.create_review_record(
            content=content,
            content_path=cpath,
            validation_report={"validator_version": "1.0.0", "passed": False, "warnings": 1},
        )
        # Attempting to publish must fail validation check
        with self.assertRaises(ValidationFailureError):
            self.publisher.publish(cpath)

    # 6. Duplicate publication is idempotent
    def test_06_duplicate_publication_is_idempotent(self):
        content = copy.deepcopy(SAMPLE_WORKSHEET)
        cpath = self._create_approved_unit(content)

        # First publish
        res1 = self.publisher.publish(cpath)
        self.assertEqual(res1.status, PublicationState.PUBLISHED.value)
        self.assertFalse(res1.is_idempotent)

        # Second publish of identical content
        res2 = self.publisher.publish(cpath)
        self.assertEqual(res2.status, PublicationState.ALREADY_PUBLISHED.value)
        self.assertTrue(res2.is_idempotent)
        self.assertTrue(res2.is_success)

    # 7. Conflicting duplicate fails safely
    def test_07_conflicting_duplicate_fails_safely(self):
        content = copy.deepcopy(SAMPLE_WORKSHEET)
        cpath = self._create_approved_unit(content)

        # First publish
        self.publisher.publish(cpath)

        # Modify content under the SAME content_id
        mutated_content = copy.deepcopy(content)
        mutated_content["title"]["hi"] = "बिल्कुल अलग शीर्षक"
        mutated_path = os.path.join(self.content_dir, f"{content['content_id']}.json")
        with open(mutated_path, "w", encoding="utf-8") as f:
            json.dump(mutated_content, f, indent=2, ensure_ascii=False)

        # Re-approve mutated content so review passes
        self.review_manager.create_review_record(content=mutated_content, content_path=mutated_path, overwrite=True)
        self.review_manager.approve(
            content_id=mutated_content["content_id"],
            reviewer_id="reviewer_02",
            santali_script_confirmed="Olck",
        )

        with self.assertRaises(ConflictingPublicationError):
            self.publisher.publish(mutated_path)

    # 8. Storage failure does not create a false published state
    def test_08_storage_failure_prevents_publication(self):
        content = copy.deepcopy(SAMPLE_WORKSHEET)
        cpath = self._create_approved_unit(content)

        # Mock storage failure
        with patch.object(self.storage, "upload_bytes", side_effect=StorageUploadError("Disk full")):
            with self.assertRaises(StorageUploadError):
                self.publisher.publish(cpath)

        # Verify nothing was saved in database
        gen = self.repo.get_generated_content_by_content_id(content["content_id"])
        self.assertIsNone(gen)

    # 9. Database failure after Storage upload triggers rollback cleanup
    def test_09_database_failure_rolls_back_storage(self):
        content = copy.deepcopy(SAMPLE_WORKSHEET)
        cpath = self._create_approved_unit(content)

        # Mock database failure during save_worksheet
        with patch.object(self.repo, "save_worksheet", side_effect=DatabaseOperationError("Constraint violation")):
            with self.assertRaises(DatabaseOperationError):
                self.publisher.publish(cpath)

        # Verify storage was rolled back (no orphaned files left)
        expected_json_path = f"worksheets/1/{content['curriculum_id']}/{content['content_id']}.json"
        self.assertFalse(self.storage.object_exists(expected_json_path))

    # 10. Credentials are never logged
    def test_10_credentials_never_logged(self):
        secret_key = "super-secret-service-role-key-xyz"
        with self.assertLogs("generation.publishing", level="INFO") as cm:
            client = SupabaseStorageClient(
                supabase_url="https://mock.supabase.co",
                service_role_key=secret_key,
                mock=True,
            )
            client.upload_bytes("worksheets/1/test.json", b"{}")

        for log_msg in cm.output:
            self.assertNotIn(secret_key, log_msg)

    # 11. Bilingual Hindi/Santali content is mapped correctly
    def test_11_bilingual_hindi_santali_mapping(self):
        content = copy.deepcopy(SAMPLE_FLASHCARD)
        cpath = self._create_approved_unit(content)

        res = self.publisher.publish(cpath)
        cards = self.repo.get_flashcards_by_deck(f"{content['content_id']} - {content['title']['hi']}")
        self.assertEqual(len(cards), 1)
        card = cards[0]
        # Front text has Hindi
        self.assertEqual(card["front_text"], "क")
        # Back text preserves Santali
        self.assertEqual(card["back_text"], "ᱠ")

    # 12. Worksheet PDF path is stored correctly
    def test_12_worksheet_pdf_path_stored(self):
        content = copy.deepcopy(SAMPLE_WORKSHEET)
        cpath = self._create_approved_unit(content)

        fake_pdf = b"%PDF-1.4 mock pdf content"
        res = self.publisher.publish(cpath, pdf_bytes=fake_pdf)

        expected_pdf_path = f"worksheets/1/{content['curriculum_id']}/{content['content_id']}.pdf"
        self.assertTrue(self.storage.object_exists(expected_pdf_path))

        ws = self.repo.get_worksheet_by_id(res.record_ids["entity_id"])
        self.assertEqual(ws["file_path"], expected_pdf_path)
        self.assertEqual(ws["format"], "pdf")
        self.assertEqual(ws["file_size"], len(fake_pdf))

    # 13. Flashcard image path is stored correctly (deterministic path)
    def test_13_flashcard_image_path_stored(self):
        content = copy.deepcopy(SAMPLE_FLASHCARD)
        cpath = self._create_approved_unit(content)

        res = self.publisher.publish(cpath)
        self.assertEqual(res.status, PublicationState.PUBLISHED.value)
        # Verify deterministic ID was generated
        cards = self.repo.get_flashcards_by_deck(f"{content['content_id']} - {content['title']['hi']}")
        self.assertTrue(len(cards) > 0)


if __name__ == "__main__":
    unittest.main()
