import asyncio
import os
import sys
import uuid
import httpx

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from app.db.session import engine

async def test_advanced_sync():
    base_url = "http://127.0.0.1:8000"
    
    # -------------------------------------------------------------
    # 1. IDEMPOTENCY TEST
    # -------------------------------------------------------------
    test_op_id = f"test_idemp_{uuid.uuid4().hex[:12]}"
    test_res_id = f"res_idemp_{uuid.uuid4().hex[:12]}"
    
    payload = {
        "device_id": "test_device_adv_001",
        "app_version": "1.0.0",
        "operations": [
            {
                "operation_id": test_op_id,
                "entity_type": "assessment_result",
                "entity_id": test_res_id,
                "operation": "CREATE",
                "client_timestamp": "2026-09-19T02:00:00Z",
                "payload": {
                    "id": test_res_id,
                    "student_id": "std_idemp_001",
                    "student_name": "Sita Munda",
                    "outcome_code": "H1.2.3",
                    "score": 5.0,
                    "max_score": 5.0,
                    "status": "Achieved",
                    "grade": 1,
                    "subject": "Hindi"
                }
            }
        ]
    }
    
    async with httpx.AsyncClient(base_url=base_url) as client:
        # First send -> SUCCESS
        r1 = await client.post("/api/v1/sync/upload", json=payload)
        assert r1.status_code == 200, f"Expected 200, got {r1.status_code}: {r1.text}"
        data1 = r1.json()
        assert data1["results"][0]["status"] == "SUCCESS", f"Expected SUCCESS, got {data1}"
        print("1. IDEMPOTENCY FIRST SEND: SUCCESS")

        # Second send -> DUPLICATE_IGNORED
        r2 = await client.post("/api/v1/sync/upload", json=payload)
        assert r2.status_code == 200, f"Expected 200, got {r2.status_code}: {r2.text}"
        data2 = r2.json()
        assert data2["results"][0]["status"] == "DUPLICATE_IGNORED", f"Expected DUPLICATE_IGNORED, got {data2}"
        print("2. IDEMPOTENCY SECOND SEND: DUPLICATE_IGNORED")

        # Independent database verification
        async with engine.connect() as conn:
            res = await conn.execute(text("SELECT COUNT(*) FROM sync_logs WHERE operation_id = :op_id"), {"op_id": test_op_id})
            count = res.scalar()
            assert count == 1, f"Expected exactly 1 sync_logs row, got {count}"
            
            res2 = await conn.execute(text("SELECT COUNT(*) FROM assessment_results WHERE local_id = :res_id"), {"res_id": test_res_id})
            count2 = res2.scalar()
            assert count2 == 1, f"Expected exactly 1 assessment_results row, got {count2}"
            print(f"3. IDEMPOTENCY DB VERIFIED: Exactly 1 record in PostgreSQL (sync_logs={count}, assessment_results={count2})")

        # -------------------------------------------------------------
        # 2. PARTIAL BATCH TEST (Operation A valid, Operation B invalid)
        # -------------------------------------------------------------
        op_a_id = f"test_batch_a_{uuid.uuid4().hex[:12]}"
        res_a_id = f"res_batch_a_{uuid.uuid4().hex[:12]}"
        op_b_id = f"test_batch_b_{uuid.uuid4().hex[:12]}"

        partial_payload = {
            "device_id": "test_device_adv_001",
            "app_version": "1.0.0",
            "operations": [
                {
                    "operation_id": op_a_id,
                    "entity_type": "assessment_result",
                    "entity_id": res_a_id,
                    "operation": "CREATE",
                    "client_timestamp": "2026-09-19T02:00:00Z",
                    "payload": {
                        "id": res_a_id,
                        "student_id": "std_batch_a",
                        "student_name": "Rohan Mahato",
                        "outcome_code": "M1.1.1",
                        "score": 3.0,
                        "max_score": 5.0,
                        "status": "Developing",
                        "grade": 1,
                        "subject": "Mathematics"
                    }
                },
                {
                    "operation_id": op_b_id,
                    "entity_type": "unsupported_unknown_entity_type",  # Invalid entity type
                    "entity_id": "invalid_entity_id_xyz",
                    "operation": "CREATE",
                    "client_timestamp": "2026-09-19T02:00:00Z",
                    "payload": {"junk": "data"}
                }
            ]
        }

        r_batch = await client.post("/api/v1/sync/upload", json=partial_payload)
        assert r_batch.status_code == 200, f"Expected 200, got {r_batch.status_code}: {r_batch.text}"
        data_batch = r_batch.json()
        assert len(data_batch["results"]) == 2, f"Expected 2 results, got {data_batch}"
        
        status_map = {r["operation_id"]: r["status"] for r in data_batch["results"]}
        assert status_map[op_a_id] == "SUCCESS", f"Expected Operation A SUCCESS, got {status_map[op_a_id]}"
        assert status_map[op_b_id] == "FAILED", f"Expected Operation B FAILED, got {status_map[op_b_id]}"
        print(f"4. PARTIAL BATCH VERIFIED: Operation A -> {status_map[op_a_id]}, Operation B -> {status_map[op_b_id]}")

        # Independent database verification for partial batch
        async with engine.connect() as conn:
            res_a = await conn.execute(text("SELECT COUNT(*) FROM assessment_results WHERE local_id = :res_id"), {"res_id": res_a_id})
            assert res_a.scalar() == 1, "Operation A record must exist in PostgreSQL"
            
            res_b = await conn.execute(text("SELECT COUNT(*) FROM sync_logs WHERE operation_id = :op_id AND status = 'FAILED'"), {"op_id": op_b_id})
            assert res_b.scalar() == 1, "Operation B failed status must be logged in sync_logs"
            print("5. PARTIAL BATCH DB VERIFIED: Operation A committed, Operation B recorded as FAILED, no corrupt entity inserted")

    print("\nALL ADVANCED SYNC VERIFICATIONS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    asyncio.run(test_advanced_sync())
