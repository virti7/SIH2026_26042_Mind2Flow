"""Central configuration for the local Hindi <-> Santali translator.

Everything is local. Model files are read from ``models/runtime`` (the INT8
ONNX graphs the app actually infers with); the large ``.nemo`` checkpoints live
under ``models/dev`` and are only needed for conversion and benchmarking, never
by the running service.
"""

from __future__ import annotations

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# Optional. Only read for local development overrides; the service needs no
# network configuration to run.
try:
    from dotenv import load_dotenv

    load_dotenv(BASE_DIR / ".env")
except Exception:
    pass

MODELS_DIR = BASE_DIR / "models"
RUNTIME_MODELS_DIR = MODELS_DIR / "runtime" / "asr"
DEV_MODELS_DIR = MODELS_DIR / "dev" / "nemo"
REPORTS_DIR = MODELS_DIR / "reports"
TEST_AUDIO_DIR = MODELS_DIR / "test_audio"

GENERATED_AUDIO_DIR = BASE_DIR / "generated_audio"
LOGS_DIR = BASE_DIR / "logs"
GENERATED_AUDIO_DIR.mkdir(parents=True, exist_ok=True)
LOGS_DIR.mkdir(parents=True, exist_ok=True)

# --- this service -------------------------------------------------------------
SERVICE_HOST = os.environ.get("TRANSLATION_SERVICE_HOST", "127.0.0.1")
SERVICE_PORT = int(os.environ.get("TRANSLATION_SERVICE_PORT", "7871"))

# --- ASR ----------------------------------------------------------------------
# Runtime ASR is the INT8 ONNX graph. The .nemo checkpoints are reference-only.
ASR_BACKEND = os.environ.get("ASR_BACKEND", "onnx").strip().lower()
ONNX_INT8_FILENAME = "model.int8.onnx"
ONNX_INT8_THREADS = int(os.environ.get("ONNX_INT8_THREADS", "0"))

#: Runtime INT8 graphs, keyed by the short language code the rest of the app uses.
ASR_RUNTIME_MODELS: dict[str, dict[str, Path]] = {
    "hi": {
        "model": RUNTIME_MODELS_DIR / "hindi" / ONNX_INT8_FILENAME,
        "vocab": RUNTIME_MODELS_DIR / "hindi" / "vocab.json",
    },
    "sat": {
        "model": RUNTIME_MODELS_DIR / "santali" / ONNX_INT8_FILENAME,
        "vocab": RUNTIME_MODELS_DIR / "santali" / "vocab.json",
    },
}

#: Development / benchmark reference only. Never loaded by the default runtime.
ASR_REFERENCE_MODELS: dict[str, Path] = {
    "hi": DEV_MODELS_DIR / "indicconformer_stt_hi_hybrid_rnnt_large.nemo",
    "sat": DEV_MODELS_DIR / "indicconformer_stt_sat_hybrid_rnnt_large.nemo",
}

# --- translation model --------------------------------------------------------
# Cached locally; no network calls at inference time.
TRANSLATION_MODEL_ID = os.environ.get(
    "TRANSLATION_MODEL_ID", "ai4bharat/indictrans2-indic-indic-1B"
)


def _read_hf_token() -> str | None:
    """Optional Hugging Face token, used only to populate the local model cache."""
    tok = os.environ.get("HF_TOKEN")
    if tok:
        return tok
    for p in (
        Path.home() / ".cache" / "huggingface" / "token",
        Path.home() / ".huggingface" / "token",
    ):
        if p.exists():
            try:
                val = p.read_text(encoding="utf-8").strip()
                if val:
                    return val
            except Exception:
                continue
    return None


# Never logged.
HF_TOKEN = _read_hf_token()

# --- language tags (IndicTrans2 / FLORES-200 style) ----------------------------
HINDI_TAG = "hin_Deva"
SANTALI_TAG = "sat_Olck"

DEFAULT_TAGS = (HINDI_TAG, SANTALI_TAG)

#: Aliases accepted anywhere a source/target language is supplied.
LANG_ALIASES: dict[str, str] = {
    "hi": "hi",
    "hin": "hi",
    "hindi": "hi",
    "hin_deva": "hi",
    "sat": "sat",
    "santali": "sat",
    "sat_olck": "sat",
}


def normalize_lang(value: str | None) -> str:
    """Map any accepted alias to ``'hi'`` or ``'sat'``.

    Raises :class:`ValueError` for anything else so callers surface a real
    error instead of guessing.
    """
    key = (value or "").strip().lower()
    try:
        return LANG_ALIASES[key]
    except KeyError:
        raise ValueError(
            f"Unsupported language {value!r}. Use 'hi' (Hindi) or 'sat' (Santali)."
        ) from None
