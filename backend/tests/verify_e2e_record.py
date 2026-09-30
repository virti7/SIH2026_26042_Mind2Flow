import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select
from app.db.session import AsyncSessionLocal
from app.db.models.sync import SyncQueueLog
from app.db.models.assessment import AssessmentResult, LearningGap

async def verify_latest():
    async with AsyncSessionLocal() as session:
        log_q = await session.execute(
            select(SyncQueueLog).order_by(SyncQueueLog.received_at.desc()).limit(5)
        )
        logs = log_q.scalars().all()
        print(f"--- SYNC QUEUE LOGS (Found {len(logs)}) ---")
        for log in logs:
            print(f"Log: operation_id={log.operation_id}, entity_type={log.entity_type}, entity_id={log.entity_id}, status={log.status}")

        ass_q = await session.execute(
            select(AssessmentResult).order_by(AssessmentResult.created_at.desc()).limit(5)
        )
        results = ass_q.scalars().all()
        print(f"\n--- ASSESSMENT RESULTS (Found {len(results)}) ---")
        for r in results:
            print(f"Result: id={r.id}, local_id={r.local_id}, student_name={r.student_name}, score={r.score}/{r.max_score}, status={r.status}")

        if not logs or not results:
            print("\nVerification Warning: No logs or assessment results found yet.")
            return False

        latest_log = logs[0]
        latest_res = results[0]
        assert latest_log.status == "SUCCESS", f"Expected SUCCESS, got {latest_log.status}"
        assert latest_res.student_name in ("Birsa Oraon", "Birsa Munda"), f"Unexpected student: {latest_res.student_name}"
        print("\n>>> BACKEND VERIFICATION SUCCESSFUL: Record genuinely stored in database! <<<")
        return True

if __name__ == "__main__":
    success = asyncio.run(verify_latest())
    sys.exit(0 if success else 1)
