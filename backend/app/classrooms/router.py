from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.classrooms.schemas import ClassroomCreate, ClassroomResponse
from app.core.dependencies import get_current_user, get_db
from app.core.exceptions import NotFoundException
from app.core.security import UserContext
from app.db.models.school import Classroom, StudentLanguageGroup

router = APIRouter(prefix="/classrooms", tags=["Classrooms"])


@router.get("", response_model=List[ClassroomResponse], summary="List Classrooms")
async def list_classrooms(
    grade: Optional[int] = Query(None),
    school_id: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    query = select(Classroom).options(selectinload(Classroom.language_groups))
    if grade is not None:
        query = query.where(Classroom.grade == grade)
    if school_id:
        query = query.where(Classroom.school_id == school_id)
    elif current_user.school_id and not current_user.is_admin():
        query = query.where(Classroom.school_id == current_user.school_id)

    res = await db.execute(query)
    return res.scalars().all()


@router.post("", response_model=ClassroomResponse, summary="Create Classroom")
async def create_classroom(
    req: ClassroomCreate,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    classroom = Classroom(
        school_id=req.school_id,
        teacher_id=req.teacher_id,
        grade=req.grade,
        section=req.section,
        room_number=req.room_number,
        academic_year=req.academic_year,
    )
    db.add(classroom)
    await db.flush()

    if req.language_groups:
        for lg in req.language_groups:
            group = StudentLanguageGroup(
                classroom_id=classroom.id,
                language_id=lg.language_id,
                student_count=lg.student_count,
            )
            db.add(group)

    await db.commit()
    res = await db.execute(
        select(Classroom)
        .options(selectinload(Classroom.language_groups))
        .where(Classroom.id == classroom.id)
    )
    return res.scalar_one()


@router.get("/{id}", response_model=ClassroomResponse, summary="Get Classroom by ID")
async def get_classroom(
    id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    res = await db.execute(
        select(Classroom)
        .options(selectinload(Classroom.language_groups))
        .where(Classroom.id == id)
    )
    classroom = res.scalar_one_or_none()
    if not classroom:
        raise NotFoundException("Classroom", id)
    return classroom
