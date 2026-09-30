import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_ai_generation_and_validation_pipeline(
    client: AsyncClient,
    teacher_auth_headers: dict,
    reviewer_auth_headers: dict,
    admin_auth_headers: dict,
):
    # 1. Create a Learning Outcome to base generation on
    lo_resp = await client.post(
        "/api/v1/nipun/outcomes",
        json={
            "competency_id": "dummy-comp-id",
            "code": "LO_HO_01",
            "description": "Naming body parts and greetings in Ho",
            "grade": 1,
            "subject": "Hindi",
        },
        headers=admin_auth_headers,
    )
    lo_id = lo_resp.json()["id"]

    # 2. Teacher or reviewer requests AI content preparation
    gen_req = {
        "learning_outcome_id": lo_id,
        "content_type": "lesson",
        "grade": 1,
        "subject": "Hindi",
        "target_language": "Ho",
    }
    gen_resp = await client.post("/api/v1/ai/generate", json=gen_req, headers=teacher_auth_headers)
    assert gen_resp.status_code == 201
    content_id = gen_resp.json()["id"]
    assert gen_resp.json()["status"] == "GENERATED"
    assert "teacher_moves" in gen_resp.json()["raw_output"]

    # 3. Content Reviewer moves status to REVIEW
    review_resp = await client.patch(
        f"/api/v1/ai/content/{content_id}/status",
        json={"status": "REVIEW", "review_notes": "Pedagogical moves aligned with NIPUN guidelines"},
        headers=reviewer_auth_headers,
    )
    assert review_resp.status_code == 200
    assert review_resp.json()["status"] == "REVIEW"

    # 4. Content Reviewer approves and publishes content to catalog
    pub_resp = await client.patch(
        f"/api/v1/ai/content/{content_id}/status",
        json={"status": "PUBLISHED", "publish_to_catalog": True},
        headers=reviewer_auth_headers,
    )
    assert pub_resp.status_code == 200
    assert pub_resp.json()["status"] == "PUBLISHED"

    # 5. Check that the lesson was cataloged and can be queried
    lessons_resp = await client.get("/api/v1/lessons", headers=teacher_auth_headers)
    assert lessons_resp.status_code == 200
    lessons = lessons_resp.json()
    assert any("Bilingual NIPUN Lesson" in l["title"] for l in lessons)


@pytest.mark.asyncio
async def test_analytics_summary(
    client: AsyncClient,
    admin_auth_headers: dict,
):
    resp = await client.get("/api/v1/analytics/summary", headers=admin_auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "total_teachers" in data
    assert "total_lessons" in data
    assert "active_language_packs" in data
    assert "timestamp" in data
