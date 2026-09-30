"""Multilingual source-language tests for worksheet generation.

Verifies the registry-routed two-leg pipeline: any provider-supported
language may serve as source; Ho/Mundari stay on custom pipelines; unknown
languages fail clearly. Sarvam HTTP is faked deterministically with exact
language-code call assertions (no key material anywhere).
"""
import uuid

import pytest

from app.translation.providers import CorpusNmtProvider, SarvamTranslateProvider
from app.translation.registry import LanguageCapabilityRegistry
from app.worksheets.schemas import WorksheetGenerationParams
from app.worksheets.service import worksheet_generation_service
from app.worksheets.translator import rebase_source
from app.worksheets.validator import check_numeric_preserved


class FakeResp:
    def __init__(self, status_code, payload):
        self.status_code = status_code
        self._payload = payload

    def json(self):
        return self._payload


class RecordingTranslateClient:
    """Fake Sarvam /translate that records exact (source, target) codes."""

    calls = []
    fail_400_pairs = set()

    def __init__(self, *args, **kwargs):
        pass

    def post(self, url, headers=None, json=None, timeout=None):
        pair = (json["source_language_code"], json["target_language_code"])
        RecordingTranslateClient.calls.append((pair[0], pair[1], json["input"]))
        if pair in RecordingTranslateClient.fail_400_pairs:
            return FakeResp(400, {"error": "unsupported language pair"})
        return FakeResp(200, {"translated_text": f"[{pair[1]}] {json['input']}"})

    def close(self):
        pass


def _enable_recording_sarvam(monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "SARVAM_API_KEY", "test-sarvam-key")
    import app.translation.providers as providers_mod

    RecordingTranslateClient.calls = []
    RecordingTranslateClient.fail_400_pairs = set()
    monkeypatch.setattr(providers_mod.httpx, "Client", RecordingTranslateClient)


def _params(source, target, **overrides):
    base = {
        "request_id": f"req-{uuid.uuid4()}",
        "grade": 2,
        "subject": "Mathematics",
        "topic": "Numbers up to 100",
        "nipun_outcome": "M2.1.4",
        "nipun_code": "M2.1.4",
        "source_language": source,
        "target_language": target,
        "worksheet_type": "practice",
        "question_count": 2,
        "difficulty": "easy",
        "visual_support": False,
        "origin": "online",
    }
    base.update(overrides)
    return WorksheetGenerationParams(**base)


def _pairs():
    return [(c[0], c[1]) for c in RecordingTranslateClient.calls]


# ---------------------------------------------------------------------------
# Registry routing is target-driven; sources are not hardcoded
# ---------------------------------------------------------------------------

def test_registry_serves_sarvam_pairs_in_both_directions():
    registry = LanguageCapabilityRegistry()
    assert isinstance(registry.provider_for("hi", "sat"), SarvamTranslateProvider)
    assert isinstance(registry.provider_for("sat", "hi"), SarvamTranslateProvider)
    assert isinstance(registry.provider_for("en", "sat"), SarvamTranslateProvider)
    assert isinstance(registry.provider_for("bn", "sat"), SarvamTranslateProvider)


def test_registry_keeps_ho_mundari_off_sarvam_regardless_of_source():
    registry = LanguageCapabilityRegistry()
    for target in ("ho", "unr", "mundari"):
        assert isinstance(registry.provider_for("hi", target), CorpusNmtProvider)
        assert isinstance(registry.provider_for("sat", target), CorpusNmtProvider)


# ---------------------------------------------------------------------------
# Hindi -> Santali (+ exact codes)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_hindi_to_santali_reports_exact_codes(db_session, monkeypatch):
    _enable_recording_sarvam(monkeypatch)
    result = await worksheet_generation_service.generate(
        _params("hi", "sat"), db_session, "teacher-user-1"
    )
    assert result.status == "READY"
    assert result.provider == "sarvam-translate"
    assert ("hi-IN", "sat-IN") in _pairs()
    content = result.content
    assert content["source_language"] == "hi"
    assert content["target_language"] == "sat"
    assert all(q["promptHindi"] and q["promptTribal"] for q in content["questions"])


# ---------------------------------------------------------------------------
# English -> Santali (source leg hi->en, then en->sat)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_english_to_santali_uses_two_sarvam_legs(db_session, monkeypatch):
    _enable_recording_sarvam(monkeypatch)
    result = await worksheet_generation_service.generate(
        _params("en", "sat"), db_session, "teacher-user-1"
    )
    assert result.status == "READY"
    pairs = _pairs()
    assert ("hi-IN", "en-IN") in pairs  # source leg
    assert ("en-IN", "sat-IN") in pairs  # target leg
    content = result.content
    assert content["source_language"] == "en"
    assert content["target_language"] == "sat"
    assert content["translation"]["complete"] is True
    q = content["questions"][0]
    assert "[en-IN]" in q["prompt_source"]
    assert "[sat-IN]" in q["prompt_target"]
    assert q["prompt_source_lang"] == "en"
    assert q["prompt_target_lang"] == "sat"


