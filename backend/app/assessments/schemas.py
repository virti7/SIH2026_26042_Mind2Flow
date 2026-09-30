from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict


class QuestionCreate(BaseModel):
    question_text: str
    question_type: str = "multiple_choice"
    options: Optional[List[str]] = None
    correct_answer: Optional[str] = None
    marks: int = 1


class QuestionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    assessment_id: str
    question_text: str
    question_type: str
    options: Optional[List[str]] = None
    correct_answer: Optional[str] = None
    marks: int



class AssessmentCreate(BaseModel):
    title: str
    grade: int
    subject: str
    lesson_id: Optional[str] = None
    learning_outcome_id: Optional[str] = None
    total_marks: int = 10
    passing_marks: int = 6
    questions: Optional[List[QuestionCreate]] = None


class AssessmentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    grade: int
    subject: str
    lesson_id: Optional[str] = None
    learning_outcome_id: Optional[str] = None
    total_marks: int
    passing_marks: int
    created_at: datetime
    questions: List[QuestionResponse] = []


class AssessmentSubmissionCreate(BaseModel):
    student_name: str
    student_id: Optional[str] = None
    score: float
    max_score: float = 10.0
    status: Optional[str] = None  # Achieved, Developing, Needs Support (auto-calculated if None)
    local_id: Optional[str] = None


class AssessmentResultResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    local_id: Optional[str] = None
    assessment_id: str
    teacher_id: str
    student_name: str
    student_id: Optional[str] = None
    score: float
    max_score: float
    status: str
    created_at: datetime

