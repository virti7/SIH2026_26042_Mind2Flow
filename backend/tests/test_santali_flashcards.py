"""Santali multilingual flashcard tests (Hi/En/Sat only).

Static example words are test-only fixtures. Production concepts come
from topic-based resolution + live Sarvam translation (mocked here).
"""
from pathlib import Path

import pytest
from httpx import AsyncClient

from app.flashcards.concepts import resolve_concepts
from app.flashcards.image_library import FlashcardImageLibrary
from app.flashcards.pdf import render_flashcard_pdf
from app.flashcards.schemas import (
    FlashcardDocument,
    FlashcardGenerationParams,
    FlashcardItem,
)
from app.flashcards.visuals import resolve_visual
from app.translation.providers import (
    BatchTranslation,
    SarvamTranslateProvider,
    TranslationItem,
    TranslationResult,
)


class _FakeSarvam(SarvamTranslateProvider):
    """Sarvam subclass so provider_api_languages resolves real BCP-47
    codes; translate_batch is stubbed (no network, no key)."""

    def __init__(self, mapping):
        super().__init__(api_key="test-key")
        self.mapping = mapping
        self.calls = []

    def translate_batch(self, items, source_lang, target_lang):
        self.calls.append((source_lang, target_lang))
        results = []
        for it in items:
            text = self.mapping.get(it.text.strip(), f"{it.text} (ᱥᱟᱱᱛᱟᱲᱤ)")
            results.append(TranslationResult(it.field_id, text, self.name, True))
        return BatchTranslation(results=results)


# Sarvam-path tests run without the picture library so topics such as
# "Fruits" exercise the translation fallback.
_NO_LIBRARY = FlashcardImageLibrary(root=Path("__no_image_library__"))


def _params(**over):
    base = dict(
        request_id="req-test-12345678",
        grade=1,
        subject="Environmental Studies",
        topic="Fruits",
        language_mode="hi_sat",
        flashcard_type="vocabulary",
        card_count=4,
    )
    base.update(over)
    return FlashcardGenerationParams(**base)


# LANGUAGE -----------------------------------------------------------------

def test_language_modes_only_hi_en_sat():
    assert _params(language_mode="hi_sat").source_languages() == ["hi"]
    assert _params(language_mode="en_sat").source_languages() == ["en"]
    assert _params(language_mode="hi_en_sat").source_languages() == ["hi", "en"]
    with pytest.raises(Exception):
        _params(language_mode="ho_sat")
    with pytest.raises(Exception):
        _params(language_mode="mundari")


def test_no_unsupported_language_in_generator():
    import app.flashcards.schemas as s

    assert s.ALLOWED_CODES == {"hi", "en", "sat"}
    assert "ho" not in s.ALLOWED_CODES and "unr" not in s.ALLOWED_CODES


# GENERATION ----------------------------------------------------------------

@pytest.mark.asyncio
async def test_generates_requested_count_with_sarvam_codes(db_session):
    from app.flashcards.service import FlashcardGenerationService
    from app.translation.registry import LanguageCapabilityRegistry

    mapping = {"आम": "ᱟᱢ", "केला": "ᱠᱮᱞᱟ", "अमरूद": "ᱟᱢᱨᱩᱫ", "पपीता": "ᱯᱟᱯᱤᱛᱟ"}
    fake = _FakeSarvam(mapping)

    class _Reg(LanguageCapabilityRegistry):
        def provider_for(self, source_lang, target_lang):
            return fake

    svc = FlashcardGenerationService(registry=_Reg(), image_library=_NO_LIBRARY)
    result = await svc.generate(
        _params(card_count=4), db_session, teacher_user_id="user-a-uuid-0001"
    )
    assert result.status == "READY", result.error
    assert result.content is not None
    assert len(result.content["cards"]) == 4
    assert result.content["target_language_code"] == "sat-IN"
    # Correct Sarvam codes used for hi_sat.
    assert fake.calls and fake.calls[0] == ("hi-IN", "sat-IN")
    for card in result.content["cards"]:
        assert card["santali"] and card["santali"] != card.get("hindi")
        assert card["visual"] and card["concept"]
    assert result.content["metadata"]["source_language_codes"] == ["hi-IN"]


