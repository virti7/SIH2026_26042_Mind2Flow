import pytest
from httpx import AsyncClient
from app.services.generation_jobs import generation_job_manager
from app.db.models.resource import Flashcard


@pytest.mark.asyncio
async def test_health_public(client: AsyncClient):
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"


@pytest.mark.asyncio
async def test_me_endpoint_alias(client: AsyncClient, db_session, teacher_auth_headers: dict):
    # Tests the /api/v1/me alias added to FastAPI. /me resolves the teacher
    # by authenticated user id, so the profile row must exist.
    from app.db.models.school import Teacher

    db_session.add(
        Teacher(
            user_id="teacher-user-uuid-1",
            name="Alias Teacher",
            email="teacher1@jharkhand.edu.in",
            designation="Primary Teacher",
            is_active=True,
        )
    )
    await db_session.commit()

    response = await client.get("/api/v1/me", headers=teacher_auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["user_id"] == "teacher-user-uuid-1"
    assert data["role"] == "teacher"


@pytest.mark.asyncio
async def test_me_endpoint_unauthenticated(client: AsyncClient):
    # Calling /api/v1/me without Authorization header must return 401
    response = await client.get("/api/v1/me")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_flashcard_generate_missing_auth(client: AsyncClient):
    payload = {
        "grade": 1,
        "subject": "Mathematics",
        "target_language": "sat",
        "topic": "Numbers",
        "card_count": 5,
    }
    response = await client.post("/api/v1/flashcards/generate", json=payload)
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_flashcard_generate_non_teacher_forbidden(client: AsyncClient, student_auth_headers: dict):
    # Non-teacher roles must receive HTTP 403 Forbidden
    payload = {
        "grade": 1,
        "subject": "Mathematics",
        "target_language": "sat",
        "topic": "Numbers",
        "card_count": 5,
    }
    response = await client.post("/api/v1/flashcards/generate", json=payload, headers=student_auth_headers)
    assert response.status_code == 403
    assert "Teacher role required" in response.json()["detail"]


@pytest.mark.asyncio
async def test_worksheet_generate_missing_auth(client: AsyncClient):
    payload = {
        "grade": 1,
        "subject": "Mathematics",
        "target_language": "sat",
        "topic": "Addition",
        "worksheet_type": "mcq",
    }
    response = await client.post("/api/v1/worksheets/generate", json=payload)
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_worksheet_generate_non_teacher_forbidden(client: AsyncClient, student_auth_headers: dict):
    payload = {
        "grade": 1,
        "subject": "Mathematics",
        "target_language": "sat",
        "topic": "Addition",
        "worksheet_type": "mcq",
    }
    response = await client.post("/api/v1/worksheets/generate", json=payload, headers=student_auth_headers)
    assert response.status_code == 403
    assert "Teacher role required" in response.json()["detail"]


@pytest.mark.asyncio
async def test_worksheet_generate_teacher_success(client: AsyncClient, teacher_auth_headers: dict):
    payload = {
        "grade": 1,
        "subject": "Mathematics",
        "target_language": "sat",
        "topic": "Addition",
        "worksheet_type": "mcq",
    }
    response = await client.post("/api/v1/worksheets/generate", json=payload, headers=teacher_auth_headers)
    assert response.status_code == 202
    assert "job_id" in response.json()


@pytest.mark.asyncio
async def test_flashcard_generate_invalid_auth(client: AsyncClient):
    payload = {
        "grade": 1,
        "subject": "Mathematics",
        "target_language": "sat",
        "topic": "Numbers",
        "card_count": 5,
    }
    response = await client.post(
        "/api/v1/flashcards/generate",
        json=payload,
        headers={"Authorization": "Bearer invalid.jwt.token"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_flashcard_generate_unsupported_grade(client: AsyncClient, teacher_auth_headers: dict):
    # Only Grade 1 and 2 are supported for foundational primary prototype
    payload = {
        "grade": 3,
        "subject": "Mathematics",
        "target_language": "sat",
        "topic": "Numbers",
        "card_count": 5,
    }
    response = await client.post("/api/v1/flashcards/generate", json=payload, headers=teacher_auth_headers)
    assert response.status_code == 400
    assert "Grade 3 is unsupported" in response.json()["detail"]


@pytest.mark.asyncio
async def test_flashcard_generate_unsupported_language(client: AsyncClient, teacher_auth_headers: dict):
    payload = {
        "grade": 1,
        "subject": "Mathematics",
        "target_language": "klingon",
        "topic": "Numbers",
        "card_count": 5,
    }
    response = await client.post("/api/v1/flashcards/generate", json=payload, headers=teacher_auth_headers)
    assert response.status_code == 400
    assert "not supported" in response.json()["detail"]


@pytest.mark.asyncio
async def test_flashcard_generate_success_and_persist(client: AsyncClient, teacher_auth_headers: dict, db_session):
    payload = {
        "grade": 1,
        "subject": "Mathematics",
        "target_language": "sat",
        "topic": "Numbers and Counting",
        "blueprint_id": "BP-G1-NUM-041-01",
        "card_count": 5,
    }
    response = await client.post("/api/v1/flashcards/generate", json=payload, headers=teacher_auth_headers)
    assert response.status_code == 202
    data = response.json()
    assert "job_id" in data
    assert data["grade"] == 1
    assert data["target_language"] == "sat"
    job_id = data["job_id"]

    # Execute the background generation pipeline
    generation_job_manager.execute_job_sync(job_id)
    job = generation_job_manager.get_job(job_id)
    assert job is not None
    assert job.status in ["READY", "REVIEW_REQUIRED"]
    assert job.content is not None
    assert job.content["content_type"] == "flashcard"
    assert "items" in job.content
    assert len(job.content["items"]) > 0

    # Seed a flashcard deck in the test DB session to verify retrieval endpoints
    deck_card = Flashcard(
        deck_name="Numbers 1 to 10",
        front_text="१ (एक)",
        back_text="᱑ (ᱢᱤᱫ)",
        grade=1,
        language_id="sat",
    )
    db_session.add(deck_card)
    await db_session.commit()

    # Verify retrieval via decks endpoint
    decks_resp = await client.get("/api/v1/flashcards/decks", headers=teacher_auth_headers)
    assert decks_resp.status_code == 200
    decks = decks_resp.json()
    assert len(decks) >= 1
    deck = decks[0]
    assert deck["deck_name"] == "Numbers 1 to 10"
    assert deck["card_count"] >= 1

    # Verify detail retrieval by deck_name
    detail_resp = await client.get(f"/api/v1/flashcards/decks/{deck['deck_name']}", headers=teacher_auth_headers)
    assert detail_resp.status_code == 200
    deck_detail = detail_resp.json()
    assert deck_detail["deck_name"] == "Numbers 1 to 10"
    assert "cards" in deck_detail
    assert len(deck_detail["cards"]) >= 1


@pytest.mark.asyncio
async def test_user_metadata_role_rejected_for_privileged_access(client: AsyncClient):
    """Part 1 Security Test: user_metadata.role must NEVER be trusted for privileged roles (teacher, admin, etc.)."""
    from jose import jwt
    from app.core.config import settings
    from datetime import datetime, timezone, timedelta

    # Craft an attacker token where user_metadata claims role='teacher'
    # but app_metadata has NO role and top-level has role='authenticated'
    now = datetime.now(timezone.utc)
    token = jwt.encode(
        {
            "sub": "attacker-user-id-666",
            "email": "attacker@example.com",
            "role": "authenticated",
            "user_metadata": {"role": "teacher", "name": "Fake Teacher"},
            "app_metadata": {},
            "exp": now + timedelta(hours=1),
            "iat": now,
        },
        settings.SUPABASE_JWT_SECRET or "dev-secret",
        algorithm="HS256",
    )
    untrusted_headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "grade": 1,
        "subject": "Mathematics",
        "target_language": "sat",
        "topic": "Numbers",
        "card_count": 5,
    }
    # Attempting teacher operation must be rejected with 403 Forbidden!
    response = await client.post("/api/v1/flashcards/generate", json=payload, headers=untrusted_headers)
    assert response.status_code == 403
    assert "Teacher role required" in response.json()["detail"]


@pytest.mark.asyncio
async def test_db_teacher_lookup_authorizes_generation(client: AsyncClient, db_session):
    """Part 1 & 3 Test: Authoritative server-side DB lookup in teachers table grants teacher access."""
    from jose import jwt
    from app.core.config import settings
    from datetime import datetime, timezone, timedelta
    from app.db.models.school import Teacher

    teacher_uid = "real-db-teacher-uuid-777"
    teacher_email = "dbteacher@jharkhand.edu.in"

    # Seed teacher in local database
    db_teacher = Teacher(
        user_id=teacher_uid,
        email=teacher_email,
        name="DB Teacher Shanti",
        designation="Primary Teacher",
        is_active=True,
    )
    db_session.add(db_teacher)
    await db_session.commit()

    # User token has NO app_metadata role (e.g. freshly registered on Supabase)
    now = datetime.now(timezone.utc)
    token = jwt.encode(
        {
            "sub": teacher_uid,
            "email": teacher_email,
            "role": "authenticated",
            "user_metadata": {},
            "app_metadata": {},
            "exp": now + timedelta(hours=1),
            "iat": now,
        },
        settings.SUPABASE_JWT_SECRET or "dev-secret",
        algorithm="HS256",
    )
    auth_headers = {"Authorization": f"Bearer {token}"}

    # /api/v1/me should verify teacher role from DB lookup
    me_resp = await client.get("/api/v1/me", headers=auth_headers)
    assert me_resp.status_code == 200
    assert me_resp.json()["role"] == "teacher"

    # Teacher operation should succeed
    payload = {
        "grade": 1,
        "subject": "Mathematics",
        "target_language": "sat",
        "topic": "Numbers",
        "card_count": 5,
    }
    response = await client.post("/api/v1/flashcards/generate", json=payload, headers=auth_headers)
    assert response.status_code == 202

