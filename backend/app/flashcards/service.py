"""Multilingual flashcard generation service (Hi/En/Sat only).

Reuses the worksheet translation provider registry + local IndicTrans2 integration:
source_language_code / target_language_code are set per language mode,
never hardcoded to Hindi->Santali only. Server-side API key handling,
retry semantics and error mapping come from the existing providers.
"""
from __future__ import annotations

import asyncio
import json
import logging
from typing import Any, Dict, List, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.flashcards.concepts import resolve_concepts
from app.flashcards.image_library import (
    SOURCE_AI_GENERATED,
    SOURCE_IMAGE_CATALOG,
    TOPIC_SOURCE_CATALOG,
    PROVIDER_NAME,
    FlashcardImageLibrary,
    flashcard_image_library,
)
from app.flashcards.schemas import (
    ALLOWED_CODES,
    FlashcardDocument,
    FlashcardGenerationParams,
    FlashcardGenerationResult,
    FlashcardItem,
)
from app.flashcards.visuals import resolve_visual
from app.translation.providers import (
    TranslationItem,
    TranslationNotConfiguredError,
    TranslationProviderError,
    TranslationRateLimitedError,
    TranslationUnsupportedError,
)
from app.translation.registry import (
    LanguageCapabilityRegistry,
    normalize_language_code,
    bcp47_code,
)
from app.worksheets.translator import provider_api_languages

logger = logging.getLogger(__name__)


def _content_id_for(params: FlashcardGenerationParams) -> str:
    subj = "".join(ch for ch in params.subject.upper() if ch.isalnum())[:6] or "SUBJ"
    return f"FC-G{params.grade}-{subj}-{params.language_mode}-{params.request_id[:8]}"


def to_flutter_payload(doc: FlashcardDocument) -> Dict[str, Any]:
    meta = doc.metadata
    return {
        "content_id": doc.content_id,
        "request_id": doc.request_id,
        "title": doc.title,
        "grade": meta.get("grade"),
        "section": meta.get("section"),
        "subject": meta.get("subject"),
        "topic": meta.get("topic"),
        "topic_source": meta.get("topic_source"),
        "nipun_outcome": meta.get("nipun_outcome"),
        "nipun_code": meta.get("nipun_code"),
        "strand": meta.get("strand"),
        "language_mode": meta.get("language_mode"),
        "source_languages": meta.get("source_languages"),
        "target_language": "sat",
        "target_language_code": "sat-IN",
        "content_type": "flashcard",
        "flashcard_type": meta.get("flashcard_type"),
        "card_count": len(doc.cards),
        "difficulty": meta.get("difficulty"),
        "visual_style": meta.get("visual_style"),
        "pronunciation": meta.get("pronunciation"),
        "generated_at": meta.get("generated_at"),
        "cards": [c.model_dump() for c in doc.cards],
        "source": meta.get("source", SOURCE_AI_GENERATED),
        "translation": {
            "provider": meta.get("provider"),
            "complete": True,
        },
        "metadata": meta,
    }