@pytest.mark.asyncio
async def test_en_sat_uses_en_in_source(db_session):
    from app.flashcards.service import FlashcardGenerationService
    from app.translation.registry import LanguageCapabilityRegistry

    fake = _FakeSarvam({})

    class _Reg(LanguageCapabilityRegistry):
        def provider_for(self, source_lang, target_lang):
            return fake

    svc = FlashcardGenerationService(registry=_Reg(), image_library=_NO_LIBRARY)
    result = await svc.generate(
        _params(language_mode="en_sat", card_count=2),
        db_session, teacher_user_id="user-a-uuid-0002",
    )
    assert result.status == "READY", result.error
    assert fake.calls[0] == ("en-IN", "sat-IN")
    for card in result.content["cards"]:
        assert card["english"] and card["hindi"] is None


@pytest.mark.asyncio
async def test_hi_en_sat_has_all_three(db_session):
    from app.flashcards.service import FlashcardGenerationService
    from app.translation.registry import LanguageCapabilityRegistry

    fake = _FakeSarvam({})

    class _Reg(LanguageCapabilityRegistry):
        def provider_for(self, source_lang, target_lang):
            return fake

    svc = FlashcardGenerationService(registry=_Reg(), image_library=_NO_LIBRARY)
    result = await svc.generate(
        _params(language_mode="hi_en_sat", card_count=2),
        db_session, teacher_user_id="user-a-uuid-0003",
    )
    assert result.status == "READY", result.error
    for card in result.content["cards"]:
        # Same concept in all three languages; Santali traced to hi anchor.
        assert card["hindi"] and card["english"] and card["santali"]
        assert card["santali_source_lang"] == "hi"
        assert card["santali_source"] == card["hindi"]
        assert "[sat]" not in card["santali"]
    assert result.content["metadata"]["santali_source_code"] == "hi-IN"
    assert result.content["metadata"]["santali_target_code"] == "sat-IN"


@pytest.mark.asyncio
async def test_sarvam_failure_never_fakes_santali(db_session):
    from app.flashcards.service import FlashcardGenerationService
    from app.translation.providers import TranslationProviderError
    from app.translation.registry import LanguageCapabilityRegistry

    class _Boom:
        name = "sarvam-translate"

        def translate_batch(self, items, s, t):
            raise TranslationProviderError("down")

    class _Reg(LanguageCapabilityRegistry):
        def provider_for(self, source_lang, target_lang):
            return _Boom()

    svc = FlashcardGenerationService(registry=_Reg(), image_library=_NO_LIBRARY)
    result = await svc.generate(
        _params(card_count=2), db_session, teacher_user_id="user-a-uuid-0004"
    )
    assert result.status == "FAILED"
    assert "Santali" in (result.error or "")
    assert result.content is None


def test_concepts_come_from_topic_not_fixed_list():
    fruits = resolve_concepts("Fruits", "EVS", None, "vocabulary", 5)
    animals = resolve_concepts("Animals", "EVS", None, "vocabulary", 5)
    assert len(fruits) == 5 and len(animals) == 5
    assert {c["english"] for c in fruits} != {c["english"] for c in animals}


def test_visual_resolution_priority():
    v = resolve_visual("Mango", "आम", "illustrated", 0)
    assert v["source"] == "curated" and v["art"] == "mango" and v["has_text"] is False
    v2 = resolve_visual("XyzUnknownConcept", "अज्ञात", "illustrated", 1)
    assert v2["source"] in ("generated", "vector") and v2["has_text"] is False
    assert v2["art"] == "emblem"
    # Renderers must paint vector art, never emoji.
    assert "glyph" not in v and "glyph" not in v2


def test_number_visual_draws_count():
    v = resolve_visual("Five", "पाँच", "illustrated", 4, flashcard_type="number", count=5)
    assert v["art"] == "apples" and v["count"] == 5


def test_vector_art_emits_operators_not_text():
    from app.flashcards.vector_art import draw_art
    for art in ["mango", "cow", "triangle", "swatch", "apples", "emblem"]:
        ops = draw_art(art, 297.0, 600.0, 150.0, (0.1, 0.48, 0.3),
                       {"count": 5, "swatch": "red"})
        assert "q " in ops and ops.rstrip().endswith("Q")
        assert "Tj" not in ops  # no words inside the image
    pdf = render_flashcard_pdf(_doc(n=2))
    assert pdf[:4] == b"%PDF"


