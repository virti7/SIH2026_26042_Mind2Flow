from datetime import datetime
from typing import Optional
from sqlalchemy import BigInteger, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.models.base import TimestampMixin, UUIDMixin, utc_now
from app.db.session import Base


class LanguagePack(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "language_packs"

    language_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("languages.id", ondelete="SET NULL"), nullable=True)
    language_code: Mapped[str] = mapped_column(String(20), index=True, nullable=False)  # ho, unr, sat, hi
    version: Mapped[str] = mapped_column(String(50), nullable=False)  # e.g. "1.2.0"
    model_version: Mapped[str] = mapped_column(String(50), default="1.0.0", nullable=False)
    content_version: Mapped[str] = mapped_column(String(50), default="1.0.0", nullable=False)
    package_size: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)  # bytes
    checksum: Mapped[str] = mapped_column(String(128), nullable=False)  # sha256 hash
    download_url: Mapped[str] = mapped_column(String(500), nullable=False)
    release_status: Mapped[str] = mapped_column(String(50), default="RELEASED", nullable=False)  # DRAFT, RELEASED, DEPRECATED
    compatible_app_version: Mapped[str] = mapped_column(String(50), default=">=1.0.0", nullable=False)
    min_android_version: Mapped[int] = mapped_column(Integer, default=24, nullable=False)


class ModelVersion(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "model_versions"

    model_name: Mapped[str] = mapped_column(String(100), index=True, nullable=False)  # e.g. "nipun-nmt-ho"
    model_type: Mapped[str] = mapped_column(String(50), index=True, nullable=False)  # asr, nmt, tts
    language_code: Mapped[str] = mapped_column(String(20), index=True, nullable=False)
    version: Mapped[str] = mapped_column(String(50), nullable=False)
    checksum: Mapped[str] = mapped_column(String(128), nullable=False)
    size_bytes: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)
    download_url: Mapped[str] = mapped_column(String(500), nullable=False)
    compatibility: Mapped[str] = mapped_column(String(100), default="onxx-runtime-1.16", nullable=False)
    release_status: Mapped[str] = mapped_column(String(50), default="RELEASED", nullable=False)
    released_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, nullable=False)


class VerifiedPhrase(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "verified_phrases"

    source_language_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("languages.id", ondelete="SET NULL"), nullable=True)
    target_language_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("languages.id", ondelete="SET NULL"), nullable=True)

    source_text: Mapped[str] = mapped_column(Text, nullable=False)
    translated_text: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str] = mapped_column(String(100), default="Classroom Instructions", nullable=False)
    domain: Mapped[str] = mapped_column(String(100), default="Education", nullable=False)
    verification_status: Mapped[str] = mapped_column(String(50), default="VERIFIED", nullable=False)  # PENDING, VERIFIED, REJECTED
    verified_by: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
