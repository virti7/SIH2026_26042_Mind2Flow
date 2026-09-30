import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from app.db.session import engine

async def check_synced_record():
    async with engine.connect() as conn:
        res = await conn.execute(text("SELECT id, operation_id, entity_type, entity_id, status, received_at FROM sync_logs WHERE operation_id LIKE 'e2e_op_%' ORDER BY received_at DESC LIMIT 5;"))
        rows = res.fetchall()
        print('SYNC_LOGS ROWS COUNT:', len(rows))
        for r in rows:
            print('SYNC_LOG:', r)
        
        res2 = await conn.execute(text("SELECT id, local_id, student_id, student_name, score, max_score, status FROM assessment_results WHERE local_id LIKE 'e2e_res_%' OR id LIKE 'e2e_res_%' ORDER BY created_at DESC LIMIT 5;"))
        rows2 = res2.fetchall()
        print('ASSESSMENT_RESULTS ROWS COUNT:', len(rows2))
        for r in rows2:
            print('ASSESSMENT_RESULT:', r)

if __name__ == '__main__':
    asyncio.run(check_synced_record())
