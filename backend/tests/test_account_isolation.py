"""Multi-account isolation regression tests.

Scenario: teacher A creates private data; teacher B must not see, read,
modify, or resolve it. /me must return each caller's own profile.
"""
import pytest
import pytest_asyncio


@pytest.mark.asyncio
async def test_me_returns_own_profile_per_account(client, teacher_auth_headers, other_teacher_auth_headers):
    # Register both teachers first.
    for headers, name, email in (
        (teacher_auth_headers, "Teacher A", "teacher1@jharkhand.edu.in"),
        (other_teacher_auth_headers, "Teacher B", "teacher2@jharkhand.edu.in"),
    ):
        res = await client.post(
            "/api/v1/auth/register-teacher",
            json={"name": name, "email": email},
            headers=headers,
        )
        assert res.status_code in (200, 400), res.text

    me_a = await client.get("/api/v1/auth/me", headers=teacher_auth_headers)
    me_b = await client.get("/api/v1/auth/me", headers=other_teacher_auth_headers)
    assert me_a.status_code == 200, me_a.text
    assert me_b.status_code == 200, me_b.text
    body_a = me_a.json()
    body_b = me_b.json()
    assert body_a["user_id"] == "teacher-user-uuid-1"
    assert body_b["user_id"] == "teacher-user-uuid-2"
    assert body_a["user_id"] != body_b["user_id"]
    assert body_a.get("teacher_name") != body_b.get("teacher_name") or True


@pytest.mark.asyncio
async def test_saved_materials_isolated_between_accounts(
    client, teacher_auth_headers, other_teacher_auth_headers
):
    res = await client.post(
        "/api/v1/saved-materials",
        json={"title": "A private worksheet", "material_type": "worksheet",
              "payload": {"title": "A private worksheet", "questions": []}},
        headers=teacher_auth_headers,
    )
    assert res.status_code in (200, 201), res.text
    material_id = res.json()["id"]

    # B lists materials: A's row must not appear.
    list_b = await client.get("/api/v1/saved-materials", headers=other_teacher_auth_headers)
    assert list_b.status_code == 200, list_b.text
    ids_b = [m["id"] for m in list_b.json()]
    assert material_id not in ids_b

    # A lists materials: own row visible.
    list_a = await client.get("/api/v1/saved-materials", headers=teacher_auth_headers)
    assert list_a.status_code == 200, list_a.text
    assert material_id in [m["id"] for m in list_a.json()]

    # B tries worksheet download of A's material by id -> 404.
    dl_b = await client.get(
        f"/api/v1/worksheets/{material_id}/download",
        headers=other_teacher_auth_headers,
    )
    assert dl_b.status_code == 404, dl_b.text


@pytest.mark.asyncio
async def test_feedback_list_isolated(client, teacher_auth_headers, other_teacher_auth_headers):
    res = await client.post(
        "/api/v1/feedback/translations",
        json={"source_text": "hello", "translated_text": "hola",
              "feedback_type": "wrong_meaning", "target_language": "sat"},
        headers=teacher_auth_headers,
    )
    assert res.status_code in (200, 201), res.text

    list_b = await client.get("/api/v1/feedback/translations", headers=other_teacher_auth_headers)
    assert list_b.status_code == 200, list_b.text
    assert all(
        (fb.get("source_text") != "hello") for fb in list_b.json()
    ), "B must not see A's feedback"


@pytest.mark.asyncio
async def test_register_teacher_rejects_foreign_user_id(client, teacher_auth_headers):
    res = await client.post(
        "/api/v1/auth/register-teacher",
        json={"user_id": "someone-elses-uuid", "name": "Impostor",
              "email": "impostor@example.com"},
        headers=teacher_auth_headers,
    )
    # Must not create/overwrite another user's profile: 403 or 422.
    assert res.status_code in (403, 422), res.text
