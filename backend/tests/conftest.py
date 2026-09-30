import asyncio
import os
import sys
from typing import AsyncGenerator

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ["PUBLISHER_MOCK_MODE"] = "true"

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.security import create_access_token
from app.db.base import metadata
from app.db.init_db import seed_initial_data
from app.db.session import get_db
from app.main import app

from sqlalchemy.pool import StaticPool

# In-memory SQLite database for isolated unit and integration testing
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)

TestSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="function")
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    async with test_engine.begin() as conn:
        await conn.run_sync(metadata.create_all)

    async with TestSessionLocal() as session:
        await seed_initial_data(session)
        yield session

    async with test_engine.begin() as conn:
        await conn.run_sync(metadata.drop_all)


@pytest_asyncio.fixture(scope="function")
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest.fixture
def teacher_auth_headers():
    token = create_access_token({
        "sub": "teacher-user-uuid-1",
        "email": "teacher1@jharkhand.edu.in",
        "role": "teacher",
        "user_metadata": {"name": "Sunita Devi", "role": "teacher"},
    })
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def other_teacher_auth_headers():
    token = create_access_token({
        "sub": "teacher-user-uuid-2",
        "email": "teacher2@jharkhand.edu.in",
        "role": "teacher",
        "user_metadata": {"name": "Ramesh Soren", "role": "teacher"},
    })
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def admin_auth_headers():
    token = create_access_token({
        "sub": "admin-user-uuid-99",
        "email": "admin@jharkhand.edu.in",
        "role": "admin",
        "user_metadata": {"name": "Admin Officer", "role": "admin"},
    })
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def reviewer_auth_headers():
    token = create_access_token({
        "sub": "reviewer-user-uuid-50",
        "email": "reviewer@jharkhand.edu.in",
        "role": "content_reviewer",
        "user_metadata": {"name": "Language Expert", "role": "content_reviewer"},
    })
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def student_auth_headers():
    token = create_access_token({
        "sub": "student-user-uuid-10",
        "email": "student1@jharkhand.edu.in",
        "role": "student",
        "user_metadata": {"name": "Birsa Munda", "role": "student"},
    })
    return {"Authorization": f"Bearer {token}"}
