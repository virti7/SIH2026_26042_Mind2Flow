import json
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from typing import Optional

from app.core.config import settings


def _is_placeholder_url(url: Optional[str]) -> bool:
    if not url:
        return True
    lowered = url.lower()
    return "example" in lowered or "your-project" in lowered or "dummy" in lowered


def _is_placeholder_key(value: Optional[str]) -> bool:
    if not value:
        return True
    lowered = value.lower()
    return "dummy" in lowered or "example" in lowered or "your-" in lowered


class StorageService:
    """
    Manages asset metadata, bucket organization, and authenticated/signed URLs
    for Supabase Storage.

    Signed URLs are created server-side via the Supabase Storage
    ``/object/sign`` endpoint using the service-role key. The service-role key
    never leaves the backend.
    """

    def __init__(self):
        self.supabase_url = (settings.SUPABASE_URL or "").rstrip("/")
        self.service_role_key = settings.SUPABASE_SERVICE_ROLE_KEY
        self.bucket_packs = settings.STORAGE_BUCKET_LANGUAGE_PACKS
        self.bucket_models = settings.STORAGE_BUCKET_MODELS
        self.bucket_content = settings.STORAGE_BUCKET_CONTENT
        # Category buckets fall back to the generic content bucket unless the
        # deployment configures dedicated buckets. Confirm names in Supabase.
        self.bucket_generated = (
            settings.STORAGE_BUCKET_GENERATED_RESOURCES or settings.STORAGE_BUCKET_CONTENT
        )
        self.bucket_worksheets = (
            settings.STORAGE_BUCKET_WORKSHEETS or settings.STORAGE_BUCKET_CONTENT
        )
        self.bucket_flashcards = (
            settings.STORAGE_BUCKET_FLASHCARDS or settings.STORAGE_BUCKET_CONTENT
        )

    def _live_configured(self) -> bool:
        return not _is_placeholder_url(self.supabase_url) and not _is_placeholder_key(
            self.service_role_key
        )

    def _sign_via_supabase(
        self, bucket: str, clean_path: str, expires_in_seconds: int
    ) -> str:
        endpoint = (
            f"{self.supabase_url}/storage/v1/object/sign/{bucket}/{clean_path}"
        )
        body = json.dumps({"expiresIn": expires_in_seconds}).encode("utf-8")
        req = urllib.request.Request(
            endpoint,
            data=body,
            method="POST",
            headers={
                "Content-Type": "application/json",
                "apikey": self.service_role_key or "",
                "Authorization": f"Bearer {self.service_role_key or ''}",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:  # noqa: S310
                payload = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            status = exc.code
            if status in (400, 404):
                raise FileNotFoundError(
                    f"Storage object not found: bucket='{bucket}' path='{clean_path}'"
                ) from exc
            if status in (401, 403):
                raise PermissionError(
                    "Storage signing rejected: check service-role credentials and bucket policies"
                ) from exc
            raise RuntimeError(
                f"Storage signing failed with HTTP {status}"
            ) from exc
        except urllib.error.URLError as exc:
            raise RuntimeError("Storage service unreachable") from exc

        signed = None
        if isinstance(payload, dict):
            signed = payload.get("signedURL") or payload.get("signedUrl")
        if not signed:
            raise RuntimeError("Storage signing failed: malformed response")
        if signed.startswith("http"):
            return signed
        return f"{self.supabase_url}/storage/v1{signed}"

    def upload_text_object(self, bucket: str, path: str, content: str) -> str:
        """Upload a text artifact (e.g. generated worksheet JSON) server-side.

        Uses the service-role key when live Supabase is configured and returns
        the storage path. In dev/test (or on upload failure) returns the
        logical path so callers keep a stable reference. Never logs secrets.
        """
        if not bucket or not path:
            raise ValueError("bucket and path are required")
        clean_path = path.lstrip("/")
        if not self._live_configured():
            return f"{bucket}/{clean_path}"
        endpoint = f"{self.supabase_url}/storage/v1/object/{bucket}/{clean_path}"
        body = content.encode("utf-8")
        req = urllib.request.Request(
            endpoint,
            data=body,
            method="POST",
            headers={
                "Content-Type": "application/json",
                "apikey": self.service_role_key or "",
                "Authorization": f"Bearer {self.service_role_key or ''}",
                "x-upsert": "true",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:  # noqa: S310
                resp.read()
        except urllib.error.HTTPError as exc:
            if exc.code in (400, 404):
                raise FileNotFoundError(
                    f"Storage bucket not found: bucket='{bucket}'"
                ) from exc
            if exc.code in (401, 403):
                raise PermissionError(
                    "Storage upload rejected: check service-role credentials and bucket policies"
                ) from exc
            raise RuntimeError(f"Storage upload failed with HTTP {exc.code}") from exc
        except urllib.error.URLError as exc:
            raise RuntimeError("Storage service unreachable") from exc
        return f"{bucket}/{clean_path}"

    def upload_bytes(
        self, bucket: str, path: str, data: bytes, content_type: str = "application/octet-stream"
    ) -> str:
        """Upload raw bytes (e.g. rendered worksheet PDF) server-side.

        Returns the storage path. In dev/test without live Supabase, returns
        the logical path so callers keep a stable reference.
        """
        if not bucket or not path:
            raise ValueError("bucket and path are required")
        clean_path = path.lstrip("/")
        if not self._live_configured():
            return f"{bucket}/{clean_path}"
        endpoint = f"{self.supabase_url}/storage/v1/object/{bucket}/{clean_path}"
        req = urllib.request.Request(
            endpoint,
            data=data,
            method="POST",
            headers={
                "Content-Type": content_type,
                "apikey": self.service_role_key or "",
                "Authorization": f"Bearer {self.service_role_key or ''}",
                "x-upsert": "true",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:  # noqa: S310
                resp.read()
        except urllib.error.HTTPError as exc:
            if exc.code in (400, 404):
                raise FileNotFoundError(f"Storage bucket not found: bucket='{bucket}'") from exc
            if exc.code in (401, 403):
                raise PermissionError(
                    "Storage upload rejected: check service-role credentials and bucket policies"
                ) from exc
            raise RuntimeError(f"Storage upload failed with HTTP {exc.code}") from exc
        except urllib.error.URLError as exc:
            raise RuntimeError("Storage service unreachable") from exc
        return f"{bucket}/{clean_path}"

    def get_signed_download_url(        self,
        bucket: str,
        path: str,
        expires_in_seconds: int = 3600,
    ) -> str:
        """
        Returns a time-limited signed URL for downloading protected objects.

        Uses the live Supabase Storage signing endpoint when server-side
        credentials are configured; otherwise returns a local mock endpoint
        for development & testing. Never logs secret values.
        """
        if not bucket or not path:
            raise ValueError("bucket and path are required")
        clean_path = path.lstrip("/")
        if self._live_configured():
            return self._sign_via_supabase(bucket, clean_path, expires_in_seconds)

        # Safe local mock URL for development & testing
        expires_timestamp = int(
            (datetime.now(timezone.utc) + timedelta(seconds=expires_in_seconds)).timestamp()
        )
        safe_bucket = urllib.parse.quote(bucket, safe="")
        safe_path = urllib.parse.quote(clean_path, safe="/")
        return (
            f"/api/v1/storage/download/{safe_bucket}/{safe_path}"
            f"?token=mock_signature_{expires_timestamp}"
        )


storage_service = StorageService()
