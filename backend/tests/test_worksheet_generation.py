"""Tests for server-side bilingual worksheet generation.

Covers: provider registry routing, Sarvam Translate batching, Santali
support, Ho/Mundari custom routing, unsupported-language rejection,
duplicate request_id idempotency, ordering, bilingual completeness, NIPUN
preservation, saved-material persistence, provider failure, 429 handling,
retry behavior, and authentication.
"""
import uuid
from datetime import datetime, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy import select

from app.db.models.resource import SavedMaterial
from app.translation.providers import (
    CorpusNmtProvider,
    SarvamTranslateProvider,
    TranslationItem,
    TranslationNotConfiguredError,
    TranslationRateLimitedError,
    TranslationUnsupportedError,
    chunk_items,
)
from app.translation.registry import LanguageCapabilityRegistry, normalize_language_code
from app.worksheets.builder import ScaffoldBuilder
from app.worksheets.schemas import WorksheetGenerationParams
from app.worksheets.service import worksheet_generation_service
from app.worksheets.validator import validate_worksheet


# ---------------------------------------------------------------------------
# Fakes
# ---------------------------------------------------------------------------

class FakeResp:
    def __init__(self, status_code, payload):
        self.status_code = status_code
        self._payload = payload

    def json(self):
        return self._payload


class FakeTranslateClient:
    """Deterministic Sarvam /translate stand-in: echoes tagged text."""

    def __init__(self, *args, **kwargs):
        pass

    def post(self, url, headers=None, json=None, timeout=None):
        assert "/translate" in url
        assert headers and "api-subscription-key" in headers
        # The key itself must never travel in the URL.
        assert "test-sarvam-key" not in url
        return FakeResp(200, {"translated_text": f"[{json['target_language_code']}] {json['input']}"})

    def close(self):
        pass


class Fake429Client(FakeTranslateClient):
    def post(self, url, headers=None, json=None, timeout=None):
        return FakeResp(429, {"error": "rate limited"})


class Fake500Client(FakeTranslateClient):
    def post(self, url, headers=None, json=None, timeout=None):
        return FakeResp(500, {"error": "boom"})


def _enable_sarvam(monkeypatch, client_cls=FakeTranslateClient):
    from app.core.config import settings

    monkeypatch.setattr(settings, "SARVAM_API_KEY", "test-sarvam-key")
    import app.translation.providers as providers_mod

    monkeypatch.setattr(providers_mod.httpx, "Client", client_cls)


def _params(**overrides):
    base = {
        "request_id": f"req-{uuid.uuid4()}",
        "grade": 2,
        "subject": "Mathematics",
        "topic": "Numbers up to 100",
        "nipun_outcome": "M2.1.4",
        "nipun_code": "M2.1.4",
        "source_language": "hi",
        "target_language": "sat",
        "worksheet_type": "practice",
        "question_count": 3,
        "difficulty": "easy",
        "visual_support": True,
        "origin": "online",
    }
    base.update(overrides)
    return WorksheetGenerationParams(**base)


# ---------------------------------------------------------------------------
# A/B/C: registry routing + codes
# ---------------------------------------------------------------------------

def test_registry_routes_santali_to_sarvam():
    registry = LanguageCapabilityRegistry()
    provider = registry.provider_for("hi", "sat")
    assert isinstance(provider, SarvamTranslateProvider)


def test_registry_routes_ho_and_mundari_to_custom():
    registry = LanguageCapabilityRegistry()
    assert isinstance(registry.provider_for("hi", "ho"), CorpusNmtProvider)
    assert isinstance(registry.provider_for("hi", "mundari"), CorpusNmtProvider)
    assert isinstance(registry.provider_for("hi", "unr"), CorpusNmtProvider)


def test_registry_rejects_unsupported_language():
    registry = LanguageCapabilityRegistry()
    with pytest.raises(TranslationNotConfiguredError) as exc:
        registry.provider_for("hi", "xx")
    assert "not currently configured" in str(exc.value)


def test_normalize_language_codes():
    assert normalize_language_code("sat-IN") == "sat"
    assert normalize_language_code("Santali") == "sat"
    assert normalize_language_code("mundari") == "unr"
    assert normalize_language_code("Ho") == "ho"
    assert normalize_language_code("hi-IN") == "hi"


