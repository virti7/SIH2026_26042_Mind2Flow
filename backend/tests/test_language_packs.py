import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_language_pack_manifest_and_version_check(
    client: AsyncClient,
    admin_auth_headers: dict,
):
    # 1. Admin publishes Ho language pack v1.2.0
    pack_payload = {
        "language_code": "ho",
        "version": "1.2.0",
        "model_version": "1.1.0",
        "content_version": "1.2.0",
        "package_size": 25000000,
        "checksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        "download_url": "/api/v1/storage/download/language-packs/ho/v1.2.0.zip",
        "release_status": "RELEASED",
        "compatible_app_version": ">=1.0.0",
        "min_android_version": 24,
    }
    create_resp = await client.post("/api/v1/language-packs", json=pack_payload, headers=admin_auth_headers)
    assert create_resp.status_code == 200
    assert create_resp.json()["version"] == "1.2.0"

    # 2. Device checks manifest without downloading heavy archive
    manifest_resp = await client.get("/api/v1/language-packs/ho/manifest")
    assert manifest_resp.status_code == 200
    manifest = manifest_resp.json()
    assert manifest["version"] == "1.2.0"
    assert manifest["package_size_bytes"] == 25000000
    assert "checksum_sha256" in manifest
    assert "assets" in manifest

    # 3. Device version check: client has older version 1.1.0 -> update_available == True
    check_resp = await client.get("/api/v1/language-packs/ho/version?client_version=1.1.0")
    assert check_resp.status_code == 200
    assert check_resp.json()["update_available"] is True
    assert check_resp.json()["current_server_version"] == "1.2.0"

    # 4. Device version check: client already has 1.2.0 -> update_available == False
    check_same = await client.get("/api/v1/language-packs/ho/version?client_version=1.2.0")
    assert check_same.status_code == 200
    assert check_same.json()["update_available"] is False


@pytest.mark.asyncio
async def test_model_version_management(
    client: AsyncClient,
    admin_auth_headers: dict,
):
    model_payload = {
        "model_name": "nipun-nmt-santali-int8",
        "model_type": "nmt",
        "language_code": "sat",
        "version": "1.0.0",
        "checksum": "abc123sha256...",
        "size_bytes": 15000000,
        "download_url": "/api/v1/storage/download/models/nmt/santali.onnx",
        "compatibility": "onnx-runtime-1.16",
        "release_status": "RELEASED",
    }
    create_resp = await client.post("/api/v1/model-versions", json=model_payload, headers=admin_auth_headers)
    assert create_resp.status_code == 200
    assert create_resp.json()["model_name"] == model_payload["model_name"]

    list_resp = await client.get("/api/v1/model-versions?model_type=nmt")
    assert list_resp.status_code == 200
    assert len(list_resp.json()) >= 1
