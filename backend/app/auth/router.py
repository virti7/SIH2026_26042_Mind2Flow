import logging

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger("app.auth.router")

from app.auth.schemas import (
    CheckUsernameRequest,
    CheckUsernameResponse,
    DevTokenRequest,
    DevTokenResponse,
    RegisterTeacherRequest,
    ResolveIdentifierRequest,
    ResolveIdentifierResponse,
    UserProfileResponse,
)
from app.core.config import settings
from app.core.dependencies import get_current_user, get_db
from app.core.exceptions import BadRequestException, ConflictException, ForbiddenException, NotFoundException
from app.core.security import UserContext, create_access_token
from app.db.models.school import Teacher

router = APIRouter(prefix="/auth", tags=["Authentication"])


def _normalize_username(value: object | None) -> str:
    """Trim + lowercase a username for consistent case-insensitive handling."""
    return str(value or "").strip().lower()


def _username_column_normalized():
    """SQL expression matching uq_teachers_username_lower semantics.

    DB index: LOWER(BTRIM(username)). TRIM in SQLAlchemy renders as
    TRIM (Postgres treats plain TRIM as BTRIM with spaces), which is
    equivalent for whitespace and works on both Postgres and SQLite.
    """
    return func.lower(func.trim(Teacher.username))


@router.get("/me", response_model=UserProfileResponse, summary="Get Current User Profile")
async def get_current_user_profile(
    current_user: UserContext = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Returns the authenticated user context derived from Supabase Auth JWT,
    hydrating with the Teacher profile linked to the authenticated user id.
    The Supabase user id is the identity; teachers.username is never used
    for authentication. Responds 404 when no teacher profile exists.
    """
    # Resolve by the authenticated Supabase user id first, then email.
    # Username stays NULL for legacy rows until legitimately set.
    teacher = (
        await db.execute(
            select(Teacher).where(Teacher.user_id == current_user.user_id)
        )
    ).scalar_one_or_none()
    if teacher is None and current_user.email:
        teacher = (
            await db.execute(
                select(Teacher).where(Teacher.email == current_user.email)
            )
        ).scalar_one_or_none()
    if teacher is None:
        raise NotFoundException("Teacher profile", current_user.user_id)

    return UserProfileResponse(
        user_id=current_user.user_id,
        username=str(teacher.username) if (teacher and teacher.username) else None,
        email=current_user.email if current_user.email else None,
        role=current_user.role,
        school_id=str(teacher.school_id) if (teacher and teacher.school_id) else (current_user.school_id if current_user.school_id else None),
        school_name=str(teacher.school_name) if (teacher and teacher.school_name) else None,
        teacher_id=str(teacher.id) if (teacher and teacher.id) else None,
        teacher_name=str(teacher.name) if (teacher and teacher.name) else None,
        preferred_language=str(teacher.preferred_language) if (teacher and teacher.preferred_language) else None,
        metadata=current_user.user_metadata,
    )


@router.post(
    "/resolve-identifier",
    response_model=ResolveIdentifierResponse,
    summary="Resolve Teacher Username to Registered Email",
)
async def resolve_identifier(
    req: ResolveIdentifierRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Resolves a teacher username or teacher code to the registered email address
    required by Supabase Auth for signInWithPassword.
    Never returns passwords or credentials.
    """
    ident = (req.identifier or "").strip()
    if not ident:
        return ResolveIdentifierResponse(found=False)

    # If already an email format, return immediately
    if "@" in ident:
        return ResolveIdentifierResponse(email=ident.lower(), found=True)

    # Query teachers table by normalized username (case-insensitive,
    # whitespace-trimmed, consistent with uq_teachers_username_lower).
    normalized = _normalize_username(ident)
    stmt = select(Teacher.email).where(
        _username_column_normalized() == normalized,
        Teacher.is_active.is_(True),
    )
    res = await db.execute(stmt)
    email = res.scalars().first()

    # Fallback: match raw user_id (teacher code) for legacy rows with
    # NULL username.
    if not email:
        stmt_uid = select(Teacher.email).where(
            Teacher.user_id == ident.strip(),
            Teacher.is_active.is_(True),
        )
        email = (await db.execute(stmt_uid)).scalars().first()

    # Fallback for prototype accounts if username not set
    if not email:
        if ident.lower() in ("teacher", "teacher01", "teacher_01", "primary_teacher"):
            email = "teacher@test.com"
        elif ident.lower() in ("jh_teacher_01", "jharkhand_teacher"):
            email = "teacher.jharkhand@gov.in"

    if email:
        return ResolveIdentifierResponse(email=email, found=True)
    return ResolveIdentifierResponse(email=None, found=False)


@router.post(
    "/check-username",
    response_model=CheckUsernameResponse,
    summary="Check Teacher Code/Username Availability",
)
async def check_username(
    req: CheckUsernameRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Checks whether a teacher code / username is available for registration.
    """
    username = _normalize_username(req.username)
    if not username or len(username) < 3:
        return CheckUsernameResponse(
            available=False,
            message="Teacher code must be at least 3 characters.",
        )
    stmt = select(Teacher.id).where(_username_column_normalized() == username)
    res = await db.execute(stmt)
    if res.scalars().first():
        return CheckUsernameResponse(
            available=False,
            message="Teacher code is already registered.",
        )
    return CheckUsernameResponse(available=True)


@router.post(
    "/register-teacher",
    response_model=UserProfileResponse,
    summary="Register and Link Teacher Profile to Supabase User ID",
)
async def register_teacher(
    req: RegisterTeacherRequest,
    current_user: UserContext = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Creates or updates the Teacher profile in PostgreSQL/SQLite linked to Supabase Auth user.id.
    Newly registered teachers always receive the normal teacher role through trusted server-side logic.
    Username is optional (email + password is the only login credential);
    existing usernames are preserved when none is supplied.

    SECURITY: the canonical identity is the authenticated Supabase JWT
    (`sub` claim). A client-supplied `user_id` that does not match the JWT
    is rejected with 403, so one teacher can never create/overwrite another
    teacher's profile. Unauthenticated callers receive 401. This endpoint
    deliberately does NOT require the teacher role (chicken-and-egg: the
    profile being created is what grants it).
    """
    jwt_user_id = (current_user.user_id or "").strip()
    if not jwt_user_id:
        raise BadRequestException("authenticated user id is required")
    body_user_id = (req.user_id or "").strip()
    if body_user_id and body_user_id != jwt_user_id:
        logger.warning(
            "[AuthDiag] register-teacher identity mismatch: "
            "jwt sub does not match request user_id"
        )
        raise ForbiddenException(
            "Teacher profile identity does not match the authenticated user"
        )
    user_id = jwt_user_id
    username = _normalize_username(req.username) or None
    # Prefer the JWT email when the token carries one; it is authoritative.
    # Otherwise fall back to the validated request email.
    jwt_email = (current_user.email or "").strip().lower()
    email = jwt_email or (req.email or "").strip().lower()
    name = (req.name or "").strip()

    if not user_id or not email or not name:
        raise BadRequestException("user_id, email, and name are required")

    # Check username uniqueness only when one is supplied (normalized,
    # consistent with uq_teachers_username_lower).
    if username:
        res_uname = await db.execute(
            select(Teacher).where(_username_column_normalized() == username)
        )
        existing_uname = res_uname.scalar_one_or_none()
        if existing_uname and existing_uname.user_id != user_id:
            raise ConflictException("Teacher code is already registered.")

    # Check email uniqueness against any other teacher (case-insensitive).
    res_email = await db.execute(
        select(Teacher).where(func.lower(func.trim(Teacher.email)) == email)
    )
    existing_email = res_email.scalar_one_or_none()
    if existing_email and existing_email.user_id != user_id:
        raise ConflictException("Email address is already registered.")

    # Check if teacher record already exists for this Supabase user_id.
    # Legacy rows may carry a NULL username; never invent values for them
    # except the username being explicitly registered now.
    res_user = await db.execute(select(Teacher).where(Teacher.user_id == user_id))
    teacher = res_user.scalar_one_or_none()

    school_id = (req.school_id or "").strip() or None
    school_name = (req.school_name or "").strip() or None
    phone = (req.phone or "").strip() or None
    designation = (req.designation or "").strip() or None
    preferred_language = (req.preferred_language or "").strip() or None

    if teacher:
        logger.info("[AuthDiag] register-teacher: linked existing profile")
        # Never null out an existing username when none is supplied.
        if username is not None:
            teacher.username = username
        teacher.name = name
        teacher.email = email
        if school_id is not None:
            teacher.school_id = school_id
        # Never null out an existing school name when none is supplied.
        if school_name is not None:
            teacher.school_name = school_name
        if phone is not None:
            teacher.phone = phone
        if designation is not None:
            teacher.designation = designation
        if preferred_language is not None:
            teacher.preferred_language = preferred_language
    else:
        logger.info("[AuthDiag] register-teacher: created new profile")
        teacher = Teacher(
            user_id=user_id,
            username=username,
            name=name,
            email=email,
            school_id=school_id,
            school_name=school_name,
            phone=phone,
            designation=designation or "Primary Teacher",
            preferred_language=preferred_language or "Hindi",
            is_active=True,
        )
        db.add(teacher)

    await db.commit()
    await db.refresh(teacher)

    return UserProfileResponse(
        user_id=str(teacher.user_id),
        username=str(teacher.username) if teacher.username else None,
        email=str(teacher.email) if teacher.email else None,
        role="teacher",
        school_id=str(teacher.school_id) if teacher.school_id else None,
        school_name=str(teacher.school_name) if teacher.school_name else None,
        teacher_id=str(teacher.id) if teacher.id else None,
        teacher_name=str(teacher.name) if teacher.name else None,
        preferred_language=str(teacher.preferred_language) if teacher.preferred_language else None,
        metadata={"role": "teacher"},
    )


@router.post("/dev-token", response_model=DevTokenResponse, summary="Generate Dev/Test JWT Token")
async def generate_dev_token(req: DevTokenRequest):
    """
    Generate a signed JWT token matching Supabase Auth JWT schema for local development
    and automated integration testing. Disabled in production: HS256 dev tokens are
    rejected by the production verifier, so this endpoint must never mint tokens there.
    """
    if (settings.ENVIRONMENT or "").strip().lower() == "production":
        raise ForbiddenException("Dev token issuance is disabled in production")
    token_payload = {
        "sub": req.user_id,
        "email": req.email,
        "role": req.role,
        "app_metadata": {"role": req.role, "school_id": req.school_id},
        "user_metadata": {"role": req.role, "school_id": req.school_id},
    }
    token = create_access_token(token_payload)
    return DevTokenResponse(
        access_token=token,
        user_id=req.user_id,
        role=req.role,
    )