# ---------------------------------------------------------------------------
# F: Sarvam provider batching + limits
# ---------------------------------------------------------------------------

def test_sarvam_batch_preserves_order_and_ids(monkeypatch):
    _enable_sarvam(monkeypatch)
    provider = SarvamTranslateProvider()
    items = [TranslationItem(f"q{i}", f"प्रश्न {i} गिनो") for i in range(1, 8)]
    batch = provider.translate_batch(items, "hi-IN", "sat-IN")
    assert [r.field_id for r in batch.results] == [f"q{i}" for i in range(1, 8)]
    assert all(r.translated and r.provider == "sarvam-translate" for r in batch.results)
    assert all("[sat-IN]" in r.text for r in batch.results)


def test_sarvam_numeric_passthrough_never_translated(monkeypatch):
    _enable_sarvam(monkeypatch)
    provider = SarvamTranslateProvider()
    batch = provider.translate_batch([TranslationItem("n", "42")], "hi-IN", "sat-IN")
    assert batch.results[0].text == "42"
    assert batch.results[0].provider == "passthrough"


def test_sarvam_unsupported_target_rejected(monkeypatch):
    _enable_sarvam(monkeypatch)
    provider = SarvamTranslateProvider()
    with pytest.raises(TranslationUnsupportedError):
        provider.translate_batch([TranslationItem("t", "नमस्ते")], "hi-IN", "ho")


def test_sarvam_429_maps_to_rate_limited(monkeypatch):
    _enable_sarvam(monkeypatch, Fake429Client)
    provider = SarvamTranslateProvider()
    with pytest.raises(TranslationRateLimitedError):
        provider.translate_batch([TranslationItem("t", "नमस्ते")], "hi-IN", "sat-IN")


def test_chunking_preserves_boundaries():
    items = [TranslationItem(f"f{i}", "x" * 900) for i in range(5)]
    chunks = chunk_items(items, max_chars=2000, max_items=25)
    assert [len(c) for c in chunks] == [2, 2, 1]
    assert [it.field_id for c in chunks for it in c] == [f"f{i}" for i in range(5)]


# ---------------------------------------------------------------------------
# H/I/J: Ho/Mundari routing + unsupported
# ---------------------------------------------------------------------------

def test_custom_provider_unconfigured_raises_clear_error():
    provider = CorpusNmtProvider("ho")
    with pytest.raises(TranslationNotConfiguredError) as exc:
        provider.translate_batch([TranslationItem("t", "गिनो")], "hi", "ho")
    assert "Ho" in str(exc.value)


def test_custom_provider_glossary_and_verified_lookup():
    provider = CorpusNmtProvider(
        "unr",
        verified_lookup=lambda text, src, tgt: "VERIFIED-UNR" if text == "गिनो" else None,
        glossary_path=None,
    )
    # Force configured state via lookup (glossary empty, no NMT).
    provider._verified_lookup = lambda text, src, tgt: "V" if text == "गिनो" else None
    batch = provider.translate_batch(
        [TranslationItem("a", "गिनो"), TranslationItem("b", "अज्ञात पाठ")], "hi", "unr"
    )
    by_id = {r.field_id: r for r in batch.results}
    assert by_id["a"].translated and by_id["a"].text == "V"
    assert not by_id["b"].translated
    assert by_id["b"].text == "अज्ञात पाठ"  # source preserved, flagged


# ---------------------------------------------------------------------------
# Builder: structure, caps, determinism
# ---------------------------------------------------------------------------

def test_builder_counts_ids_and_grade_caps():
    builder = ScaffoldBuilder()
    doc = builder.build(
        request_id="req-det-1", grade=2, subject="Mathematics", topic="Numbers up to 100",
        nipun_outcome="M2.1.4", nipun_code="M2.1.4", source_language="hi",
        target_language="sat", worksheet_type="practice", question_count=4,
        difficulty="easy", visual_support=True, bilingual_answers=True, audio_cue=False,
    )
    assert len(doc.questions) == 4
    assert [q.id for q in doc.questions] == ["q1", "q2", "q3", "q4"]
    assert doc.metadata["nipun_code"] == "M2.1.4"
    assert doc.metadata["target_language"] == "sat"
    assert doc.title.source and doc.instructions.source

    g1 = ScaffoldBuilder().build(
        request_id="req-g1", grade=1, subject="Mathematics", topic="T",
        nipun_outcome=None, nipun_code=None, source_language="hi", target_language="sat",
        worksheet_type="counting", question_count=6, difficulty="easy",
        visual_support=False, bilingual_answers=True, audio_cue=False,
    )
    import re

    for q in g1.questions:
        for n in re.findall(r"\d+", q.prompt.source):
            assert int(n) <= 20  # X_G1_NUMBER_RANGE / X_G1_COUNT_RANGE


