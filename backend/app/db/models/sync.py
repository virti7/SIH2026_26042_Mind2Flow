from datetime import datetime
from typing import Any, Dict, Optional
from sqlalchemy import JSON, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.models.base import TimestampMixin, UUIDMixin, utc_now
from app.db.session import Base


class SyncQueueLog(Base, UUIDMixin):
    __tablename__ = "sync_logs"

    operation_id: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    device_id: Mapped[str] = mapped_column(String(100), index=True, nullable=False)
    teacher_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("teachers.id", ondelete="SET NULL"), nullable=True)

    entity_type: Mapped[str] = mapped_column(String(100), index=True, nullable=False)  # assessment_result, lesson, saved_material, feedback
    entity_id: Mapped[str] = mapped_column(String(100), nullable=False)
    operation: Mapped[str] = mapped_column(String(20), nullable=False)  # CREATE, UPDATE, DELETE
    payload: Mapped[Dict[str, Any]] = mapped_column(JSON, nullable=False)

    status: Mapped[str] = mapped_column(String(50), default="SUCCESS", nullable=False)  # SUCCESS, FAILED, CONFLICT
    error_details: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    received_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, nullable=False)
    processed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, nullable=False)


class DeviceInfo(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "devices"

    device_id: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    teacher_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("teachers.id", ondelete="SET NULL"), nullable=True)
    app_version: Mapped[str] = mapped_column(String(50), default="1.0.0", nullable=False)
    android_version: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    installed_language_packs: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSON, nullable=True)
    installed_models: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSON, nullable=True)
    last_sync_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, nullable=False)


class IdempotencyRecord(Base, UUIDMixin):
    __tablename__ = "idempotency_records"

    key: Mapped[str] = mapped_column(String(128), unique=True, index=True, nullable=False)
    response_payload: Mapped[Dict[str, Any]] = mapped_column(JSON, nullable=False)
    status_code: Mapped[int] = mapped_column(Integer, default=200, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, nullable=False)
    expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
