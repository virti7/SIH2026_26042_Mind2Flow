from typing import Any, Dict, Optional
from pydantic import BaseModel, EmailStr


class UserProfileResponse(BaseModel):
    user_id: str
    username: Optional[str] = None
    email: Optional[str] = None
    role: str
    school_id: Optional[str] = None
    school_name: Optional[str] = None
    teacher_id: Optional[str] = None
    teacher_name: Optional[str] = None
    preferred_language: Optional[str] = None
    metadata: Dict[str, Any] = {}


class ResolveIdentifierRequest(BaseModel):
    identifier: str


class ResolveIdentifierResponse(BaseModel):
    email: Optional[str] = None
    found: bool = False


class CheckUsernameRequest(BaseModel):
    username: str


class CheckUsernameResponse(BaseModel):
    available: bool
    message: Optional[str] = None


class RegisterTeacherRequest(BaseModel):
    user_id: str
    # Optional since email + password is the only login credential.
    # The teachers.username column stays nullable for legacy rows.
    username: Optional[str] = None
    name: str
    email: EmailStr
    # Optional profile fields (when supplied they are saved, otherwise
    # server defaults apply; school_name is never nulled by an update that
    # omits it, mirroring the username behavior).
    school_id: Optional[str] = None
    school_name: Optional[str] = None
    phone: Optional[str] = None
    designation: Optional[str] = None
    preferred_language: Optional[str] = None


class DevTokenRequest(BaseModel):
    user_id: str
    email: str
    role: str = "teacher"  # teacher, admin, content_reviewer, language_expert
    school_id: Optional[str] = None


class DevTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    role: str
