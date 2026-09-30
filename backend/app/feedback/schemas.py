from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class TranslationFeedbackCreate(BaseModel):
    source_text: str
    translated_text: str
    suggested_correction: Optional[str] = None
    feedback_type: str = "wrong_meaning"  # wrong_meaning, unnatural_wording, pronunciation_issue, other
    audio_url: Optional[str] = None
    target_language: str = "Ho"
    local_id: Optional[str] = None


class TranslationFeedbackResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: Optional[str] = None
    source_text: str
    translated_text: str
    suggested_correction: Optional[str] = None
    feedback_type: str
    audio_url: Optional[str] = None
    created_at: datetime


class ReviewQueueItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    feedback_id: Optional[str] = None
    source_text: str
    candidate_translation: str
    target_language: str
    status: str  # PENDING, UNDER_REVIEW, APPROVED, REJECTED
    priority: str
    notes: Optional[str] = None
    reviewer_id: Optional[str] = None
    reviewed_at: Optional[datetime] = None
    created_at: datetime



class ReviewActionRequest(BaseModel):
    status: str  # APPROVED, REJECTED, UNDER_REVIEW
    notes: Optional[str] = None
    verified_translation: Optional[str] = None
    promote_to_verified_phrases: bool = True
