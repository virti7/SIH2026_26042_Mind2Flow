"""Unit tests for SupabaseStorageClient and storage path generators."""
import unittest

from generation.publishing.models import StorageUploadError
from generation.publishing.storage import (
    SupabaseStorageClient,
    build_flashcard_storage_path,
    build_worksheet_storage_path,
)


class TestSupabaseStorage(unittest.TestCase):
    def setUp(self):
        self.client = SupabaseStorageClient(
            supabase_url="https://mock.supabase.co",
            service_role_key="test-secret-key-12345",
            bucket="content",
            mock=True,
        )

    def test_deterministic_paths(self):
        ws_path = build_worksheet_storage_path(grade=1, curriculum_id="G1-NUM-032", content_id="GC-G1-NUM-032-01-bi-v1", ext="pdf")
        self.assertEqual(ws_path, "worksheets/1/G1-NUM-032/GC-G1-NUM-032-01-bi-v1.pdf")

        fc_path = build_flashcard_storage_path(grade=1, curriculum_id="G1-LIT-011", content_id="GC-G1-LIT-011-01-hi-v1", asset_id="card1", ext="png")
        self.assertEqual(fc_path, "flashcards/1/G1-LIT-011/GC-G1-LIT-011-01-hi-v1_card1.png")

    def test_upload_and_exists(self):
        path = "worksheets/1/test.pdf"
        data = b"%PDF-1.4 test data"
        stored_path = self.client.upload_bytes(path, data, content_type="application/pdf")
        self.assertEqual(stored_path, path)
        self.assertTrue(self.client.object_exists(path))
        self.assertFalse(self.client.object_exists("nonexistent.pdf"))

    def test_signed_url_generation(self):
        path = "worksheets/1/test.pdf"
        url = self.client.get_signed_url(path, expires_in=120)
        self.assertIn("test.pdf", url)
        self.assertIn("mock", url)

    def test_delete_objects_cleanup(self):
        path1 = "worksheets/1/temp1.pdf"
        path2 = "worksheets/1/temp2.pdf"
        self.client.upload_bytes(path1, b"data1")
        self.client.upload_bytes(path2, b"data2")
        self.assertTrue(self.client.object_exists(path1))
        self.assertTrue(self.client.object_exists(path2))

        self.client.delete_objects([path1, path2])
        self.assertFalse(self.client.object_exists(path1))
        self.assertFalse(self.client.object_exists(path2))

    def test_credentials_never_exposed(self):
        # Service role key should not appear in client string representation
        client_repr = str(self.client)
        self.assertNotIn("test-secret-key-12345", client_repr)


if __name__ == "__main__":
    unittest.main()
