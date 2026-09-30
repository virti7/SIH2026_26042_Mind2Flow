from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db, require_admin
from app.core.exceptions import ConflictException, ForbiddenException, NotFoundException
from app.core.security import UserContext
from app.db.models.school import Teacher
from app.teachers.schemas import TeacherCreate, TeacherProfileUpdate, TeacherResponse

router = APIRouter(prefix="/teachers", tags=["Teachers"])


@router.get("/profile", response_model=TeacherResponse, summary="Get Current Teacher Profile")
async def get_teacher_profile(
    current_user: UserContext = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    res = await db.execute(select(Teacher).where(Teacher.user_id == current_user.user_id))
    teacher = res.scalar_one_or_none()
    if not teacher:
        # Create a default teacher record linked to user_id if first time login
        teacher = Teacher(
            user_id=current_user.user_id,
            email=current_user.email or f"user_{current_user.user_id[:8]}@example.com",
            name=current_user.user_metadata.get("name") or "Teacher",
            preferred_language="Hindi",
            designation="Primary Teacher",
            school_id=current_user.school_id,
        )
        db.add(teacher)
        await db.commit()
        await db.refresh(teacher)
    return teacher


@router.put("/profile", response_model=TeacherResponse, summary="Update Current Teacher Profile")
async def update_teacher_profile(
    req: TeacherProfileUpdate,
    current_user: UserContext = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    res = await db.execute(select(Teacher).where(Teacher.user_id == current_user.user_id))
    teacher = res.scalar_one_or_none()
    if not teacher:
        teacher = Teacher(
            user_id=current_user.user_id,
            email=current_user.email or f"user_{current_user.user_id[:8]}@example.com",
            name=req.name or "Teacher",
            phone=req.phone,
            designation=req.designation or "Primary Teacher",
            preferred_language=req.preferred_language or "Hindi",
            school_id=current_user.school_id,
        )
        db.add(teacher)
    else:
        if req.name is not None:
            teacher.name = req.name
        if req.phone is not None:
            teacher.phone = req.phone
        if req.designation is not None:
            teacher.designation = req.designation
        if req.preferred_language is not None:
            teacher.preferred_language = req.preferred_language

    await db.commit()
    await db.refresh(teacher)
    return teacher


@router.get("", response_model=List[TeacherResponse], summary="List Teachers")
async def list_teachers(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    school_id: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    query = select(Teacher).offset(skip).limit(limit)
    if not current_user.is_admin():
        # Teachers can only view teachers in their own school
        if current_user.school_id:
            query = query.where(Teacher.school_id == current_user.school_id)
    elif school_id:
        query = query.where(Teacher.school_id == school_id)

    res = await db.execute(query)
    return res.scalars().all()


@router.get("/{id}", response_model=TeacherResponse, summary="Get Teacher by ID")
async def get_teacher(
    id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    teacher = await db.get(Teacher, id)
    if not teacher:
        raise NotFoundException("Teacher", id)
    if not current_user.is_admin() and teacher.user_id != current_user.user_id:
        if teacher.school_id != current_user.school_id:
            raise ForbiddenException("Cannot view teacher outside your school")
    return teacher
