from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class SchoolCreate(BaseModel):
    name: str
    code: str
    block: Optional[str] = None
    district: Optional[str] = None
    state: str = "Jharkhand"


class SchoolResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    code: str
    block: Optional[str] = None
    district: Optional[str] = None
    state: str
    created_at: datetime
    updated_at: datetime

