"""Server-side translation providers.

All providers run on the backend only. API keys never leave the server.
"""
from __future__ import annotations

import json
import logging
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional

import httpx

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Errors (never include secret values in messages)
# ---------------------------------------------------------------------------

class TranslationError(Exception):
    """Base translation failure."""


class TranslationNotConfiguredError(TranslationError):
    """No provider exists for the requested language."""


class TranslationRateLimitedError(TranslationError):
    """Provider throttled the request (HTTP 429). Retryable."""


class TranslationUnsupportedError(TranslationError):
    """Provider rejected the language pair."""


class TranslationProviderError(TranslationError):
    """Provider-side failure (HTTP 5xx, network, malformed response)."""


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

@dataclass
class TranslationItem:
    """One translatable leaf field. IDs preserve worksheet structure."""

    field_id: str
    text: str


@dataclass
class TranslationResult:
    field_id: str
    text: str  # translated text, or source text when untranslated
    provider: str
    translated: bool = True
    error: Optional[str] = None


@dataclass
class BatchTranslation:
    results: List[TranslationResult] = field(default_factory=list)

    @property
    def translated_count(self) -> int:
        return sum(1 for r in self.results if r.translated)

    @property
    def total_count(self) -> int:
        return len(self.results)


# ---------------------------------------------------------------------------
# Provider abstraction: Provider -> supports(language) -> translate(...)
# ---------------------------------------------------------------------------

class TranslationProvider(ABC):
    """Translation provider contract."""

    name: str = "base"

    @abstractmethod
    def supports(self, source_lang: str, target_lang: str) -> bool:
        """True when this provider handles the language pair."""

    @abstractmethod
    def translate_batch(
        self,
        items: List[TranslationItem],
        source_lang: str,
        target_lang: str,
    ) -> BatchTranslation:
        """Translate items preserving order and IDs."""


def chunk_items(
    items: List[TranslationItem],
    max_chars: int,
    max_items: int,
) -> List[List[TranslationItem]]:
    """Split items into chunks preserving order, IDs, and question boundaries.

    A chunk boundary is only ever placed *between* items, never inside a
    field. Numeric-only items are passed through untranslated by the caller.
    """
    chunks: List[List[TranslationItem]] = []
    current: List[TranslationItem] = []
    current_chars = 0
    for item in items:
        size = len(item.text)
        if current and (len(current) >= max_items or current_chars + size > max_chars):
            chunks.append(current)
            current = []
            current_chars = 0
        current.append(item)
        current_chars += size
    if current:
        chunks.append(current)
    return chunks


def is_numeric_text(text: str) -> bool:
    """True for pure numbers/symbols that must never be sent for translation."""
    stripped = text.strip()
    if not stripped:
        return True
    return all(ch.isdigit() or ch in " .,+−-×÷=%()[]/" for ch in stripped)


# ---------------------------------------------------------------------------
# Local model provider (app/ FastAPI service on 127.0.0.1)
# ---------------------------------------------------------------------------

