import urllib.request
import json
import os

SUPABASE_URL = "https://zowjbmjehuyfwjjcgzqo.supabase.co"
# The anon key passed in flutter run
ANON_KEY = "sb_publishable_eW_HNMFz8WtMagIq5AaBcQ_-TON41z2"

headers = {
    "apikey": ANON_KEY,
    "Authorization": f"Bearer {ANON_KEY}",
    "Content-Type": "application/json"
}

body = json.dumps({
    "email": "teacher@test.com",
    "password": "Test@12345"
}).encode("utf-8")

req = urllib.request.Request(
    f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
    data=body,
    headers=headers,
    method="POST"
)

try:
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        token = data.get("access_token")
        user = data.get("user", {})
        print("REAL_SUPABASE_LOGIN_STATUS=SUCCESS")
        print(f"USER_ID={user.get('id')}")
        print(f"EMAIL={user.get('email')}")
        print(f"TOKEN_PRESENT={token is not None and len(token) > 0}")
        # Test token against FastAPI backend
        fastapi_req = urllib.request.Request(
            "http://127.0.0.1:8000/api/v1/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        with urllib.request.urlopen(fastapi_req) as f_resp:
            f_data = json.loads(f_resp.read().decode("utf-8"))
            print("FASTAPI_GET_ME_STATUS=200")
            print(f"FASTAPI_USER_ROLE={f_data.get('role')}")
            print(f"FASTAPI_USER_ID={f_data.get('user_id')}")

        # Test POST /api/v1/worksheets/generate
        ws_body = json.dumps({
            "content_type": "worksheet",
            "grade": 1,
            "subject": "Mathematics",
            "target_language": "sat",
            "difficulty": "medium",
            "question_count": 3
        }).encode("utf-8")
        ws_req = urllib.request.Request(
            "http://127.0.0.1:8000/api/v1/worksheets/generate",
            data=ws_body,
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(ws_req) as ws_resp:
            ws_data = json.loads(ws_resp.read().decode("utf-8"))
            print(f"FASTAPI_WORKSHEET_STATUS={ws_resp.status}")
            print(f"FASTAPI_WORKSHEET_JOB_ID={ws_data.get('job_id')}")

        # Test POST /api/v1/flashcards/generate
        fc_body = json.dumps({
            "content_type": "flashcard",
            "grade": 1,
            "subject": "Mathematics",
            "target_language": "sat",
            "difficulty": "medium",
            "question_count": 3
        }).encode("utf-8")
        fc_req = urllib.request.Request(
            "http://127.0.0.1:8000/api/v1/flashcards/generate",
            data=fc_body,
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(fc_req) as fc_resp:
            fc_data = json.loads(fc_resp.read().decode("utf-8"))
            print(f"FASTAPI_FLASHCARD_STATUS={fc_resp.status}")
            print(f"FASTAPI_FLASHCARD_JOB_ID={fc_data.get('job_id')}")

except urllib.error.HTTPError as e:
    print(f"HTTP_ERROR={e.code}")
    print(f"ERROR_BODY={e.read().decode('utf-8')}")
except Exception as e:
    print(f"ERROR={e}")
