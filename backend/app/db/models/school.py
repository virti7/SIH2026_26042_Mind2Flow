from typing import List, Optional
from sqlalchemy import Boolean, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.models.base import TimestampMixin, UUIDMixin
from app.db.session import Base


class School(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "schools"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    code: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    block: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    district: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    state: Mapped[str] = mapped_column(String(100), default="Jharkhand", nullable=False)

    teachers: Mapped[List["Teacher"]] = relationship("Teacher", back_populates="school", cascade="all, delete-orphan")
    classrooms: Mapped[List["Classroom"]] = relationship("Classroom", back_populates="school", cascade="all, delete-orphan")


class Teacher(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "teachers"

    # User ID links to Supabase Auth `sub` claim
    user_id: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    # Username is nullable to preserve legacy rows (NULL until legitimately set).
    # Length matches real Supabase schema VARCHAR(255).
    # Case-insensitive uniqueness is enforced by the partial functional index
    # uq_teachers_username_lower ON (LOWER(BTRIM(username)))
    # WHERE username IS NOT NULL AND BTRIM(username) <> ''
    # (see Alembic migration), NOT by a column-level UNIQUE constraint, so that
    # multiple NULLs are allowed and 'Teacher01' vs 'teacher01' collide.
    username: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    school_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("schools.id", ondelete="SET NULL"), nullable=True)
    # Free-text school name captured at signup (e.g. "Govt. Primary School, Torpa").
    # Additional profile information only: school_id remains the relational link
    # and is never replaced by this column. Nullable so existing rows keep working.
    school_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    phone: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    designation: Mapped[str] = mapped_column(String(100), default="Primary Teacher", nullable=False)
    preferred_language: Mapped[str] = mapped_column(String(50), default="Hindi", nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    school: Mapped[Optional["School"]] = relationship("School", back_populates="teachers")
    classrooms: Mapped[List["Classroom"]] = relationship("Classroom", back_populates="teacher")


class Classroom(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "classrooms"

    school_id: Mapped[str] = mapped_column(String(36), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False)
    teacher_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("teachers.id", ondelete="SET NULL"), nullable=True)
    grade: Mapped[int] = mapped_column(Integer, nullable=False)  # 1, 2, 3, etc.
    section: Mapped[str] = mapped_column(String(10), default="A", nullable=False)
    room_number: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    academic_year: Mapped[str] = mapped_column(String(20), default="2026-2027", nullable=False)

    school: Mapped["School"] = relationship("School", back_populates="classrooms")
    teacher: Mapped[Optional["Teacher"]] = relationship("Teacher", back_populates="classrooms")
    language_groups: Mapped[List["StudentLanguageGroup"]] = relationship(
        "StudentLanguageGroup", back_populates="classroom", cascade="all, delete-orphan"
    )


class Language(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "languages"

    code: Mapped[str] = mapped_column(String(20), unique=True, index=True, nullable=False)  # hi, ho, unr, sat
    name: Mapped[str] = mapped_column(String(100), nullable=False)  # Hindi, Ho, Mundari, Santali
    script: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)  # Devanagari, Warang Chiti, Ol Chiki
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class StudentLanguageGroup(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "student_language_groups"

    classroom_id: Mapped[str] = mapped_column(String(36), ForeignKey("classrooms.id", ondelete="CASCADE"), nullable=False)
    language_id: Mapped[str] = mapped_column(String(36), ForeignKey("languages.id", ondelete="CASCADE"), nullable=False)
    student_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    classroom: Mapped["Classroom"] = relationship("Classroom", back_populates="language_groups")
    language: Mapped["Language"] = relationship("Language")
