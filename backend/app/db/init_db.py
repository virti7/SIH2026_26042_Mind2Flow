from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import metadata
from app.db.models import Language, NipunGoal, NipunCompetency, LearningOutcome, Subject, Topic
from app.db.session import engine


async def init_db_schema() -> None:
    """Create all tables in the database if they do not already exist."""
    async with engine.begin() as conn:
        await conn.run_sync(metadata.create_all)


async def seed_initial_data(session: AsyncSession) -> None:
    """Seed initial core data such as languages and foundation NIPUN data."""
    # 1. Languages
    languages_data = [
        {"code": "hi", "name": "Hindi", "script": "Devanagari"},
        {"code": "ho", "name": "Ho", "script": "Warang Chiti"},
        {"code": "unr", "name": "Mundari", "script": "Baniuri"},
        {"code": "sat", "name": "Santali", "script": "Ol Chiki"},
    ]

    for lang_info in languages_data:
        res = await session.execute(select(Language).where(Language.code == lang_info["code"]))
        existing = res.scalar_one_or_none()
        if not existing:
            session.add(Language(**lang_info))

    # 2. Subjects
    subjects_data = [
        {"code": "HIN_G1", "name": "Hindi", "icon": "menu_book", "grade": 1},
        {"code": "MATH_G1", "name": "Mathematics", "icon": "calculate", "grade": 1},
        {"code": "EVS_G1", "name": "Environmental Studies", "icon": "nature_people", "grade": 1},
    ]
    for sub in subjects_data:
        res = await session.execute(select(Subject).where(Subject.code == sub["code"]))
        if not res.scalar_one_or_none():
            session.add(Subject(**sub))

    await session.commit()
