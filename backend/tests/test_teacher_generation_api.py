"""Tests for teacher asynchronous generation API with Sarvam and offline preparation."""
import pytest
from httpx import AsyncClient

from app.core.config import settings
from app.core.security import create_access_token
from app.services.generation_jobs import generation_job_manager


@pytest.fixture
def teacher_auth_headers():
    token = create_access_token(
        data={
            "sub": "user_teacher_test_01",
            "role": "teacher",
            "school_id": "school_torpa_01",
            "district": "Khunti",
        }
    )
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_unauthenticated_request_rejected(client: AsyncClient):
    """Unauthenticated generation requests must be rejected with 401."""
    resp = await client.post(
        "/api/v1/ai/teacher/generate",
        json={
            "content_type": "worksheet",
            "grade": 1,
            "subject": "Mathematics",
            "target_language": "sat",
        },
    )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_authenticated_teacher_can_request_generation(client: AsyncClient, teacher_auth_headers):
    """Authenticated teacher can request generation and receives a 202 with job_id."""
    resp = await client.post(
        "/api/v1/ai/teacher/generate",
        headers=teacher_auth_headers,
        json={
            "content_type": "worksheet",
            "grade": 1,
            "subject": "Mathematics",
            "target_language": "sat",
            "difficulty": "medium",
            "idempotency_key": "idem_test_001",
        },
    )
    assert resp.status_code == 202
    data = resp.json()
    assert "job_id" in data
    assert data["status"] in ("PENDING", "GENERATING", "VALIDATING", "READY", "REVIEW_REQUIRED")
    assert data["content_type"] == "worksheet"
    assert data["grade"] == 1


@pytest.mark.asyncio
async def test_idempotent_duplicate_request_returns_same_job(client: AsyncClient, teacher_auth_headers):
    """Submitting the same idempotency key returns the same job."""
    resp1 = await client.post(
        "/api/v1/ai/teacher/generate",
        headers=teacher_auth_headers,
        json={
            "content_type": "flashcard",
            "grade": 1,
            "subject": "Mathematics",
            "target_language": "sat",
            "idempotency_key": "idem_duplicate_key_123",
        },
    )
    assert resp1.status_code == 202
    job1 = resp1.json()

    resp2 = await client.post(
        "/api/v1/ai/teacher/generate",
        headers=teacher_auth_headers,
        json={
            "content_type": "flashcard",
            "grade": 1,
            "subject": "Mathematics",
            "target_language": "sat",
            "idempotency_key": "idem_duplicate_key_123",
        },
    )
    assert resp2.status_code == 202
    job2 = resp2.json()

    assert job1["job_id"] == job2["job_id"]


@pytest.mark.asyncio
async def test_job_status_and_approval_flow(client: AsyncClient, teacher_auth_headers):
    """Test full asynchronous execution, status polling, and review approval."""
    # Create job with mock mode
    req = {
        "content_type": "worksheet",
        "grade": 1,
        "subject": "Mathematics",
        "curriculum_id": "GC-G1-NUM-032-01-bi",
        "target_language": "sat",
        "idempotency_key": "idem_flow_test_999",
    }
    resp = await client.post("/api/v1/ai/teacher/generate", headers=teacher_auth_headers, json=req)
    assert resp.status_code == 202
    job_id = resp.json()["job_id"]

    # Execute synchronously for deterministic testing
    generation_job_manager.execute_job_sync(job_id)

    # Poll status
    poll_resp = await client.get(f"/api/v1/ai/jobs/{job_id}", headers=teacher_auth_headers)
    assert poll_resp.status_code == 200
    poll_data = poll_resp.json()

    # Santali generation requires review gate (LANG_SAT_SCRIPT_UNCONFIRMED)
    assert poll_data["status"] in ("REVIEW_REQUIRED", "READY")

    if poll_data["status"] == "REVIEW_REQUIRED":
        assert poll_data["review_gates"] is not None
        # Teacher approves script
        approve_resp = await client.post(
            f"/api/v1/ai/jobs/{job_id}/approve",
            headers=teacher_auth_headers,
            json={"santali_script_confirmed": "Olck", "notes": "Verified Ol Chiki script"},
        )
        assert approve_resp.status_code == 200
        approved_data = approve_resp.json()
        assert approved_data["status"] == "READY"
        assert approved_data["content"] is not None
        assert approved_data["assets"] is not None


@pytest.mark.asyncio
async def test_secrets_never_exposed_in_job_responses(client: AsyncClient, teacher_auth_headers):
    """Verify that sensitive secrets and tokens are never returned in job payloads."""
    resp = await client.post(
        "/api/v1/ai/teacher/generate",
        headers=teacher_auth_headers,
        json={
            "content_type": "worksheet",
            "grade": 1,
            "subject": "Mathematics",
            "target_language": "sat",
        },
    )
    job_text = resp.text
    if settings.SUPABASE_JWT_SECRET:
        assert settings.SUPABASE_JWT_SECRET not in job_text
    if settings.SUPABASE_SERVICE_ROLE_KEY:
        assert settings.SUPABASE_SERVICE_ROLE_KEY not in job_text
    if settings.SARVAM_API_KEY:
        assert settings.SARVAM_API_KEY not in job_text
    assert "SARVAM_API_KEY" not in job_text
