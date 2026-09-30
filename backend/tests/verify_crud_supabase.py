import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select
from app.db.session import AsyncSessionLocal
from app.db.models.school import School

async def test_crud():
    async with AsyncSessionLocal() as session:
        test_code = "TEMP-VERIF-001"
        
        # 1. CREATE
        school = School(
            code=test_code,
            name="Temporary E2E Verification School",
            district="Khunti",
            state="Jharkhand",
        )
        session.add(school)
        await session.commit()
        school_id = school.id
        print(f"1. CREATED: id={school_id}, code={school.code}")

        # 2. SELECT (Read back)
        res = await session.execute(select(School).where(School.id == school_id))
        s_read = res.scalar_one_or_none()
        assert s_read is not None, "Failed to read back created school"
        assert s_read.code == test_code
        print(f"2. SELECTED: name={s_read.name}")

        # 3. UPDATE
        s_read.name = "Updated E2E School Name"
        await session.commit()
        print("3. UPDATED")

        # 4. SELECT (Verify update)
        res2 = await session.execute(select(School).where(School.id == school_id))
        s_updated = res2.scalar_one_or_none()
        assert s_updated is not None
        assert s_updated.name == "Updated E2E School Name"
        print(f"4. VERIFIED UPDATE: new name={s_updated.name}")

        # 5. DELETE
        await session.delete(s_updated)
        await session.commit()
        print("5. DELETED")

        # 6. SELECT (Verify deletion)
        res3 = await session.execute(select(School).where(School.id == school_id))
        s_deleted = res3.scalar_one_or_none()
        assert s_deleted is None, "School was not deleted properly"
        print("6. VERIFIED DELETION: record no longer exists in Supabase PostgreSQL")

        print(">>> REAL CRUD TEST IN SUPABASE POSTGRESQL: 100% PASSED <<<")

if __name__ == "__main__":
    asyncio.run(test_crud())
