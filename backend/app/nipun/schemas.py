from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class NipunGoalCreate(BaseModel):
    code: str
    title: str
    description: Optional[str] = None
    grade: int


class NipunGoalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    code: str
    title: str
    description: Optional[str] = None
    grade: int
    created_at: datetime


class NipunCompetencyCreate(BaseModel):
    goal_id: str
    code: str
    title: str
    description: Optional[str] = None
    domain: str = "Foundational Literacy"


class NipunCompetencyResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    goal_id: str
    code: str
    title: str
    description: Optional[str] = None
    domain: str
    created_at: datetime


class LearningOutcomeCreate(BaseModel):
    competency_id: str
    code: str
    description: str
    grade: int
    subject: str


class LearningOutcomeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    competency_id: str
    code: str
    description: str
    grade: int
    subject: str
    created_at: datetime

