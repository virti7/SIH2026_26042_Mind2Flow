from typing import List, Optional
from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.models.base import TimestampMixin, UUIDMixin
from app.db.session import Base


class NipunGoal(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "nipun_goals"

    code: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)  # e.g., HW1, EC1, IL1
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    grade: Mapped[int] = mapped_column(Integer, index=True, nullable=False)  # 1, 2, 3

    competencies: Mapped[List["NipunCompetency"]] = relationship("NipunCompetency", back_populates="goal", cascade="all, delete-orphan")


class NipunCompetency(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "nipun_competencies"

    goal_id: Mapped[str] = mapped_column(String(36), ForeignKey("nipun_goals.id", ondelete="CASCADE"), nullable=False)
    code: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)  # e.g., C-1.1, C-2.3
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    domain: Mapped[str] = mapped_column(String(100), default="Foundational Literacy", nullable=False)  # Foundational Literacy / Numeracy

    goal: Mapped["NipunGoal"] = relationship("NipunGoal", back_populates="competencies")
    learning_outcomes: Mapped[List["LearningOutcome"]] = relationship("LearningOutcome", back_populates="competency", cascade="all, delete-orphan")


class LearningOutcome(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "learning_outcomes"

    competency_id: Mapped[str] = mapped_column(String(36), ForeignKey("nipun_competencies.id", ondelete="CASCADE"), nullable=False)
    code: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)  # e.g., LO-1.1.2
    description: Mapped[str] = mapped_column(Text, nullable=False)
    grade: Mapped[int] = mapped_column(Integer, index=True, nullable=False)
    subject: Mapped[str] = mapped_column(String(100), index=True, nullable=False)  # e.g. Hindi, Mathematics, EVS

    competency: Mapped["NipunCompetency"] = relationship("NipunCompetency", back_populates="learning_outcomes")
