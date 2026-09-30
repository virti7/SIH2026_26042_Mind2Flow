import asyncio
import os
import sys
import httpx

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select
from app.core.security import create_access_token
from app.db.session import AsyncSessionLocal
from app.db.models.lesson import Lesson

async def test_fastapi_to_supabase():
    # 1. Generate test token
    token = create_access_token({
        "sub": "user_test_teacher_42",
        "email": "teacher.e2e@jharkhand.edu.in",
        "role": "teacher",
        "user_metadata": {"name": "Sita Soren"}
    })

    test_title = "Bilingual Counting in Ho and Hindi (Live Test)"
    payload = {
        "title": test_title,
        "grade": 2,
        "subject": "Mathematics",
        "language": "Ho",
        "objective": "Understand base-10 and base-20 tribal numbers"
    }

    # 2. HTTP POST to live FastAPI server
    async with httpx.AsyncClient(base_url="http://127.0.0.1:8000") as client:
        r = await client.post(
            "/api/v1/lessons",
            json=payload,
            headers={"Authorization": f"Bearer {token}"}
        )
        print("HTTP POST /api/v1/lessons status:", r.status_code)
        assert r.status_code == 201, f"Expected 201, got {r.status_code}: {r.text}"
        data = r.json()
        lesson_id = data["id"]
        print(f"Created Lesson ID via FastAPI: {lesson_id}")

    # 3. Independently query real Supabase PostgreSQL
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Lesson).where(Lesson.id == lesson_id))
        pg_lesson = res.scalar_one_or_none()
        assert pg_lesson is not None, "Record does NOT exist in Supabase PostgreSQL!"
        assert pg_lesson.title == test_title, f"Title mismatch: {pg_lesson.title}"
        print(f"Independently verified in Supabase PostgreSQL: id={pg_lesson.id}, title='{pg_lesson.title}', teacher_id={pg_lesson.teacher_id}")

        # 4. Clean up test record
        await session.delete(pg_lesson)
        await session.commit()
        print("Cleaned up temporary test lesson from Supabase PostgreSQL")

    print(">>> FASTAPI -> REAL SUPABASE POSTGRESQL MUTATION VERIFIED <<<")

if __name__ == "__main__":
    asyncio.run(test_fastapi_to_supabase())
