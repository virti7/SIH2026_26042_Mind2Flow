from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, EmailStr


class TeacherProfileUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    designation: Optional[str] = None
    preferred_language: Optional[str] = None


class TeacherCreate(BaseModel):
    user_id: str
    school_id: Optional[str] = None
    name: str
    email: EmailStr
    phone: Optional[str] = None
    designation: str = "Primary Teacher"
    preferred_language: str = "Hindi"


class TeacherResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    school_id: Optional[str] = None
    name: str
    email: str
    phone: Optional[str] = None
    designation: str
    preferred_language: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

