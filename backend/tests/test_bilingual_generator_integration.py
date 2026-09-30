import json
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_backend_can_invoke_generator_valid_result(
    client: AsyncClient,
    teacher_auth_headers: dict,
):
    """Scenario 1 & 2: Backend can invoke generator and receive structured content."""
    req = {
        "blueprint_id": "BP-G1-NUM-032-01",
        "content_type": "worksheet",
        "target_language": "sat",
        "mock_mode": True,
        "force": True,
    }
    resp = await client.post("/api/v1/ai/generate", json=req, headers=teacher_auth_headers)
    assert resp.status_code == 201, f"Expected 201, got {resp.status_code}: {resp.text}"

    data = resp.json()
    assert data["status"] == "GENERATED"
    assert data["content_type"] == "worksheet"
    assert "raw_output" in data
    raw = data["raw_output"]
    assert raw["content_id"] == "GC-G1-NUM-032-01-bi-v1"
    assert raw["blueprint_id"] == "BP-G1-NUM-032-01"
    assert raw["grade"] == 1
    assert "items" in raw
    assert len(raw["items"]) > 0

    # Verify content can be queried by ID
    get_resp = await client.get(f"/api/v1/ai/content/{data['id']}", headers=teacher_auth_headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["id"] == data["id"]


@pytest.mark.asyncio
async def test_invalid_generation_is_rejected(
    client: AsyncClient,
    teacher_auth_headers: dict,
):
    """Scenario 3: Invalid generation requests (e.g. unknown blueprint) are rejected."""
    req = {
        "blueprint_id": "BP-INVALID-UNKNOWN-999",
        "mock_mode": True,
    }
    resp = await client.post("/api/v1/ai/generate", json=req, headers=teacher_auth_headers)
    assert resp.status_code == 400, f"Expected 400, got {resp.status_code}: {resp.text}"
    err = resp.json()
    assert err["code"] == "BAD_REQUEST"


@pytest.mark.asyncio
async def test_review_gates_retrieval_and_enforcement(
    client: AsyncClient,
    reviewer_auth_headers: dict,
):
    """Scenario 4: Review gates remain enforced and can be inspected/updated."""
    content_id = "GC-G1-NUM-032-01-bi-v1"

    # 1. Fetch review record
    resp = await client.get(f"/api/v1/ai/content/{content_id}/review", headers=reviewer_auth_headers)
    assert resp.status_code == 200
    record = resp.json()
    assert "review_status" in record or "status" in record
    if "gates" in record:
        assert "hindi" in record["gates"]
        assert "santali" in record["gates"]
        assert "curriculum" in record["gates"]
        assert "answer_key" in record["gates"]

    # 2. Update a review gate note
    update_req = {
        "notes": "Reviewed mathematical accuracy and Ol Chiki rendering",
    }
    up_resp = await client.post(
        f"/api/v1/ai/content/{content_id}/review",
        json=update_req,
        headers=reviewer_auth_headers,
    )
    assert up_resp.status_code == 200


@pytest.mark.asyncio
async def test_unapproved_content_cannot_publish(
    client: AsyncClient,
    reviewer_auth_headers: dict,
):
    """Scenario 5: Backend MUST NOT publish unapproved content."""
    # Temporarily set review status to 'in_review' / pending gates
    content_id = "GC-G1-NUM-032-01-bi-v1"
    await client.post(
        f"/api/v1/ai/content/{content_id}/review",
        json={"status": "in_review", "gates": {"hindi": "pending"}},
        headers=reviewer_auth_headers,
    )

    # Attempt to publish unapproved content
    pub_resp = await client.post(
        f"/api/v1/ai/content/{content_id}/publish",
        json={"dry_run": False},
        headers=reviewer_auth_headers,
    )
    assert pub_resp.status_code == 400, f"Expected 400, got {pub_resp.status_code}: {pub_resp.text}"
    assert "rejected" in pub_resp.json()["detail"].lower() or "unapproved" in pub_resp.json()["detail"].lower()


@pytest.mark.asyncio
async def test_approved_worksheet_persistence_storage_paths_and_idempotency(
    client: AsyncClient,
    reviewer_auth_headers: dict,
    teacher_auth_headers: dict,
):
    """Scenario 6, 7, 8 & 9: Approved worksheet persistence, deterministic storage paths, and idempotency."""
    content_id = "GC-G1-NUM-032-01-bi-v1"

    # 1. Approve all gates
    approve_req = {
        "status": "approved",
        "gates": {
            "hindi": "pass",
            "santali": "pass",
            "curriculum": "pass",
            "answer_key": "pass",
            "provisional_range": "pass",
        },
        "santali_script_confirmed": "Olck",
        "notes": "All review gates passed by authorized reviewer.",
    }
    app_resp = await client.post(
        f"/api/v1/ai/content/{content_id}/review",
        json=approve_req,
        headers=reviewer_auth_headers,
    )
    assert app_resp.status_code == 200

    # 2. Publish worksheet
    pub_resp = await client.post(
        f"/api/v1/ai/content/{content_id}/publish",
        json={"dry_run": False, "publish_to_catalog": True},
        headers=reviewer_auth_headers,
    )
    assert pub_resp.status_code == 200
    pub_data = pub_resp.json()
    assert pub_data["status"] in ("published", "already_published")
    assert pub_data["content_type"] == "worksheet"
    assert "entity_id" in pub_data["record_ids"]
    assert "generated_content_id" in pub_data["record_ids"]
    assert len(pub_data["storage_paths"]) > 0
    storage_path = pub_data["storage_paths"][0]
    # Check deterministic storage path: worksheets/{grade}/{curriculum_id}/{content_id}.json
    assert storage_path.startswith("worksheets/1/G1-NUM-032/")
    assert storage_path.endswith(".json")

    # 3. Check worksheet was cataloged in DB
    ws_resp = await client.get("/api/v1/worksheets", headers=teacher_auth_headers)
    assert ws_resp.status_code == 200
    worksheets = ws_resp.json()
    assert any(w["id"] == content_id for w in worksheets)

    # 4. Duplicate publication must be idempotent
    dup_resp = await client.post(
        f"/api/v1/ai/content/{content_id}/publish",
        json={"dry_run": False, "publish_to_catalog": True},
        headers=reviewer_auth_headers,
    )
    assert dup_resp.status_code == 200
    dup_data = dup_resp.json()
    assert dup_data["status"] == "already_published"
    assert dup_data["record_ids"]["generated_content_id"] == pub_data["record_ids"]["generated_content_id"]


@pytest.mark.asyncio
async def test_credentials_are_never_exposed(
    client: AsyncClient,
    teacher_auth_headers: dict,
    reviewer_auth_headers: dict,
):
    """Scenario 10: Secrets and API keys are never exposed in any API response."""
    content_id = "GC-G1-NUM-032-01-bi-v1"

    # Test generation response
    gen_resp = await client.post(
        "/api/v1/ai/generate",
        json={"blueprint_id": "BP-G1-NUM-032-01", "mock_mode": True, "force": True},
        headers=teacher_auth_headers,
    )
    text = gen_resp.text
    assert "GEMINI_API_KEY" not in text
    assert "service_role" not in text.lower()
    assert "dummy-service-role-key" not in text

    # Test review response
    rev_resp = await client.get(f"/api/v1/ai/content/{content_id}/review", headers=reviewer_auth_headers)
    text = rev_resp.text
    assert "GEMINI_API_KEY" not in text
    assert "dummy-service-role-key" not in text

    # Test publish response
    pub_resp = await client.post(
        f"/api/v1/ai/content/{content_id}/publish",
        json={"dry_run": True},
        headers=reviewer_auth_headers,
    )
    text = pub_resp.text
    assert "GEMINI_API_KEY" not in text
    assert "SARVAM_API_KEY" not in text
    assert "dummy-service-role-key" not in text


def test_bilingual_generator_service_sarvam_provider_resolution(monkeypatch):
    """Scenario 11: BilingualGeneratorService resolves SarvamProvider when configured."""
    from app.services.bilingual_generator import bilingual_generator_service
    from providers.sarvam import SarvamProvider

    # When SARVAM_API_KEY is missing, raises RuntimeError
    monkeypatch.delenv("SARVAM_API_KEY", raising=False)
    with pytest.raises(RuntimeError) as exc:
        bilingual_generator_service.get_provider("sarvam")
    assert "SARVAM_API_KEY" in str(exc.value)

    # When SARVAM_API_KEY is configured, resolves SarvamProvider
    monkeypatch.setenv("SARVAM_API_KEY", "dummy-sarvam-key-for-test")
    provider = bilingual_generator_service.get_provider("sarvam")
    assert isinstance(provider, SarvamProvider)
    assert provider.model == "sarvam-105b"
