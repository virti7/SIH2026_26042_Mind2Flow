from datetime import datetime
from typing import Any, Dict, List, Optional
from sqlalchemy import JSON, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.models.base import SoftDeleteMixin, TimestampMixin, UUIDMixin, utc_now
from app.db.session import Base


class Assessment(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "assessments"

    lesson_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("lessons.id", ondelete="SET NULL"), nullable=True)
    learning_outcome_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("learning_outcomes.id", ondelete="SET NULL"), nullable=True)

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    grade: Mapped[int] = mapped_column(Integer, index=True, nullable=False)
    subject: Mapped[str] = mapped_column(String(100), index=True, nullable=False)
    total_marks: Mapped[int] = mapped_column(Integer, default=10, nullable=False)
    passing_marks: Mapped[int] = mapped_column(Integer, default=6, nullable=False)

    questions: Mapped[List["AssessmentQuestion"]] = relationship("AssessmentQuestion", back_populates="assessment", cascade="all, delete-orphan")
    results: Mapped[List["AssessmentResult"]] = relationship("AssessmentResult", back_populates="assessment", cascade="all, delete-orphan")


class AssessmentQuestion(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "assessment_questions"

    assessment_id: Mapped[str] = mapped_column(String(36), ForeignKey("assessments.id", ondelete="CASCADE"), nullable=False)
    question_text: Mapped[str] = mapped_column(Text, nullable=False)
    question_type: Mapped[str] = mapped_column(String(50), default="multiple_choice", nullable=False)  # multiple_choice, oral, practical
    options: Mapped[Optional[List[str]]] = mapped_column(JSON, nullable=True)
    correct_answer: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    marks: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    assessment: Mapped["Assessment"] = relationship("Assessment", back_populates="questions")


class AssessmentResult(Base, UUIDMixin, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "assessment_results"

    local_id: Mapped[Optional[str]] = mapped_column(String(100), index=True, nullable=True)
    assessment_id: Mapped[str] = mapped_column(String(36), ForeignKey("assessments.id", ondelete="CASCADE"), nullable=False)
    teacher_id: Mapped[str] = mapped_column(String(36), ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False)

    student_name: Mapped[str] = mapped_column(String(255), nullable=False)
    student_id: Mapped[Optional[str]] = mapped_column(String(100), index=True, nullable=True)
    score: Mapped[float] = mapped_column(Float, nullable=False)
    max_score: Mapped[float] = mapped_column(Float, default=10.0, nullable=False)
    status: Mapped[str] = mapped_column(String(50), default="Achieved", nullable=False)  # Achieved, Developing, Needs Support

    assessment: Mapped["Assessment"] = relationship("Assessment", back_populates="results")
    learning_gaps: Mapped[List["LearningGap"]] = relationship("LearningGap", back_populates="assessment_result", cascade="all, delete-orphan")


class LearningGap(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "learning_gaps"

    student_name: Mapped[str] = mapped_column(String(255), index=True, nullable=False)
    student_id: Mapped[Optional[str]] = mapped_column(String(100), index=True, nullable=True)
    learning_outcome_id: Mapped[str] = mapped_column(String(36), ForeignKey("learning_outcomes.id", ondelete="CASCADE"), nullable=False)
    assessment_result_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("assessment_results.id", ondelete="SET NULL"), nullable=True)

    gap_description: Mapped[str] = mapped_column(Text, nullable=False)
    severity: Mapped[str] = mapped_column(String(50), default="Medium", nullable=False)  # Low, Medium, High
    detected_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, nullable=False)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    assessment_result: Mapped[Optional["AssessmentResult"]] = relationship("AssessmentResult", back_populates="learning_gaps")
    remediations: Mapped[List["RemedialRecommendation"]] = relationship("RemedialRecommendation", back_populates="learning_gap", cascade="all, delete-orphan")


class RemedialRecommendation(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "remedial_recommendations"

    learning_gap_id: Mapped[str] = mapped_column(String(36), ForeignKey("learning_gaps.id", ondelete="CASCADE"), nullable=False)
    recommendation_text: Mapped[str] = mapped_column(Text, nullable=False)
    suggested_activity_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("activities.id", ondelete="SET NULL"), nullable=True)
    strategy: Mapped[str] = mapped_column(String(100), default="Peer-learning", nullable=False)  # Peer-learning, Multi-sensory, Drill, Storytelling

    learning_gap: Mapped["LearningGap"] = relationship("LearningGap", back_populates="remediations")
