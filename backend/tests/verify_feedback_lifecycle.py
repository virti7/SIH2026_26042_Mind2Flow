import asyncio
import os
import sys
import uuid
import httpx

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from app.db.session import engine
from app.core.security import create_access_token

async def test_feedback_lifecycle():
    base_url = "http://127.0.0.1:8000"
    admin_token = create_access_token({"sub": "admin_test_user_001", "role": "admin"})

    fb_local_id = f"fb_local_{uuid.uuid4().hex[:10]}"
    op_id = f"op_fb_{uuid.uuid4().hex[:10]}"

    payload = {
        "device_id": "test_device_fb_001",
        "app_version": "1.0.0",
        "operations": [
            {
                "operation_id": op_id,
                "entity_type": "feedback",
                "entity_id": fb_local_id,
                "operation": "CREATE",
                "client_timestamp": "2026-09-19T02:00:00Z",
                "payload": {
                    "source_text": "बच्चों को ध्यान से सुनो",
                    "translated_text": "होनको ध्यान ते आयुमपे",
                    "suggested_correction": "होनको बेस ते आयुमपे",
                    "feedback_type": "unnatural_wording",
                    "target_language": "Ho"
                }
            }
        ]
    }

    async with httpx.AsyncClient(base_url=base_url) as client:
        # 1. Sync upload feedback
        r_sync = await client.post("/api/v1/sync/upload", json=payload)
        assert r_sync.status_code == 200, f"Upload failed: {r_sync.text}"
        res_sync = r_sync.json()["results"][0]
        assert res_sync["status"] == "SUCCESS", f"Expected SUCCESS, got: {res_sync}"
        print("1. FEEDBACK SYNC UPLOAD: SUCCESS")

        # 2. Verify in Supabase PostgreSQL
        review_item_id = None
        async with engine.connect() as conn:
            fb_row = (await conn.execute(text("SELECT id, source_text, suggested_correction FROM translation_feedback WHERE local_id = :lid"), {"lid": fb_local_id})).fetchone()
            assert fb_row is not None, "translation_feedback record must exist in PostgreSQL"
            print(f"2. DB VERIFIED translation_feedback: id={fb_row[0]}")

            rq_row = (await conn.execute(text("SELECT id, status, candidate_translation FROM review_queue WHERE feedback_id = :fbid"), {"fbid": fb_row[0]})).fetchone()
            assert rq_row is not None, "review_queue record must exist in PostgreSQL"
            assert rq_row[1] == "PENDING", f"Expected PENDING, got {rq_row[1]}"
            review_item_id = rq_row[0]
            print(f"3. DB VERIFIED review_queue: id={review_item_id}, status={rq_row[1]}")

        # 3. Process Review Item via Admin API -> APPROVE & PROMOTE
        headers = {"Authorization": f"Bearer {admin_token}"}
        review_req = {
            "status": "APPROVED",
            "notes": "Verified by language expert; accurate idiom",
            "promote_to_verified_phrases": True,
            "verified_translation": "होनको बेस ते आयुमपे"
        }
        r_rev = await client.post(f"/api/v1/review-queue/{review_item_id}/review", json=review_req, headers=headers)
        assert r_rev.status_code == 200, f"Review API failed: {r_rev.text}"
        rev_data = r_rev.json()
        assert rev_data["status"] == "APPROVED"
        print(f"4. ADMIN REVIEW PROCESSED: status={rev_data['status']}")

        # 4. Verify in Supabase PostgreSQL that VerifiedPhrase was created
        async with engine.connect() as conn:
            phrase_row = (await conn.execute(text("SELECT id, source_text, translated_text, verification_status FROM verified_phrases WHERE source_text = 'बच्चों को ध्यान से सुनो'"))).fetchone()
            assert phrase_row is not None, "verified_phrases record must exist in PostgreSQL"
            assert phrase_row[3] == "VERIFIED", f"Expected VERIFIED, got {phrase_row[3]}"
            print(f"5. DB VERIFIED verified_phrases: id={phrase_row[0]}, text={phrase_row[2]}, status={phrase_row[3]}")

            # Cleanup
            await conn.execute(text("DELETE FROM verified_phrases WHERE id = :id"), {"id": phrase_row[0]})
            await conn.execute(text("DELETE FROM review_queue WHERE id = :id"), {"id": review_item_id})
            await conn.execute(text("DELETE FROM translation_feedback WHERE local_id = :lid"), {"lid": fb_local_id})
            await conn.execute(text("DELETE FROM sync_logs WHERE operation_id = :op"), {"op": op_id})
            await conn.commit()
            print("6. TEST RECORDS CLEANED UP SAFELY")

    print("\nFEEDBACK TO VERIFIED PHRASE E2E PIPELINE FULLY VERIFIED!")

if __name__ == "__main__":
    asyncio.run(test_feedback_lifecycle())
