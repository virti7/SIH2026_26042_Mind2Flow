from typing import Any, Dict, Optional
from sqlalchemy import JSON, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.models.base import SoftDeleteMixin, TimestampMixin, UUIDMixin
from app.db.session import Base


class Worksheet(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "worksheets"

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    grade: Mapped[int] = mapped_column(Integer, index=True, nullable=False)
    subject: Mapped[str] = mapped_column(String(100), index=True, nullable=False)
    file_path: Mapped[str] = mapped_column(String(500), nullable=False)
    file_size: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    format: Mapped[str] = mapped_column(String(20), default="pdf", nullable=False)

    learning_outcome_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("learning_outcomes.id", ondelete="SET NULL"), nullable=True)
    language_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("languages.id", ondelete="SET NULL"), nullable=True)


class Flashcard(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "flashcards"

    deck_name: Mapped[str] = mapped_column(String(100), index=True, nullable=False)
    front_text: Mapped[str] = mapped_column(Text, nullable=False)
    back_text: Mapped[str] = mapped_column(Text, nullable=False)
    image_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    audio_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    grade: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    language_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("languages.id", ondelete="SET NULL"), nullable=True)


class SavedMaterial(Base, UUIDMixin, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "saved_materials"

    local_id: Mapped[Optional[str]] = mapped_column(String(100), index=True, nullable=True)
    teacher_id: Mapped[str] = mapped_column(String(36), ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    material_type: Mapped[str] = mapped_column(String(50), default="worksheet", nullable=False)  # worksheet, lesson_plan, flashcard
    payload: Mapped[Dict[str, Any]] = mapped_column(JSON, nullable=False)