# PDF -----------------------------------------------------------------------

def _doc(mode="hi_en_sat", n=3):
    cards = [
        FlashcardItem(
            id=f"card_{i + 1:02d}", number=i + 1, concept=f"Concept{i}",
            hindi=f"शब्द{i}", english=f"Word{i}", santali=f"ᱥᱟᱱᱛᱟᱲᱤ{i}",
            visual={"art": "mango", "description_en": "illustration",
                    "source": "curated", "has_text": False,
                    "palette": "#E65100"},
        )
        for i in range(n)
    ]
    return FlashcardDocument(
        content_id="FC-TEST", request_id="req-test", title="Fruits (3 cards)",
        cards=cards,
        metadata={"grade": 1, "subject": "EVS", "topic": "Fruits",
                  "language_mode": mode, "flashcard_type": "vocabulary"},
    )


def test_pdf_one_page_per_card_with_glyphs():
    pdf = render_flashcard_pdf(_doc(n=3))
    assert pdf[:4] == b"%PDF"
    assert pdf.count(b"/Type /Page ") == 3 or pdf.count(b"/Type /Page") >= 3
    # Real multilingual content embedded (UTF-16BE hex), Santali present.
    assert "ᱥᱟᱱᱛᱟᱲᱤ".encode("utf-16-be").hex().upper().encode() in pdf
    assert "शब्द".encode("utf-16-be").hex().upper().encode() in pdf


# API -----------------------------------------------------------------------

@pytest.mark.asyncio
async def test_content_endpoint_rejects_bad_mode(client: AsyncClient, teacher_auth_headers: dict):
    payload = {"grade": 1, "subject": "Hindi", "topic": "Fruits",
               "language_mode": "ho_sat", "card_count": 4}
    r = await client.post("/api/v1/content/flashcards/generate", json=payload,
                          headers=teacher_auth_headers)
    assert r.status_code == 400


@pytest.mark.asyncio
async def test_content_endpoint_full_job_flow(client: AsyncClient, teacher_auth_headers: dict):
    from app.services.generation_jobs import generation_job_manager

    payload = {"grade": 1, "subject": "Hindi", "topic": "Fruits",
               "language_mode": "hi_sat", "flashcard_type": "vocabulary",
               "card_count": 2}
    r = await client.post("/api/v1/content/flashcards/generate", json=payload,
                          headers=teacher_auth_headers)
    assert r.status_code == 202
    job_id = r.json()["job_id"]
    generation_job_manager.execute_job_sync(job_id)
    job = generation_job_manager.get_job(job_id)
    assert job is not None
    # Without SARVAM_API_KEY in test env the job fails closed with a clear
    # Santali error (never fake content) or succeeds when configured.
    assert job.status in ("READY", "FAILED")
    if job.status == "READY":
        assert len(job.content["cards"]) == 2
    else:
        assert "Santali" in (job.error or "") or "translation" in (job.error or "").lower()


@pytest.mark.asyncio
async def test_account_isolation_between_teachers(client: AsyncClient, db_session):
    from jose import jwt
    from datetime import datetime, timedelta, timezone
    from app.core.config import settings
    from app.db.models.school import Teacher
    from app.flashcards.service import FlashcardGenerationService
    from app.translation.registry import LanguageCapabilityRegistry

    for uid in ("iso-user-aaa-0001", "iso-user-bbb-0002"):
        db_session.add(Teacher(user_id=uid, name=f"T {uid}",
                               email=f"{uid}@x.local"))
    await db_session.commit()

    fake = _FakeSarvam({})

    class _Reg(LanguageCapabilityRegistry):
        def provider_for(self, s, t):
            return fake

    svc = FlashcardGenerationService(registry=_Reg(), image_library=_NO_LIBRARY)
    for uid, topic in (("iso-user-aaa-0001", "Fruits"), ("iso-user-bbb-0002", "Animals")):
        res = await svc.generate(
            _params(topic=topic, card_count=2,
                    request_id=f"req-{uid}"), db_session, teacher_user_id=uid)
        assert res.status == "READY"

    def headers(uid):
        now = datetime.now(timezone.utc)
        tok = jwt.encode({"sub": uid, "email": f"{uid}@x.local",
                          "role": "authenticated", "user_metadata": {},
                          "app_metadata": {},
                          "exp": now + timedelta(hours=1), "iat": now},
                         settings.SUPABASE_JWT_SECRET or "dev-secret", algorithm="HS256")
        return {"Authorization": f"Bearer {tok}"}

    # Teacher B must not see teacher A's materials.
    r = await client.get("/api/v1/saved-materials?material_type=flashcard",
                         headers=headers("iso-user-bbb-0002"))
    assert r.status_code == 200
    titles = [m["title"] for m in r.json()]
    assert not any("Fruits" in t for t in titles)


