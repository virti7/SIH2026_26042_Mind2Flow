from typing import List
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db, require_admin
from app.core.exceptions import ConflictException, NotFoundException
from app.core.security import UserContext
from app.db.models.school import School
from app.schools.schemas import SchoolCreate, SchoolResponse

router = APIRouter(prefix="/schools", tags=["Schools"])


@router.get("", response_model=List[SchoolResponse], summary="List Schools")
async def list_schools(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    district: str = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    query = select(School).offset(skip).limit(limit)
    if district:
        query = query.where(School.district == district)
    res = await db.execute(query)
    return res.scalars().all()


@router.post("", response_model=SchoolResponse, summary="Create School (Admin only)")
async def create_school(
    req: SchoolCreate,
    db: AsyncSession = Depends(get_db),
    admin_user: UserContext = Depends(require_admin),
):
    existing = await db.execute(select(School).where(School.code == req.code))
    if existing.scalar_one_or_none():
        raise ConflictException(f"School with code '{req.code}' already exists")

    school = School(**req.model_dump())
    db.add(school)
    await db.commit()
    await db.refresh(school)
    return school


@router.get("/{id}", response_model=SchoolResponse, summary="Get School by ID")
async def get_school(
    id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    school = await db.get(School, id)
    if not school:
        raise NotFoundException("School", id)
    return school
