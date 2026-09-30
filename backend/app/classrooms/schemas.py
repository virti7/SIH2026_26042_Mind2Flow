from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class StudentLanguageGroupCreate(BaseModel):
    language_id: str
    student_count: int = 0


class StudentLanguageGroupResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    language_id: str
    student_count: int


class ClassroomCreate(BaseModel):
    school_id: str
    teacher_id: Optional[str] = None
    grade: int
    section: str = "A"
    room_number: Optional[str] = None
    academic_year: str = "2026-2027"
    language_groups: Optional[List[StudentLanguageGroupCreate]] = None


class ClassroomResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    school_id: str
    teacher_id: Optional[str] = None
    grade: int
    section: str
    room_number: Optional[str] = None
    academic_year: str
    created_at: datetime
    updated_at: datetime
    language_groups: List[StudentLanguageGroupResponse] = []

