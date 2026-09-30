from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.activities.schemas import ActivityCreate, ActivityResponse
from app.core.dependencies import get_current_user, get_db
from app.core.security import UserContext
from app.db.models.lesson import Activity

router = APIRouter(prefix="/activities", tags=["Activities"])


@router.get("", response_model=List[ActivityResponse], summary="List Activities")
async def list_activities(
    lesson_id: Optional[str] = Query(None),
    learning_outcome_id: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    query = select(Activity)
    if lesson_id:
        query = query.where(Activity.lesson_id == lesson_id)
    if learning_outcome_id:
        query = query.where(Activity.learning_outcome_id == learning_outcome_id)

    res = await db.execute(query)
    return res.scalars().all()


@router.post("", response_model=ActivityResponse, summary="Create Activity")
async def create_activity(
    req: ActivityCreate,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    activity = Activity(**req.model_dump())
    db.add(activity)
    await db.commit()
    await db.refresh(activity)
    return activity
