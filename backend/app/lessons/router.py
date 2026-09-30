from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db
from app.core.exceptions import ForbiddenException, NotFoundException
from app.core.security import UserContext
from app.db.models.lesson import Lesson, LessonDeliveryRecord
from app.db.models.school import Teacher
from app.lessons.schemas import (
    DeliveryRecordCreate,
    DeliveryRecordResponse,
    LessonCreate,
    LessonResponse,
    LessonUpdate,
)

router = APIRouter(prefix="/lessons", tags=["Lessons"])


@router.get("", response_model=List[LessonResponse], summary="List Lessons")
async def list_lessons(
    grade: Optional[int] = Query(None),
    subject: Optional[str] = Query(None),
    topic_id: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    query = select(Lesson).where(Lesson.deleted_at.is_(None))
    if grade is not None:
        query = query.where(Lesson.grade == grade)
    if subject:
        query = query.where(Lesson.subject == subject)
    if topic_id:
        query = query.where(Lesson.topic_id == topic_id)

    res = await db.execute(query.offset(skip).limit(limit).order_by(Lesson.created_at.desc()))
    return res.scalars().all()


@router.post("", response_model=LessonResponse, status_code=status.HTTP_201_CREATED, summary="Create Lesson")
async def create_lesson(
    req: LessonCreate,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    # Find or create teacher record for user
    res = await db.execute(select(Teacher).where(Teacher.user_id == current_user.user_id))
    teacher = res.scalar_one_or_none()
    if not teacher:
        teacher = Teacher(
            user_id=current_user.user_id,
            email=current_user.email or f"{current_user.user_id}@example.com",
            name=current_user.user_metadata.get("name") or "Teacher",
            preferred_language="Hindi",
            designation="Primary Teacher",
            school_id=current_user.school_id,
        )
        db.add(teacher)
        await db.flush()

    lesson = Lesson(
        title=req.title,
        topic_id=req.topic_id,
        learning_outcome_id=req.learning_outcome_id,
        teacher_id=teacher.id,
        objective=req.objective,
        prerequisite=req.prerequisite,
        teacher_moves=req.teacher_moves,
        remediation_info=req.remediation_info,
        grade=req.grade,
        subject=req.subject,
        language=req.language,
        version=req.version,
        local_id=req.local_id,
    )
    db.add(lesson)
    await db.commit()
    await db.refresh(lesson)
    return lesson


@router.get("/{id}", response_model=LessonResponse, summary="Get Lesson by ID")
async def get_lesson(
    id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    lesson = await db.get(Lesson, id)
    if not lesson or lesson.deleted_at is not None:
        raise NotFoundException("Lesson", id)
    return lesson


@router.put("/{id}", response_model=LessonResponse, summary="Update Lesson")
async def update_lesson(
    id: str,
    req: LessonUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    lesson = await db.get(Lesson, id)
    if not lesson or lesson.deleted_at is not None:
        raise NotFoundException("Lesson", id)

    # Check ownership
    res = await db.execute(select(Teacher).where(Teacher.user_id == current_user.user_id))
    teacher = res.scalar_one_or_none()
    if not current_user.is_admin() and lesson.teacher_id:
        if not teacher or lesson.teacher_id != teacher.id:
            raise ForbiddenException("Cannot edit lessons created by another teacher")

    update_data = req.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(lesson, field, value)

    lesson.version += 1
    await db.commit()
    await db.refresh(lesson)
    return lesson


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT, summary="Soft Delete Lesson")
async def delete_lesson(
    id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    lesson = await db.get(Lesson, id)
    if not lesson or lesson.deleted_at is not None:
        raise NotFoundException("Lesson", id)

    # Ownership: mirror update_lesson so teachers cannot delete others' lessons.
    res = await db.execute(select(Teacher).where(Teacher.user_id == current_user.user_id))
    teacher = res.scalar_one_or_none()
    if not current_user.is_admin() and lesson.teacher_id:
        if not teacher or lesson.teacher_id != teacher.id:
            raise ForbiddenException("Cannot delete lessons created by another teacher")

    # Soft delete for offline sync synchronization
    lesson.deleted_at = datetime.now(timezone.utc)
    await db.commit()
    return None


@router.post("/{id}/delivery", response_model=DeliveryRecordResponse, summary="Record Lesson Delivery Progress")
async def record_delivery(
    id: str,
    req: DeliveryRecordCreate,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    lesson = await db.get(Lesson, id)
    if not lesson:
        raise NotFoundException("Lesson", id)

    from app.core.ownership import require_teacher as _require_teacher_del
    teacher = await _require_teacher_del(db, current_user)
    teacher_id = teacher.id

    delivery = LessonDeliveryRecord(
        lesson_id=id,
        teacher_id=teacher_id,
        classroom_id=req.classroom_id,
        completed_step_index=req.completed_step_index,
        total_steps=req.total_steps,
        notes=req.notes,
        local_id=req.local_id,
    )
    db.add(delivery)
    await db.commit()
    await db.refresh(delivery)
    return delivery
