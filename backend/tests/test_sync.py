import uuid
from datetime import datetime, timezone
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_offline_sync_lifecycle_and_idempotency(
    client: AsyncClient,
    teacher_auth_headers: dict,
):
    """
    Validates the end-to-end sync contract:
    - Offline-created assessment result is packaged into a SyncOperationItem
    - FastAPI processes it and writes to database
    - A repeated upload of the same operation ID returns DUPLICATE_IGNORED without duplicating
    """
    op_id = f"op-{uuid.uuid4()}"
    client_local_id = f"local-res-{uuid.uuid4()}"

    batch_payload = {
        "device_id": "tablet-jharkhand-042",
        "app_version": "1.0.0",
        "android_version": "13",
        "operations": [
            {
                "operation_id": op_id,
                "entity_type": "assessment_result",
                "entity_id": client_local_id,
                "operation": "CREATE",
                "payload": {
                    "student_name": "Sanatan Hembram",
                    "student_id": "STU_HO_09",
                    "score": 9.0,
                    "max_score": 10.0,
                    "status": "Achieved",
                },
                "client_updated_at": datetime.now(timezone.utc).isoformat(),
            }
        ],
    }

    # First upload -> Success
    res1 = await client.post("/api/v1/sync/upload", json=batch_payload, headers=teacher_auth_headers)
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["successful_count"] == 1
    assert data1["failed_count"] == 0
    assert len(data1["results"]) == 1
    assert data1["results"][0]["operation_id"] == op_id
    assert data1["results"][0]["status"] == "SUCCESS"
    remote_id = data1["results"][0]["remote_id"]
    assert remote_id is not None

    # Repeated upload (retry/network replay with same operation_id) -> Idempotent DUPLICATE_IGNORED
    res2 = await client.post("/api/v1/sync/upload", json=batch_payload, headers=teacher_auth_headers)
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2["successful_count"] == 1
    assert data2["results"][0]["status"] == "DUPLICATE_IGNORED"
    assert data2["results"][0]["remote_id"] == remote_id


@pytest.mark.asyncio
async def test_sync_partial_batch_failure(
    client: AsyncClient,
    teacher_auth_headers: dict,
):
    """
    Validates that a batch with one valid and one invalid operation succeeds partially
    without failing the entire batch, giving per-operation feedback.
    """
    valid_op_id = f"op-valid-{uuid.uuid4()}"
    invalid_op_id = f"op-invalid-{uuid.uuid4()}"

    batch_payload = {
        "device_id": "tablet-jharkhand-042",
        "operations": [
            {
                "operation_id": valid_op_id,
                "entity_type": "saved_material",
                "entity_id": "mat-local-1",
                "operation": "CREATE",
                "payload": {"title": "Animal Matching Flashcards", "material_type": "flashcard"},
            },
            {
                "operation_id": invalid_op_id,
                "entity_type": "unsupported_unknown_entity_type",
                "entity_id": "unknown-1",
                "operation": "CREATE",
                "payload": {},
            },
        ],
    }

    resp = await client.post("/api/v1/sync/upload", json=batch_payload, headers=teacher_auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_operations"] == 2
    assert data["successful_count"] == 1
    assert data["failed_count"] == 1

    results_by_id = {r["operation_id"]: r for r in data["results"]}
    assert results_by_id[valid_op_id]["status"] == "SUCCESS"
    assert results_by_id[invalid_op_id]["status"] == "FAILED"
    assert "Unsupported entity type" in results_by_id[invalid_op_id]["error"]


@pytest.mark.asyncio
async def test_sync_manifest_and_updates(client: AsyncClient):
    # Manifest
    manifest_resp = await client.get("/api/v1/sync/manifest")
    assert manifest_resp.status_code == 200
    assert "language_packs" in manifest_resp.json()

    # Updates since
    updates_resp = await client.get("/api/v1/sync/updates")
    assert updates_resp.status_code == 200
    assert "lessons" in updates_resp.json()
