import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_assessment_progress_and_remediation(
    client: AsyncClient,
    teacher_auth_headers: dict,
    admin_auth_headers: dict,
):
    # 1. Create NIPUN Outcome
    goal_resp = await client.post(
        "/api/v1/nipun/goals",
        json={"code": "G1_NUM", "title": "Foundational Numeracy", "grade": 1},
        headers=admin_auth_headers,
    )
    goal_id = goal_resp.json()["id"]

    comp_resp = await client.post(
        "/api/v1/nipun/competencies",
        json={"goal_id": goal_id, "code": "C2.1", "title": "Counting 1-10", "domain": "Foundational Numeracy"},
        headers=admin_auth_headers,
    )
    comp_id = comp_resp.json()["id"]

    lo_resp = await client.post(
        "/api/v1/nipun/outcomes",
        json={
            "competency_id": comp_id,
            "code": "LO2.1.1",
            "description": "Counts objects 1 to 10 in mother tongue and connects with numerals",
            "grade": 1,
            "subject": "Mathematics",
        },
        headers=admin_auth_headers,
    )
    lo_id = lo_resp.json()["id"]

    # 2. Create Assessment with questions
    assessment_payload = {
        "title": "Numbers 1-10 Oral & Visual Check",
        "grade": 1,
        "subject": "Mathematics",
        "learning_outcome_id": lo_id,
        "total_marks": 10,
        "passing_marks": 6,
        "questions": [
            {
                "question_text": "Count the apples in Ho and point to the number 5",
                "question_type": "oral",
                "marks": 5,
            },
            {
                "question_text": "Which digit is greater: 4 or 7?",
                "question_type": "multiple_choice",
                "options": ["4", "7"],
                "correct_answer": "7",
                "marks": 5,
            },
        ],
    }
    ass_resp = await client.post("/api/v1/assessments", json=assessment_payload, headers=teacher_auth_headers)
    assert ass_resp.status_code == 201
    assessment_id = ass_resp.json()["id"]

    # 3. Submit low-scoring assessment for student "Birsa Munda" -> Should auto-generate LearningGap & Remediation
    sub_payload = {
        "student_name": "Birsa Munda",
        "student_id": "STUDENT_001",
        "score": 3.0,
        "max_score": 10.0,
        "status": "Needs Support",
    }
    sub_resp = await client.post(f"/api/v1/assessments/{assessment_id}/submit", json=sub_payload, headers=teacher_auth_headers)
    assert sub_resp.status_code == 200
    assert sub_resp.json()["status"] == "Needs Support"

    # 4. Check Learner Progress endpoint
    progress_resp = await client.get("/api/v1/progress/learners/STUDENT_001", headers=teacher_auth_headers)
    assert progress_resp.status_code == 200
    prog_data = progress_resp.json()
    assert prog_data["student_name"] == "Birsa Munda"
    assert prog_data["overall_status"] == "Needs Support"
    assert len(prog_data["active_gaps"]) >= 1

    gap_id = prog_data["active_gaps"][0]["id"]
    assert len(prog_data["active_gaps"][0]["remediations"]) >= 1

    # 5. Teacher resolves the learning gap after classroom remedial session
    res_resp = await client.post(f"/api/v1/progress/gaps/{gap_id}/resolve", headers=teacher_auth_headers)
    assert res_resp.status_code == 200
