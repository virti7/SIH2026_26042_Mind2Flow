"""Data models, configuration, and exception classes for Supabase publishing."""
import os
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional


class PublicationState(str, Enum):
    """Publication lifecycle state."""
    PENDING = "pending"
    UPLOADING = "uploading"
    PUBLISHED = "published"
    FAILED = "failed"
    ALREADY_PUBLISHED = "already_published"


class PublishError(Exception):
    """Base exception for all publication failures."""
    pass


class UnapprovedContentError(PublishError):
    """Raised when an attempt is made to publish content that is not human-approved."""
    pass


class ValidationFailureError(PublishError):
    """Raised when content failed machine validation or schema checks."""
    pass


class IntegrityVerificationError(PublishError):
    """Raised when content SHA256 does not match the review record hash."""
    pass


class ConflictingPublicationError(PublishError):
    """Raised when content with the same ID already exists with different content."""
    pass


class StorageUploadError(PublishError):
    """Raised when asset upload to Supabase Storage fails."""
    pass


class DatabaseOperationError(PublishError):
    """Raised when database query or mutation fails."""
    pass


@dataclass
class PublishConfig:
    """Configuration options for Supabase publication."""
    supabase_url: Optional[str] = None
    supabase_service_role_key: Optional[str] = None
    content_bucket: str = "content"
    dry_run: bool = False
    mock: bool = False

    @classmethod
    def from_env(cls, dry_run: bool = False, mock: bool = False) -> "PublishConfig":
        """Load configuration from environment variables."""
        return cls(
            supabase_url=os.getenv("SUPABASE_URL"),
            supabase_service_role_key=os.getenv("SUPABASE_SERVICE_ROLE_KEY"),
            content_bucket=os.getenv("STORAGE_BUCKET_CONTENT", "content"),
            dry_run=dry_run,
            mock=mock or (os.getenv("PUBLISHER_MOCK_MODE", "").lower() in ("true", "1")),
        )


@dataclass
class PublicationResult:
    """Structured result returned by the publisher."""
    content_id: str
    content_type: str
    status: str  # published, already_published, dry_run, failed
    is_idempotent: bool = False
    storage_paths: List[str] = field(default_factory=list)
    record_ids: Dict[str, Any] = field(default_factory=dict)
    published_at: Optional[str] = None
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    dry_run: bool = False
    details: Dict[str, Any] = field(default_factory=dict)

    @property
    def is_success(self) -> bool:
        return self.status in (PublicationState.PUBLISHED.value, PublicationState.ALREADY_PUBLISHED.value, "dry_run")

    def to_dict(self) -> Dict[str, Any]:
        return {
            "content_id": self.content_id,
            "content_type": self.content_type,
            "status": self.status,
            "is_idempotent": self.is_idempotent,
            "storage_paths": self.storage_paths,
            "record_ids": self.record_ids,
            "published_at": self.published_at,
            "errors": self.errors,
            "warnings": self.warnings,
            "dry_run": self.dry_run,
            "details": self.details,
        }
