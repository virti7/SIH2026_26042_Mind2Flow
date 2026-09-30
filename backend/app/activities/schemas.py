from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class ActivityCreate(BaseModel):
    lesson_id: Optional[str] = None
    learning_outcome_id: Optional[str] = None
    title: str
    description: Optional[str] = None
    activity_type: str = "Interactive"
    duration_minutes: int = 15
    instructions: Optional[List[str]] = None
    materials_needed: Optional[List[str]] = None


class ActivityResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    lesson_id: Optional[str] = None
    learning_outcome_id: Optional[str] = None
    title: str
    description: Optional[str] = None
    activity_type: str
    duration_minutes: int
    instructions: Optional[List[str]] = None
    materials_needed: Optional[List[str]] = None
    created_at: datetime

