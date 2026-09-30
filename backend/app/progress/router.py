from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.dependencies import get_current_user, get_db
from app.core.exceptions import NotFoundException
from app.core.security import UserContext
from app.db.models.assessment import AssessmentResult, LearningGap, RemedialRecommendation
from app.db.models.nipun import LearningOutcome
from app.progress.schemas import LearningGapResponse, LearnerProgressResponse, OutcomeProgressItem

router = APIRouter(prefix="/progress", tags=["Progress & Remediation"])


@router.get("/learners/{student_id}", response_model=LearnerProgressResponse, summary="Get Individual Learner Progress")
async def get_learner_progress(
    student_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    from app.core.ownership import get_owned_teacher_or_none
    teacher = await get_owned_teacher_or_none(db, current_user)
    if teacher is None:
        raise NotFoundException("Learner", student_id)
    # Teacher-owned results only: never enumerate another teacher's students.
    query = select(AssessmentResult).where(
        AssessmentResult.teacher_id == teacher.id,
        or_(
            AssessmentResult.student_id == student_id,
            AssessmentResult.student_name == student_id,
        ),
    )
    res = await db.execute(query)
    results = res.scalars().all()
    if not results:
        raise NotFoundException("Learner", student_id)

    # Gaps linked to this teacher's own assessment results.
    owned_result_ids = {r.id for r in results}
    gaps_res = await db.execute(
        select(LearningGap)
        .options(selectinload(LearningGap.remediations))
        .where(
            or_(
                LearningGap.student_id == student_id,
                LearningGap.student_name == student_id,
            )
        )
        .order_by(LearningGap.detected_at.desc())
    )
    gaps = [
        g
        for g in gaps_res.scalars().all()
        if g.assessment_result_id is None
        or g.assessment_result_id in owned_result_ids
    ]

    total_taken = len(results)
    avg_score = 0.0
    if total_taken > 0:
        total_percent = sum((r.score / r.max_score) * 100 for r in results if r.max_score > 0)
        avg_score = round(total_percent / total_taken, 1)

    overall_status = "Developing"
    if avg_score >= 75.0:
        overall_status = "Achieved"
    elif avg_score < 50.0 and total_taken > 0:
        overall_status = "Needs Support"

    student_name = results[0].student_name if results else (gaps[0].student_name if gaps else student_id)

    # Fetch outcomes for active gaps
    outcomes: List[OutcomeProgressItem] = []
    for g in gaps:
        lo = await db.get(LearningOutcome, g.learning_outcome_id)
        if lo:
            status_val = "Resolved" if g.resolved_at else ("Needs Support" if g.severity == "High" else "Developing")
            outcomes.append(
                OutcomeProgressItem(
                    learning_outcome_id=lo.id,
                    outcome_code=lo.code,
                    description=lo.description,
                    status=status_val,
                    subject=lo.subject,
                )
            )

    return LearnerProgressResponse(
        student_name=student_name,
        student_id=student_id,
        overall_status=overall_status,
        total_assessments_taken=total_taken,
        average_score_percent=avg_score,
        outcomes=outcomes,
        active_gaps=gaps,
    )


@router.get("/gaps", response_model=List[LearningGapResponse], summary="List Learning Gaps")
async def list_learning_gaps(
    severity: Optional[str] = Query(None),
    unresolved_only: bool = Query(True),
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    from app.core.ownership import get_owned_teacher_or_none
    teacher = await get_owned_teacher_or_none(db, current_user)
    if teacher is None:
        return []
    # Only gaps reachable from this teacher's own assessment results.
    owned_ids_res = await db.execute(
        select(AssessmentResult.id).where(AssessmentResult.teacher_id == teacher.id)
    )
    owned_ids = {r for (r,) in owned_ids_res.all()}
    if not owned_ids:
        return []
    query = select(LearningGap).options(selectinload(LearningGap.remediations)).where(
        LearningGap.assessment_result_id.in_(owned_ids)
    )
    if unresolved_only:
        query = query.where(LearningGap.resolved_at.is_(None))
    if severity:
        query = query.where(LearningGap.severity == severity)

    res = await db.execute(query.order_by(LearningGap.detected_at.desc()))
    return res.scalars().all()


@router.post("/gaps/{gap_id}/resolve", summary="Mark Learning Gap as Resolved")
async def resolve_learning_gap(
    gap_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    from app.core.ownership import get_owned_teacher_or_none
    gap = await db.get(LearningGap, gap_id)
    if not gap:
        raise NotFoundException("LearningGap", gap_id)
    teacher = await get_owned_teacher_or_none(db, current_user)
    if teacher is None or gap.assessment_result_id is None:
        raise NotFoundException("LearningGap", gap_id)
    owner_res = await db.execute(
        select(AssessmentResult.id).where(
            AssessmentResult.id == gap.assessment_result_id,
            AssessmentResult.teacher_id == teacher.id,
        )
    )
    if owner_res.scalar_one_or_none() is None:
        raise NotFoundException("LearningGap", gap_id)

    gap.resolved_at = datetime.now(timezone.utc)
    await db.commit()
    return {"message": "Learning gap marked as resolved successfully", "gap_id": gap_id}
