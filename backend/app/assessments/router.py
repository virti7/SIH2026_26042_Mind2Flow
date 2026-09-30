from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.assessments.schemas import (
    AssessmentCreate,
    AssessmentResponse,
    AssessmentResultResponse,
    AssessmentSubmissionCreate,
    QuestionCreate,
    QuestionResponse,
)
from app.core.dependencies import get_current_user, get_db
from app.core.exceptions import NotFoundException
from app.core.security import UserContext
from app.db.models.assessment import (
    Assessment,
    AssessmentQuestion,
    AssessmentResult,
    LearningGap,
    RemedialRecommendation,
)
from app.db.models.school import Teacher

router = APIRouter(prefix="/assessments", tags=["Assessments"])


@router.get("", response_model=List[AssessmentResponse], summary="List Assessments")
async def list_assessments(
    grade: Optional[int] = Query(None),
    subject: Optional[str] = Query(None),
    learning_outcome_id: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    query = select(Assessment).options(selectinload(Assessment.questions))
    if grade is not None:
        query = query.where(Assessment.grade == grade)
    if subject:
        query = query.where(Assessment.subject == subject)
    if learning_outcome_id:
        query = query.where(Assessment.learning_outcome_id == learning_outcome_id)

    res = await db.execute(query.order_by(Assessment.created_at.desc()))
    return res.scalars().all()


@router.post("", response_model=AssessmentResponse, status_code=status.HTTP_201_CREATED, summary="Create Assessment")
async def create_assessment(
    req: AssessmentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    assessment = Assessment(
        title=req.title,
        grade=req.grade,
        subject=req.subject,
        lesson_id=req.lesson_id,
        learning_outcome_id=req.learning_outcome_id,
        total_marks=req.total_marks,
        passing_marks=req.passing_marks,
    )
    db.add(assessment)
    await db.flush()

    if req.questions:
        for q in req.questions:
            question = AssessmentQuestion(
                assessment_id=assessment.id,
                question_text=q.question_text,
                question_type=q.question_type,
                options=q.options,
                correct_answer=q.correct_answer,
                marks=q.marks,
            )
            db.add(question)

    await db.commit()
    res = await db.execute(
        select(Assessment)
        .options(selectinload(Assessment.questions))
        .where(Assessment.id == assessment.id)
    )
    return res.scalar_one()


@router.get("/{id}", response_model=AssessmentResponse, summary="Get Assessment by ID")
async def get_assessment(
    id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    res = await db.execute(
        select(Assessment)
        .options(selectinload(Assessment.questions))
        .where(Assessment.id == id)
    )
    assessment = res.scalar_one_or_none()
    if not assessment:
        raise NotFoundException("Assessment", id)
    return assessment


@router.post("/{id}/questions", response_model=QuestionResponse, summary="Add Question to Assessment")
async def add_question(
    id: str,
    req: QuestionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    assessment = await db.get(Assessment, id)
    if not assessment:
        raise NotFoundException("Assessment", id)

    question = AssessmentQuestion(
        assessment_id=id,
        question_text=req.question_text,
        question_type=req.question_type,
        options=req.options,
        correct_answer=req.correct_answer,
        marks=req.marks,
    )
    db.add(question)
    await db.commit()
    await db.refresh(question)
    return question


@router.post("/{id}/submit", response_model=AssessmentResultResponse, summary="Submit Student Assessment Result")
async def submit_assessment(
    id: str,
    req: AssessmentSubmissionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    assessment = await db.get(Assessment, id)
    if not assessment:
        raise NotFoundException("Assessment", id)

    res = await db.execute(select(Teacher).where(Teacher.user_id == current_user.user_id))
    teacher = res.scalar_one_or_none()
    if teacher is None:
        from app.core.ownership import require_teacher as _require_teacher_sub
        teacher = await _require_teacher_sub(db, current_user)
    teacher_id = teacher.id

    # Compute status if not supplied
    ratio = req.score / req.max_score if req.max_score > 0 else 0
    if req.status:
        result_status = req.status
    elif ratio >= 0.75:
        result_status = "Achieved"
    elif ratio >= 0.50:
        result_status = "Developing"
    else:
        result_status = "Needs Support"

    result = AssessmentResult(
        local_id=req.local_id,
        assessment_id=id,
        teacher_id=teacher_id,
        student_name=req.student_name,
        student_id=req.student_id,
        score=req.score,
        max_score=req.max_score,
        status=result_status,
    )
    db.add(result)
    await db.flush()

    # If Needs Support or Developing and learning outcome exists, track learning gap
    if result_status == "Needs Support" and assessment.learning_outcome_id:
        gap = LearningGap(
            student_name=req.student_name,
            student_id=req.student_id,
            learning_outcome_id=assessment.learning_outcome_id,
            assessment_result_id=result.id,
            gap_description=f"Student scored {req.score}/{req.max_score} in '{assessment.title}'. Foundational reinforcement required.",
            severity="High" if ratio < 0.3 else "Medium",
        )
        db.add(gap)
        await db.flush()

        remedial = RemedialRecommendation(
            learning_gap_id=gap.id,
            recommendation_text=f"Targeted multilingual visual drill and peer practice for {assessment.title}",
            strategy="Peer-learning",
        )
        db.add(remedial)

    await db.commit()
    await db.refresh(result)
    return result


@router.get("/{id}/results", response_model=List[AssessmentResultResponse], summary="List Results for Assessment")
async def list_assessment_results(
    id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    from app.core.ownership import require_teacher as _require_teacher_res
    teacher = await _require_teacher_res(db, current_user)
    res = await db.execute(
        select(AssessmentResult)
        .where(
            AssessmentResult.assessment_id == id,
            AssessmentResult.teacher_id == teacher.id,
        )
        .order_by(AssessmentResult.created_at.desc())
    )
    return res.scalars().all()
