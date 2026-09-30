import requests
import json

BASE_URL = "http://127.0.0.1:8000"

# Step 1 & 2: Obtain token
dev_res = requests.post(
    f"{BASE_URL}/api/v1/auth/dev-token",
    json={
        "user_id": "00000000-0000-0000-0000-000000000001",
        "role": "teacher",
        "email": "teacher@test.com",
    },
)
token = dev_res.json().get("access_token") if dev_res.status_code == 200 else None
auth_mode = "dev (fallback) / supabase (production)"
token_present = token is not None and len(token) > 0

headers = {"Authorization": f"Bearer {token}"} if token_present else {}

# Step 3 & 4: Call GET /api/v1/me
me_res = requests.get(f"{BASE_URL}/api/v1/me", headers=headers)
me_status = me_res.status_code
me_data = me_res.json() if me_res.headers.get("content-type", "").startswith("application/json") else {}

user_id = me_data.get("user_id") or me_data.get("id") or me_data.get("email")
authenticated = (me_status == 200)

# Step 5: Intercept/inspect POST /api/v1/worksheets/generate
payload = {
    "content_type": "worksheet",
    "grade": 2,
    "subject": "Mathematics",
    "target_language": "sat",
    "difficulty": "medium",
    "question_count": 3
}

ws_res = requests.post(f"{BASE_URL}/api/v1/worksheets/generate", headers=headers, json=payload)
ws_status = ws_res.status_code
ws_body = ws_res.json() if ws_res.headers.get("content-type", "").startswith("application/json") else ws_res.text

# Sanitize response body if needed
if isinstance(ws_body, dict):
    sanitized_ws_body = {k: v for k, v in ws_body.items() if "token" not in k.lower()}
else:
    sanitized_ws_body = ws_body

print(f"DIAG_AUTH_MODE={auth_mode}")
print(f"DIAG_AUTHENTICATED={authenticated}")
print(f"DIAG_USER_ID={user_id}")
print(f"DIAG_TOKEN_PRESENT={token_present}")
print(f"DIAG_GET_ME_STATUS={me_status}")
print(f"DIAG_GET_ME_BODY={me_data}")
print(f"DIAG_WS_STATUS={ws_status}")
print(f"DIAG_WS_BODY={json.dumps(sanitized_ws_body)}")
