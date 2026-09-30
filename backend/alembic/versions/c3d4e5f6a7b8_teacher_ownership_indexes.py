"""teacher_ownership_indexes (idempotent)

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
Create Date: 2026-09-23 00:00:00.000000

Multi-account isolation hardening for teacher-owned rows:

- public.teachers.user_id already UNIQUE + indexed (one Supabase auth user
  owns exactly one teacher profile).
- Adds indexes on teacher-owned foreign keys so every account-scoped query
  (teacher_id = JWT owner) is performant:
    saved_materials.teacher_id
    assessment_results.teacher_id
    lesson_delivery_records.teacher_id
    lessons.teacher_id
    translation_feedback.teacher_id
    classrooms.teacher_id

No columns are added, no rows are modified, no data is deleted.
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision: str = "c3d4e5f6a7b8"
down_revision: Union[str, Sequence[str], None] = "b2c3d4e5f6a7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


_INDEXES = [
    ("ix_saved_materials_teacher_id", "saved_materials", "teacher_id"),
    ("ix_assessment_results_teacher_id", "assessment_results", "teacher_id"),
    ("ix_lesson_delivery_records_teacher_id", "lesson_delivery_records", "teacher_id"),
    ("ix_lessons_teacher_id", "lessons", "teacher_id"),
    ("ix_translation_feedback_teacher_id", "translation_feedback", "teacher_id"),
    ("ix_classrooms_teacher_id", "classrooms", "teacher_id"),
]


def upgrade() -> None:
    bind = op.get_bind()
    dialect = bind.dialect.name if bind is not None else ""
    if dialect == "sqlite":
        for name, table, column in _INDEXES:
            try:
                op.execute(sa.text(f"CREATE INDEX IF NOT EXISTS {name} ON {table} ({column})"))
            except Exception:
                pass
        return
    for name, table, column in _INDEXES:
        op.execute(
            sa.text(f"CREATE INDEX IF NOT EXISTS {name} ON public.{table} ({column})")
        )


def downgrade() -> None:
    bind = op.get_bind()
    dialect = bind.dialect.name if bind is not None else ""
    for name, table, _ in _INDEXES:
        try:
            if dialect == "sqlite":
                op.execute(sa.text(f"DROP INDEX IF EXISTS {name}"))
            else:
                op.execute(sa.text(f"DROP INDEX IF EXISTS public.{name}"))
        except Exception:
            pass
