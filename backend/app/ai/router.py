import json
import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.schemas import (
    ContentGenerationRequest,
    ContentPublishRequest,
    ContentPublishResponse,
    ContentStatusUpdateRequest,
    GeneratedContentResponse,
    GenerationJobResponse,
    JobApproveRequest,
    ReviewRecordResponse,
    ReviewUpdateRequest,
    TeacherGenerationRequest,
)
from app.core.dependencies import get_current_user, get_db, require_reviewer, require_teacher
from app.core.exceptions import BadRequestException, NotFoundException
from app.core.security import UserContext
from app.db.models.ai import GeneratedContent
from app.db.models.lesson import Activity, Lesson
from app.db.models.nipun import LearningOutcome
from app.db.models.resource import Flashcard, Worksheet
from app.services.bilingual_generator import bilingual_generator_service
from app.services.generation_jobs import generation_job_manager

router = APIRouter(prefix="/ai", tags=["Server-Side Generative AI Orchestration"])


@router.post("/generate", response_model=GeneratedContentResponse, status_code=status.HTTP_201_CREATED, summary="Orchestrate Content Preparation via Generative AI")
async def generate_curriculum_content(
    req: ContentGenerationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    """
    Server-side generative AI orchestration for educational content preparation.
    Supports either:
    1. Direct blueprint execution via the Bilingual Generator (req.blueprint_id)
    2. NIPUN Learning Outcome pedagogical lesson plan generation (req.learning_outcome_id)
    """
    # 1. Bilingual Generator Blueprint Flow
    if req.blueprint_id:
        gen_result = bilingual_generator_service.generate_content(
            blueprint_id=req.blueprint_id,
            target_language=req.target_language or "sat",
            provider_name=req.provider,
            mock_mode=req.mock_mode,
            force=req.force,
        )
        if not gen_result.is_success:
            raise BadRequestException(
                f"Bilingual generation failed with status '{gen_result.status}'",
                errors=gen_result.errors,
            )

        raw_data = gen_result.data or {}
        content_id = gen_result.content_id or str(uuid.uuid4())
        content_type = raw_data.get("content_type", req.content_type).lower()

        lo_id = req.learning_outcome_id
        if not lo_id and "curriculum_id" in raw_data:
            lo_code = raw_data["curriculum_id"]
            res = await db.execute(select(LearningOutcome).where(LearningOutcome.code == lo_code))
            lo = res.scalar_one_or_none()
            if lo:
                lo_id = lo.id

        existing = await db.get(GeneratedContent, content_id)
        if existing:
            existing.raw_output = raw_data
            existing.validated_output = raw_data if gen_result.validation_status == "valid" else None
            existing.status = "GENERATED"
            existing.prompt_used = f"Blueprint: {req.blueprint_id} (Provider: {gen_result.provider_used})"
            content = existing
        else:
            content = GeneratedContent(
                id=content_id,
                learning_outcome_id=lo_id,
                content_type=content_type,
                prompt_used=f"Blueprint: {req.blueprint_id} (Provider: {gen_result.provider_used})",
                raw_output=raw_data,
                validated_output=raw_data if gen_result.validation_status == "valid" else None,
                status="GENERATED",
                created_by=current_user.user_id,
            )
            db.add(content)

        await db.commit()
        await db.refresh(content)
        return content

    # 2. Standard Learning Outcome Lesson Plan Flow
    if not req.learning_outcome_id:
        raise BadRequestException("Either 'blueprint_id' or 'learning_outcome_id' must be provided.")

    lo = await db.get(LearningOutcome, req.learning_outcome_id)
    if not lo:
        raise NotFoundException("LearningOutcome", req.learning_outcome_id)

    prompt = (
        f"Design a Grade {req.grade} {req.subject} bilingual {req.content_type} plan for NIPUN Bharat learning outcome "
        f"[{lo.code}]: '{lo.description}'. Provide structured scaffolding for native {req.target_language} speaking students."
    )

    # Structured pedagogical payload matching NIPUN requirements
    generated_payload = {
        "title": f"Bilingual NIPUN Lesson: {lo.code}",
        "subject": req.subject,
        "grade": req.grade,
        "target_language": req.target_language,
        "learning_outcome_code": lo.code,
        "learning_outcome_description": lo.description,
        "objective": f"Students demonstrate competency in {lo.description} using visual and bilingual support.",
        "prerequisite": "Basic oral comprehension in mother tongue",
        "teacher_moves": [
            {
                "step": 1,
                "title": "Bilingual Warmup & Hook",
                "description": f"Introduce the concept using contextual stories in {req.target_language} and Hindi.",
                "duration_minutes": 5,
            },
            {
                "step": 2,
                "title": "Guided Visual Modeling",
                "description": "Demonstrate the learning outcome with tangible objects, flashcards, and gestures.",
                "duration_minutes": 10,
            },
            {
                "step": 3,
                "title": "Peer Activity & Formative Check",
                "description": "Students work in pairs to practice the skill with immediate positive reinforcement.",
                "duration_minutes": 15,
            },
            {
                "step": 4,
                "title": "Closure & Reflection",
                "description": "Quick oral check-in and informal assessment of understanding.",
                "duration_minutes": 5,
            },
        ],
        "remediation": {
            "strategy": "Peer-assisted repetition",
            "suggested_materials": ["Flashcards", "Counting beads"],
        },
    }

    content = GeneratedContent(
        learning_outcome_id=req.learning_outcome_id,
        content_type=req.content_type,
        prompt_used=prompt,
        raw_output=generated_payload,
        status="GENERATED",
        created_by=current_user.user_id,
    )
    db.add(content)
    await db.commit()
    await db.refresh(content)
    return content


@router.get("/content", response_model=List[GeneratedContentResponse], summary="List AI Generated Content in Review Workflow")
async def list_generated_content(
    status_filter: Optional[str] = Query(None, description="GENERATED, REVIEW, APPROVED, PUBLISHED"),
    content_type: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    reviewer: UserContext = Depends(require_reviewer),
):
    query = select(GeneratedContent)
    if status_filter:
        query = query.where(GeneratedContent.status == status_filter.upper())
    if content_type:
        query = query.where(GeneratedContent.content_type == content_type.lower())

    res = await db.execute(query.offset(skip).limit(limit).order_by(GeneratedContent.created_at.desc()))
    return res.scalars().all()


@router.get("/content/{id}", response_model=GeneratedContentResponse, summary="Get AI Generated Content by ID")
async def get_generated_content(
    id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserContext = Depends(get_current_user),
):
    content = await db.get(GeneratedContent, id)
    if not content:
        raise NotFoundException("GeneratedContent", id)
    # Ownership: teachers can only fetch content they created (created_by is
    # the verified JWT subject, never client input). Reviewers/admins keep
    # access for the review workflow. 404 avoids leaking other teachers' ids.
    if not current_user.is_reviewer() and (
        content.created_by or ""
    ) != current_user.user_id:
        raise NotFoundException("GeneratedContent", id)
    return content


@router.get("/content/{id}/review", summary="Get Review Status and Gates for Generated Content")
async def get_content_review(
    id: str,
    db: AsyncSession = Depends(get_db),
    reviewer: UserContext = Depends(require_reviewer),
):
    # Check generator review record first
    record = bilingual_generator_service.get_review_status(id)
    if record:
        return record

    # Fallback to database content record
    content = await db.get(GeneratedContent, id)
    if not content:
        raise NotFoundException("GeneratedContent", id)

    return {
        "content_id": content.id,
        "review_status": content.status.lower(),
        "review_notes": content.review_notes,
        "reviewed_by": content.reviewed_by,
    }


@router.post("/content/{id}/review", summary="Update Review Gates & Status (Reviewer/Admin only)")
async def update_content_review(
    id: str,
    req: ReviewUpdateRequest,
    db: AsyncSession = Depends(get_db),
    reviewer: UserContext = Depends(require_reviewer),
):
    content = await db.get(GeneratedContent, id)
    if not content:
        # Check if record exists on disk in generator review manager
        record = bilingual_generator_service.get_review_status(id)
        if not record:
            raise NotFoundException("GeneratedContent", id)
        content = GeneratedContent(
            id=id,
            content_type="worksheet" if "NUM" in id or "LIT" in id else "flashcard",
            prompt_used=f"Blueprint: {record.get('blueprint_id', 'unknown')}",
            raw_output=record,
            status=record.get("review_status", "PENDING").upper(),
            created_by=reviewer.user_id,
        )
        db.add(content)

    try:
        record = bilingual_generator_service.update_review(
            content_id=id,
            reviewer_id=reviewer.user_id,
            status=req.status,
            gate_updates=req.gates,
            notes=req.notes,
            santali_script_confirmed=req.santali_script_confirmed,
        )
    except FileNotFoundError:
        record = None
    except ValueError as e:
        raise BadRequestException(str(e))

    if req.status:
        content.status = req.status.upper()
    content.reviewed_by = reviewer.user_id
    if req.notes:
        content.review_notes = (content.review_notes or "") + f"\n[{reviewer.user_id}]: {req.notes}"

    await db.commit()
    await db.refresh(content)
    return record or {
        "content_id": content.id,
        "review_status": content.status.lower(),
        "reviewed_by": content.reviewed_by,
        "review_notes": content.review_notes,
    }


@router.post("/content/{id}/publish", response_model=ContentPublishResponse, summary="Publish Approved Content to Catalog & Storage")
async def publish_content(
    id: str,
    req: ContentPublishRequest,
    db: AsyncSession = Depends(get_db),
    reviewer: UserContext = Depends(require_reviewer),
):
    content = await db.get(GeneratedContent, id)
    if not content:
        record = bilingual_generator_service.get_review_status(id)
        if not record:
            raise NotFoundException("GeneratedContent", id)
        content = GeneratedContent(
            id=id,
            content_type="worksheet" if "NUM" in id or "LIT" in id else "flashcard",
            prompt_used=f"Blueprint: {record.get('blueprint_id', 'unknown')}",
            raw_output=record,
            status=record.get("review_status", "PENDING").upper(),
            created_by=reviewer.user_id,
        )
        db.add(content)

    try:
        pub_result = bilingual_generator_service.publish_content(
            content_id=id,
            dry_run=req.dry_run,
        )
    except Exception as e:
        raise BadRequestException(f"Publication rejected: {str(e)}")

    # If published and cataloging requested, persist to local database tables if not already present
    if pub_result.status in ("published", "already_published") and req.publish_to_catalog:
        content.status = "PUBLISHED"
        payload = content.validated_output or content.raw_output or {}
        content_type = content.content_type.lower()
        grade = int(payload.get("grade", 1))
        subject = str(payload.get("subject", "Math"))
        title = str(payload.get("title", f"Bilingual {content_type.title()}"))

        if content_type == "worksheet":
            existing_ws = await db.get(Worksheet, id)
            if not existing_ws:
                ws = Worksheet(
                    id=id,
                    title=title,
                    grade=grade,
                    subject=subject,
                    file_path=pub_result.storage_paths[0] if pub_result.storage_paths else f"worksheets/{id}.json",
                    file_size=len(json.dumps(payload)),
                    format="json",
                    learning_outcome_id=content.learning_outcome_id,
                )
                db.add(ws)

        elif content_type == "flashcard":
            deck_name = str(payload.get("deck_name", title))
            for idx, item in enumerate(payload.get("items", [])):
                fc_id = f"{id}_{idx+1}"
                existing_fc = await db.get(Flashcard, fc_id)
                if not existing_fc:
                    fc = Flashcard(
                        id=fc_id,
                        deck_name=deck_name,
                        front_text=str(item.get("front_text", item.get("front", ""))),
                        back_text=str(item.get("back_text", item.get("back", ""))),
                        image_url=item.get("image_url"),
                        audio_url=item.get("audio_url"),
                        grade=grade,
                    )
                    db.add(fc)

        await db.commit()
        await db.refresh(content)

    return ContentPublishResponse(
        content_id=id,
        content_type=pub_result.content_type,
        status=pub_result.status,
        is_idempotent=pub_result.is_idempotent,
        record_ids=pub_result.record_ids,
        storage_paths=pub_result.storage_paths,
        details=pub_result.details,
    )


@router.patch("/content/{id}/status", response_model=GeneratedContentResponse, summary="Review & Publish Generated Content (Reviewer/Admin only)")
async def update_generated_content_status(
    id: str,
    req: ContentStatusUpdateRequest,
    db: AsyncSession = Depends(get_db),
    reviewer: UserContext = Depends(require_reviewer),
):
    """
    Human verification step: transitions content from GENERATED to REVIEW to APPROVED to PUBLISHED.
    When published, it is automatically cataloged as trusted curriculum material.
    """
    content = await db.get(GeneratedContent, id)
    if not content:
        raise NotFoundException("GeneratedContent", id)

    valid_statuses = ("REVIEW", "APPROVED", "PUBLISHED")
    if req.status.upper() not in valid_statuses:
        raise BadRequestException(f"Invalid status '{req.status}'. Must be one of {valid_statuses}")

    content.status = req.status.upper()
    content.reviewed_by = reviewer.user_id
    if req.review_notes:
        content.review_notes = req.review_notes
    if req.validated_output:
        content.validated_output = req.validated_output

    # If PUBLISHED and publish_to_catalog is True, convert into formal Lesson/Worksheet/Flashcard in DB
    if content.status == "PUBLISHED" and (req.publish_to_catalog or content.content_type == "lesson"):
        payload = content.validated_output or content.raw_output or {}
        content_type = content.content_type.lower()
        grade = int(payload.get("grade", 1))
        subject = str(payload.get("subject", "Hindi"))
        language = str(payload.get("target_language", "Ho"))

        if content_type == "lesson":
            lesson = Lesson(
                title=payload.get("title", "AI Generated Lesson"),
                learning_outcome_id=content.learning_outcome_id,
                objective=payload.get("objective"),
                prerequisite=payload.get("prerequisite"),
                teacher_moves=payload.get("teacher_moves"),
                remediation_info=payload.get("remediation"),
                grade=grade,
                subject=subject,
                language=language,
                is_published=True,
            )
            db.add(lesson)
        elif content_type == "worksheet":
            existing_ws = await db.get(Worksheet, id)
            if not existing_ws:
                ws = Worksheet(
                    id=id,
                    title=payload.get("title", "Bilingual Worksheet"),
                    grade=grade,
                    subject=subject,
                    file_path=f"worksheets/{id}.json",
                    file_size=len(json.dumps(payload)),
                    format="json",
                    learning_outcome_id=content.learning_outcome_id,
                )
                db.add(ws)

    await db.commit()
    await db.refresh(content)
    return content


# =====================================================================
# TEACHER ASYNCHRONOUS GENERATION & OFFLINE PREPARATION ENDPOINTS
# =====================================================================

@router.post(
    "/teacher/generate",
    response_model=GenerationJobResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Request Teacher Content Generation (Asynchronous)",
)
@router.post(
    "/content/generate",
    response_model=GenerationJobResponse,
    status_code=status.HTTP_202_ACCEPTED,
    include_in_schema=False,
)
async def request_teacher_generation(
    req: TeacherGenerationRequest,
    current_user: UserContext = Depends(require_teacher),
):
    """
    Teacher-facing asynchronous content generation endpoint.
    Verifies teacher authentication, enforces idempotency, and dispatches server-side
    generation with Sarvam-105B and the bilingual generator pipeline.
    """
    job = generation_job_manager.create_job(
        req=req,
        teacher_id=current_user.user_id,
        provider="sarvam",
    )

    # If job is newly created (PENDING), execute on this request's event
    # loop as an asyncio Task (never asyncio.run/threads: the app's
    # AsyncEngine belongs to this loop).
    if job.status == "PENDING":
        generation_job_manager.schedule_job(job.job_id)

    return job


@router.get(
    "/jobs/{job_id}",
    response_model=GenerationJobResponse,
    summary="Get Teacher Generation Job Status",
)
async def get_teacher_generation_job(
    job_id: str,
    current_user: UserContext = Depends(get_current_user),
):
    """Get the status and payload of an asynchronous generation job."""
    job = generation_job_manager.get_job(job_id)
    if not job:
        raise NotFoundException("GenerationJob", job_id)
    # Ownership: a teacher can only poll their own generation jobs.
    # (Checked against the server-recorded JWT owner, never client input.
    # 404 — not 403 — avoids leaking whether another teacher owns the id.)
    if (generation_job_manager.job_owner(job_id) or "") != current_user.user_id:
        raise NotFoundException("GenerationJob", job_id)
    return job


@router.post(
    "/jobs/{job_id}/approve",
    response_model=GenerationJobResponse,
    summary="Approve Teacher Content Generation (Transitions to READY for download)",
)
async def approve_teacher_generation_job(
    job_id: str,
    req: JobApproveRequest,
    current_user: UserContext = Depends(get_current_user),
):
    """
    Confirm review gates (e.g. Santali script confirmation) and approve generated content
    for offline classroom use, publishing it to storage and transitioning job status to READY.
    """
    job = generation_job_manager.get_job(job_id)
    if not job:
        raise NotFoundException("GenerationJob", job_id)
    # Ownership: a teacher can only approve their own generation jobs.
    if (generation_job_manager.job_owner(job_id) or "") != current_user.user_id:
        raise NotFoundException("GenerationJob", job_id)

    approved_job = generation_job_manager.approve_job(
        job_id=job_id,
        reviewer_id=current_user.user_id,
        santali_script_confirmed=req.santali_script_confirmed or "Olck",
        notes=req.notes,
    )
    if not approved_job:
        raise BadRequestException(f"Failed to approve job {job_id}")

    return approved_job

