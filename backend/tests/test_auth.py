import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_auth_me_valid_token(client: AsyncClient, teacher_auth_headers: dict):
    response = await client.get("/api/v1/auth/me", headers=teacher_auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["user_id"] == "teacher-user-uuid-1"
    assert data["role"] == "teacher"
    assert data["email"] == "teacher1@jharkhand.edu.in"


@pytest.mark.asyncio
async def test_auth_missing_token(client: AsyncClient):
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 401
    assert "detail" in response.json()


@pytest.mark.asyncio
async def test_auth_invalid_token(client: AsyncClient):
    response = await client.get("/api/v1/auth/me", headers={"Authorization": "Bearer invalid.jwt.token"})
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_admin_role_authorization(client: AsyncClient, teacher_auth_headers: dict, admin_auth_headers: dict):
    # Teacher trying to create a school -> 403 Forbidden
    school_payload = {"name": "Govt Primary School Ranchi", "code": "GPS-RAN-001"}
    resp_teacher = await client.post("/api/v1/schools", json=school_payload, headers=teacher_auth_headers)
    assert resp_teacher.status_code == 403

    # Admin creating a school -> 200 OK
    resp_admin = await client.post("/api/v1/schools", json=school_payload, headers=admin_auth_headers)
    assert resp_admin.status_code == 200
    assert resp_admin.json()["name"] == "Govt Primary School Ranchi"
