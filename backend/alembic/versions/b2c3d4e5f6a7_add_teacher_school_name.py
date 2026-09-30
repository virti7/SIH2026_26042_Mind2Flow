"""add_teacher_school_name (idempotent)

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-09-23 00:00:00.000000

Reconciles the ORM Teacher.school_name model with the real Supabase
public.teachers table WITHOUT dropping the table or deleting rows.

Real database state (manually applied):
    ALTER TABLE public.teachers
    ADD COLUMN IF NOT EXISTS school_name VARCHAR(255);

This migration is therefore idempotent:
- safe on an existing DB where the column already exists
- creates it on a fresh DB where it is missing
- never deletes teacher rows, never invents school names
- school_id remains the relational school link; school_name is
  additional free-text profile information only
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision: str = "b2c3d4e5f6a7"
down_revision: Union[str, Sequence[str], None] = "a1b2c3d4e5f6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add school_name column if missing."""
    bind = op.get_bind()
    dialect = bind.dialect.name if bind is not None else ""

    if dialect == "sqlite":
        # SQLite (local dev / tests): ADD COLUMN is not idempotent,
        # so inspect first.
        from sqlalchemy import inspect as sa_inspect

        cols = [c["name"] for c in sa_inspect(bind).get_columns("teachers")]
        if "school_name" not in cols:
            with op.batch_alter_table("teachers") as batch_op:
                batch_op.add_column(
                    sa.Column("school_name", sa.String(length=255), nullable=True)
                )
        return

    # PostgreSQL / Supabase: fully idempotent raw SQL.
    op.execute(
        sa.text(
            "ALTER TABLE public.teachers "
            "ADD COLUMN IF NOT EXISTS school_name VARCHAR(255)"
        )
    )


def downgrade() -> None:
    """Remove the school_name column if present."""
    bind = op.get_bind()
    dialect = bind.dialect.name if bind is not None else ""

    if dialect == "sqlite":
        from sqlalchemy import inspect as sa_inspect

        cols = [c["name"] for c in sa_inspect(bind).get_columns("teachers")]
        if "school_name" in cols:
            with op.batch_alter_table("teachers") as batch_op:
                batch_op.drop_column("school_name")
        return

    op.execute(
        sa.text("ALTER TABLE IF EXISTS public.teachers DROP COLUMN IF EXISTS school_name")
    )
