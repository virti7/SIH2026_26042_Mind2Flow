from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db, require_reviewer
from app.core.exceptions import BadRequestException, NotFoundException
from app.core.security import UserContext
from app.db.models.feedback import ReviewQueueItem, TranslationFeedback
from app.db.models.language_pack import VerifiedPhrase
from app.feedback.schemas import (
    ReviewActionRequest,
    ReviewQueueItemResponse,
    TranslationFeedbackCreate,
    TranslationFeedbackResponse,
)

router = APIRouter(tags=["Feedback & Review Queue"])


@router.post("/feedback/translations", response_model=TranslationFeedbackResponse, status_code=status.HTTP_201_CREATED, summary="Submit Teacher Translation Feedback")
async def submit_translation_feedback(
    req: TranslationFeedbackCreate,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    """
    Records teacher feedback on offline translation issues (wrong meaning, pronunciation, unnatural).
    Asynchronously enqueues into review queue without blocking classroom teaching.
    The feedback is owned by the JWT teacher (row auto-provisioned).
    """
    from app.core.ownership import require_teacher as _require_teacher_fb
    teacher = await _require_teacher_fb(db, current_user)
    teacher_id = teacher.id

    fb = TranslationFeedback(
        teacher_id=teacher_id,
        source_text=req.source_text,
        translated_text=req.translated_text,
        suggested_correction=req.suggested_correction,
        feedback_type=req.feedback_type,
        audio_url=req.audio_url,
        local_id=req.local_id,
    )
    db.add(fb)
    await db.flush()

    # Automatically enqueue for language expert review
    review_item = ReviewQueueItem(
        feedback_id=fb.id,
        source_text=req.source_text,
        candidate_translation=req.suggested_correction or req.translated_text,
        target_language=req.target_language,
        status="PENDING",
        priority="HIGH" if req.feedback_type == "wrong_meaning" else "MEDIUM",
    )
    db.add(review_item)

    await db.commit()
    await db.refresh(fb)
    return fb


@router.get("/feedback/translations", response_model=List[TranslationFeedbackResponse], summary="List Translation Feedback")
async def list_feedback(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    from app.core.ownership import get_owned_teacher_or_none
    teacher = await get_owned_teacher_or_none(db, current_user)
    if teacher is None:
        return []
    query = (
        select(TranslationFeedback)
        .where(TranslationFeedback.teacher_id == teacher.id)
        .offset(skip)
        .limit(limit)
        .order_by(TranslationFeedback.created_at.desc())
    )
    res = await db.execute(query)
    return res.scalars().all()


@router.get("/review-queue", response_model=List[ReviewQueueItemResponse], summary="List Translation Review Queue")
async def list_review_queue(
    status_filter: Optional[str] = Query(None, description="PENDING, UNDER_REVIEW, APPROVED, REJECTED"),
    target_language: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    reviewer: UserContext = Depends(require_reviewer),
):
    """
    Expert review queue for validating teacher corrections and candidate translations.
    """
    query = select(ReviewQueueItem)
    if status_filter:
        query = query.where(ReviewQueueItem.status == status_filter.upper())
    if target_language:
        query = query.where(ReviewQueueItem.target_language == target_language)

    res = await db.execute(query.offset(skip).limit(limit).order_by(ReviewQueueItem.created_at.desc()))
    return res.scalars().all()


@router.post("/review-queue/{id}/review", response_model=ReviewQueueItemResponse, summary="Process Review Queue Item (Reviewer/Admin only)")
async def process_review_item(
    id: str,
    req: ReviewActionRequest,
    db: AsyncSession = Depends(get_db),
    reviewer: UserContext = Depends(require_reviewer),
):
    item = await db.get(ReviewQueueItem, id)
    if not item:
        raise NotFoundException("ReviewQueueItem", id)

    valid_statuses = ("APPROVED", "REJECTED", "UNDER_REVIEW")
    if req.status.upper() not in valid_statuses:
        raise BadRequestException(f"Invalid status '{req.status}'. Must be one of {valid_statuses}")

    now = datetime.now(timezone.utc)
    item.status = req.status.upper()
    item.notes = req.notes
    item.reviewer_id = reviewer.user_id
    item.reviewed_at = now

    # If APPROVED and promotion requested, insert into Verified Phrases bank
    if item.status == "APPROVED" and req.promote_to_verified_phrases:
        phrase = VerifiedPhrase(
            source_text=item.source_text,
            translated_text=req.verified_translation or item.candidate_translation,
            category="Classroom Review Verified",
            domain="Education",
            verification_status="VERIFIED",
            verified_by=reviewer.user_id,
        )
        db.add(phrase)

    await db.commit()
    await db.refresh(item)
    return item
