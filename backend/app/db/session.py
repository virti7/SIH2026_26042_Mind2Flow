from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import declarative_base

from app.core.config import settings

# Adjust database URL for async drivers if necessary
db_url = settings.DATABASE_URL
if db_url.startswith("postgresql://"):
    db_url = db_url.replace("postgresql://", "postgresql+asyncpg://", 1)
elif db_url.startswith("postgres://"):
    db_url = db_url.replace("postgres://", "postgresql+asyncpg://", 1)
elif db_url.startswith("sqlite:///"):
    db_url = db_url.replace("sqlite:///", "sqlite+aiosqlite:///", 1)

# SQLite specific connect args
connect_args = {}
if "sqlite" in db_url:
    connect_args = {"check_same_thread": False}

engine = create_async_engine(
    db_url,
    echo=False,
    connect_args=connect_args,
    pool_pre_ping=True if "sqlite" not in db_url else False,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


def make_session_factory(db_url_override: str | None = None):
    """Build an isolated engine + session factory (e.g. for worker threads).

    asyncpg connections bind to the event loop running inside the thread
    that first uses them, so code executing on a *different* loop than the
    application's must NEVER reuse the module-level ``engine`` /
    ``AsyncSessionLocal``. Call this inside the worker thread/loop that
    will own the sessions, and dispose the engine when done::

        factory = make_session_factory()
        try:
            async with factory() as session:
                ...
        finally:
            await factory.kw["bind"].dispose()
    """
    url = db_url_override or settings.DATABASE_URL
    if url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
    elif url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql+asyncpg://", 1)
    elif url.startswith("sqlite:///"):
        url = url.replace("sqlite:///", "sqlite+aiosqlite:///", 1)

    local_connect_args = {}
    if "sqlite" in url:
        local_connect_args = {"check_same_thread": False}

    local_engine = create_async_engine(
        url,
        echo=False,
        connect_args=local_connect_args,
        pool_pre_ping=True if "sqlite" not in url else False,
    )
    return async_sessionmaker(
        bind=local_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False,
    )

Base = declarative_base()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