class LocalServiceTranslateProvider(TranslationProvider):
    """Translate via the project's own local model service.

    The service (``app/main.py``) runs ONNX INT8 ASR, IndicTrans2 and Indic
    Parler-TTS on this machine. No API key, no outbound internet request, and no
    third-party inference: this provider only forwards text to a loopback
    address owned by the same repository.

    It supports the language pairs the local model actually covers, which is
    Hindi <-> Santali. Anything else fails closed with a clear error instead of
    silently returning untranslated text.
    """

    name = "local-indictrans2"

    #: Internal code pairs the local IndicTrans2 model supports.
    SUPPORTED_PAIRS = frozenset({("hi", "sat"), ("sat", "hi")})

    def __init__(
        self,
        base_url: Optional[str] = None,
        timeout: float = 120.0,
        client: Optional["httpx.Client"] = None,
    ):
        from app.core.config import settings

        self.base_url = (base_url or settings.LOCAL_TRANSLATION_SERVICE_URL).rstrip("/")
        self.timeout = timeout or settings.LOCAL_TRANSLATION_SERVICE_TIMEOUT
        self._client = client
        self._owns_client = client is None

    def supports(self, source_lang: str, target_lang: str) -> bool:
        return (source_lang.lower(), target_lang.lower()) in self.SUPPORTED_PAIRS

    def _translate_one(self, client: "httpx.Client", text: str, source: str, target: str) -> str:
        try:
            resp = client.post(
                f"{self.base_url}/api/translate",
                json={"text": text, "src_lang": source, "tgt_lang": target},
                timeout=self.timeout,
            )
        except httpx.TimeoutException as exc:
            raise TranslationProviderError(
                "The local translation service timed out. Is app/ running?"
            ) from exc
        except httpx.HTTPError as exc:
            raise TranslationProviderError(
                f"Cannot reach the local translation service at {self.base_url}."
            ) from exc
        if resp.status_code == 503:
            raise TranslationNotConfiguredError(
                "The local translation service reports that the model is unavailable."
            )
        if resp.status_code != 200:
            detail = ""
            try:
                detail = str(resp.json().get("detail") or "")
            except ValueError:
                pass
            raise TranslationProviderError(
                f"Local translation failed (HTTP {resp.status_code}). {detail}".strip()
            )
        try:
            payload = resp.json()
        except ValueError as exc:
            raise TranslationProviderError(
                "The local translation service returned a malformed response."
            ) from exc
        translated = payload.get("translated_text")
        if not isinstance(translated, str) or not translated.strip():
            raise TranslationProviderError("The local model returned an empty translation.")
        return translated

    def translate_batch(
        self,
        items: List[TranslationItem],
        source_lang: str,
        target_lang: str,
    ) -> BatchTranslation:
        if not self.supports(source_lang, target_lang):
            raise TranslationUnsupportedError(
                f"The local model does not support '{source_lang}' -> '{target_lang}'. "
                "It covers Hindi <-> Santali only."
            )
        results: List[TranslationResult] = []
        client = self._client or httpx.Client()
        try:
            for item in items:
                if is_numeric_text(item.text):
                    results.append(
                        TranslationResult(
                            item.field_id, item.text, "passthrough", True
                        )
                    )
                    continue
                text = self._translate_one(client, item.text, source_lang, target_lang)
                results.append(
                    TranslationResult(item.field_id, text, self.name, True)
                )
        finally:
            if self._owns_client:
                client.close()
        return BatchTranslation(results=results)


# ---------------------------------------------------------------------------
# Custom pipeline provider for Ho / Mundari (corpus + configured NMT)
# ---------------------------------------------------------------------------

VerifiedLookup = Callable[[str, str, str], Optional[str]]
NmtCall = Callable[[List[str], str, str], List[str]]


