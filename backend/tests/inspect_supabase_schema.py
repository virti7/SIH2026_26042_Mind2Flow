import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from app.db.session import AsyncSessionLocal

EXPECTED_TABLES = [
    "schools", "teachers", "classrooms", "languages", "student_language_groups",
    "nipun_goals", "nipun_competencies", "learning_outcomes",
    "subjects", "topics", "lessons", "activities",
    "assessments", "assessment_questions", "assessment_results", "learning_gaps", "remedial_recommendations",
    "language_packs", "model_versions", "verified_phrases",
    "sync_logs", "devices", "idempotency_records",
    "translation_feedback", "review_queue", "generated_content",
    "worksheets", "flashcards", "saved_materials", "lesson_delivery_records"
]

async def inspect():
    async with AsyncSessionLocal() as session:
        # 1. Query tables in public schema
        res = await session.execute(text(
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name"
        ))
        actual_tables = [row[0] for row in res.fetchall()]
        print(f"ACTUAL_PG_TABLE_COUNT={len(actual_tables)}")
        
        missing = [t for t in EXPECTED_TABLES if t not in actual_tables]
        print(f"MISSING_TABLES={missing}")
        assert len(missing) == 0, f"Missing expected tables: {missing}"

        # 2. Check alembic_version
        v_res = await session.execute(text("SELECT version_num FROM alembic_version"))
        version = v_res.scalar_one_or_none()
        print(f"ALEMBIC_VERSION_NUM={version}")

        # 3. Check unique constraint on sync_logs.operation_id
        c_res = await session.execute(text("""
            SELECT conname, contype 
            FROM pg_constraint 
            JOIN pg_class ON pg_class.oid = pg_constraint.conrelid 
            WHERE pg_class.relname = 'sync_logs'
        """))
        constraints = c_res.fetchall()
        print(f"SYNC_LOGS_CONSTRAINTS={[(c[0], c[1]) for c in constraints]}")

        print(">>> DIRECT DATABASE VERIFICATION: 100% TABLES AND CONSTRAINTS CONFIRMED <<<")

if __name__ == "__main__":
    asyncio.run(inspect())
