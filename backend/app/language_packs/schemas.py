from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict


class LanguagePackCreate(BaseModel):
    language_code: str  # ho, unr, sat, hi
    version: str  # "1.0.0"
    model_version: str = "1.0.0"
    content_version: str = "1.0.0"
    package_size: int = 0
    checksum: str  # sha256
    download_url: str
    release_status: str = "RELEASED"  # DRAFT, RELEASED, DEPRECATED
    compatible_app_version: str = ">=1.0.0"
    min_android_version: int = 24


class LanguagePackResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    language_code: str
    version: str
    model_version: str
    content_version: str
    package_size: int
    checksum: str
    download_url: str
    release_status: str
    compatible_app_version: str
    min_android_version: int
    created_at: datetime
    updated_at: datetime



class LanguagePackManifest(BaseModel):
    pack_id: str
    language: str
    version: str
    model_version: str
    content_version: str
    package_size_bytes: int
    checksum_sha256: str
    download_url: str
    release_status: str
    compatible_app_version: str
    min_android_version: int
    assets: Dict[str, Any] = {}
    created_at: datetime


class LanguagePackVersionCheck(BaseModel):
    language: str
    current_server_version: str
    client_version: Optional[str] = None
    update_available: bool
    download_url: Optional[str] = None
    checksum: Optional[str] = None
    package_size_bytes: Optional[int] = None
