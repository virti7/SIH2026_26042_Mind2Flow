import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_languages_seeded(client: AsyncClient):
    response = await client.get("/api/v1/languages")
    assert response.status_code == 200
    langs = response.json()
    assert len(langs) >= 4
    codes = [l["code"] for l in langs]
    assert "hi" in codes
    assert "ho" in codes
    assert "unr" in codes
    assert "sat" in codes


@pytest.mark.asyncio
async def test_nipun_curriculum_flow(client: AsyncClient, admin_auth_headers: dict):
    # 1. Check grades
    grades_resp = await client.get("/api/v1/nipun/grades")
    assert grades_resp.status_code == 200
    assert 1 in grades_resp.json()

    # 2. Admin creates Goal
    goal_resp = await client.post(
        "/api/v1/nipun/goals",
        json={
            "code": "G1_LIT",
            "title": "Oral Language & Phonological Awareness",
            "description": "Foundational Literacy Goal 1",
            "grade": 1,
        },
        headers=admin_auth_headers,
    )
    assert goal_resp.status_code == 200
    goal_id = goal_resp.json()["id"]

    # 3. Admin creates Competency
    comp_resp = await client.post(
        "/api/v1/nipun/competencies",
        json={
            "goal_id": goal_id,
            "code": "C1.1",
            "title": "Phonemic Awareness in Mother Tongue and Hindi",
            "domain": "Foundational Literacy",
        },
        headers=admin_auth_headers,
    )
    assert comp_resp.status_code == 200
    comp_id = comp_resp.json()["id"]

    # 4. Admin creates Learning Outcome
    lo_resp = await client.post(
        "/api/v1/nipun/outcomes",
        json={
            "competency_id": comp_id,
            "code": "LO1.1.1",
            "description": "Recognizes beginning phonemes in familiar bilingual vocabulary",
            "grade": 1,
            "subject": "Hindi",
        },
        headers=admin_auth_headers,
    )
    assert lo_resp.status_code == 200
    lo_id = lo_resp.json()["id"]

    # 5. Teacher queries outcomes by grade and subject
    filter_resp = await client.get("/api/v1/nipun/outcomes?grade=1&subject=Hindi")
    assert filter_resp.status_code == 200
    outcomes = filter_resp.json()
    assert any(o["code"] == "LO1.1.1" for o in outcomes)
