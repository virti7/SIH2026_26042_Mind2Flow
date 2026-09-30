from datetime import datetime
from typing import Optional
from sqlalchemy import DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.models.base import TimestampMixin, UUIDMixin
from app.db.session import Base


class TranslationFeedback(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "translation_feedback"

    local_id: Mapped[Optional[str]] = mapped_column(String(100), index=True, nullable=True)
    teacher_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("teachers.id", ondelete="SET NULL"), nullable=True)
    source_language_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("languages.id", ondelete="SET NULL"), nullable=True)
    target_language_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("languages.id", ondelete="SET NULL"), nullable=True)

    source_text: Mapped[str] = mapped_column(Text, nullable=False)
    translated_text: Mapped[str] = mapped_column(Text, nullable=False)
    suggested_correction: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    feedback_type: Mapped[str] = mapped_column(String(50), default="wrong_meaning", nullable=False)  # wrong_meaning, unnatural_wording, pronunciation_issue, other
    audio_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)

    review_item: Mapped[Optional["ReviewQueueItem"]] = relationship("ReviewQueueItem", back_populates="feedback", uselist=False)


class ReviewQueueItem(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "review_queue"

    feedback_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("translation_feedback.id", ondelete="SET NULL"), nullable=True)
    source_text: Mapped[str] = mapped_column(Text, nullable=False)
    candidate_translation: Mapped[str] = mapped_column(Text, nullable=False)
    target_language: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[str] = mapped_column(String(50), default="PENDING", index=True, nullable=False)  # PENDING, UNDER_REVIEW, APPROVED, REJECTED
    priority: Mapped[str] = mapped_column(String(20), default="MEDIUM", nullable=False)  # LOW, MEDIUM, HIGH
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    reviewer_id: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    reviewed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    feedback: Mapped[Optional["TranslationFeedback"]] = relationship("TranslationFeedback", back_populates="review_item")
