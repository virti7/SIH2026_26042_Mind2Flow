import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.db.models.school import Teacher


@pytest.mark.asyncio
async def test_resolve_identifier_by_username_and_email(client: AsyncClient, db_session: AsyncSession):
    # Seed teacher
    t = Teacher(
        user_id="auth-test-teacher-uuid-001",
        username="teacher01",
        name="Rameshwar Soren",
        email="rameshwar.soren@school.edu.in",
        designation="Primary Teacher",
        preferred_language="Hindi",
        is_active=True,
    )
    db_session.add(t)
    await db_session.commit()

    # 1. Resolve by username
    resp1 = await client.post("/api/v1/auth/resolve-identifier", json={"identifier": "teacher01"})
    assert resp1.status_code == 200
    data1 = resp1.json()
    assert data1["found"] is True
    assert data1["email"] == "rameshwar.soren@school.edu.in"
    # Verify no password or credentials leaked
    assert "password" not in data1
    assert "hash" not in data1
    assert "token" not in data1

    # 2. Resolve by email
    resp2 = await client.post("/api/v1/auth/resolve-identifier", json={"identifier": "rameshwar.soren@school.edu.in"})
    assert resp2.status_code == 200
    data2 = resp2.json()
    assert data2["found"] is True
    assert data2["email"] == "rameshwar.soren@school.edu.in"

    # 3. Unknown identifier
    resp3 = await client.post("/api/v1/auth/resolve-identifier", json={"identifier": "unknown_code_999"})
    assert resp3.status_code == 200
    data3 = resp3.json()
    assert data3["found"] is False
    assert data3["email"] is None


@pytest.mark.asyncio
async def test_username_availability(client: AsyncClient, db_session: AsyncSession):
    t = Teacher(
        user_id="uuid-taken-001",
        username="taken_code",
        name="Sunita Devi",
        email="sunita@school.edu.in",
    )
    db_session.add(t)
    await db_session.commit()

    # Check taken username
    r_taken = await client.post("/api/v1/auth/check-username", json={"username": "taken_code"})
    assert r_taken.status_code == 200
    assert r_taken.json()["available"] is False
    assert "already registered" in r_taken.json()["message"]

    # Check available username
    r_avail = await client.post("/api/v1/auth/check-username", json={"username": "available_new_code"})
    assert r_avail.status_code == 200
    assert r_avail.json()["available"] is True


@pytest.mark.asyncio
async def test_signup_creates_teacher_profile_with_server_enforced_teacher_role(
    client: AsyncClient,
    db_session: AsyncSession,
):
    # Attempt to self-assign role = "admin" through registration payload
    payload = {
        "user_id": "supabase-uuid-9999",
        "username": "new_teacher_01",
        "name": "Arjun Soren",
        "email": "arjun@jharkhand.gov.in",
        "role": "admin",  # Client tries to inject admin role
    }
    signup_headers = {
        "Authorization": f"Bearer {create_access_token({'sub': 'supabase-uuid-9999', 'email': 'arjun@jharkhand.gov.in', 'role': 'teacher'})}"
    }
    resp = await client.post(
        "/api/v1/auth/register-teacher", json=payload, headers=signup_headers
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["user_id"] == "supabase-uuid-9999"
    assert data["username"] == "new_teacher_01"
    # MUST be enforced as 'teacher', not client-supplied 'admin'
    assert data["role"] == "teacher"

    # Verify DB record
    stmt = select(Teacher).where(Teacher.user_id == "supabase-uuid-9999")
    res = await db_session.execute(stmt)
    teacher = res.scalar_one_or_none()
    assert teacher is not None
    assert teacher.username == "new_teacher_01"
    assert teacher.email == "arjun@jharkhand.gov.in"

    # Duplicate username registration returns 409 Conflict
    dup_payload = {
        "user_id": "other-uuid-8888",
        "username": "new_teacher_01",
        "name": "Other Name",
        "email": "other@jharkhand.gov.in",
    }
    dup_headers = {
        "Authorization": f"Bearer {create_access_token({'sub': 'other-uuid-8888', 'email': 'other@jharkhand.gov.in', 'role': 'teacher'})}"
    }
    dup_resp = await client.post(
        "/api/v1/auth/register-teacher", json=dup_payload, headers=dup_headers
    )
    assert dup_resp.status_code == 409
    assert "already registered" in dup_resp.json()["detail"]


@pytest.mark.asyncio
async def test_get_current_user_profile_me(client: AsyncClient, db_session: AsyncSession):
    # Seed teacher profile
    t = Teacher(
        user_id="verified-teacher-uuid",
        username="teachervip",
        name="Sunita Soren",
        email="sunita.soren@jharkhand.edu.in",
        preferred_language="Ho",
    )
    db_session.add(t)
    await db_session.commit()

    token = create_access_token({
        "sub": "verified-teacher-uuid",
        "email": "sunita.soren@jharkhand.edu.in",
        "role": "teacher",
    })

    # Call /api/v1/me
    resp = await client.get("/api/v1/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["user_id"] == "verified-teacher-uuid"
    assert data["username"] == "teachervip"
    assert data["role"] == "teacher"
    assert data["teacher_name"] == "Sunita Soren"
    assert data["preferred_language"] == "Ho"

    # Call without token -> 401
    resp_no_token = await client.get("/api/v1/me")
    assert resp_no_token.status_code == 401


@pytest.mark.asyncio
async def test_teacher_content_generation_authorization(client: AsyncClient, teacher_auth_headers: dict):
    # Teacher is authorized to generate worksheets
    ws_payload = {
        "grade": 2,
        "subject": "Mathematics",
        "topic": "Numbers up to 100",
        "target_language": "sat",
        "num_questions": 3,
        "worksheet_type": "practice",
    }
    resp_ws = await client.post("/api/v1/worksheets/generate", json=ws_payload, headers=teacher_auth_headers)
    assert resp_ws.status_code == 202
    assert "job_id" in resp_ws.json()

    # Teacher is authorized to generate flashcards
    fc_payload = {
        "grade": 2,
        "subject": "Hindi",
        "theme": "Animals",
        "target_language": "sat",
        "card_count": 4,
    }
    resp_fc = await client.post("/api/v1/flashcards/generate", json=fc_payload, headers=teacher_auth_headers)
    assert resp_fc.status_code == 202
    assert "job_id" in resp_fc.json()

    # Student token cannot generate worksheets (require_teacher)
    student_token = create_access_token({
        "sub": "student-uuid-1",
        "email": "student@school.edu.in",
        "role": "student",
    })
    resp_student = await client.post(
        "/api/v1/worksheets/generate",
        json=ws_payload,
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert resp_student.status_code == 403

    # Unauthenticated request -> 401
    resp_unauth = await client.post("/api/v1/worksheets/generate", json=ws_payload)
    assert resp_unauth.status_code == 401
