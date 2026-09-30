import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.assessment import (
    Assessment,
    AssessmentResult,
    LearningGap,
    RemedialRecommendation,
)
from app.db.models.feedback import ReviewQueueItem, TranslationFeedback
from app.db.models.lesson import Lesson, LessonDeliveryRecord
from app.db.models.nipun import LearningOutcome
from app.db.models.resource import SavedMaterial
from app.db.models.school import Teacher
from app.db.models.sync import DeviceInfo, SyncQueueLog
from app.sync.schemas import (
    OperationSyncResult,
    SyncOperationItem,
    SyncUploadRequest,
    SyncUploadResponse,
)


class SyncService:
    async def process_batch(
        self,
        db: AsyncSession,
        req: SyncUploadRequest,
        current_teacher_id: Optional[str] = None,
    ) -> SyncUploadResponse:
        results: List[OperationSyncResult] = []
        successful_count = 0
        failed_count = 0

        # 1. Update or create DeviceInfo record
        dev_res = await db.execute(select(DeviceInfo).where(DeviceInfo.device_id == req.device_id))
        device = dev_res.scalar_one_or_none()
        now = datetime.now(timezone.utc)

        if not device:
            device = DeviceInfo(
                device_id=req.device_id,
                teacher_id=current_teacher_id,
                app_version=req.app_version or "1.0.0",
                android_version=req.android_version,
                last_sync_at=now,
            )
            db.add(device)
        else:
            device.app_version = req.app_version or device.app_version
            device.android_version = req.android_version or device.android_version
            device.teacher_id = current_teacher_id or device.teacher_id
            device.last_sync_at = now

        # 2. Process each sync operation
        for op in req.operations:
            op_result = await self._process_single_operation(db, op, req.device_id, current_teacher_id)
            results.append(op_result)
            if op_result.status in ("SUCCESS", "DUPLICATE_IGNORED"):
                successful_count += 1
            else:
                failed_count += 1

        await db.commit()

        return SyncUploadResponse(
            device_id=req.device_id,
            total_operations=len(req.operations),
            successful_count=successful_count,
            failed_count=failed_count,
            results=results,
            synced_at=now,
        )

    async def _process_single_operation(
        self,
        db: AsyncSession,
        op: SyncOperationItem,
        device_id: str,
        teacher_id: Optional[str],
    ) -> OperationSyncResult:
        # Check idempotency: If this operation_id was already processed, ignore or return cached state.
        # Owner-scoped: another teacher's log must never satisfy this
        # teacher's idempotency check (or leak their worksheet payload).
        log_res = await db.execute(select(SyncQueueLog).where(SyncQueueLog.operation_id == op.operation_id))
        existing_log = log_res.scalar_one_or_none()
        if existing_log is not None and getattr(existing_log, "teacher_id", None) != teacher_id:
            existing_log = None
        if existing_log:
            duplicate_data = None
            if op.entity_type.lower() == "worksheet_generation":
                # Re-attach the completed worksheet so re-uploads converge
                # without generating duplicates.
                duplicate_data = await self._lookup_generated_worksheet(
                    db, op.entity_id, teacher_id
                )
            return OperationSyncResult(
                operation_id=op.operation_id,
                entity_type=op.entity_type,
                entity_id=op.entity_id,
                status="DUPLICATE_IGNORED",
                remote_id=existing_log.entity_id,
                message="Operation was previously processed and logged (idempotent ignore)",
                data=duplicate_data,
            )

        now = datetime.now(timezone.utc)
        status = "SUCCESS"
        error_details = None
        remote_id = None
        result_data = None

        try:
            entity_type = op.entity_type.lower()
            payload = op.payload or {}

            if entity_type == "assessment_result":
                remote_id = await self._handle_assessment_result(db, op, teacher_id)
            elif entity_type == "lesson":
                remote_id = await self._handle_lesson(db, op, teacher_id)
            elif entity_type == "saved_material":
                remote_id = await self._handle_saved_material(db, op, teacher_id)
            elif entity_type == "feedback":
                remote_id = await self._handle_feedback(db, op, teacher_id)
            elif entity_type in ("lesson_delivery", "lesson_delivery_record"):
                remote_id = await self._handle_lesson_delivery(db, op, teacher_id)
            elif entity_type == "worksheet_generation":
                remote_id, result_data = await self._handle_worksheet_generation(db, op, teacher_id)
            else:
                status = "FAILED"
                error_details = f"Unsupported entity type: '{op.entity_type}'"

        except Exception as e:
            status = "FAILED"
            error_details = str(e)

        # Log operation in SyncQueueLog
        sync_log = SyncQueueLog(
            operation_id=op.operation_id,
            device_id=device_id,
            teacher_id=teacher_id,
            entity_type=op.entity_type,
            entity_id=remote_id or op.entity_id,
            operation=op.operation,
            payload=op.payload,
            status=status,
            error_details=error_details,
            received_at=now,
            processed_at=datetime.now(timezone.utc),
        )
        db.add(sync_log)

        return OperationSyncResult(
            operation_id=op.operation_id,
            entity_type=op.entity_type,
            entity_id=op.entity_id,
            status=status,
            remote_id=remote_id,
            message="Operation synced successfully" if status == "SUCCESS" else None,
            error=error_details,
            data=result_data,
        )

    async def _ensure_teacher(self, db: AsyncSession, teacher_id: Optional[str]) -> str:
        if teacher_id:
            res = await db.get(Teacher, teacher_id)
            if res:
                return res.id
        # Never attribute synced content to an arbitrary other teacher or a
        # shared fallback: without a verified owner the operation cannot be
        # safely applied.
        raise ValueError("Sync operation has no verified teacher owner.")

    async def _handle_assessment_result(
        self,
        db: AsyncSession,
        op: SyncOperationItem,
        teacher_id: Optional[str],
    ) -> str:
        p = op.payload
        valid_teacher_id = await self._ensure_teacher(db, teacher_id)
        # Owner-scoped dedup: one teacher's local_id must never match
        # another teacher's row.
        res = await db.execute(
            select(AssessmentResult).where(
                AssessmentResult.local_id == op.entity_id,
                AssessmentResult.teacher_id == valid_teacher_id,
            )
        )
        result = res.scalar_one_or_none()

        assessment_id = p.get("assessment_id")
        ass_res = await db.get(Assessment, assessment_id) if assessment_id else None
        if not ass_res:
            ass_check = await db.execute(select(Assessment).limit(1))
            first_ass = ass_check.scalar_one_or_none()
            if first_ass:
                ass_res = first_ass
                assessment_id = first_ass.id
            else:
                # Create a placeholder assessment to ensure FK consistency
                ass_res = Assessment(
                    title="Classroom Assessment",
                    grade=int(p.get("grade", 1)),
                    subject=str(p.get("subject", "Hindi")),
                    total_marks=int(p.get("max_score") or p.get("total_questions", 10)),
                )
                db.add(ass_res)
                await db.flush()
                assessment_id = ass_res.id

        score_val = p.get("score") if p.get("score") is not None else p.get("correct_count", 0.0)
        score = float(score_val)
        max_val = p.get("max_score") if p.get("max_score") is not None else p.get("total_questions", 10.0)
        max_score = float(max_val)
        status_val = p.get("status")
        if not status_val:
            ratio = score / max_score if max_score > 0 else 0
            status_val = "Achieved" if ratio >= 0.75 else ("Developing" if ratio >= 0.50 else "Needs Support")
        elif status_val == "needsSupport":
            status_val = "Needs Support"
        elif status_val == "developing":
            status_val = "Developing"
        elif status_val == "achieved":
            status_val = "Achieved"

        if not result:
            result = AssessmentResult(
                local_id=op.entity_id,
                assessment_id=assessment_id,
                teacher_id=valid_teacher_id,
                student_name=p.get("student_name", "Student"),
                student_id=p.get("student_id"),
                score=score,
                max_score=max_score,
                status=status_val,
            )
            db.add(result)
            await db.flush()
        else:
            result.score = score
            result.max_score = max_score
            result.status = status_val

        # Auto-track learning gap if Needs Support
        if status_val == "Needs Support":
            lo_id = ass_res.learning_outcome_id if ass_res else None
            if not lo_id:
                lo_res = await db.execute(select(LearningOutcome).limit(1))
                lo = lo_res.scalar_one_or_none()
                lo_id = lo.id if lo else None
            if lo_id:
                gap = LearningGap(
                    student_name=result.student_name,
                    student_id=result.student_id,
                    learning_outcome_id=lo_id,
                    assessment_result_id=result.id,
                    gap_description=f"Requires remediation based on score {score}/{max_score}",
                    severity="High" if (score / max_score) < 0.35 else "Medium",
                )
                db.add(gap)

        return result.id

    async def _handle_lesson(
        self,
        db: AsyncSession,
        op: SyncOperationItem,
        teacher_id: Optional[str],
    ) -> str:
        p = op.payload
        valid_lesson_teacher = await self._ensure_teacher(db, teacher_id)
        res = await db.execute(select(Lesson).where(Lesson.local_id == op.entity_id))
        lesson = res.scalar_one_or_none()
        if lesson is not None and getattr(lesson, "teacher_id", None) not in (None, valid_lesson_teacher):
            raise ValueError("Lesson belongs to a different teacher account.")

        if op.operation == "DELETE":
            if lesson:
                lesson.deleted_at = datetime.now(timezone.utc)
                return lesson.id
            return op.entity_id

        if not lesson:
            lesson = Lesson(
                local_id=op.entity_id,
                teacher_id=valid_lesson_teacher,
                title=p.get("title", "Untitled Lesson"),
                objective=p.get("objective"),
                prerequisite=p.get("prerequisite"),
                teacher_moves=p.get("teacher_moves"),
                grade=int(p.get("grade", 1)),
                subject=p.get("subject", "Hindi"),
                language=p.get("language", "Hindi"),
                version=int(p.get("version", 1)),
            )
            db.add(lesson)
            await db.flush()
        else:
            if "title" in p:
                lesson.title = p["title"]
            if "objective" in p:
                lesson.objective = p["objective"]
            if "teacher_moves" in p:
                lesson.teacher_moves = p["teacher_moves"]
            lesson.version += 1

        return lesson.id

    async def _handle_saved_material(
        self,
        db: AsyncSession,
        op: SyncOperationItem,
        teacher_id: Optional[str],
    ) -> str:
        p = op.payload
        valid_teacher_id = await self._ensure_teacher(db, teacher_id)
        res = await db.execute(select(SavedMaterial).where(SavedMaterial.local_id == op.entity_id))
        material = res.scalar_one_or_none()
        if material is not None and getattr(material, "teacher_id", None) != valid_teacher_id:
            raise ValueError("Saved material belongs to a different teacher account.")

        if op.operation == "DELETE":
            if material:
                material.deleted_at = datetime.now(timezone.utc)
                return material.id
            return op.entity_id

        if not material:
            material = SavedMaterial(
                local_id=op.entity_id,
                teacher_id=valid_teacher_id,
                title=p.get("title", "Saved Resource"),
                material_type=p.get("material_type", "worksheet"),
                payload=p.get("payload", p),
            )
            db.add(material)
            await db.flush()
        else:
            material.title = p.get("title", material.title)
            material.payload = p.get("payload", material.payload)

        return material.id

    async def _handle_feedback(
        self,
        db: AsyncSession,
        op: SyncOperationItem,
        teacher_id: Optional[str],
    ) -> str:
        p = op.payload
        valid_fb_teacher = await self._ensure_teacher(db, teacher_id)
        res = await db.execute(select(TranslationFeedback).where(TranslationFeedback.local_id == op.entity_id))
        fb = res.scalar_one_or_none()
        if fb is not None and getattr(fb, "teacher_id", None) not in (None, valid_fb_teacher):
            raise ValueError("Feedback belongs to a different teacher account.")

        if not fb:
            fb = TranslationFeedback(
                local_id=op.entity_id,
                teacher_id=valid_fb_teacher,
                source_text=p.get("source_text", ""),
                translated_text=p.get("translated_text", ""),
                suggested_correction=p.get("suggested_correction"),
                feedback_type=p.get("feedback_type", "wrong_meaning"),
                audio_url=p.get("audio_url"),
            )
            db.add(fb)
            await db.flush()

            # Enqueue into ReviewQueue
            rq = ReviewQueueItem(
                feedback_id=fb.id,
                source_text=fb.source_text,
                candidate_translation=fb.suggested_correction or fb.translated_text,
                target_language=p.get("target_language", "Ho"),
                status="PENDING",
            )
            db.add(rq)

        return fb.id

    async def _handle_lesson_delivery(
        self,
        db: AsyncSession,
        op: SyncOperationItem,
        teacher_id: Optional[str],
    ) -> str:
        p = op.payload
        valid_teacher_id = await self._ensure_teacher(db, teacher_id)
        res = await db.execute(select(LessonDeliveryRecord).where(LessonDeliveryRecord.local_id == op.entity_id))
        record = res.scalar_one_or_none()
        if record is not None and getattr(record, "teacher_id", None) != valid_teacher_id:
            raise ValueError("Delivery record belongs to a different teacher account.")

        lesson_id = p.get("lesson_id")
        les_res = await db.get(Lesson, lesson_id) if lesson_id else None
        if not les_res:
            les_check = await db.execute(select(Lesson).limit(1))
            first_les = les_check.scalar_one_or_none()
            if first_les:
                lesson_id = first_les.id
            else:
                placeholder_lesson = Lesson(
                    title="Classroom Lesson",
                    grade=1,
                    subject="Hindi",
                    language="Hindi",
                )
                db.add(placeholder_lesson)
                await db.flush()
                lesson_id = placeholder_lesson.id

        if not record:
            record = LessonDeliveryRecord(
                local_id=op.entity_id,
                lesson_id=lesson_id,
                teacher_id=valid_teacher_id,
                completed_step_index=int(p.get("completed_step_index", 0)),
                total_steps=int(p.get("total_steps", 4)),
                notes=p.get("notes"),
            )
            db.add(record)
            await db.flush()
        else:
            record.completed_step_index = int(p.get("completed_step_index", record.completed_step_index))
            record.notes = p.get("notes", record.notes)

        return record.id

    async def _lookup_generated_worksheet(
        self, db: AsyncSession, request_id: str, teacher_id: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """Return completed worksheet data for an already-processed request."""
        from app.db.models.resource import SavedMaterial

        query = select(SavedMaterial).where(SavedMaterial.local_id == request_id)
        if teacher_id:
            query = query.where(SavedMaterial.teacher_id == teacher_id)
        res = await db.execute(query)
        material = res.scalar_one_or_none()
        if not material:
            return None
        payload = material.payload if isinstance(material.payload, dict) else {}
        return {
            "request_id": request_id,
            "content_id": payload.get("content_id"),
            "status": "READY",
            "provider": (payload.get("translation") or {}).get("provider"),
            "content": payload,
            "saved_material_id": material.id,
        }

    async def _handle_worksheet_generation(
        self,
        db: AsyncSession,
        op: SyncOperationItem,
        teacher_id: Optional[str],
    ) -> tuple:
        """Execute a queued offline worksheet request server-side.

        Returns (remote_id, result_data). Generation runs inline so the client
        receives the completed worksheet in the same sync response.
        """
        from app.worksheets.schemas import WorksheetGenerationParams
        from app.worksheets.service import worksheet_generation_service

        p = op.payload or {}
        # Queued Santali flashcard requests (Hi/En/Sat only) run the
        # flashcard pipeline, never the worksheet pipeline.
        if (p.get("content_type") or "").strip().lower() == "flashcard":
            return await self._handle_flashcard_generation(db, op, teacher_id)
        try:
            wt = p.get("worksheet_types") or ([p.get("worksheet_type")] if p.get("worksheet_type") else None)
            params = WorksheetGenerationParams(
                request_id=str(p.get("request_id") or op.entity_id),
                teacher_id=p.get("teacher_id"),
                device_id=p.get("device_id"),
                grade=int(p.get("grade", p.get("class", 1))),
                section=p.get("section"),
                subject=str(p.get("subject", "Mathematics")),
                topic=str(p.get("topic", p.get("subject", "Practice"))),
                topic_source=str(p.get("topic_source", "curriculum")),
                topic_id=p.get("topic_id"),
                topic_input_language=str(p.get("topic_input_language", "en")),
                nipun_outcome=p.get("nipun_outcome"),
                nipun_code=p.get("nipun_code") or p.get("nipun_outcome"),
                source_language=str(p.get("source_language") or p.get("language_1", "hi")),
                target_language=str(p.get("target_language") or p.get("language_2", "sat")),
                language_1=p.get("language_1"),
                language_2=p.get("language_2"),
                worksheet_type=str((wt or ["practice"])[0]),
                worksheet_types=wt,
                question_count=int(p.get("question_count", 10)),
                difficulty=str(p.get("difficulty", "medium")),
                visual_support=bool(p.get("visual_support", p.get("visual_illustrations", True))),
                bilingual_answers=bool(p.get("bilingual_answers", p.get("bilingual_answer_spaces", True))),
                audio_cue=bool(p.get("audio_cue", p.get("audio_pronunciation", False))),
                origin="offline",
                created_at=p.get("created_at"),
            )
        except Exception as exc:
            raise ValueError(f"Invalid worksheet request: {exc}") from exc

        # generate() expects the JWT subject (Teacher.user_id), not the row
        # PK: resolve it so offline generations are owned by the uploader.
        teacher_sub: Optional[str] = None
        if teacher_id:
            owner_row = await db.get(Teacher, teacher_id)
            if owner_row is not None:
                teacher_sub = owner_row.user_id
        result = await worksheet_generation_service.generate(params, db, teacher_sub)
        if result.status == "FAILED":
            raise RuntimeError(result.error or "Worksheet generation failed")

        data = {
            "request_id": result.request_id,
            "content_id": result.content_id,
            "status": result.status,
            "provider": result.provider,
            "coverage": result.coverage,
            "content": result.content,
            "assets": result.assets,
            "saved_material_id": result.saved_material_id,
            "review_gates": result.review_gates,
        }
        return result.content_id or result.request_id, data

    async def _handle_flashcard_generation(
        self,
        db: AsyncSession,
        op: SyncOperationItem,
        teacher_id: Optional[str],
    ) -> tuple:
        """Execute a queued offline Santali flashcard request server-side."""
        from app.flashcards.schemas import FlashcardGenerationParams
        from app.flashcards.service import flashcard_generation_service

        p = op.payload or {}
        try:
            params = FlashcardGenerationParams(
                request_id=str(p.get("request_id") or op.entity_id),
                teacher_id=p.get("teacher_id"),
                device_id=p.get("device_id"),
                grade=int(p.get("grade", 1)),
                section=p.get("section"),
                subject=str(p.get("subject", "Hindi")),
                topic=str(p.get("topic", "Fruits")),
                topic_source=str(p.get("topic_source", "curriculum")),
                topic_id=p.get("topic_id"),
                topic_input_language=str(p.get("topic_input_language", "en")),
                nipun_outcome=p.get("nipun_outcome"),
                nipun_code=p.get("nipun_code"),
                strand=p.get("strand"),
                language_mode=str(p.get("language_mode", "hi_sat")),
                flashcard_type=str(p.get("flashcard_type", "vocabulary")),
                card_count=int(p.get("card_count") or p.get("question_count") or 8),
                difficulty=str(p.get("difficulty", "medium")),
                visual_style=str(p.get("visual_style", "illustrated")),
                pronunciation=bool(p.get("pronunciation", False)),
                origin="offline",
                created_at=p.get("created_at"),
            )
        except Exception as exc:
            raise ValueError(f"Invalid flashcard request: {exc}") from exc

        teacher_sub: Optional[str] = None
        if teacher_id:
            owner_row = await db.get(Teacher, teacher_id)
            if owner_row is not None:
                teacher_sub = owner_row.user_id
        result = await flashcard_generation_service.generate(params, db, teacher_sub)
        if result.status == "FAILED":
            raise RuntimeError(result.error or "Flashcard generation failed")

        data = {
            "request_id": result.request_id,
            "content_id": result.content_id,
            "status": result.status,
            "provider": result.provider,
            "coverage": result.coverage,
            "content": result.content,
            "assets": result.assets,
            "saved_material_id": result.saved_material_id,
        }
        return result.content_id or result.request_id, data


sync_service = SyncService()
