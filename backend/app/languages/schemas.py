from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class LanguageCreate(BaseModel):
    code: str  # e.g., 'ho', 'unr', 'sat', 'hi'
    name: str  # e.g., 'Ho', 'Mundari', 'Santali', 'Hindi'
    script: Optional[str] = None  # e.g., 'Warang Chiti', 'Ol Chiki'
    is_active: bool = True


class LanguageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    code: str
    name: str
    script: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

