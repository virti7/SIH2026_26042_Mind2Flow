"""Teacher profile provisioning linked to the Supabase Auth identity.

Contract pinned here (§11 backend items 1-10):

1. Authenticated user WITH teacher profile -> /me 200.
2. Authenticated user WITHOUT profile -> register-teacher -> /me 200.
3. Duplicate provisioning never creates duplicate rows.
4. Unauthenticated register-teacher -> 401 (and /me -> 401).
5. Forged client user_id (mismatch with JWT sub) -> 403, no row created.
6. Legacy rows (dev-teacher-001, user_test_teacher_42) are never modified.
7. Worksheet generation works after provisioning (-> 202); without a
   profile and without a teacher-like email it is rejected (-> 403).
"""

import pytest
from httpx import AsyncClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.db.models.school import Teacher


def _headers(sub: str, email: str, role: str = "teacher") -> dict:
    token = create_access_token({"sub": sub, "email": email, "role": role})
    return {"Authorization": f"Bearer {token}"}


def _register_payload(user_id: str, email: str, name: str = "Provisioned Teacher"):
    return {"user_id": user_id, "name": name, "email": email}


@pytest.mark.asyncio
async def test_me_200_after_provisioning(client: AsyncClient):
    uid, email = "prov-flow-uid-1", "prov.flow.1@school.edu.in"
    reg = await client.post(
        "/api/v1/auth/register-teacher",
        json=_register_payload(uid, email),
        headers=_headers(uid, email),
    )
    assert reg.status_code == 200, reg.text

    me = await client.get("/api/v1/me", headers=_headers(uid, email))
    assert me.status_code == 200
    data = me.json()
    assert data["user_id"] == uid
    assert data["teacher_name"] == "Provisioned Teacher"


@pytest.mark.asyncio
async def test_duplicate_provisioning_keeps_single_row(
    client: AsyncClient, db_session: AsyncSession
):
    uid, email = "prov-dedupe-uid-1", "prov.dedupe.1@school.edu.in"
    for _ in range(2):
        reg = await client.post(
            "/api/v1/auth/register-teacher",
            json=_register_payload(uid, email),
            headers=_headers(uid, email),
        )
        assert reg.status_code == 200, reg.text

    count = (
        await db_session.execute(
            select(func.count()).select_from(Teacher).where(Teacher.user_id == uid)
        )
    ).scalar_one()
    assert count == 1


@pytest.mark.asyncio
async def test_register_teacher_requires_authentication(client: AsyncClient):
    reg = await client.post(
        "/api/v1/auth/register-teacher",
        json=_register_payload("no-auth-uid", "no.auth@school.edu.in"),
    )
    assert reg.status_code == 401

    me = await client.get("/api/v1/me")
    assert me.status_code == 401


@pytest.mark.asyncio
async def test_register_teacher_rejects_forged_user_id(
    client: AsyncClient, db_session: AsyncSession
):
    forged = await client.post(
        "/api/v1/auth/register-teacher",
        json=_register_payload("victim-uid-1", "victim@school.edu.in"),
        headers=_headers("attacker-uid-9", "attacker@school.edu.in"),
    )
    assert forged.status_code == 403

    row = (
        await db_session.execute(
            select(Teacher).where(Teacher.user_id == "victim-uid-1")
        )
    ).scalar_one_or_none()
    assert row is None

    row_attacker = (
        await db_session.execute(
            select(Teacher).where(Teacher.user_id == "attacker-uid-9")
        )
    ).scalar_one_or_none()
    assert row_attacker is None


@pytest.mark.asyncio
async def test_legacy_teacher_rows_remain_intact(
    client: AsyncClient, db_session: AsyncSession
):
    legacy = [
        ("dev-teacher-001", None, "Dev Teacher", "dev.teacher.001@school.edu.in"),
        ("user_test_teacher_42", "test_teacher_42", "Test Teacher", "test.teacher.42@school.edu.in"),
    ]
    for user_id, username, name, email in legacy:
        db_session.add(
            Teacher(
                user_id=user_id,
                username=username,
                name=name,
                email=email,
                designation="Primary Teacher",
                is_active=True,
            )
        )
    await db_session.commit()

    # Provision an unrelated new teacher; legacy rows must not be touched.
    uid, email = "prov-legacy-uid-1", "prov.legacy.1@school.edu.in"
    reg = await client.post(
        "/api/v1/auth/register-teacher",
        json=_register_payload(uid, email),
        headers=_headers(uid, email),
    )
    assert reg.status_code == 200, reg.text

    for user_id, username, name, email in legacy:
        row = (
            await db_session.execute(
                select(Teacher).where(Teacher.user_id == user_id)
            )
        ).scalar_one()
        assert row.username == username
        assert row.name == name
        assert row.email == email


