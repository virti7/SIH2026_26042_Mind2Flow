from typing import Any, Dict, Optional
from sqlalchemy import JSON, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.models.base import TimestampMixin, UUIDMixin
from app.db.session import Base


class GeneratedContent(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "generated_content"

    learning_outcome_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("learning_outcomes.id", ondelete="SET NULL"), nullable=True)
    content_type: Mapped[str] = mapped_column(String(50), nullable=False)  # lesson, activity, worksheet, flashcard, assessment
    prompt_used: Mapped[str] = mapped_column(Text, nullable=False)
    raw_output: Mapped[Dict[str, Any]] = mapped_column(JSON, nullable=False)
    validated_output: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSON, nullable=True)
    status: Mapped[str] = mapped_column(String(50), default="GENERATED", index=True, nullable=False)  # GENERATED, REVIEW, APPROVED, PUBLISHED
    created_by: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    reviewed_by: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    review_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