def test_builder_deterministic_per_request_id():
    kwargs = dict(
        grade=2, subject="Mathematics", topic="Numbers up to 100",
        nipun_outcome="M2.1.4", nipun_code="M2.1.4", source_language="hi",
        target_language="sat", worksheet_type="practice", question_count=3,
        difficulty="easy", visual_support=True, bilingual_answers=True, audio_cue=False,
    )
    a = ScaffoldBuilder().build(request_id="same-req", **kwargs)
    b = ScaffoldBuilder().build(request_id="same-req", **kwargs)
    assert [q.prompt.source for q in a.questions] == [q.prompt.source for q in b.questions]


def test_builder_rejects_unsupported_source():
    with pytest.raises(ValueError):
        ScaffoldBuilder().build(
            request_id="r", grade=2, subject="M", topic="T", nipun_outcome=None,
            nipun_code=None, source_language="xx", target_language="sat",
            worksheet_type="practice", question_count=2, difficulty="easy",
            visual_support=False, bilingual_answers=True, audio_cue=False,
        )


# ---------------------------------------------------------------------------
# E/G/M/N: service success path (mocked Sarvam HTTP)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_service_generates_complete_bilingual_worksheet(db_session, monkeypatch):
    _enable_sarvam(monkeypatch)
    params = _params(question_count=3)
    result = await worksheet_generation_service.generate(params, db_session, "teacher-user-1")
    assert result.status == "READY"
    assert result.provider == "sarvam-translate"
    content = result.content
    assert content["question_count"] == 3
    assert len(content["questions"]) == 3
    # M: every question bilingual, none Hindi-only.
    for q in content["questions"]:
        assert q["promptHindi"] and q["promptTribal"]
        assert q["promptHindi"] != q["promptTribal"]
        assert q["answer"] and q["options"]
    assert content["translation"]["complete"] is True
    # N: NIPUN metadata preserved.
    assert content["curriculum_id"] == "M2.1.4"
    assert content["nipun_outcome"] == "M2.1.4"
    assert content["metadata"]["nipun_code"] == "M2.1.4"
    assert content["target_language"] == "sat"
    # P: persisted as teacher saved material (drives Saved Materials + Progress).
    res = await db_session.execute(
        select(SavedMaterial).where(SavedMaterial.local_id == params.request_id)
    )
    material = res.scalar_one_or_none()
    assert material is not None
    assert material.material_type == "worksheet"
    assert result.saved_material_id == material.id


@pytest.mark.asyncio
async def test_duplicate_request_id_is_idempotent(db_session, monkeypatch):
    _enable_sarvam(monkeypatch)
    params = _params()
    first = await worksheet_generation_service.generate(params, db_session, "teacher-user-1")
    second = await worksheet_generation_service.generate(params, db_session, "teacher-user-1")
    assert first.status == "READY" and second.status == "READY"
    assert first.content_id == second.content_id
    res = await db_session.execute(
        select(SavedMaterial).where(SavedMaterial.local_id == params.request_id)
    )
    assert len(res.scalars().all()) == 1


@pytest.mark.asyncio
async def test_unsupported_language_fails_cleanly(db_session, monkeypatch):
    _enable_sarvam(monkeypatch)
    params = _params(target_language="xx")
    result = await worksheet_generation_service.generate(params, db_session, "teacher-user-1")
    assert result.status == "FAILED"
    assert "not currently configured" in (result.error or "")


@pytest.mark.asyncio
async def test_ho_without_configuration_fails_cleanly(db_session, monkeypatch):
    _enable_sarvam(monkeypatch)
    params = _params(target_language="ho")
    result = await worksheet_generation_service.generate(params, db_session, "teacher-user-1")
    assert result.status == "FAILED"
    assert "Ho" in (result.error or "")


