from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, require_admin
from app.core.exceptions import ConflictException, NotFoundException
from app.core.security import UserContext
from app.db.models.lesson import Activity
from app.db.models.nipun import LearningOutcome, NipunCompetency, NipunGoal
from app.nipun.schemas import (
    LearningOutcomeCreate,
    LearningOutcomeResponse,
    NipunCompetencyCreate,
    NipunCompetencyResponse,
    NipunGoalCreate,
    NipunGoalResponse,
)

router = APIRouter(prefix="/nipun", tags=["NIPUN Curriculum"])


@router.get("/grades", response_model=List[int], summary="Get Supported NIPUN Grades")
async def get_supported_grades():
    """Returns list of foundational grades covered under NIPUN Bharat (Balvatika, Grade 1, Grade 2, Grade 3)."""
    return [1, 2, 3]


@router.get("/goals", response_model=List[NipunGoalResponse], summary="List NIPUN Goals")
async def list_goals(
    grade: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    query = select(NipunGoal)
    if grade is not None:
        query = query.where(NipunGoal.grade == grade)
    res = await db.execute(query.order_by(NipunGoal.code))
    return res.scalars().all()


@router.post("/goals", response_model=NipunGoalResponse, summary="Create NIPUN Goal (Admin only)")
async def create_goal(
    req: NipunGoalCreate,
    db: AsyncSession = Depends(get_db),
    admin_user: UserContext = Depends(require_admin),
):
    existing = await db.execute(select(NipunGoal).where(NipunGoal.code == req.code))
    if existing.scalar_one_or_none():
        raise ConflictException(f"NIPUN Goal with code '{req.code}' already exists")

    goal = NipunGoal(**req.model_dump())
    db.add(goal)
    await db.commit()
    await db.refresh(goal)
    return goal


@router.get("/competencies", response_model=List[NipunCompetencyResponse], summary="List NIPUN Competencies")
async def list_competencies(
    goal_id: Optional[str] = Query(None),
    domain: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    query = select(NipunCompetency)
    if goal_id:
        query = query.where(NipunCompetency.goal_id == goal_id)
    if domain:
        query = query.where(NipunCompetency.domain == domain)
    res = await db.execute(query.order_by(NipunCompetency.code))
    return res.scalars().all()


@router.post("/competencies", response_model=NipunCompetencyResponse, summary="Create NIPUN Competency (Admin only)")
async def create_competency(
    req: NipunCompetencyCreate,
    db: AsyncSession = Depends(get_db),
    admin_user: UserContext = Depends(require_admin),
):
    existing = await db.execute(select(NipunCompetency).where(NipunCompetency.code == req.code))
    if existing.scalar_one_or_none():
        raise ConflictException(f"NIPUN Competency with code '{req.code}' already exists")

    competency = NipunCompetency(**req.model_dump())
    db.add(competency)
    await db.commit()
    await db.refresh(competency)
    return competency


@router.get("/outcomes", response_model=List[LearningOutcomeResponse], summary="List Learning Outcomes")
async def list_outcomes(
    grade: Optional[int] = Query(None),
    subject: Optional[str] = Query(None),
    competency_id: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    query = select(LearningOutcome)
    if grade is not None:
        query = query.where(LearningOutcome.grade == grade)
    if subject:
        query = query.where(LearningOutcome.subject == subject)
    if competency_id:
        query = query.where(LearningOutcome.competency_id == competency_id)
    res = await db.execute(query.order_by(LearningOutcome.code))
    return res.scalars().all()


@router.post("/outcomes", response_model=LearningOutcomeResponse, summary="Create Learning Outcome (Admin only)")
async def create_outcome(
    req: LearningOutcomeCreate,
    db: AsyncSession = Depends(get_db),
    admin_user: UserContext = Depends(require_admin),
):
    existing = await db.execute(select(LearningOutcome).where(LearningOutcome.code == req.code))
    if existing.scalar_one_or_none():
        raise ConflictException(f"Learning Outcome with code '{req.code}' already exists")

    outcome = LearningOutcome(**req.model_dump())
    db.add(outcome)
    await db.commit()
    await db.refresh(outcome)
    return outcome
