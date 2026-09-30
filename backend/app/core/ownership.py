"""Central teacher-ownership helpers: JWT subject is the ONLY owner key.

Every teacher-owned query must filter by the verified JWT ``sub``
(``current_user.user_id``). Client-supplied ``user_id``/``teacher_id``/
``email`` values are NEVER trusted for ownership.
"""
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundException
from app.core.security import UserContext
from app.db.models.school import Teacher


async def require_teacher(
    db: AsyncSession, current_user: UserContext
) -> Teacher:
    """Return the Teacher row owned by the JWT subject.

    Auto-provisions a minimal row for a valid authenticated user that has
    no profile yet (first login), instead of falling back to
    "anonymous-teacher" or another teacher's row.
    """
    res = await db.execute(
        select(Teacher).where(Teacher.user_id == current_user.user_id)
    )
    teacher = res.scalar_one_or_none()
    if teacher is not None:
        return teacher
    teacher = Teacher(
        user_id=current_user.user_id,
        name=(current_user.user_metadata.get("name")
              or current_user.user_metadata.get("full_name")
              or "Teacher"),
        email=current_user.email or f"{current_user.user_id}@provisioned.local",
    )
    db.add(teacher)
    await db.flush()
    return teacher


async def get_owned_teacher_or_none(
    db: AsyncSession, current_user: UserContext
) -> Optional[Teacher]:
    res = await db.execute(
        select(Teacher).where(Teacher.user_id == current_user.user_id)
    )
    return res.scalar_one_or_none()


def ensure_owner_match(resource_teacher_id: Optional[str], teacher_id: str, resource_label: str, resource_id: str) -> None:
    """Raise 404 unless the resource belongs to the authenticated teacher.

    404 (not 403) avoids leaking whether another teacher owns the id.
    """
    if resource_teacher_id != teacher_id:
        raise NotFoundException(resource_label, resource_id)
