"""Supabase Storage client and deterministic path generator for bilingual content assets."""
import logging
import mimetypes
import os
from typing import Dict, List, Optional

import httpx

from .models import StorageUploadError

logger = logging.getLogger(__name__)


def build_worksheet_storage_path(
    grade: int,
    curriculum_id: str,
    content_id: str,
    ext: str = "pdf",
) -> str:
    """Generate deterministic storage path for a worksheet asset.

    Example: 'worksheets/1/G1-NUM-032/GC-G1-NUM-032-01-bi-v1.pdf'
    """
    clean_ext = ext.lstrip(".")
    return f"worksheets/{grade}/{curriculum_id}/{content_id}.{clean_ext}"


def build_flashcard_storage_path(
    grade: int,
    curriculum_id: str,
    content_id: str,
    asset_id: str,
    ext: str = "png",
) -> str:
    """Generate deterministic storage path for a flashcard asset.

    Example: 'flashcards/1/G1-LIT-011/GC-G1-LIT-011-01-hi-v1_img_card1.png'
    """
    clean_ext = ext.lstrip(".")
    return f"flashcards/{grade}/{curriculum_id}/{content_id}_{asset_id}.{clean_ext}"


class SupabaseStorageClient:
    """Manages asset uploads, existence checks, signed URLs, and rollbacks in Supabase Storage."""

    def __init__(
        self,
        supabase_url: Optional[str] = None,
        service_role_key: Optional[str] = None,
        bucket: str = "content",
        mock: bool = False,
        timeout: float = 30.0,
    ):
        self.supabase_url = (supabase_url or os.getenv("SUPABASE_URL", "")).rstrip("/")
        self._service_role_key = service_role_key or os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
        self.bucket = bucket or os.getenv("STORAGE_BUCKET_CONTENT", "content")
        self.mock = mock or (not self.supabase_url or not self._service_role_key)
        self.timeout = timeout

        # In-memory storage for mock mode / unit tests: key -> {"data": bytes, "content_type": str}
        self._mock_objects: Dict[str, Dict[str, Any]] = {}

    def _headers(self, content_type: Optional[str] = None, upsert: bool = True) -> Dict[str, str]:
        headers = {
            "apikey": self._service_role_key,
            "Authorization": f"Bearer {self._service_role_key}",
        }
        if content_type:
            headers["Content-Type"] = content_type
        if upsert:
            headers["x-upsert"] = "true"
        return headers

    def upload_bytes(
        self,
        path: str,
        data: bytes,
        content_type: Optional[str] = None,
        upsert: bool = True,
    ) -> str:
        """Upload raw bytes to Supabase Storage at the specified object path.

        Args:
            path: Relative path within the bucket (e.g. 'worksheets/1/.../foo.pdf').
            data: Binary data to upload.
            content_type: Optional MIME type; inferred from path extension if omitted.
            upsert: Whether to overwrite existing object at the same path.

        Returns:
            The stored object path.
        """
        clean_path = path.lstrip("/")
        if not content_type:
            guessed, _ = mimetypes.guess_type(clean_path)
            content_type = guessed or "application/octet-stream"

        if self.mock:
            key = f"{self.bucket}/{clean_path}"
            self._mock_objects[key] = {
                "data": data,
                "content_type": content_type,
                "size": len(data),
            }
            logger.info("MOCK Storage upload succeeded for %s (%d bytes)", clean_path, len(data))
            return clean_path

        url = f"{self.supabase_url}/storage/v1/object/{self.bucket}/{clean_path}"
        headers = self._headers(content_type=content_type, upsert=upsert)

        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.post(url, content=data, headers=headers)
                if resp.status_code not in (200, 201):
                    raise StorageUploadError(
                        f"Supabase Storage upload failed for '{clean_path}' (HTTP {resp.status_code}): {resp.text}"
                    )
                logger.info("Storage upload succeeded for %s/%s", self.bucket, clean_path)
                return clean_path
        except httpx.RequestError as e:
            # Note: Do NOT log or expose the service role key in error messages!
            raise StorageUploadError(f"Network error during Storage upload for '{clean_path}': {type(e).__name__}")

    def object_exists(self, path: str) -> bool:
        """Check whether an object exists at the specified path in the bucket."""
        clean_path = path.lstrip("/")
        if self.mock:
            return f"{self.bucket}/{clean_path}" in self._mock_objects

        # Use object info endpoint or list
        prefix = os.path.dirname(clean_path)
        name = os.path.basename(clean_path)
        url = f"{self.supabase_url}/storage/v1/object/list/{self.bucket}"
        headers = self._headers()

        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.post(url, json={"prefix": prefix, "limit": 100}, headers=headers)
                if resp.status_code != 200:
                    return False
                items = resp.json()
                return any(item.get("name") == name for item in items)
        except Exception:
            return False

    def get_signed_url(self, path: str, expires_in: int = 3600) -> str:
        """Generate a time-limited signed URL for a protected storage object."""
        clean_path = path.lstrip("/")
        if self.mock:
            return f"https://mock-storage.local/{self.bucket}/{clean_path}?token=mock_signed_token"

        url = f"{self.supabase_url}/storage/v1/object/sign/{self.bucket}/{clean_path}"
        headers = self._headers()

        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.post(url, json={"expiresIn": expires_in}, headers=headers)
                if resp.status_code != 200:
                    raise StorageUploadError(f"Failed to create signed URL for '{clean_path}': {resp.text}")
                signed_path = resp.json().get("signedURL", "")
                return f"{self.supabase_url}/storage/v1{signed_path}"
        except httpx.RequestError as e:
            raise StorageUploadError(f"Network error creating signed URL for '{clean_path}': {type(e).__name__}")

    def delete_objects(self, paths: List[str]) -> bool:
        """Delete multiple objects from the bucket. Used for cleanup/rollback.

        Args:
            paths: List of object paths within the bucket.

        Returns:
            True if all objects were deleted or no objects were passed.
        """
        if not paths:
            return True

        clean_paths = [p.lstrip("/") for p in paths]

        if self.mock:
            for p in clean_paths:
                key = f"{self.bucket}/{p}"
                self._mock_objects.pop(key, None)
            logger.info("MOCK Storage deleted %d objects", len(clean_paths))
            return True

        url = f"{self.supabase_url}/storage/v1/object/{self.bucket}"
        headers = self._headers()

        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.request("DELETE", url, json={"prefixes": clean_paths}, headers=headers)
                if resp.status_code != 200:
                    logger.warning("Failed to delete objects during cleanup: %s", resp.text)
                    return False
                logger.info("Storage cleanup deleted %d objects from %s", len(clean_paths), self.bucket)
                return True
        except Exception as e:
            logger.warning("Exception during Storage cleanup: %s", e)
            return False
