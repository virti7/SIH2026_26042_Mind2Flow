"""Unit tests for SupabaseRepository and deterministic UUID generation."""
import unittest

from generation.publishing.repository import SupabaseRepository, deterministic_uuid


class TestSupabaseRepository(unittest.TestCase):
    def setUp(self):
        self.repo = SupabaseRepository(mock=True)

    def test_deterministic_uuid(self):
        id1 = deterministic_uuid("worksheets", "GC-G1-NUM-032-01-bi-v1")
        id2 = deterministic_uuid("worksheets", "GC-G1-NUM-032-01-bi-v1")
        self.assertEqual(id1, id2)

        id3 = deterministic_uuid("flashcards", "GC-G1-NUM-032-01-bi-v1")
        self.assertNotEqual(id1, id3)

    def test_language_and_learning_outcome_lookups(self):
        hi_id = self.repo.get_language_id("hi")
        sat_id = self.repo.get_language_id("sat")
        self.assertIsNotNone(hi_id)
        self.assertIsNotNone(sat_id)
        self.assertNotEqual(hi_id, sat_id)
        self.assertIsNone(self.repo.get_language_id("unknown_lang"))

        lo_id = self.repo.get_learning_outcome_id("G1-NUM-032")
        self.assertIsNotNone(lo_id)
        self.assertIsNone(self.repo.get_learning_outcome_id("UNKNOWN-LO"))

    def test_generated_content_persistence(self):
        cid = "GC-TEST-001"
        data = {
            "raw_output": {"content_id": cid, "grade": 1},
            "status": "PUBLISHED",
            "prompt_used": "base_prompt",
        }
        saved = self.repo.save_generated_content(data)
        self.assertIn("id", saved)

        loaded = self.repo.get_generated_content_by_content_id(cid)
        self.assertIsNotNone(loaded)
        self.assertEqual(loaded["id"], saved["id"])
        self.assertEqual(loaded["status"], "PUBLISHED")

    def test_worksheet_persistence_and_rollback(self):
        ws_id = deterministic_uuid("worksheets", "GC-WS-001")
        rec = {
            "id": ws_id,
            "title": "Test Worksheet",
            "grade": 1,
            "subject": "Mathematics",
            "file_path": "worksheets/1/test.pdf",
            "file_size": 1024,
            "format": "pdf",
        }
        self.repo.save_worksheet(rec)
        loaded = self.repo.get_worksheet_by_id(ws_id)
        self.assertIsNotNone(loaded)
        self.assertEqual(loaded["title"], "Test Worksheet")

        # Test rollback deletion
        deleted = self.repo.delete_worksheet(ws_id)
        self.assertTrue(deleted)
        self.assertIsNone(self.repo.get_worksheet_by_id(ws_id))

    def test_flashcard_persistence_and_rollback(self):
        deck = "DECK-001"
        fc_id1 = deterministic_uuid("flashcards", "card1")
        fc_id2 = deterministic_uuid("flashcards", "card2")
        self.repo.save_flashcard({"id": fc_id1, "deck_name": deck, "front_text": "A", "back_text": "B", "grade": 1})
        self.repo.save_flashcard({"id": fc_id2, "deck_name": deck, "front_text": "C", "back_text": "D", "grade": 1})

        cards = self.repo.get_flashcards_by_deck(deck)
        self.assertEqual(len(cards), 2)

        self.repo.delete_flashcards([fc_id1, fc_id2])
        self.assertEqual(len(self.repo.get_flashcards_by_deck(deck)), 0)


if __name__ == "__main__":
    unittest.main()
