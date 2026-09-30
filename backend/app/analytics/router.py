from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.analytics.schemas import AnalyticsSummaryResponse, SyncLogResponse
from app.core.dependencies import get_db, require_admin
from app.core.security import UserContext
from app.db.models.assessment import AssessmentResult
from app.db.models.feedback import TranslationFeedback
from app.db.models.language_pack import LanguagePack, VerifiedPhrase
from app.db.models.lesson import Lesson
from app.db.models.school import School, Teacher
from app.db.models.sync import SyncQueueLog

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/summary", response_model=AnalyticsSummaryResponse, summary="Get Platform Analytics Summary (Admin only)")
async def get_analytics_summary(
    db: AsyncSession = Depends(get_db),
    admin: UserContext = Depends(require_admin),
):
    total_teachers = (await db.execute(select(func.count(Teacher.id)))).scalar_one() or 0
    total_schools = (await db.execute(select(func.count(School.id)))).scalar_one() or 0
    total_lessons = (await db.execute(select(func.count(Lesson.id)).where(Lesson.deleted_at.is_(None)))).scalar_one() or 0
    total_assessments = (await db.execute(select(func.count(AssessmentResult.id)))).scalar_one() or 0
    total_syncs = (await db.execute(select(func.count(SyncQueueLog.id)))).scalar_one() or 0
    total_feedback = (await db.execute(select(func.count(TranslationFeedback.id)))).scalar_one() or 0
    total_phrases = (await db.execute(select(func.count(VerifiedPhrase.id)))).scalar_one() or 0
    total_packs = (await db.execute(select(func.count(LanguagePack.id)).where(LanguagePack.release_status == "RELEASED"))).scalar_one() or 0

    return AnalyticsSummaryResponse(
        total_teachers=total_teachers,
        total_schools=total_schools,
        total_lessons=total_lessons,
        total_assessments_taken=total_assessments,
        total_sync_operations_processed=total_syncs,
        total_translation_feedback=total_feedback,
        total_verified_phrases=total_phrases,
        active_language_packs=total_packs,
        timestamp=datetime.now(timezone.utc),
    )


@router.get("/sync-logs", response_model=List[SyncLogResponse], summary="List Synchronization Event Logs (Admin only)")
async def list_sync_logs(
    device_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    admin: UserContext = Depends(require_admin),
):
    query = select(SyncQueueLog)
    if device_id:
        query = query.where(SyncQueueLog.device_id == device_id)
    if status:
        query = query.where(SyncQueueLog.status == status.upper())

    res = await db.execute(query.offset(skip).limit(limit).order_by(SyncQueueLog.received_at.desc()))
    return res.scalars().all()
