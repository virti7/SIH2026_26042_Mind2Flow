from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class VerifiedPhraseCreate(BaseModel):
    source_text: str
    translated_text: str
    source_language_id: Optional[str] = None
    target_language_id: Optional[str] = None
    category: str = "Classroom Instructions"
    domain: str = "Education"
    verification_status: str = "VERIFIED"


class VerifiedPhraseResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    source_text: str
    translated_text: str
    category: str
    domain: str
    verification_status: str
    verified_by: Optional[str] = None
    version: int
    created_at: datetime

