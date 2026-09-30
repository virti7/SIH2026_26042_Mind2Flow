"""Email + password authentication contract.

Supabase owns credentials; FastAPI trusts the authenticated user id from the
JWT. This suite pins the backend side of that contract:

- GET /api/v1/me resolves the teacher by authenticated user id (200).
- GET /api/v1/me falls back to email match (200).
- GET /api/v1/me returns 404 when no teacher profile exists.
- POST /api/v1/auth/register-teacher accepts a missing/null username.
- Username uniqueness is still enforced when one is supplied.
- The teachers.username column is preserved (backward compatibility).
"""

import pytest
from httpx import AsyncClient
from sqlalchemy import inspect, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.db.models.school import Teacher


def _token(sub: str, email: str) -> dict:
    token = create_access_token({"sub": sub, "email": email, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


def _rtoken(sub: str, email: str) -> dict:
    """Auth headers for register-teacher: JWT sub must equal the body user_id."""
    return _token(sub, email)


@pytest.mark.asyncio
async def test_me_resolves_teacher_by_authenticated_user_id(
    client: AsyncClient, db_session: AsyncSession
):
    db_session.add(
        Teacher(
            user_id="email-auth-uid-1",
            username="email_auth_01",
            name="Email Teacher",
            email="email.auth.01@school.edu.in",
            designation="Primary Teacher",
            is_active=True,
        )
    )
    await db_session.commit()

    resp = await client.get(
        "/api/v1/me", headers=_token("email-auth-uid-1", "email.auth.01@school.edu.in")
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["user_id"] == "email-auth-uid-1"
    assert data["teacher_name"] == "Email Teacher"
    assert data["role"] == "teacher"


@pytest.mark.asyncio
async def test_me_falls_back_to_email_match(
    client: AsyncClient, db_session: AsyncSession
):
    db_session.add(
        Teacher(
            user_id="some-other-uid",
            name="Fallback Teacher",
            email="fallback.match@school.edu.in",
            designation="Primary Teacher",
            is_active=True,
        )
    )
    await db_session.commit()

    resp = await client.get(
        "/api/v1/me", headers=_token("fresh-supabase-uid", "fallback.match@school.edu.in")
    )
    assert resp.status_code == 200
    assert resp.json()["teacher_name"] == "Fallback Teacher"


@pytest.mark.asyncio
async def test_me_missing_profile_returns_404(client: AsyncClient):
    resp = await client.get(
        "/api/v1/me",
        headers=_token("ghost-uid-404", "ghost.teacher@school.edu.in"),
    )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_me_without_token_returns_401(client: AsyncClient):
    assert (await client.get("/api/v1/me")).status_code == 401


@pytest.mark.asyncio
async def test_register_teacher_accepts_null_username(
    client: AsyncClient, db_session: AsyncSession
):
    resp = await client.post(
        "/api/v1/auth/register-teacher",
        json={
            "user_id": "email-only-uid-1",
            "username": None,
            "name": "Email Only",
            "email": "email.only@school.edu.in",
        },
        headers=_rtoken("email-only-uid-1", "email.only@school.edu.in"),
    )
    assert resp.status_code == 200
    assert resp.json()["username"] is None

    row = (
        await db_session.execute(
            select(Teacher).where(Teacher.user_id == "email-only-uid-1")
        )
    ).scalar_one()
    assert row.username is None
    assert row.email == "email.only@school.edu.in"


@pytest.mark.asyncio
async def test_register_teacher_accepts_missing_username_key(client: AsyncClient):
    resp = await client.post(
        "/api/v1/auth/register-teacher",
        json={
            "user_id": "email-only-uid-2",
            "name": "Email Only Two",
            "email": "email.only.2@school.edu.in",
        },
        headers=_rtoken("email-only-uid-2", "email.only.2@school.edu.in"),
    )
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_register_teacher_still_requires_identity_fields(client: AsyncClient):
    resp = await client.post(
        "/api/v1/auth/register-teacher",
        json={"user_id": "x", "name": "No Email"},
        headers=_rtoken("x", "x@school.edu.in"),
    )
    assert resp.status_code in (400, 422)


@pytest.mark.asyncio
async def test_null_usernames_never_conflict(client: AsyncClient):
    for uid in ("null-uname-a", "null-uname-b"):
        resp = await client.post(
            "/api/v1/auth/register-teacher",
            json={
                "user_id": uid,
                "username": None,
                "name": f"Null {uid}",
                "email": f"{uid}@school.edu.in",
            },
            headers=_rtoken(uid, f"{uid}@school.edu.in"),
        )
        assert resp.status_code == 200


@pytest.mark.asyncio
async def test_supplied_duplicate_username_still_rejected(client: AsyncClient):
    first = await client.post(
        "/api/v1/auth/register-teacher",
        json={
            "user_id": "dup-email-uid-1",
            "username": "email_dup_code",
            "name": "Dup One",
            "email": "dup.one@school.edu.in",
        },
        headers=_rtoken("dup-email-uid-1", "dup.one@school.edu.in"),
    )
    assert first.status_code == 200

    dup = await client.post(
        "/api/v1/auth/register-teacher",
        json={
            "user_id": "dup-email-uid-2",
            "username": "EMAIL_DUP_CODE",
            "name": "Dup Two",
            "email": "dup.two@school.edu.in",
        },
        headers=_rtoken("dup-email-uid-2", "dup.two@school.edu.in"),
    )
    assert dup.status_code == 409


@pytest.mark.asyncio
async def test_username_column_preserved_for_existing_rows(
    client: AsyncClient, db_session: AsyncSession
):
    cols = {c.name for c in inspect(Teacher).columns}
    assert "username" in cols

    # Re-registering without a username must not wipe the stored one.
    db_session.add(
        Teacher(
            user_id="preserve-uid-1",
            username="keep_me",
            name="Keep Teacher",
            email="keep.me@school.edu.in",
            designation="Primary Teacher",
            is_active=True,
        )
    )
    await db_session.commit()

    resp = await client.post(
        "/api/v1/auth/register-teacher",
        json={
            "user_id": "preserve-uid-1",
            "username": None,
            "name": "Keep Teacher Updated",
            "email": "keep.me@school.edu.in",
        },
        headers=_rtoken("preserve-uid-1", "keep.me@school.edu.in"),
    )
    assert resp.status_code == 200
    assert resp.json()["username"] == "keep_me"
    assert resp.json()["teacher_name"] == "Keep Teacher Updated"
