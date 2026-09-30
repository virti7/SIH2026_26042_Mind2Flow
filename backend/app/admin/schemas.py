from typing import Optional
from pydantic import BaseModel


class PackPublicationRequest(BaseModel):
    pack_id: str
    release_status: str = "RELEASED"  # DRAFT, RELEASED, DEPRECATED


class AdminActionResponse(BaseModel):
    success: bool
    message: str
