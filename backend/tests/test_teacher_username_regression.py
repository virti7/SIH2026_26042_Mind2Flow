"""Regression tests for the teachers.username reconciliation.

Covers:
- ORM model exposes a nullable username matching the real Supabase schema
- existing teacher with NULL username -> /me still works (no invented values)
- new username -> registration works
- duplicate username (case/whitespace variants) -> rejected cleanly
- check-username normalization is case-insensitive
"""
import pytest
from httpx import AsyncClient
from sqlalchemy import inspect, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.db.models.school import Teacher


def test_teacher_username_column_present_and_nullable():
    """Guards against `column teachers.username does not exist` regressions."""
    cols = {c.name: c for c in inspect(Teacher).columns}
    assert "username" in cols, "Teacher model must expose username"
    assert cols["username"].nullable is True, (
        "username must stay nullable for legacy rows"
    )
    # Real Supabase schema is VARCHAR(255).
    assert getattr(cols["username"].type, "length", None) == 255


def _reg_headers(sub: str, email: str) -> dict:
    """register-teacher requires a JWT whose sub equals the body user_id."""
    token = create_access_token({"sub": sub, "email": email, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


def test_teacher_username_has_no_column_level_unique_constraint():
    """Uniqueness comes from uq_teachers_username_lower, not a plain UNIQUE.

    A column-level unique=True would recreate ix_teachers_username on fresh
    deployments, diverging from the real DB's partial functional index and
    enforcing case-sensitive uniqueness instead of case-insensitive.
    """
    cols = {c.name: c for c in inspect(Teacher).columns}
    assert cols["username"].unique is not True


@pytest.mark.asyncio
async def test_me_works_for_legacy_teacher_with_null_username(
    client: AsyncClient, db_session: AsyncSession
):
    """Existing teachers with NULL username must not break /me."""
    t = Teacher(
        user_id="legacy-teacher-uuid-null-001",
        username=None,
        name="Legacy Teacher",
        email="legacy.null.username@school.edu.in",
        designation="Primary Teacher",
        preferred_language="Hindi",
        is_active=True,
    )
    db_session.add(t)
    await db_session.commit()

    token = create_access_token(
        {
            "sub": "legacy-teacher-uuid-null-001",
            "email": "legacy.null.username@school.edu.in",
            "role": "teacher",
        }
    )
    resp = await client.get(
        "/api/v1/me", headers={"Authorization": f"Bearer {token}"}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["user_id"] == "legacy-teacher-uuid-null-001"
    assert data["username"] is None
    assert data["teacher_name"] == "Legacy Teacher"

    # The legacy row must be untouched: username still NULL, never invented.
    row = (
        await db_session.execute(
            select(Teacher).where(
                Teacher.user_id == "legacy-teacher-uuid-null-001"
            )
        )
    ).scalar_one()
    assert row.username is None


@pytest.mark.asyncio
async def test_register_new_username_then_duplicate_rejected(
    client: AsyncClient, db_session: AsyncSession
):
    """New username registers; exact/case/whitespace duplicates get 409."""
    payload = {
        "user_id": "regression-new-teacher-001",
        "username": "regression_code_01",
        "name": "Regression Teacher",
        "email": "regression.code.01@school.edu.in",
    }
    resp = await client.post(
        "/api/v1/auth/register-teacher",
        json=payload,
        headers=_reg_headers(
            "regression-new-teacher-001", "regression.code.01@school.edu.in"
        ),
    )
    assert resp.status_code == 200
    assert resp.json()["username"] == "regression_code_01"

    for dup_username in (
        "regression_code_01",
        "Regression_Code_01",
        "  REGRESSION_CODE_01  ",
    ):
        dup_uid = f"regression-other-{dup_username.strip().lower()}"
        dup_email = f"other.{dup_username.strip().lower()}@school.edu.in"
        dup = await client.post(
            "/api/v1/auth/register-teacher",
            json={
                "user_id": dup_uid,
                "username": dup_username,
                "name": "Other Teacher",
                "email": dup_email,
            },
            headers=_reg_headers(dup_uid, dup_email),
        )
        assert dup.status_code == 409, dup_username
        assert "already registered" in dup.json()["detail"]


@pytest.mark.asyncio
async def test_check_username_is_case_insensitive(
    client: AsyncClient, db_session: AsyncSession
):
    """check-username must normalize trim + case like the DB index."""
    db_session.add(
        Teacher(
            user_id="regression-taken-uuid-001",
            username="mixedcase_code",
            name="Taken Teacher",
            email="taken.mixedcase@school.edu.in",
        )
    )
    await db_session.commit()

    for variant in ("mixedcase_code", "MixedCase_Code", "  MIXEDCASE_CODE "):
        r = await client.post(
            "/api/v1/auth/check-username", json={"username": variant}
        )
        assert r.status_code == 200
        assert r.json()["available"] is False, variant

    r_free = await client.post(
        "/api/v1/auth/check-username",
        json={"username": "regression_brand_new_code"},
    )
    assert r_free.status_code == 200
    assert r_free.json()["available"] is True
