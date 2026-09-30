import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_feedback_submission_and_review_workflow(
    client: AsyncClient,
    teacher_auth_headers: dict,
    reviewer_auth_headers: dict,
):
    # 1. Teacher submits translation feedback
    fb_payload = {
        "source_text": "बच्चों, अपनी किताबें खोलो",
        "translated_text": "Wrong translation text",
        "suggested_correction": "Honko, apeag puthi odonpe",
        "feedback_type": "wrong_meaning",
        "target_language": "Ho",
    }
    fb_resp = await client.post("/api/v1/feedback/translations", json=fb_payload, headers=teacher_auth_headers)
    assert fb_resp.status_code == 201
    assert fb_resp.json()["suggested_correction"] == fb_payload["suggested_correction"]

    # 2. Reviewer views review queue
    rq_resp = await client.get("/api/v1/review-queue?status_filter=PENDING", headers=reviewer_auth_headers)
    assert rq_resp.status_code == 200
    queue_items = rq_resp.json()
    assert len(queue_items) >= 1
    item_id = queue_items[0]["id"]

    # 3. Reviewer approves translation and promotes to verified phrases
    review_action = {
        "status": "APPROVED",
        "notes": "Verified correct Ho classroom imperative idiom",
        "promote_to_verified_phrases": True,
    }
    action_resp = await client.post(f"/api/v1/review-queue/{item_id}/review", json=review_action, headers=reviewer_auth_headers)
    assert action_resp.status_code == 200
    assert action_resp.json()["status"] == "APPROVED"

    # 4. Check Verified Phrases bank contains the approved phrase
    vp_resp = await client.get("/api/v1/verified-phrases")
    assert vp_resp.status_code == 200
    phrases = vp_resp.json()
    assert any("अपनी किताबें खोलो" in p["source_text"] for p in phrases)
