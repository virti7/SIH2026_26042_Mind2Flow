import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_lesson_lifecycle(
    client: AsyncClient,
    teacher_auth_headers: dict,
    other_teacher_auth_headers: dict,
    admin_auth_headers: dict,
):
    # 1. Teacher 1 creates a Lesson
    lesson_payload = {
        "title": "Bilingual Animal Sounds (जानवरों की बोलियाँ)",
        "grade": 1,
        "subject": "Hindi",
        "language": "Ho",
        "objective": "Identify animals and their sounds in Ho and Hindi",
        "prerequisite": "Knows common domestic animals",
        "teacher_moves": [
            {"step": 1, "title": "Warmup", "description": "Sound imitation game in Ho and Hindi", "duration_minutes": 5},
            {"step": 2, "title": "Flashcards", "description": "Show animal cards", "duration_minutes": 10},
        ],
        "local_id": "local-lesson-101",
    }
    create_resp = await client.post("/api/v1/lessons", json=lesson_payload, headers=teacher_auth_headers)
    assert create_resp.status_code == 201
    lesson_data = create_resp.json()
    lesson_id = lesson_data["id"]
    assert lesson_data["title"] == lesson_payload["title"]
    assert lesson_data["version"] == 1

    # 2. Get Lesson by ID
    get_resp = await client.get(f"/api/v1/lessons/{lesson_id}", headers=teacher_auth_headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["id"] == lesson_id

    # 3. Teacher 1 updates Lesson
    update_payload = {"title": "Bilingual Animal Sounds (जानवरों की बोलियाँ) - Updated"}
    update_resp = await client.put(f"/api/v1/lessons/{lesson_id}", json=update_payload, headers=teacher_auth_headers)
    assert update_resp.status_code == 200
    assert update_resp.json()["version"] == 2

    # 4. Teacher 2 attempts to edit Teacher 1's lesson -> 403 Forbidden
    resp_other = await client.put(f"/api/v1/lessons/{lesson_id}", json={"title": "Hacked Title"}, headers=other_teacher_auth_headers)
    assert resp_other.status_code == 403

    # 5. Teacher records lesson delivery progress
    delivery_payload = {
        "completed_step_index": 2,
        "total_steps": 4,
        "notes": "Class engaged actively with animal sounds in Ho.",
    }
    deliv_resp = await client.post(f"/api/v1/lessons/{lesson_id}/delivery", json=delivery_payload, headers=teacher_auth_headers)
    assert deliv_resp.status_code == 200
    assert deliv_resp.json()["completed_step_index"] == 2

    # 6. Soft Delete Lesson
    del_resp = await client.delete(f"/api/v1/lessons/{lesson_id}", headers=teacher_auth_headers)
    assert del_resp.status_code == 204

    # Subsequent GET returns 404
    get_del = await client.get(f"/api/v1/lessons/{lesson_id}", headers=teacher_auth_headers)
    assert get_del.status_code == 404
