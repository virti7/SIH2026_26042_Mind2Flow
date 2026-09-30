"""add_teacher_username (idempotent)

Revision ID: a1b2c3d4e5f6
Revises: 3249505944d9
Create Date: 2026-09-22 01:10:00.000000

Reconciles the ORM Teacher.username model with the real Supabase
public.teachers table WITHOUT dropping the table or deleting rows.

Real database state (manually applied):
    ALTER TABLE public.teachers
    ADD COLUMN IF NOT EXISTS username VARCHAR(255);
    CREATE UNIQUE INDEX IF NOT EXISTS uq_teachers_username_lower
    ON public.teachers (LOWER(BTRIM(username)))
    WHERE username IS NOT NULL AND BTRIM(username) <> '';

This migration is therefore idempotent:
- safe on an existing DB where the column/index already exist
- creates them on a fresh DB where they are missing
- never deletes teacher rows, never invents usernames
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, Sequence[str], None] = "3249505944d9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add username column and case-insensitive unique index if missing."""
    bind = op.get_bind()
    dialect = bind.dialect.name if bind is not None else ""

    if dialect == "sqlite":
        # SQLite (local dev / tests): ADD COLUMN is not idempotent,
        # so inspect first. Functional partial index keeps the same
        # name/semantics via TRIM (equivalent to BTRIM for spaces).
        from sqlalchemy import inspect as sa_inspect

        cols = [c["name"] for c in sa_inspect(bind).get_columns("teachers")]
        if "username" not in cols:
            with op.batch_alter_table("teachers") as batch_op:
                batch_op.add_column(
                    sa.Column("username", sa.String(length=255), nullable=True)
                )
        existing_indexes = {
            ix["name"] for ix in sa_inspect(bind).get_indexes("teachers")
        }
        if "uq_teachers_username_lower" not in existing_indexes:
            op.execute(
                sa.text(
                    "CREATE UNIQUE INDEX IF NOT EXISTS "
                    "uq_teachers_username_lower ON teachers "
                    "(LOWER(TRIM(username))) "
                    "WHERE username IS NOT NULL AND TRIM(username) <> ''"
                )
            )
        # Drop legacy case-sensitive index from the earlier non-idempotent
        # revision if it exists; the functional index is authoritative.
        if "ix_teachers_username" in existing_indexes:
            with op.batch_alter_table("teachers") as batch_op:
                batch_op.drop_index("ix_teachers_username")
        return

    # PostgreSQL / Supabase: fully idempotent raw SQL.
    op.execute(
        sa.text(
            "ALTER TABLE public.teachers "
            "ADD COLUMN IF NOT EXISTS username VARCHAR(255)"
        )
    )
    op.execute(
        sa.text(
            "CREATE UNIQUE INDEX IF NOT EXISTS uq_teachers_username_lower "
            "ON public.teachers (LOWER(BTRIM(username))) "
            "WHERE username IS NOT NULL AND BTRIM(username) <> ''"
        )
    )
    # Remove the legacy case-sensitive unique index if a previous run of
    # this revision created it; safe (index only, no data loss).
    op.execute(sa.text("DROP INDEX IF EXISTS ix_teachers_username"))


def downgrade() -> None:
    """Remove the username uniqueness index and column (index first)."""
    bind = op.get_bind()
    dialect = bind.dialect.name if bind is not None else ""

    if dialect == "sqlite":
        from sqlalchemy import inspect as sa_inspect

        existing_indexes = {
            ix["name"] for ix in sa_inspect(bind).get_indexes("teachers")
        }
        if "uq_teachers_username_lower" in existing_indexes:
            op.execute(sa.text("DROP INDEX IF EXISTS uq_teachers_username_lower"))
        cols = [c["name"] for c in sa_inspect(bind).get_columns("teachers")]
        if "username" in cols:
            with op.batch_alter_table("teachers") as batch_op:
                batch_op.drop_column("username")
        return

    op.execute(sa.text("DROP INDEX IF EXISTS uq_teachers_username_lower"))
    op.execute(sa.text("ALTER TABLE IF EXISTS public.teachers DROP COLUMN IF EXISTS username"))
