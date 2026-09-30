from datetime import datetime
from typing import Any, Dict, Optional
from pydantic import BaseModel, ConfigDict


class WorksheetCreate(BaseModel):
    title: str
    grade: int
    subject: str
    file_path: str
    file_size: int = 0
    format: str = "pdf"
    learning_outcome_id: Optional[str] = None
    language_id: Optional[str] = None


class WorksheetResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    grade: int
    subject: str
    file_path: str
    file_size: int
    format: str
    learning_outcome_id: Optional[str] = None
    language_id: Optional[str] = None
    created_at: datetime


class FlashcardCreate(BaseModel):
    deck_name: str
    front_text: str
    back_text: str
    image_url: Optional[str] = None
    audio_url: Optional[str] = None
    grade: int = 1
    language_id: Optional[str] = None


class FlashcardResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    deck_name: str
    front_text: str
    back_text: str
    image_url: Optional[str] = None
    audio_url: Optional[str] = None
    grade: int
    language_id: Optional[str] = None
    created_at: datetime


class FlashcardDeckResponse(BaseModel):
    deck_name: str
    card_count: int
    grade: int = 1
    language_id: Optional[str] = None
    created_at: Optional[datetime] = None


class FlashcardDeckDetailResponse(BaseModel):
    deck_name: str
    grade: int = 1
    language_id: Optional[str] = None
    cards: list[FlashcardResponse]


class SavedMaterialCreate(BaseModel):
    title: str
    material_type: str = "worksheet"
    payload: Dict[str, Any]
    local_id: Optional[str] = None


class SavedMaterialResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str
    title: str
    material_type: str
    payload: Dict[str, Any]
    local_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime

