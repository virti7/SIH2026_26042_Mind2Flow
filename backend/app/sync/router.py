from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db, get_optional_user
from app.core.security import UserContext
from app.db.models.assessment import Assessment
from app.db.models.language_pack import LanguagePack, ModelVersion, VerifiedPhrase
from app.db.models.lesson import Lesson
from app.db.models.resource import Worksheet
from app.sync.schemas import (
    SyncCheckRequest,
    SyncCheckResponse,
    SyncManifestResponse,
    SyncUpdatesResponse,
    SyncUploadRequest,
    SyncUploadResponse,
)
from app.sync.service import sync_service

router = APIRouter(prefix="/sync", tags=["Synchronization"])


@router.post("/upload", response_model=SyncUploadResponse, summary="Batch Upload Offline Operations")
async def sync_upload(
    req: SyncUploadRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Optional[UserContext] = Depends(get_optional_user),
):
    """
    Accepts batched operations from the Flutter client's Drift/SQLite SyncQueue.
    Performs idempotent execution per operation_id and returns per-operation status
    without failing the entire batch if an individual item is invalid.

    Teacher attribution comes ONLY from the verified JWT: anonymous uploads
    carry no owner and teacher-owned handlers reject them instead of
    attributing them to another teacher's row.
    """
    teacher_id = None
    if current_user:
        from app.core.ownership import require_teacher as _require_teacher_sync
        teacher = await _require_teacher_sync(db, current_user)
        teacher_id = teacher.id

    return await sync_service.process_batch(db, req, teacher_id)


@router.post("/check", response_model=SyncCheckResponse, summary="Check for Remote Updates")
async def sync_check(
    req: SyncCheckRequest,
    db: AsyncSession = Depends(get_db),
    current_user: Optional[UserContext] = Depends(get_optional_user),
):
    """
    Lightweight check allowing Flutter device to discover if newer content
    or language pack versions are available on the server.
    """
    now = datetime.now(timezone.utc)
    packs_res = await db.execute(
        select(LanguagePack).where(LanguagePack.release_status == "RELEASED")
    )
    available_packs = packs_res.scalars().all()

    updates: list[str] = []
    for p in available_packs:
        client_ver = req.installed_packs.get(p.language_code)
        if client_ver != p.version:
            updates.append(p.language_code)

    return SyncCheckResponse(
        device_id=req.device_id,
        server_time=now,
        updates_available=len(updates) > 0,
        content_version=1,
        language_pack_updates=updates,
        pending_server_updates_count=len(updates),
    )


@router.get("/manifest", response_model=SyncManifestResponse, summary="Get Full Synchronization Manifest")
async def get_sync_manifest(
    db: AsyncSession = Depends(get_db),
):
    """
    Returns complete metadata manifest of language packs and models
    to allow partial/selective offline bundle caching.
    """
    now = datetime.now(timezone.utc)
    packs_res = await db.execute(select(LanguagePack).where(LanguagePack.release_status == "RELEASED"))
    packs = packs_res.scalars().all()

    models_res = await db.execute(select(ModelVersion).where(ModelVersion.release_status == "RELEASED"))
    models = models_res.scalars().all()

    return SyncManifestResponse(
        server_time=now,
        content_version=1,
        curriculum_version="2026.1",
        language_packs=[
            {
                "id": p.id,
                "language": p.language_code,
                "version": p.version,
                "size_bytes": p.package_size,
                "checksum": p.checksum,
                "download_url": p.download_url,
            }
            for p in packs
        ],
        models=[
            {
                "id": m.id,
                "name": m.model_name,
                "type": m.model_type,
                "language": m.language_code,
                "version": m.version,
                "checksum": m.checksum,
                "download_url": m.download_url,
            }
            for m in models
        ],
    )


@router.get("/updates", response_model=SyncUpdatesResponse, summary="Get Server -> Device Incremental Updates")
async def get_sync_updates(
    since: Optional[datetime] = Query(None, description="ISO timestamp of last successful sync"),
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieves server records created/modified since a given timestamp so the
    Flutter tablet can incrementally update its local SQLite database.
    """
    now = datetime.now(timezone.utc)

    # Lessons
    lesson_q = select(Lesson).where(Lesson.deleted_at.is_(None))
    if since:
        lesson_q = lesson_q.where(Lesson.updated_at > since)
    lessons = (await db.execute(lesson_q.limit(100))).scalars().all()

    # Assessments
    ass_q = select(Assessment)
    if since:
        ass_q = ass_q.where(Assessment.updated_at > since)
    assessments = (await db.execute(ass_q.limit(100))).scalars().all()

    # Worksheets
    ws_q = select(Worksheet)
    if since:
        ws_q = ws_q.where(Worksheet.updated_at > since)
    worksheets = (await db.execute(ws_q.limit(100))).scalars().all()

    # Verified Phrases
    vp_q = select(VerifiedPhrase).where(VerifiedPhrase.verification_status == "VERIFIED")
    if since:
        vp_q = vp_q.where(VerifiedPhrase.updated_at > since)
    phrases = (await db.execute(vp_q.limit(200))).scalars().all()

    return SyncUpdatesResponse(
        server_time=now,
        since=since,
        lessons=[
            {
                "id": l.id,
                "title": l.title,
                "grade": l.grade,
                "subject": l.subject,
                "language": l.language,
                "objective": l.objective,
                "teacher_moves": l.teacher_moves,
                "updated_at": l.updated_at.isoformat(),
            }
            for l in lessons
        ],
        assessments=[
            {
                "id": a.id,
                "title": a.title,
                "grade": a.grade,
                "subject": a.subject,
                "total_marks": a.total_marks,
                "updated_at": a.updated_at.isoformat(),
            }
            for a in assessments
        ],
        worksheets=[
            {
                "id": w.id,
                "title": w.title,
                "grade": w.grade,
                "subject": w.subject,
                "file_path": w.file_path,
                "updated_at": w.updated_at.isoformat(),
            }
            for w in worksheets
        ],
        verified_phrases=[
            {
                "id": vp.id,
                "source_text": vp.source_text,
                "translated_text": vp.translated_text,
                "category": vp.category,
                "updated_at": vp.updated_at.isoformat(),
            }
            for vp in phrases
        ],
    )