class CorpusNmtProvider(TranslationProvider):
    """Custom translation pipeline for languages Sarvam does not cover.

    Resolution order per field:
    1. Verified community-corpus match (VerifiedPhrase lookup, injected).
    2. JSON glossary match (curated, file-backed, env-overridable).
    3. Configured NMT HTTP endpoint (e.g. nipun-nmt-ho, from ModelVersion/env).
    Fields with no coverage are returned untranslated with an explicit error;
    the caller decides failed vs. review-required from the coverage ratio.
    """

    def __init__(
        self,
        internal_code: str,
        verified_lookup: Optional[VerifiedLookup] = None,
        nmt_endpoint: Optional[str] = None,
        nmt_caller: Optional[NmtCall] = None,
        glossary_path: Optional[str] = None,
        timeout: float = 30.0,
    ):
        self.internal_code = internal_code  # ho | unr
        self.name = f"custom-{internal_code}"
        self._verified_lookup = verified_lookup
        self._nmt_endpoint = (nmt_endpoint or "").rstrip("/") or None
        self._nmt_caller = nmt_caller
        self._glossary_path = glossary_path
        self._glossary = self._load_glossary(glossary_path)
        self.timeout = timeout

    def supports(self, source_lang: str, target_lang: str) -> bool:
        return target_lang.lower() == self.internal_code

    @property
    def is_configured(self) -> bool:
        """Explicit pipeline configuration only: NMT endpoint/caller, a
        glossary path, loaded glossary entries, or an injected lookup.

        Ambient database rows are NOT configuration: the service attaches the
        verified-corpus lookup as a supplement, but an otherwise unconfigured
        pipeline must fail closed (CASE 1) rather than inferring setup from
        unrelated seed/demo data."""
        return bool(
            self._verified_lookup
            or self._glossary
            or self._glossary_path
            or self._nmt_endpoint
            or self._nmt_caller
        )

    def _load_glossary(self, path: Optional[str]) -> Dict[str, str]:
        if not path:
            return {}
        try:
            data = json.loads(Path(path).read_text(encoding="utf-8"))
            if isinstance(data, dict):
                return {str(k).strip().lower(): str(v) for k, v in data.items()}
        except Exception as exc:  # missing/unreadable glossary = no coverage, not fatal
            logger.warning("Unable to load glossary %s: %s", path, exc)
        return {}

    def _nmt_translate(self, texts: List[str], source_lang: str) -> List[str]:
        if self._nmt_caller:
            return self._nmt_caller(texts, source_lang, self.internal_code)
        if not self._nmt_endpoint:
            raise TranslationNotConfiguredError(
                f"No NMT endpoint configured for '{self.internal_code}'."
            )
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.post(
                    self._nmt_endpoint,
                    json={"inputs": texts, "source": source_lang, "target": self.internal_code},
                )
        except httpx.HTTPError as exc:
            raise TranslationProviderError("Custom NMT request failed") from exc
        if resp.status_code == 429:
            raise TranslationRateLimitedError("Custom NMT rate limit reached (429).")
        if resp.status_code != 200:
            raise TranslationProviderError(f"Custom NMT failed (HTTP {resp.status_code}).")
        try:
            payload = resp.json()
            outputs = payload.get("translations") or payload.get("outputs")
        except ValueError as exc:
            raise TranslationProviderError("Custom NMT returned a malformed response") from exc
        if not isinstance(outputs, list) or len(outputs) != len(texts):
            raise TranslationProviderError("Custom NMT returned an incomplete response")
        return [str(o) for o in outputs]

    def translate_batch(
        self,
        items: List[TranslationItem],
        source_lang: str,
        target_lang: str,
    ) -> BatchTranslation:
        if not self.supports(source_lang, target_lang):
            raise TranslationUnsupportedError(
                f"Custom '{self.internal_code}' pipeline does not support '{target_lang}'."
            )
        if not self.is_configured:
            lang_name = "Ho" if self.internal_code == "ho" else "Mundari"
            raise TranslationNotConfiguredError(
                f"Translation for {lang_name} is not currently configured. "
                "Configure a verified corpus, glossary, or NMT endpoint on the server."
            )
        results: List[TranslationResult] = []
        pending: List[TranslationItem] = []
        for item in items:
            if is_numeric_text(item.text):
                results.append(
                    TranslationResult(item.field_id, item.text, "passthrough", True)
                )
                continue
            hit = self._lookup(item.text, source_lang)
            if hit:
                results.append(
                    TranslationResult(item.field_id, hit, self.name, True)
                )
            else:
                pending.append(item)
        if pending:
            try:
                nmt_texts = self._nmt_translate([p.text for p in pending], source_lang)
            except TranslationNotConfiguredError:
                # No NMT: mark every pending field explicitly untranslated.
                for item in pending:
                    results.append(
                        TranslationResult(
                            item.field_id,
                            item.text,
                            self.name,
                            False,
                            f"No {self.internal_code} translation available for this field.",
                        )
                    )
                pending = []
            else:
                for item, text in zip(pending, nmt_texts):
                    results.append(TranslationResult(item.field_id, text, self.name, True))
                pending = []
        # CASE 1 vs CASE 2: numeric passthroughs are not translations. When no
        # REAL translation was produced for any translatable field, fail closed
        # with a clear configuration error instead of reporting partial
        # coverage over untouched source text.
        real_translations = sum(
            1 for r in results if r.translated and r.provider == self.name
        )
        translatable = sum(1 for it in items if not is_numeric_text(it.text))
        if translatable and real_translations == 0:
            lang_name = "Ho" if self.internal_code == "ho" else "Mundari"
            raise TranslationNotConfiguredError(
                f"Translation for {lang_name} is not currently configured. "
                "Configure a verified corpus, glossary, or NMT endpoint on the server."
            )
        # Restore original ordering.
        by_id = {r.field_id: r for r in results}
        return BatchTranslation(results=[by_id[it.field_id] for it in items])

    def _lookup(self, text: str, source_lang: str) -> Optional[str]:
        key = text.strip().lower()
        if key in self._glossary:
            return self._glossary[key]
        if self._verified_lookup:
            try:
                return self._verified_lookup(text, source_lang, self.internal_code)
            except Exception as exc:
                logger.warning("Verified-phrase lookup failed: %s", exc)
        return None


__all__ = [
    "BatchTranslation",
    "CorpusNmtProvider",
    "LocalServiceTranslateProvider",
    "TranslationError",
    "TranslationItem",
    "TranslationNotConfiguredError",
    "TranslationProvider",
    "TranslationProviderError",
    "TranslationRateLimitedError",
    "TranslationResult",
    "TranslationUnsupportedError",
    "chunk_items",
    "is_numeric_text",
]
