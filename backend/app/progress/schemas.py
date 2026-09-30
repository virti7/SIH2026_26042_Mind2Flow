from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class OutcomeProgressItem(BaseModel):
    learning_outcome_id: str
    outcome_code: str
    description: str
    status: str  # Achieved, Developing, Needs Support
    subject: str


class RemedialRecommendationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    recommendation_text: str
    strategy: str
    created_at: datetime


class LearningGapResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    student_name: str
    student_id: Optional[str] = None
    learning_outcome_id: str
    gap_description: str
    severity: str
    detected_at: datetime
    resolved_at: Optional[datetime] = None
    remediations: List[RemedialRecommendationResponse] = []



class LearnerProgressResponse(BaseModel):
    student_name: str
    student_id: Optional[str] = None
    overall_status: str  # Achieved, Developing, Needs Support
    total_assessments_taken: int
    average_score_percent: float
    outcomes: List[OutcomeProgressItem] = []
    active_gaps: List[LearningGapResponse] = []
