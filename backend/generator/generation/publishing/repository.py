"""Supabase repository for managing database persistence of generated content, worksheets, and flashcards."""
import logging
import os
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

import httpx

from .models import DatabaseOperationError

logger = logging.getLogger(__name__)


def deterministic_uuid(namespace: str, identifier: str) -> str:
    """Generate a deterministic UUIDv5 string based on namespace and identifier.

    Guarantees that re-publishing the same content identifier yields the exact same UUID.
    """
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"maatribhasha:{namespace}:{identifier}"))


class SupabaseRepository:
    """Handles CRUD, idempotency checks, and provenance linking in Supabase PostgreSQL."""

    def __init__(
        self,
        supabase_url: Optional[str] = None,
        service_role_key: Optional[str] = None,
        mock: bool = False,
        timeout: float = 30.0,
    ):
        self.supabase_url = (supabase_url or os.getenv("SUPABASE_URL", "")).rstrip("/")
        self._service_role_key = service_role_key or os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
        self.mock = mock or (not self.supabase_url or not self._service_role_key)
        self.timeout = timeout

        # In-memory stores for mock mode / unit tests
        self._mock_generated_content: Dict[str, Dict[str, Any]] = {}
        self._mock_worksheets: Dict[str, Dict[str, Any]] = {}
        self._mock_flashcards: Dict[str, Dict[str, Any]] = {}
        self._mock_languages: Dict[str, Dict[str, Any]] = {
            "hi": {"id": "lang-hi-uuid-0001", "code": "hi", "name": "Hindi", "script": "Devanagari"},
            "sat": {"id": "lang-sat-uuid-0002", "code": "sat", "name": "Santali", "script": "Ol Chiki"},
            "ho": {"id": "lang-ho-uuid-0003", "code": "ho", "name": "Ho", "script": "Warang Chiti"},
            "unr": {"id": "lang-unr-uuid-0004", "code": "unr", "name": "Mundari", "script": "Baniuri"},
        }
        self._mock_learning_outcomes: Dict[str, Dict[str, Any]] = {
            "G1-NUM-032": {"id": "lo-g1-num-032-uuid", "code": "G1-NUM-032", "grade": 1, "subject": "Mathematics"},
            "G1-LIT-011": {"id": "lo-g1-lit-011-uuid", "code": "G1-LIT-011", "grade": 1, "subject": "Hindi"},
            "G1-LIT-001": {"id": "lo-g1-lit-001-uuid", "code": "G1-LIT-001", "grade": 1, "subject": "Hindi"},
        }

    def _headers(self, prefer: str = "return=representation") -> Dict[str, str]:
        return {
            "apikey": self._service_role_key,
            "Authorization": f"Bearer {self._service_role_key}",
            "Content-Type": "application/json",
            "Prefer": prefer,
        }

    # -------------------------------------------------------------------------
    # Lookups
    # -------------------------------------------------------------------------

    def get_language_id(self, code: str) -> Optional[str]:
        """Look up the UUID for a language by its ISO code (e.g. 'hi', 'sat')."""
        if self.mock:
            record = self._mock_languages.get(code)
            return record["id"] if record else None

        url = f"{self.supabase_url}/rest/v1/languages"
        params = {"code": f"eq.{code}", "select": "id"}
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.get(url, params=params, headers=self._headers())
                if resp.status_code == 200 and resp.json():
                    return resp.json()[0]["id"]
                return None
        except httpx.RequestError as e:
            raise DatabaseOperationError(f"Failed to lookup language '{code}': {type(e).__name__}")

    def get_learning_outcome_id(self, code: str) -> Optional[str]:
        """Look up the UUID for a learning outcome by its code (e.g. 'G1-NUM-032')."""
        if self.mock:
            record = self._mock_learning_outcomes.get(code)
            return record["id"] if record else None

        url = f"{self.supabase_url}/rest/v1/learning_outcomes"
        params = {"code": f"eq.{code}", "select": "id"}
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.get(url, params=params, headers=self._headers())
                if resp.status_code == 200 and resp.json():
                    return resp.json()[0]["id"]
                return None
        except httpx.RequestError as e:
            raise DatabaseOperationError(f"Failed to lookup learning outcome '{code}': {type(e).__name__}")

    # -------------------------------------------------------------------------
    # Generated Content (Provenance)
    # -------------------------------------------------------------------------

    def get_generated_content_by_content_id(self, content_id: str) -> Optional[Dict[str, Any]]:
        """Find an existing generated_content record by content_id."""
        expected_id = deterministic_uuid("generated_content", content_id)
        if self.mock:
            return self._mock_generated_content.get(expected_id)

        url = f"{self.supabase_url}/rest/v1/generated_content"
        params = {"id": f"eq.{expected_id}", "select": "*"}
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.get(url, params=params, headers=self._headers())
                if resp.status_code == 200 and resp.json():
                    return resp.json()[0]
                return None
        except httpx.RequestError as e:
            raise DatabaseOperationError(f"Failed to query generated_content: {type(e).__name__}")

    def save_generated_content(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """Insert or update a record in the generated_content table."""
        rec = dict(record)
        rec.setdefault("id", deterministic_uuid("generated_content", rec["raw_output"]["content_id"]))
        now_iso = datetime.now(timezone.utc).isoformat()
        rec.setdefault("created_at", now_iso)
        rec["updated_at"] = now_iso

        if self.mock:
            self._mock_generated_content[rec["id"]] = rec
            return rec

        url = f"{self.supabase_url}/rest/v1/generated_content"
        headers = self._headers(prefer="resolution=merge-duplicates,return=representation")
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.post(url, json=rec, headers=headers)
                if resp.status_code not in (200, 201):
                    raise DatabaseOperationError(
                        f"Failed to save generated_content (HTTP {resp.status_code}): {resp.text}"
                    )
                rows = resp.json()
                return rows[0] if rows else rec
        except httpx.RequestError as e:
            raise DatabaseOperationError(f"Network error saving generated_content: {type(e).__name__}")

    # -------------------------------------------------------------------------
    # Worksheets
    # -------------------------------------------------------------------------

    def get_worksheet_by_id(self, worksheet_id: str) -> Optional[Dict[str, Any]]:
        """Query a worksheet by its primary ID."""
        if self.mock:
            return self._mock_worksheets.get(worksheet_id)

        url = f"{self.supabase_url}/rest/v1/worksheets"
        params = {"id": f"eq.{worksheet_id}", "select": "*"}
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.get(url, params=params, headers=self._headers())
                if resp.status_code == 200 and resp.json():
                    return resp.json()[0]
                return None
        except httpx.RequestError as e:
            raise DatabaseOperationError(f"Failed to query worksheets: {type(e).__name__}")

    def save_worksheet(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """Insert or update a worksheet row."""
        rec = dict(record)
        now_iso = datetime.now(timezone.utc).isoformat()
        rec.setdefault("created_at", now_iso)
        rec["updated_at"] = now_iso

        if self.mock:
            self._mock_worksheets[rec["id"]] = rec
            return rec

        url = f"{self.supabase_url}/rest/v1/worksheets"
        headers = self._headers(prefer="resolution=merge-duplicates,return=representation")
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.post(url, json=rec, headers=headers)
                if resp.status_code not in (200, 201):
                    raise DatabaseOperationError(
                        f"Failed to save worksheet (HTTP {resp.status_code}): {resp.text}"
                    )
                rows = resp.json()
                return rows[0] if rows else rec
        except httpx.RequestError as e:
            raise DatabaseOperationError(f"Network error saving worksheet: {type(e).__name__}")

    # -------------------------------------------------------------------------
    # Flashcards
    # -------------------------------------------------------------------------

    def get_flashcards_by_deck(self, deck_name: str) -> List[Dict[str, Any]]:
        """Query all flashcard rows for a given deck."""
        if self.mock:
            return [fc for fc in self._mock_flashcards.values() if fc.get("deck_name") == deck_name]

        url = f"{self.supabase_url}/rest/v1/flashcards"
        params = {"deck_name": f"eq.{deck_name}", "select": "*"}
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.get(url, params=params, headers=self._headers())
                if resp.status_code == 200:
                    return resp.json()
                return []
        except httpx.RequestError as e:
            raise DatabaseOperationError(f"Failed to query flashcards: {type(e).__name__}")

    def save_flashcard(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """Insert or update a flashcard row."""
        rec = dict(record)
        now_iso = datetime.now(timezone.utc).isoformat()
        rec.setdefault("created_at", now_iso)
        rec["updated_at"] = now_iso

        if self.mock:
            self._mock_flashcards[rec["id"]] = rec
            return rec

        url = f"{self.supabase_url}/rest/v1/flashcards"
        headers = self._headers(prefer="resolution=merge-duplicates,return=representation")
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.post(url, json=rec, headers=headers)
                if resp.status_code not in (200, 201):
                    raise DatabaseOperationError(
                        f"Failed to save flashcard (HTTP {resp.status_code}): {resp.text}"
                    )
                rows = resp.json()
                return rows[0] if rows else rec
        except httpx.RequestError as e:
            raise DatabaseOperationError(f"Network error saving flashcard: {type(e).__name__}")

    # -------------------------------------------------------------------------
    # Rollback Deletions
    # -------------------------------------------------------------------------

    def delete_worksheet(self, worksheet_id: str) -> bool:
        """Delete a worksheet row by ID (for rollback purposes)."""
        if self.mock:
            self._mock_worksheets.pop(worksheet_id, None)
            return True

        url = f"{self.supabase_url}/rest/v1/worksheets"
        params = {"id": f"eq.{worksheet_id}"}
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.delete(url, params=params, headers=self._headers())
                return resp.status_code in (200, 204)
        except Exception as e:
            logger.warning("Failed to delete worksheet %s during rollback: %s", worksheet_id, e)
            return False

    def delete_flashcards(self, flashcard_ids: List[str]) -> bool:
        """Delete flashcard rows by IDs (for rollback purposes)."""
        if not flashcard_ids:
            return True
        if self.mock:
            for fid in flashcard_ids:
                self._mock_flashcards.pop(fid, None)
            return True

        url = f"{self.supabase_url}/rest/v1/flashcards"
        params = {"id": f"in.({','.join(flashcard_ids)})"}
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.delete(url, params=params, headers=self._headers())
                return resp.status_code in (200, 204)
        except Exception as e:
            logger.warning("Failed to delete flashcards during rollback: %s", e)
            return False

    def delete_generated_content(self, generated_content_id: str) -> bool:
        """Delete a generated_content row by ID (for rollback purposes)."""
        if self.mock:
            self._mock_generated_content.pop(generated_content_id, None)
            return True

        url = f"{self.supabase_url}/rest/v1/generated_content"
        params = {"id": f"eq.{generated_content_id}"}
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.delete(url, params=params, headers=self._headers())
                return resp.status_code in (200, 204)
        except Exception as e:
            logger.warning("Failed to delete generated_content during rollback: %s", e)
            return False
