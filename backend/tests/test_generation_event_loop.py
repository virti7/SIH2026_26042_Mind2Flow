"""Regression test for the asyncpg event-loop failure in worksheet jobs.

Bug: ``POST /api/v1/worksheets/generate`` returned 202, but the background
job ran ``asyncio.run(_run())`` from a worker thread while reusing the
application's AsyncEngine/AsyncSession. asyncpg connections belong to the
loop that created them, so the job died with::

    RuntimeError: Task ... got Future ... attached to a different loop
    InternalClientError: got result for unknown protocol state

The fix keeps production execution on the request's running event loop
(``schedule_job`` / ``execute_job_async``) with the job opening its own
session inside that loop. ``execute_job_sync`` remains only as an isolated-
loop wrapper (own engine per worker thread) for scripts/tests.

These tests run the job *inside the calling event loop* with a test-owned
session factory: external translation HTTP is faked, but the SQLAlchemy
event-loop behavior is real and NOT mocked away.
"""
import asyncio
import inspect
import uuid

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

import app.services.generation_jobs as jobs_module
from app.ai.schemas import TeacherGenerationRequest
from app.db.models.resource import SavedMaterial
from app.db.models.school import Teacher
from app.services.generation_jobs import GenerationJobManager


class _FakeResp:
    def __init__(self, status_code, payload):
        self.status_code = status_code
        self._payload = payload

    def json(self):
        return self._payload


class _FakeTranslateClient:
    """Deterministic Sarvam /translate stand-in: echoes tagged text."""

    def __init__(self, *args, **kwargs):
        pass

    def post(self, url, headers=None, json=None, timeout=None):
        assert "/translate" in url
        return _FakeResp(
            200, {"translated_text": f"[{json['target_language_code']}] {json['input']}"}
        )

    def close(self):
        pass


def _enable_sarvam(monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "SARVAM_API_KEY", "test-sarvam-key")
    import app.translation.providers as providers_mod

    monkeypatch.setattr(providers_mod.httpx, "Client", _FakeTranslateClient)


def _worksheet_request(**overrides):
    base = {
        "content_type": "worksheet",
        "grade": 2,
        "subject": "Mathematics",
        "topic": "Numbers up to 100",
        "nipun_outcome": "M2.1.4",
        "target_language": "sat",
        "request_id": f"req-{uuid.uuid4()}",
    }
    base.update(overrides)
    base["idempotency_key"] = base["request_id"]
    return TeacherGenerationRequest(**base)


def test_async_execution_paths_never_call_asyncio_run():
    """Static guard: asyncio.run() must only exist in the isolated-loop wrapper.

    ``schedule_job``, ``execute_job_async`` and the ``*_async`` executors run
    on the FastAPI event loop; any asyncio.run() there would reintroduce the
    cross-loop asyncpg failure.
    """
    allowed = {"execute_job_sync"}  # isolated thread + own engine only
    offenders = []
    for name, member in inspect.getmembers(jobs_module.GenerationJobManager, inspect.isfunction):
        if name in allowed or not (
            name == "schedule_job"
            or name == "execute_job_async"
            or name.endswith("_async")
        ):
            continue
        if "asyncio.run" in inspect.getsource(member):
            offenders.append(name)
    assert not offenders, f"asyncio.run() found in same-loop path: {offenders}"


@pytest.mark.asyncio
async def test_worksheet_job_completes_in_calling_loop(db_session, monkeypatch):
    """Job awaits the real pipeline + real SQLAlchemy session in-loop → READY."""
    _enable_sarvam(monkeypatch)

    # Seed the authenticated teacher in this loop's session (real DB I/O).
    db_session.add(
        Teacher(
            user_id="loop-teacher-1",
            username="loopteacher",
            name="Loop Teacher",
            email="loop.teacher@school.edu.in",
        )
    )
    await db_session.commit()

    session_factory = async_sessionmaker(
        bind=db_session.bind,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False,
    )

    manager = GenerationJobManager()
    req = _worksheet_request()
    job = manager.create_job(req=req, teacher_id="loop-teacher-1")
    assert job.status == "PENDING"

    calling_loop = asyncio.get_running_loop()
    await manager.execute_job_async(job.job_id, session_factory=session_factory)

    # Same loop throughout: the coroutine never left it (no threads/loops).
    assert asyncio.get_running_loop() is calling_loop

    finished = manager.get_job(job.job_id)
    assert finished is not None
    assert finished.status in ("READY", "REVIEW_REQUIRED"), finished.error

    # Teacher resolved via the authenticated user id; worksheet persisted.
    res = await db_session.execute(
        select(SavedMaterial).where(SavedMaterial.local_id == req.request_id)
    )
    material = res.scalar_one_or_none()
    assert material is not None
    assert material.material_type == "worksheet"


@pytest.mark.asyncio
async def test_worksheet_job_failure_is_terminal_not_stuck(db_session):
    """An unservable request ends FAILED (never PENDING/GENERATING)."""
    session_factory = async_sessionmaker(
        bind=db_session.bind,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False,
    )
    manager = GenerationJobManager()
    req = _worksheet_request(target_language="xx")
    job = manager.create_job(req=req, teacher_id="loop-teacher-1")
    await manager.execute_job_async(job.job_id, session_factory=session_factory)

    finished = manager.get_job(job.job_id)
    assert finished is not None
    assert finished.status == "FAILED"
    assert finished.error  # safe teacher-facing copy, set server-side