# PROTOTYPE IMAGE CATALOG (image-first; Sarvam fallback only) ---------------

class _CountingRegistry:
    """Registry that records every provider lookup. Catalog topics must
    leave ``calls`` at 0 (the provider is never even resolved)."""

    def __init__(self, provider=None):
        self.calls = 0
        self._provider = provider

    def provider_for(self, source_lang, target_lang):
        self.calls += 1
        if self._provider is None:
            raise AssertionError("Sarvam must not be resolved for catalog topics")
        return self._provider


def test_catalog_resolves_topics():
    from app.flashcards.image_library import flashcard_image_library as lib

    assert lib.decks(), "bundled prototype catalog should load"
    assert lib.find_deck("Fruits").key == "fruits"
    assert lib.find_deck("फल").key == "fruits"
    assert lib.find_deck("Wild animals").key == "wild_animals"
    assert lib.find_deck("Animals").key == "animals"
    assert lib.find_deck("x", topic_id="06_fruits").key == "fruits"
    assert lib.find_deck("Addition") is None
    assert lib.find_deck("Shapes") is None


def test_catalog_rejects_path_traversal_and_absolute_paths():
    from app.flashcards.image_library import flashcard_image_library as lib

    assert lib.resolve_asset("images/fruits/fruit_apple_001.png") is not None
    assert lib.resolve_asset("../../backend/.env") is None
    assert lib.resolve_asset("images/../../../README.md") is None
    assert lib.resolve_asset("/etc/passwd") is None
    assert lib.resolve_asset("C:/Windows/win.ini") is None


def test_catalog_coverage_report():
    from app.flashcards.image_library import flashcard_image_library as lib

    report = lib.coverage_report()
    print("\nCATALOG COVERAGE:", {k: (len(v) if isinstance(v, list) else v)
                                 for k, v in report.items()})
    assert report["total_images"] > 0
    assert report["total_topics"] > 0
    assert report["duplicate_asset_ids"] == []
    assert report["missing_asset_id"] == 0
    assert report["broken_images"] == []
    assert report["uncategorised"] == []
    assert report["complete_trilingual_items"] > 0


@pytest.mark.asyncio
async def test_a_catalog_topic_uses_images_with_zero_sarvam_calls(db_session, monkeypatch):
    from app.core.config import settings
    from app.flashcards.service import FlashcardGenerationService

    # No Sarvam key: catalog topics must still succeed.
    monkeypatch.setattr(settings, "SARVAM_API_KEY", None)
    reg = _CountingRegistry()
    svc = FlashcardGenerationService(registry=reg)
    result = await svc.generate(
        _params(topic="Fruits", language_mode="hi_en_sat", card_count=5),
        db_session, teacher_user_id="user-cat-uuid-0001",
    )
    assert result.status == "READY", result.error
    assert reg.calls == 0, "Sarvam invocation count must be 0 for catalog topics"
    assert result.provider == "prototype-catalog"
    content = result.content
    assert content["source"] == "IMAGE_CATALOG"
    assert len(content["cards"]) == 5
    for card in content["cards"]:
        assert card["hindi"] and card["english"] and card["santali"]
        assert card["provider"] == "prototype-catalog"
        assert card["visual"]["kind"] == "image"
        assert card["visual"]["asset_id"]
        assert card["visual"]["image"].startswith(
            "assets/prototype_content/flashcards/images/fruits/")