# ---------------------------------------------------------------------------
# Santali -> Hindi (bidirectional verification)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_santali_to_hindi_round_trip(db_session, monkeypatch):
    _enable_recording_sarvam(monkeypatch)
    result = await worksheet_generation_service.generate(
        _params("sat", "hi"), db_session, "teacher-user-1"
    )
    assert result.status == "READY"
    pairs = _pairs()
    assert ("hi-IN", "sat-IN") in pairs
    assert ("sat-IN", "hi-IN") in pairs  # genuine reverse-direction call
    content = result.content
    assert content["source_language"] == "sat"
    assert content["target_language"] == "hi"
    assert len(content["questions"]) == 2


# ---------------------------------------------------------------------------
# Bengali -> Santali (another Sarvam-supported Indic source)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_bengali_to_santali(db_session, monkeypatch):
    _enable_recording_sarvam(monkeypatch)
    result = await worksheet_generation_service.generate(
        _params("bn", "sat"), db_session, "teacher-user-1"
    )
    assert result.status == "READY"
    pairs = _pairs()
    assert ("hi-IN", "bn-IN") in pairs
    assert ("bn-IN", "sat-IN") in pairs
    assert result.content["source_language"] == "bn"


# ---------------------------------------------------------------------------
# Same-language non-Hindi anchor (sat -> sat)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_santali_to_santali_copies_anchor(db_session, monkeypatch):
    _enable_recording_sarvam(monkeypatch)
    result = await worksheet_generation_service.generate(
        _params("sat", "sat"), db_session, "teacher-user-1"
    )
    assert result.status == "READY"
    # Only the source leg ran; nothing was copied from Hindi as Santali.
    assert ("hi-IN", "sat-IN") in _pairs()
    content = result.content
    for q in content["questions"]:
        assert q["prompt_source"] == q["prompt_target"]
        assert "[sat-IN]" in q["prompt_source"]


# ---------------------------------------------------------------------------
# Ho as source without coverage -> clear failure (never fake Ho)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_ho_source_without_coverage_fails_cleanly(db_session, monkeypatch):
    _enable_recording_sarvam(monkeypatch)
    result = await worksheet_generation_service.generate(
        _params("ho", "sat"), db_session, "teacher-user-1"
    )
    assert result.status == "FAILED"
    assert "Ho" in (result.error or "")
    assert "source" in (result.error or "").lower()


# ---------------------------------------------------------------------------
# Unknown languages fail clearly on either side
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_unknown_source_language_fails_cleanly(db_session, monkeypatch):
    _enable_recording_sarvam(monkeypatch)
    result = await worksheet_generation_service.generate(
        _params("xx", "sat"), db_session, "teacher-user-1"
    )
    assert result.status == "FAILED"
    assert "not currently configured" in (result.error or "")


@pytest.mark.asyncio
async def test_unknown_target_language_fails_cleanly(db_session, monkeypatch):
    _enable_recording_sarvam(monkeypatch)
    result = await worksheet_generation_service.generate(
        _params("hi", "xx"), db_session, "teacher-user-1"
    )
    assert result.status == "FAILED"
    assert "not currently configured" in (result.error or "")


# ---------------------------------------------------------------------------
# Provider-rejected pair is a clear non-retryable failure
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_rejected_pair_fails_without_retry(db_session, monkeypatch):
    _enable_recording_sarvam(monkeypatch)
    RecordingTranslateClient.fail_400_pairs = {("mr-IN", "sat-IN")}
    result = await worksheet_generation_service.generate(
        _params("mr", "sat"), db_session, "teacher-user-1"
    )
    assert result.status == "FAILED"
    assert result.retryable is False


# ---------------------------------------------------------------------------
# Unicode-digit numeric preservation (e.g. Ol Chiki digits)
# ---------------------------------------------------------------------------

def test_numeric_check_is_unicode_digit_aware():
    # Ol Chiki digits must compare equal to their ASCII counterparts.
    assert check_numeric_preserved([("q1", "गिनो 1, 2", "[sat] गिनो ᱑, ᱒")]) == []
    assert check_numeric_preserved([("q1", "गिनो 12", "[sat] गिनो ᱑᱒")]) == []
    bad = check_numeric_preserved([("q1", "गिनो 1, 2", "[sat] गिनो 1, 3")])
    assert len(bad) == 1 and "q1" in bad[0]


def test_rebase_rejects_partial_anchor():
    from app.worksheets.builder import ScaffoldBuilder

    doc = ScaffoldBuilder().build(
        request_id="rebase-test", grade=2, subject="Mathematics", topic="T",
        nipun_outcome=None, nipun_code=None, source_language="hi",
        target_language="sat", worksheet_type="practice", question_count=1,
        difficulty="easy", visual_support=False, bilingual_answers=True, audio_cue=False,
    )
    # Anchor leg never ran: targets empty -> rebase must refuse, not fake.
    try:
        rebase_source(doc, "sarvam-translate")
    except ValueError as exc:
        assert "incomplete" in str(exc).lower()
    else:
        raise AssertionError("rebase_source accepted an untranslated anchor")
