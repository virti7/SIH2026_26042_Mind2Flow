"""Cross-teacher isolation for generation jobs and generated content.

Regression coverage for the multi-account bug: Teacher B must never be able
to poll, approve, or fetch Teacher A's generation job / generated content
by id. The backend answers 404 (not 403) so ids of other teachers are not
disclosed. Ownership always comes from the verified JWT subject.
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_teacher_cannot_poll_or_approve_other_teachers_job(
    client: AsyncClient, teacher_auth_headers: dict, other_teacher_auth_headers: dict
):
    req = {
        "content_type": "worksheet",
        "grade": 1,
        "subject": "Mathematics",
        "curriculum_id": "GC-G1-NUM-032-01-bi",
        "target_language": "sat",
        "idempotency_key": "idem_ownership_probe_001",
    }
    create = await client.post(
        "/api/v1/ai/teacher/generate", headers=teacher_auth_headers, json=req
    )
    assert create.status_code == 202
    job_id = create.json()["job_id"]

    # Another teacher polling the job id learns nothing (404, not 403).
    poll_foreign = await client.get(
        f"/api/v1/ai/jobs/{job_id}", headers=other_teacher_auth_headers
    )
    assert poll_foreign.status_code == 404

    # Another teacher cannot approve it either.
    approve_foreign = await client.post(
        f"/api/v1/ai/jobs/{job_id}/approve",
        headers=other_teacher_auth_headers,
        json={"santali_script_confirmed": "Olck"},
    )
    assert approve_foreign.status_code == 404

    # The owning teacher is unaffected.
    poll_own = await client.get(
        f"/api/v1/ai/jobs/{job_id}", headers=teacher_auth_headers
    )
    assert poll_own.status_code == 200
    assert poll_own.json()["job_id"] == job_id


@pytest.mark.asyncio
async def test_teacher_cannot_read_other_teachers_generated_content(
    client: AsyncClient,
    teacher_auth_headers: dict,
    other_teacher_auth_headers: dict,
    reviewer_auth_headers: dict,
):
    req = {
        "blueprint_id": "BP-G1-NUM-032-01",
        "content_type": "worksheet",
        "target_language": "sat",
        "mock_mode": True,
        "force": True,
    }
    create = await client.post(
        "/api/v1/ai/generate", json=req, headers=teacher_auth_headers
    )
    assert create.status_code == 201
    content_id = create.json()["id"]

    foreign = await client.get(
        f"/api/v1/ai/content/{content_id}", headers=other_teacher_auth_headers
    )
    assert foreign.status_code == 404

    own = await client.get(
        f"/api/v1/ai/content/{content_id}", headers=teacher_auth_headers
    )
    assert own.status_code == 200

    # Reviewers keep access for the review workflow.
    review = await client.get(
        f"/api/v1/ai/content/{content_id}", headers=reviewer_auth_headers
    )
    assert review.status_code == 200
