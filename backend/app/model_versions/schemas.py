from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class ModelVersionCreate(BaseModel):
    model_name: str
    model_type: str  # asr, nmt, tts
    language_code: str
    version: str
    checksum: str
    size_bytes: int
    download_url: str
    compatibility: str = "onnx-runtime-1.16"
    release_status: str = "RELEASED"


class ModelVersionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    model_name: str
    model_type: str
    language_code: str
    version: str
    checksum: str
    size_bytes: int
    download_url: str
    compatibility: str
    release_status: str
    released_at: datetime
    created_at: datetime