@pytest.mark.asyncio
async def test_sarvam_429_is_retryable(db_session, monkeypatch):
    _enable_sarvam(monkeypatch, Fake429Client)
    params = _params()
    result = await worksheet_generation_service.generate(params, db_session, "teacher-user-1")
    assert result.status == "FAILED"
    assert result.retryable is True


@pytest.mark.asyncio
async def test_sarvam_500_is_retryable(db_session, monkeypatch):
    _enable_sarvam(monkeypatch, Fake500Client)
    params = _params()
    result = await worksheet_generation_service.generate(params, db_session, "teacher-user-1")
    assert result.status == "FAILED"
    assert result.retryable is True


# ---------------------------------------------------------------------------
# D: sync upload of queued offline request + idempotent replay
# ---------------------------------------------------------------------------

def _sync_payload(request_id, **overrides):
    payload = {
        "request_id": request_id,
        "grade": 2,
        "subject": "Mathematics",
        "topic": "Numbers up to 100",
        "nipun_outcome": "M2.1.4",
        "nipun_code": "M2.1.4",
        "source_language": "hi",
        "target_language": "sat",
        "worksheet_type": "practice",
        "question_count": 2,
        "difficulty": "easy",
        "visual_support": True,
        "origin": "offline",
    }
    payload.update(overrides)
    return {
        "device_id": "tablet_jharkhand_001",
        "app_version": "1.0.0",
        "operations": [
            {
                "operation_id": request_id,
                "entity_type": "worksheet_generation",
                "entity_id": request_id,
                "operation": "CREATE",
                "payload": payload,
                "client_updated_at": datetime.now(timezone.utc).isoformat(),
            }
        ],
    }


@pytest.mark.asyncio
async def test_sync_upload_generates_worksheet_and_replay_is_idempotent(
    client: AsyncClient, teacher_auth_headers: dict, monkeypatch
):
    _enable_sarvam(monkeypatch)
    request_id = f"req-{uuid.uuid4()}"
    res1 = await client.post(
        "/api/v1/sync/upload", json=_sync_payload(request_id), headers=teacher_auth_headers
    )
    assert res1.status_code == 200
    body1 = res1.json()
    assert body1["successful_count"] == 1
    r1 = body1["results"][0]
    assert r1["status"] == "SUCCESS"
    data = r1["data"]
    assert data["status"] == "READY"
    assert len(data["content"]["questions"]) == 2
    assert data["content"]["target_language"] == "sat"

    res2 = await client.post(
        "/api/v1/sync/upload", json=_sync_payload(request_id), headers=teacher_auth_headers
    )
    dup = res2.json()["results"][0]
    assert dup["status"] == "DUPLICATE_IGNORED"
    assert dup["data"]["content_id"] == data["content_id"]


@pytest.mark.asyncio
async def test_sync_upload_unsupported_language_fails_retryable(
    client: AsyncClient, teacher_auth_headers: dict, monkeypatch
):
    _enable_sarvam(monkeypatch)
    request_id = f"req-{uuid.uuid4()}"
    res = await client.post(
        "/api/v1/sync/upload",
        json=_sync_payload(request_id, target_language="xx"),
        headers=teacher_auth_headers,
    )
    assert res.status_code == 200
    body = res.json()
    assert body["failed_count"] == 1
    assert body["results"][0]["status"] == "FAILED"


# ---------------------------------------------------------------------------
# T: authentication on generation endpoints
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_worksheet_generate_requires_auth(client: AsyncClient):
    # Canonical route (no /resources infix: the router is mounted at /api/v1,
    # consistent with GET /api/v1/worksheets).
    res = await client.post(
        "/api/v1/worksheets/generate",
        json={"grade": 2, "subject": "Mathematics", "target_language": "sat"},
    )
    assert res.status_code == 401


@pytest.mark.asyncio
async def test_worksheet_generate_accepts_teacher_request(
    client: AsyncClient, teacher_auth_headers: dict
):
    res = await client.post(
        "/api/v1/worksheets/generate",
        json={
            "grade": 2,
            "subject": "Mathematics",
            "topic": "Numbers up to 100",
            "nipun_outcome": "M2.1.4",
            "target_language": "sat",
            "question_count": 2,
            "request_id": f"req-{uuid.uuid4()}",
        },
        headers=teacher_auth_headers,
    )
    # Accepted for background execution; client polls the job (no Sync press).
    assert res.status_code == 202
    assert res.json()["job_id"]