@pytest.mark.asyncio
async def test_catalog_caps_count_to_available_pictures(db_session):
    from app.flashcards.service import FlashcardGenerationService

    reg = _CountingRegistry()
    svc = FlashcardGenerationService(registry=reg)
    result = await svc.generate(
        _params(topic="Colours", language_mode="en_sat", card_count=20),
        db_session, teacher_user_id="user-cat-uuid-0002",
    )
    assert result.status == "READY", result.error
    assert reg.calls == 0
    cards = result.content["cards"]
    assert 0 < len(cards) < 20
    assert result.content["metadata"]["requested_card_count"] == 20


@pytest.mark.asyncio
async def test_b_uncovered_topic_falls_back_to_sarvam(db_session):
    from app.flashcards.service import FlashcardGenerationService

    fake = _FakeSarvam({})
    reg = _CountingRegistry(provider=fake)
    svc = FlashcardGenerationService(registry=reg)
    result = await svc.generate(
        _params(topic="Shapes", flashcard_type="shape", card_count=3),
        db_session, teacher_user_id="user-cat-uuid-0003",
    )
    assert result.status == "READY", result.error
    assert reg.calls == 1 and fake.calls, "Sarvam fallback expected outside the catalog"
    assert result.content["source"] == "AI_GENERATED"
    assert result.provider == "sarvam-translate"


@pytest.mark.asyncio
async def test_c_invalid_catalog_topic_fails_without_sarvam(db_session):
    from app.flashcards.service import FlashcardGenerationService

    reg = _CountingRegistry()
    svc = FlashcardGenerationService(registry=reg)
    result = await svc.generate(
        _params(topic="Planets", topic_source="image_catalog",
                topic_id="99_planets", card_count=3),
        db_session, teacher_user_id="user-cat-uuid-0004",
    )
    assert result.status == "FAILED"
    assert "catalog" in (result.error or "")
    assert reg.calls == 0


@pytest.mark.asyncio
async def test_c_empty_topic_rejected_before_generation(client: AsyncClient, teacher_auth_headers):
    payload = {"grade": 1, "subject": "Hindi", "topic": "   ",
               "language_mode": "hi_sat", "card_count": 4}
    r = await client.post("/api/v1/content/flashcards/generate", json=payload,
                          headers=teacher_auth_headers)
    assert r.status_code == 400


@pytest.mark.asyncio
async def test_catalog_endpoint_requires_auth_and_lists_real_metadata(
        client: AsyncClient, teacher_auth_headers):
    r = await client.get("/api/v1/content/flashcards/catalog")
    assert r.status_code in (401, 403)
    r = await client.get("/api/v1/content/flashcards/catalog",
                         headers=teacher_auth_headers)
    assert r.status_code == 200
    body = r.json()
    assert body["source"] == "IMAGE_CATALOG"
    keys = {t["key"] for t in body["topics"]}
    assert {"fruits", "birds", "colours"} <= keys
    assert all(t["card_count"] > 0 for t in body["topics"])
    item = body["items"][0]
    assert item["asset_path"].startswith("assets/prototype_content/flashcards/")
    assert ":" not in item["asset_path"]
    assert item["image_available"] is True


@pytest.mark.asyncio
async def test_catalog_pdf_embeds_bundled_png_not_vector_art(db_session):
    from app.flashcards.service import FlashcardGenerationService

    svc = FlashcardGenerationService(registry=_CountingRegistry())
    result = await svc.generate(
        _params(topic="Birds", card_count=2), db_session,
        teacher_user_id="user-cat-uuid-0005",
    )
    assert result.status == "READY", result.error
    cards = result.content["cards"]
    assert all("art" not in c["visual"] for c in cards), "no vector stand-in"
    doc = FlashcardDocument(
        content_id="FC-CAT-PDF", request_id="r", title="Birds",
        cards=[FlashcardItem(**c) for c in cards],
        metadata=result.content["metadata"],
    )
    pdf = render_flashcard_pdf(doc)
    assert pdf.startswith(b"%PDF")
    assert pdf.count(b"/Subtype /Image") == 2
    assert b"/Im1 Do" in pdf