class FlashcardGenerationService:
    def __init__(
        self,
        registry: Optional[LanguageCapabilityRegistry] = None,
        image_library: Optional[FlashcardImageLibrary] = None,
    ):
        self.registry = registry or LanguageCapabilityRegistry()
        self.image_library = image_library or flashcard_image_library

    async def generate(
        self,
        params: FlashcardGenerationParams,
        db: AsyncSession,
        teacher_user_id: Optional[str] = None,
    ) -> FlashcardGenerationResult:
        mode = params.language_mode
        # Strict language gate: this generator serves hi/en/sat only.
        for code in params.source_languages() + ["sat"]:
            if normalize_language_code(code) not in ALLOWED_CODES:
                return FlashcardGenerationResult(
                    request_id=params.request_id, status="FAILED",
                    error="This flashcard generator supports Hindi, English and Santali only.",
                    retryable=False,
                )

        # Prototype image catalog first: covered topics are built from its
        # pictures + printed Santali labels. This lookup runs BEFORE any
        # provider is resolved, so catalog topics make zero translation calls.
        library_result = await self._build_from_catalog(
            params, db, teacher_user_id
        )
        if library_result is not None:
            return library_result

        concepts = resolve_concepts(
            params.topic, params.subject, params.nipun_outcome,
            params.flashcard_type, params.card_count,
        )
        if len(concepts) != params.card_count:
            return FlashcardGenerationResult(
                request_id=params.request_id, status="FAILED",
                error="Could not resolve concepts for this topic. Please try again.",
                retryable=True,
            )

        # TRILINGUAL FLOW (explicit, deterministic):
        # - Hindi text  = authored Hindi anchor (never translated).
        # - English text = authored English anchor (never translated).
        # - Santali text = ONE local translation call per card from a single canonical
        #   anchor: hi-IN for hi_sat and hi_en_sat (mirrors the worksheet
        #   Hindi-anchor pipeline), en-IN for en_sat. The anchor used is
        #   recorded per card (santali_source_lang) and in metadata, so
        #   Hindi/English/Santali for the SAME concept are always aligned
        #   and English is never derived from a Hindi translation.
        try:
            provider = self.registry.provider_for("hi", "sat")
        except TranslationNotConfiguredError as exc:
            return FlashcardGenerationResult(
                request_id=params.request_id, status="FAILED",
                error=str(exc), retryable=False,
            )
        provider_name = getattr(provider, "name", "local")

        items: List[TranslationItem] = []
        anchors: List[tuple] = []  # (anchor_lang, anchor_text) per card
        for i, c in enumerate(concepts):
            anchor_lang = "en" if mode == "en_sat" else "hi"
            anchor_text = c["hindi"] if anchor_lang == "hi" else c["english"]
            anchors.append((anchor_lang, anchor_text))
            items.append(TranslationItem(f"card_{i}", anchor_text))

        # provider_api_languages resolves correct BCP-47 codes per request.
        api_src, api_tgt = provider_api_languages(provider, "hi", "sat")
        if mode == "en_sat":
            api_src, api_tgt = provider_api_languages(provider, "en", "sat")
        try:
            batch = await asyncio.to_thread(
                provider.translate_batch, items, api_src, api_tgt
            )
        except TranslationRateLimitedError:
            return self._failed(params, provider_name,
                "Could not generate Santali translation. Please try again.", True)
        except (TranslationProviderError, TranslationUnsupportedError):
            return self._failed(params, provider_name,
                "Could not generate Santali translation. Please try again.", True)
        except TranslationNotConfiguredError:
            # Missing key / unconfigured language: never fake Santali.
            return self._failed(params, provider_name,
                "Could not generate Santali translation. Please try again.", False)

        by_id = {r.field_id: r for r in batch.results}
        cards: List[FlashcardItem] = []
        for i, c in enumerate(concepts):
            res = by_id.get(f"card_{i}")
            # Never fake Santali: empty/untranslated -> generation failure.
            if res is None or not res.translated or not (res.text or "").strip():
                return self._failed(params, provider_name,
                    "Could not generate Santali translation. Please try again.", True)
            santali = res.text.strip()
            # Number cards draw N items ( Five apples -> five apple
            # visuals ); the vector composer paints ``art``.
            visual_count = (i % 10) + 1 if params.flashcard_type == "number" else None
            visual = resolve_visual(
                c["english"], c["hindi"], params.visual_style, i,
                flashcard_type=params.flashcard_type, count=visual_count,
            )
            anchor_lang, anchor_text = anchors[i]
            cards.append(FlashcardItem(
                id=f"card_{i + 1:02d}",
                number=i + 1,
                concept=c["english"],
                type=params.flashcard_type,
                hindi=c["hindi"] if params.includes("hi") else None,
                english=c["english"] if params.includes("en") else None,
                santali=santali,
                santali_source=anchor_text,
                santali_source_lang=anchor_lang,
                visual=visual,
                provider=provider_name,
                translated=True,
            ))

        # Validation: requested count == generated count; every card has
        # concept + visual + required languages + non-empty Santali.
        errors = self._validate(params, cards)
        if errors:
            return FlashcardGenerationResult(
                request_id=params.request_id, status="FAILED",
                provider=provider_name,
                error="Generated flashcards failed validation: " + "; ".join(errors[:3]),
                retryable=False,
            )

        doc = FlashcardDocument(
            content_id=_content_id_for(params),
            request_id=params.request_id,
            title=f"{params.topic} ({params.card_count} cards)",
            cards=cards,
            metadata={
                "grade": params.grade,
                "section": params.section or "General",
                "subject": params.subject,
                "topic": params.topic,
                "topic_source": params.topic_source,
                "topic_id": params.topic_id,
                "topic_input_language": params.topic_input_language,
                "nipun_outcome": params.nipun_outcome,
                "nipun_code": params.nipun_code,
                "strand": params.strand,
                "language_mode": params.language_mode,
                "source_languages": params.source_languages(),
                "target_language": "sat",
                "target_language_code": "sat-IN",
                "source_language_codes": [
                    bcp47_code(normalize_language_code(s))
                    for s in params.source_languages()
                ],
                "santali_source_lang": "en" if mode == "en_sat" else "hi",
                "santali_source_code": api_src,
                "santali_target_code": api_tgt,
                "flashcard_type": params.flashcard_type,
                "difficulty": params.difficulty,
                "visual_style": params.visual_style,
                "pronunciation": params.pronunciation,
                "provider": provider_name,
                "source": SOURCE_AI_GENERATED,
                "api_source": api_src,
                "api_target": api_tgt,
            },
        )
        return await self._persist(params, db, teacher_user_id, doc, provider_name)

    async def _build_from_catalog(
        self,
        params: FlashcardGenerationParams,
        db: AsyncSession,
        teacher_user_id: Optional[str],
    ) -> Optional[FlashcardGenerationResult]:
        """Source selection BEFORE any provider call.

        Returns an IMAGE_CATALOG result when the prototype catalog covers
        the topic, a FAILED result when the teacher explicitly picked a
        catalog topic that cannot be served (never silently sent to
        local model), or None when the topic is not in the catalog (the local
        fallback).
        """
        library = self.image_library
        picked_from_catalog = params.topic_source == TOPIC_SOURCE_CATALOG
        deck = library.find_deck(params.topic, params.topic_id)
        if deck is None:
            if picked_from_catalog:
                return self._failed(params, PROVIDER_NAME,
                    "The selected picture topic is not in the prototype catalog.", False)
            return None
        items = library.build_cards(deck, params.includes("hi"), params.card_count)
        if not items:
            if picked_from_catalog:
                return self._failed(params, PROVIDER_NAME,
                    "No pictures in this topic have the words needed for this "
                    "language mode.", False)
            return None

        requested = params.card_count
        # The catalog may hold fewer pictures than requested for a topic.
        params = params.model_copy(update={"card_count": len(items)})
        cards: List[FlashcardItem] = []
        for i, item in enumerate(items):
            # The bundled catalog PNG IS the visual (no vector-art stand-in).
            visual: Dict[str, Any] = {
                "kind": "image",
                "source": SOURCE_IMAGE_CATALOG,
                "image": item["image"],
                "label_image": item["label_image"],
                "asset_id": item["asset_id"],
                "visual_type": item["visual_type"],
                "description_en": item["caption"] or "",
            }
            if item["hex"]:
                visual["hex"] = item["hex"]
            cards.append(FlashcardItem(
                id=f"card_{i + 1:02d}",
                number=i + 1,
                concept=item["concept"],
                type=params.flashcard_type,
                hindi=item["hindi"] if params.includes("hi") else None,
                english=item["english"] if params.includes("en") else None,
                santali=item["santali"],
                santali_source=f"{item['source_document'] or 'Prototype image catalog'}"
                               f" p.{item['source_page']}",
                santali_source_lang="sat",
                visual=visual,
                provider=PROVIDER_NAME,
                translated=False,
            ))

        errors = self._validate(params, cards)
        if errors:
            logger.warning("Catalog deck %s failed validation: %s", deck.id, errors[:3])
            return self._failed(params, PROVIDER_NAME,
                "Picture flashcards failed validation: " + "; ".join(errors[:3]), False)

        doc = FlashcardDocument(
            content_id=_content_id_for(params),
            request_id=params.request_id,
            title=f"{params.topic} ({len(cards)} cards)",
            cards=cards,
            metadata={
                "grade": params.grade,
                "section": params.section or "General",
                "subject": params.subject,
                "topic": params.topic,
                "topic_source": params.topic_source,
                "topic_id": params.topic_id,
                "topic_input_language": params.topic_input_language,
                "nipun_outcome": params.nipun_outcome,
                "nipun_code": params.nipun_code,
                "strand": params.strand,
                "language_mode": params.language_mode,
                "source_languages": params.source_languages(),
                "target_language": "sat",
                "target_language_code": "sat-IN",
                "flashcard_type": params.flashcard_type,
                "difficulty": params.difficulty,
                "visual_style": params.visual_style,
                "pronunciation": params.pronunciation,
                "provider": PROVIDER_NAME,
                "source": SOURCE_IMAGE_CATALOG,
                "library_deck_id": deck.id,
                "library_deck_label": deck.label,
                "requested_card_count": requested,
            },
        )
        return await self._persist(params, db, teacher_user_id, doc, PROVIDER_NAME)

    @staticmethod
    def _failed(params, provider, message, retryable) -> FlashcardGenerationResult:
        return FlashcardGenerationResult(
            request_id=params.request_id, status="FAILED",
            provider=provider, error=message, retryable=retryable,
        )

    @staticmethod
    def _validate(params: FlashcardGenerationParams, cards: List[FlashcardItem]) -> List[str]:
        errors: List[str] = []
        if len(cards) != params.card_count:
            errors.append(f"expected {params.card_count} cards, got {len(cards)}")
        seen = set()
        for c in cards:
            if not c.concept.strip():
                errors.append(f"{c.id}: missing concept")
            if not c.visual:
                errors.append(f"{c.id}: missing visual")
            if params.includes("hi") and not (c.hindi or "").strip():
                errors.append(f"{c.id}: missing Hindi")
            if params.includes("en") and not (c.english or "").strip():
                errors.append(f"{c.id}: missing English")
            if not (c.santali or "").strip():
                errors.append(f"{c.id}: missing Santali")
            elif "[sat]" in c.santali or "TODO" in c.santali or "placeholder" in c.santali.lower():
                errors.append(f"{c.id}: placeholder Santali")
            if not (c.santali_source or "").strip():
                errors.append(f"{c.id}: missing Santali source trace")
            key = (c.hindi or "", c.english or "", c.santali)
            if key in seen:
                errors.append(f"{c.id}: duplicate card data")
            seen.add(key)
        return errors

    async def _persist(
        self,
        params: FlashcardGenerationParams,
        db: AsyncSession,
        teacher_user_id: Optional[str],
        doc: FlashcardDocument,
        provider_name: str,
    ) -> FlashcardGenerationResult:
        from app.db.models.resource import SavedMaterial
        from app.storage.service import storage_service
        from app.worksheets.service import _ensure_teacher

        import datetime as _dt
        doc.metadata["generated_at"] = _dt.datetime.now(_dt.timezone.utc).isoformat()
        doc.metadata["version"] = 1
        payload = to_flutter_payload(doc)
        teacher_id = await _ensure_teacher(db, teacher_user_id or params.teacher_id)

        res = await db.execute(
            select(SavedMaterial).where(SavedMaterial.local_id == params.request_id)
        )
        material = res.scalar_one_or_none()
        if material is not None and getattr(material, "teacher_id", None) != teacher_id:
            raise PermissionError("Flashcards belong to a different teacher account.")
        if material is None:
            material = SavedMaterial(
                local_id=params.request_id,
                teacher_id=teacher_id,
                title=payload["title"],
                material_type="flashcard",
                payload=payload,
            )
            db.add(material)
            await db.flush()
        else:
            material.title = payload["title"]
            material.payload = payload
            material.teacher_id = teacher_id

        pdf_path = f"flashcards/{doc.content_id}.pdf"
        try:
            from app.flashcards.pdf import render_flashcard_pdf
            pdf_bytes = render_flashcard_pdf(doc)
            try:
                stored_pdf = storage_service.upload_bytes(
                    storage_service.bucket_flashcards, pdf_path, pdf_bytes,
                    content_type="application/pdf",
                )
            except Exception as exc:
                logger.warning("Flashcard PDF upload failed; keeping logical path: %s", exc)
                stored_pdf = pdf_path
        except Exception as exc:
            logger.warning("Flashcard PDF render failed: %s", exc)
            stored_pdf = None
        # JSON artifact alongside the PDF.
        try:
            stored_json = storage_service.upload_text_object(
                storage_service.bucket_flashcards,
                f"flashcards/{doc.content_id}.json",
                json.dumps(payload, ensure_ascii=False),
            )
        except Exception as exc:
            logger.warning("Flashcard JSON upload failed: %s", exc)
            stored_json = f"flashcards/{doc.content_id}.json"
        await db.commit()

        assets: Dict[str, Any] = {
            "flashcard_json": stored_json, "saved_material_id": material.id,
            "version": 1, "generated_at": doc.metadata.get("generated_at"),
        }
        if stored_pdf:
            assets["pdf"] = stored_pdf
        coverage = {
            "total_fields": len(doc.cards), "translated_fields": len(doc.cards),
            "untranslated_fields": [], "provider": provider_name,
        }
        return FlashcardGenerationResult(
            request_id=params.request_id,
            content_id=doc.content_id,
            status="READY",
            provider=provider_name,
            coverage=coverage,
            content=payload,
            assets=assets,
            saved_material_id=material.id,
        )


flashcard_generation_service = FlashcardGenerationService()
