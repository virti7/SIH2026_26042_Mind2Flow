"""Language capability registry: which provider serves which target language."""
from __future__ import annotations

from typing import Dict, List, Optional

from app.translation.providers import (
    CorpusNmtProvider,
    LocalServiceTranslateProvider,
    TranslationNotConfiguredError,
    TranslationProvider,
)

# Internal codes used across backend + Flutter payloads.
INTERNAL_SOURCE_CODES = {"hi", "en"}
INTERNAL_TARGET_CODES = {"hi", "en", "sat", "ho", "unr"}
CUSTOM_PIPELINE_CODES = {"ho", "unr"}

# Alias -> canonical internal code.
_CODE_ALIASES: Dict[str, str] = {
    "hi": "hi",
    "hi-in": "hi",
    "hindi": "hi",
    "en": "en",
    "en-in": "en",
    "english": "en",
    "sat": "sat",
    "sat-in": "sat",
    "santali": "sat",
    "san": "sat",
    "ho": "ho",
    "mundari": "unr",
    "unr": "unr",
    "mun": "unr",
    "bn": "bn",
    "bn-in": "bn",
    "bengali": "bn",
    "gu": "gu",
    "gu-in": "gu",
    "gujarati": "gu",
    "kn": "kn",
    "kn-in": "kn",
    "kannada": "kn",
    "ml": "ml",
    "ml-in": "ml",
    "malayalam": "ml",
    "mr": "mr",
    "mr-in": "mr",
    "marathi": "mr",
    "od": "od",
    "od-in": "od",
    "odia": "od",
    "pa": "pa",
    "pa-in": "pa",
    "punjabi": "pa",
    "ta": "ta",
    "ta-in": "ta",
    "tamil": "ta",
    "te": "te",
    "te-in": "te",
    "telugu": "te",
}

# Internal code -> BCP-47 tag, for UI labels and the local service payload.
_BCP47_MAP: Dict[str, str] = {
    "hi": "hi-IN",
    "en": "en-IN",
    "sat": "sat-IN",
    "bn": "bn-IN",
    "gu": "gu-IN",
    "kn": "kn-IN",
    "ml": "ml-IN",
    "mr": "mr-IN",
    "od": "od-IN",
    "pa": "pa-IN",
    "ta": "ta-IN",
    "te": "te-IN",
}


def normalize_language_code(raw: str) -> str:
    """Normalize UI/API language codes to canonical internal codes."""
    key = (raw or "").strip().lower()
    if key in _CODE_ALIASES:
        return _CODE_ALIASES[key]
    return key


def bcp47_code(internal_code: str) -> str:
    """Map an internal code to its BCP-47 tag."""
    return _BCP47_MAP.get(internal_code, internal_code)


class LanguageCapabilityRegistry:
    """Selects the translation provider dynamically per requested language.

    - Local IndicTrans2 model (``app/`` service): Hindi <-> Santali.
    - Custom corpus+NMT pipelines: ho, unr (Mundari).
    - Anything else: TranslationNotConfiguredError (never a silent fallback and
      never a fabricated translation).
    """

    def __init__(
        self,
        ho_provider: Optional[TranslationProvider] = None,
        mundari_provider: Optional[TranslationProvider] = None,
        verified_lookup=None,
        nmt_endpoints: Optional[Dict[str, str]] = None,
        glossary_paths: Optional[Dict[str, str]] = None,
    ):
        self._ho_provider = ho_provider
        self._mundari_provider = mundari_provider
        self._verified_lookup = verified_lookup
        self._nmt_endpoints = nmt_endpoints or {}
        self._glossary_paths = glossary_paths or {}
        self._local_provider = LocalServiceTranslateProvider()

    def supported_targets(self) -> List[str]:
        """Target languages this deployment can actually produce."""
        targets = {src for src, _ in LocalServiceTranslateProvider.SUPPORTED_PAIRS}
        return sorted(targets | set(CUSTOM_PIPELINE_CODES))

    def is_supported_language(self, raw: str) -> bool:
        """True when a code can serve as source or target in this deployment.

        Derived from the provider itself, not from a hardcoded list, so a code
        can never be advertised as translatable when no local model serves it.
        """
        code = normalize_language_code(raw or "")
        if code in CUSTOM_PIPELINE_CODES:
            return True
        return any(
            src == code or tgt == code
            for src, tgt in LocalServiceTranslateProvider.SUPPORTED_PAIRS
        )

    def provider_for(self, source_lang: str, target_lang: str) -> TranslationProvider:
        source = normalize_language_code(source_lang)
        target = normalize_language_code(target_lang)
        if not self.is_supported_language(target):
            raise TranslationNotConfiguredError(
                f"No local model translates to '{target_lang}'. "
                "This build serves Hindi <-> Santali."
            )
        if target in CUSTOM_PIPELINE_CODES:
            return self._custom_provider(target)
        if (source, target) in LocalServiceTranslateProvider.SUPPORTED_PAIRS:
            return self._local_provider
        raise TranslationNotConfiguredError(
            f"No local model translates '{source_lang}' -> '{target_lang}'. "
            "This build serves Hindi <-> Santali."
        )

    def _custom_provider(self, internal_code: str) -> TranslationProvider:
        from app.core.config import settings

        if internal_code == "ho" and self._ho_provider:
            return self._ho_provider
        if internal_code == "unr" and self._mundari_provider:
            return self._mundari_provider
        if internal_code == "ho":
            endpoint = self._nmt_endpoints.get("ho") or settings.HO_NMT_ENDPOINT
            glossary = self._glossary_paths.get("ho") or settings.HO_GLOSSARY_PATH
            return CorpusNmtProvider(
                "ho",
                verified_lookup=self._verified_lookup,
                nmt_endpoint=endpoint,
                glossary_path=glossary,
            )
        endpoint = self._nmt_endpoints.get("unr") or settings.MUNDARI_NMT_ENDPOINT
        glossary = self._glossary_paths.get("unr") or settings.MUNDARI_GLOSSARY_PATH
        return CorpusNmtProvider(
            "unr",
            verified_lookup=self._verified_lookup,
            nmt_endpoint=endpoint,
            glossary_path=glossary,
        )


__all__ = [
    "CUSTOM_PIPELINE_CODES",
    "INTERNAL_SOURCE_CODES",
    "INTERNAL_TARGET_CODES",
    "LanguageCapabilityRegistry",
    "bcp47_code",
    "normalize_language_code",
]