import asyncio
import os
import sys
import httpx

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.security import create_access_token

async def test_auth():
    teacher_token = create_access_token({
        "sub": "user_teacher_99",
        "email": "teacher99@jharkhand.edu.in",
        "role": "teacher"
    })

    admin_token = create_access_token({
        "sub": "user_admin_01",
        "email": "admin@jharkhand.edu.in",
        "role": "admin"
    })

    async with httpx.AsyncClient(base_url="http://127.0.0.1:8000") as client:
        # Case 1: No token on protected endpoint -> 401
        r_no_token = await client.get("/api/v1/auth/me")
        print(f"1. No token -> status={r_no_token.status_code}")
        assert r_no_token.status_code == 401, f"Expected 401, got {r_no_token.status_code}"

        # Case 2: Invalid token -> 401
        r_inv_token = await client.get("/api/v1/auth/me", headers={"Authorization": "Bearer totally_bogus_token"})
        print(f"2. Invalid token -> status={r_inv_token.status_code}")
        assert r_inv_token.status_code == 401, f"Expected 401, got {r_inv_token.status_code}"

        # Case 3: Valid Teacher Token on /auth/me -> 200 with matching user_id
        r_teacher = await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {teacher_token}"})
        print(f"3. Teacher token -> status={r_teacher.status_code}")
        assert r_teacher.status_code == 200, f"Expected 200, got {r_teacher.status_code}"
        data = r_teacher.json()
        assert data["user_id"] == "user_teacher_99"
        assert data["role"] == "teacher"
        print(f"   Teacher identity confirmed: user_id={data['user_id']}, role={data['role']}")

        # Case 4: Non-admin trying to access Admin endpoint -> 403 Forbidden
        r_teacher_admin = await client.post(
            "/api/v1/admin/publish-pack",
            json={"pack_id": "dummy_pack", "release_status": "RELEASED"},
            headers={"Authorization": f"Bearer {teacher_token}"}
        )
        print(f"4. Teacher accessing admin endpoint -> status={r_teacher_admin.status_code}")
        assert r_teacher_admin.status_code == 403, f"Expected 403, got {r_teacher_admin.status_code}"

        # Case 5: Admin accessing Admin endpoint -> Non-403 (either 404 for dummy pack or 200)
        r_admin = await client.post(
            "/api/v1/admin/publish-pack",
            json={"pack_id": "dummy_pack", "release_status": "RELEASED"},
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        print(f"5. Admin accessing admin endpoint -> status={r_admin.status_code}")
        assert r_admin.status_code in (200, 404), f"Expected 200 or 404 (authorized), got {r_admin.status_code}"
        assert r_admin.status_code != 403, "Admin was rejected with 403"

        print(">>> REAL AUTHENTICATION & ROLE-BASED ACCESS CONTROL VERIFIED <<<")

if __name__ == "__main__":
    asyncio.run(test_auth())
