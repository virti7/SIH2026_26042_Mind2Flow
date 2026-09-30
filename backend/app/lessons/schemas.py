from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict


class TeacherMoveItem(BaseModel):
    step: int
    title: str
    description: str
    duration_minutes: int = 5
    prompt_text: Optional[str] = None


class LessonCreate(BaseModel):
    title: str
    topic_id: Optional[str] = None
    learning_outcome_id: Optional[str] = None
    objective: Optional[str] = None
    prerequisite: Optional[str] = None
    teacher_moves: Optional[List[Dict[str, Any]]] = None
    remediation_info: Optional[Dict[str, Any]] = None
    grade: int
    subject: str
    language: str = "Hindi"
    version: int = 1
    local_id: Optional[str] = None


class LessonUpdate(BaseModel):
    title: Optional[str] = None
    topic_id: Optional[str] = None
    learning_outcome_id: Optional[str] = None
    objective: Optional[str] = None
    prerequisite: Optional[str] = None
    teacher_moves: Optional[List[Dict[str, Any]]] = None
    remediation_info: Optional[Dict[str, Any]] = None
    grade: Optional[int] = None
    subject: Optional[str] = None
    language: Optional[str] = None
    version: Optional[int] = None
    is_published: Optional[bool] = None


class LessonResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    local_id: Optional[str] = None
    topic_id: Optional[str] = None
    learning_outcome_id: Optional[str] = None
    teacher_id: Optional[str] = None
    title: str
    objective: Optional[str] = None
    prerequisite: Optional[str] = None
    teacher_moves: Optional[List[Dict[str, Any]]] = None
    remediation_info: Optional[Dict[str, Any]] = None
    grade: int
    subject: str
    language: str
    version: int
    is_published: bool
    created_at: datetime
    updated_at: datetime


class DeliveryRecordCreate(BaseModel):
    completed_step_index: int
    total_steps: int = 4
    notes: Optional[str] = None
    classroom_id: Optional[str] = None
    local_id: Optional[str] = None


class DeliveryRecordResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    lesson_id: str
    teacher_id: str
    classroom_id: Optional[str] = None
    completed_step_index: int
    total_steps: int
    notes: Optional[str] = None
    local_id: Optional[str] = None
    created_at: datetime

