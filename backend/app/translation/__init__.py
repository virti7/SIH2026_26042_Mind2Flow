"""Server-side translation providers and language capability registry.

All translation runs on this machine: Hindi <-> Santali is served by the
project's own local model service (``app/``), and Ho / Mundari use the
corpus + NMT pipelines. There is no third-party AI provider and no API key.
"""
from app.translation.providers import (
    BatchTranslation,
    CorpusNmtProvider,
    LocalServiceTranslateProvider,
    TranslationError,
    TranslationItem,
    TranslationNotConfiguredError,
    TranslationProvider,
    TranslationProviderError,
    TranslationRateLimitedError,
    TranslationResult,
    TranslationUnsupportedError,
    chunk_items,
    is_numeric_text,
)
from app.translation.registry import (
    CUSTOM_PIPELINE_CODES,
    INTERNAL_SOURCE_CODES,
    INTERNAL_TARGET_CODES,
    LanguageCapabilityRegistry,
    bcp47_code,
    normalize_language_code,
)

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
    "CUSTOM_PIPELINE_CODES",
    "INTERNAL_SOURCE_CODES",
    "INTERNAL_TARGET_CODES",
    "LanguageCapabilityRegistry",
    "bcp47_code",
    "normalize_language_code",
]