@pytest.mark.asyncio
async def test_worksheet_generation_after_provisioning(client: AsyncClient):
    uid, email = "prov-gen-uid-1", "prov.gen.1@school.edu.in"
    reg = await client.post(
        "/api/v1/auth/register-teacher",
        json=_register_payload(uid, email),
        headers=_headers(uid, email),
    )
    assert reg.status_code == 200, reg.text

    ws_payload = {
        "grade": 2,
        "subject": "Mathematics",
        "topic": "Numbers up to 100",
        "target_language": "sat",
        "num_questions": 3,
        "worksheet_type": "practice",
    }
    gen = await client.post(
        "/api/v1/worksheets/generate",
        json=ws_payload,
        headers=_headers(uid, email),
    )
    assert gen.status_code == 202, gen.text
    assert "job_id" in gen.json()


@pytest.mark.asyncio
async def test_register_stores_school_name_and_me_returns_it(
    client: AsyncClient, db_session: AsyncSession
):
    uid, email = "prov-school-uid-1", "prov.school.1@school.edu.in"
    reg = await client.post(
        "/api/v1/auth/register-teacher",
        json={
            "user_id": uid,
            "name": "School Teacher",
            "school_name": "GPS Bundu",
            "email": email,
        },
        headers=_headers(uid, email),
    )
    assert reg.status_code == 200, reg.text
    assert reg.json()["school_name"] == "GPS Bundu"

    row = (
        await db_session.execute(select(Teacher).where(Teacher.user_id == uid))
    ).scalar_one()
    assert row.school_name == "GPS Bundu"
    # school_id stays untouched (relational link, never replaced).
    assert row.school_id is None

    me = await client.get("/api/v1/me", headers=_headers(uid, email))
    assert me.status_code == 200
    assert me.json()["school_name"] == "GPS Bundu"
    assert me.json()["teacher_name"] == "School Teacher"


@pytest.mark.asyncio
async def test_update_without_school_name_preserves_existing(
    client: AsyncClient, db_session: AsyncSession
):
    uid, email = "prov-school-uid-2", "prov.school.2@school.edu.in"
    first = await client.post(
        "/api/v1/auth/register-teacher",
        json={
            "user_id": uid,
            "name": "School Teacher",
            "school_name": "GPS Bundu",
            "email": email,
        },
        headers=_headers(uid, email),
    )
    assert first.status_code == 200, first.text

    second = await client.post(
        "/api/v1/auth/register-teacher",
        json={"user_id": uid, "name": "School Teacher", "email": email},
        headers=_headers(uid, email),
    )
    assert second.status_code == 200, second.text
    assert second.json()["school_name"] == "GPS Bundu"

    third = await client.post(
        "/api/v1/auth/register-teacher",
        json={
            "user_id": uid,
            "name": "School Teacher",
            "school_name": "GMS Khunti",
            "email": email,
        },
        headers=_headers(uid, email),
    )
    assert third.status_code == 200, third.text
    assert third.json()["school_name"] == "GMS Khunti"

    count = (
        await db_session.execute(
            select(func.count()).select_from(Teacher).where(Teacher.user_id == uid)
        )
    ).scalar_one()
    assert count == 1


@pytest.mark.asyncio
async def test_legacy_row_without_school_name_returns_null_safely(
    client: AsyncClient, db_session: AsyncSession
):
    # Existing teachers predate school_name: /me stays 200 with null,
    # never an invented value, never a 500.
    db_session.add(
        Teacher(
            user_id="legacy-noschool-uid-1",
            name="Legacy Teacher",
            email="legacy.noschool@school.edu.in",
            designation="Primary Teacher",
            is_active=True,
        )
    )
    await db_session.commit()

    me = await client.get(
        "/api/v1/me",
        headers=_headers("legacy-noschool-uid-1", "legacy.noschool@school.edu.in"),
    )
    assert me.status_code == 200
    assert me.json()["school_name"] is None
    assert me.json()["teacher_name"] == "Legacy Teacher"


@pytest.mark.asyncio
async def test_worksheet_generation_rejected_without_profile(client: AsyncClient):
    # Non-teacher email + no teacher row: role resolves to student -> 403.
    # (Emails starting with "teacher" take the legacy dev shortcut, so a
    # neutral email is used to prove the DB-backed path.)
    uid, email = "ghost-gen-uid-1", "fresh.noprofile@school.edu.in"
    ws_payload = {
        "grade": 2,
        "subject": "Mathematics",
        "topic": "Numbers up to 100",
        "target_language": "sat",
        "num_questions": 3,
        "worksheet_type": "practice",
    }
    gen = await client.post(
        "/api/v1/worksheets/generate",
        json=ws_payload,
        headers=_headers(uid, email),
    )
    assert gen.status_code == 403
