from typing import Any, Dict, List, Optional
from sqlalchemy import JSON, Boolean, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.models.base import SoftDeleteMixin, TimestampMixin, UUIDMixin
from app.db.session import Base


class Subject(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "subjects"

    code: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    icon: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    grade: Mapped[int] = mapped_column(Integer, index=True, nullable=False)

    topics: Mapped[List["Topic"]] = relationship("Topic", back_populates="subject_rel", cascade="all, delete-orphan")


class Topic(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "topics"

    subject_id: Mapped[str] = mapped_column(String(36), ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    order_index: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    subject_rel: Mapped["Subject"] = relationship("Subject", back_populates="topics")
    lessons: Mapped[List["Lesson"]] = relationship("Lesson", back_populates="topic_rel", cascade="all, delete-orphan")


class Lesson(Base, UUIDMixin, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "lessons"

    local_id: Mapped[Optional[str]] = mapped_column(String(100), index=True, nullable=True)  # client SQLite ID
    topic_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("topics.id", ondelete="SET NULL"), nullable=True)
    learning_outcome_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("learning_outcomes.id", ondelete="SET NULL"), nullable=True)
    teacher_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("teachers.id", ondelete="SET NULL"), nullable=True)

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    objective: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    prerequisite: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    teacher_moves: Mapped[Optional[List[Dict[str, Any]]]] = mapped_column(JSON, nullable=True)
    remediation_info: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSON, nullable=True)

    grade: Mapped[int] = mapped_column(Integer, index=True, nullable=False)
    subject: Mapped[str] = mapped_column(String(100), index=True, nullable=False)
    language: Mapped[str] = mapped_column(String(50), default="Hindi", nullable=False)
    version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    is_published: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    topic_rel: Mapped[Optional["Topic"]] = relationship("Topic", back_populates="lessons")
    activities: Mapped[List["Activity"]] = relationship("Activity", back_populates="lesson", cascade="all, delete-orphan")


class Activity(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "activities"

    lesson_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("lessons.id", ondelete="CASCADE"), nullable=True)
    learning_outcome_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("learning_outcomes.id", ondelete="SET NULL"), nullable=True)

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    activity_type: Mapped[str] = mapped_column(String(50), default="Interactive", nullable=False)  # Story, Game, Drill, Rhyme
    duration_minutes: Mapped[int] = mapped_column(Integer, default=15, nullable=False)
    instructions: Mapped[Optional[List[str]]] = mapped_column(JSON, nullable=True)
    materials_needed: Mapped[Optional[List[str]]] = mapped_column(JSON, nullable=True)

    lesson: Mapped[Optional["Lesson"]] = relationship("Lesson", back_populates="activities")


class LessonDeliveryRecord(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "lesson_delivery_records"

    local_id: Mapped[Optional[str]] = mapped_column(String(100), index=True, nullable=True)
    lesson_id: Mapped[str] = mapped_column(String(36), ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False)
    teacher_id: Mapped[str] = mapped_column(String(36), ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False)
    classroom_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("classrooms.id", ondelete="SET NULL"), nullable=True)

    completed_step_index: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    total_steps: Mapped[int] = mapped_column(Integer, default=4, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
