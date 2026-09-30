"""Local speech recognition for the classroom translator.

Runtime backend
---------------
The default (and only backend the application needs) is the INT8-quantized
ONNX graph from :mod:`app.onnx_asr`. It needs only ``onnxruntime``, loads in a
couple of seconds and never imports NeMo.

``ASR_BACKEND=nemo`` selects the large ``.nemo`` checkpoints from
``models/dev/nemo`` instead. That path exists purely so conversion and
benchmark work has a reference to compare against; it is not used by the
running application and it is never a silent fallback. If the configured
backend fails to load, the request fails with the real error.

Both backends implement the same contract, so the pipeline in
:func:`run_pipeline` is identical either way:

    audio (any format) --ffmpeg--> 16 kHz mono WAV
      -> local ASR          -> text in the source language
      -> local IndicTrans2  -> text in the target language
      -> local Indic Parler-TTS -> target-language audio
"""

from __future__ import annotations

import logging
import subprocess
import threading
import time
from pathlib import Path
from typing import Any

from .config import (
    ASR_BACKEND,
    ASR_REFERENCE_MODELS,
    ASR_RUNTIME_MODELS,
    ONNX_INT8_THREADS,
)

log = logging.getLogger("maatribhasha.asr")

# Per-language state, so status can report what is actually loaded.
_state: dict[str, dict[str, Any]] = {
    code: {"model": None, "load_seconds": None, "error": None, "locked": False}
    for code in ("hi", "sat")
}
_locks: dict[str, threading.Lock] = {code: threading.Lock() for code in ("hi", "sat")}


class AsrUnavailableError(RuntimeError):
    """Raised when the configured local ASR backend cannot run. Never masked."""


# ----------------------------------------------------------------- ONNX backend
def _load_onnx(code: str):
    from .onnx_asr import OnnxAsrModel

    paths = ASR_RUNTIME_MODELS[code]
    model = OnnxAsrModel(
        paths["model"], paths["vocab"], code, intra_op_threads=ONNX_INT8_THREADS
    )
    log.info(
        "ASR[%s] loaded local ONNX model %s (INT8=%s) in %.2fs from %s",
        code,
        model.describe()["model_file"],
        model.quantization == "INT8",
        model.load_seconds,
        paths["model"],
    )
    return model


# ------------------------------------------------------------------ NeMo backend
def _load_nemo(code: str):
    """Reference-only backend. Kept for conversion/benchmark parity work."""
    import torch
    import nemo.collections.asr as nemo_asr

    path: Path = ASR_REFERENCE_MODELS[code]
    if not path.exists():
        raise FileNotFoundError(f"Reference .nemo model not found: {path}")
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = nemo_asr.models.ASRModel.restore_from(str(path), map_location=device)
    model.freeze()
    model = model.to(device)
    model.cur_decoder = "rnnt"
    log.info("ASR[%s] loaded NeMo reference model %s on %s", code, path.name, device)
    return model


def get_asr(code: str):
    """Return the loaded local ASR model for ``code``, loading it once."""
    st = _state[code]
    if st["model"] is not None:
        return st["model"]
    with _locks[code]:
        if st["model"] is not None:
            return st["model"]
        if st["error"] is not None:
            raise AsrUnavailableError(str(st["error"]))
        loader = _load_nemo if ASR_BACKEND == "nemo" else _load_onnx
        try:
            st["model"] = loader(code)
            st["load_seconds"] = round(
                getattr(st["model"], "load_seconds", 0.0) or 0.0, 4
            )
        except Exception as exc:
            st["error"] = f"{type(exc).__name__}: {exc}"
            raise AsrUnavailableError(st["error"]) from exc
        return st["model"]


def preload_all() -> dict:
    """Best-effort eager load. Reports per-language success or the real error."""
    out: dict[str, Any] = {}
    for code in ("hi", "sat"):
        try:
            get_asr(code)
            out[code] = {"loaded": True}
        except Exception as exc:
            out[code] = {"loaded": False, "error": str(exc)}
    return out


# --------------------------------------------------------------------- status
def asr_status() -> dict:
    """Report the real configured backend and what is actually loaded."""
    def describe(code: str) -> dict:
        st = _state[code]
        base: dict[str, Any] = {
            "backend": ASR_BACKEND,
            "loaded": st["model"] is not None,
            "load_seconds": st["load_seconds"],
            "error": st["error"],
        }
        if ASR_BACKEND == "nemo":
            base.update(
                {
                    "runtime": "nemo",
                    "model_file": ASR_REFERENCE_MODELS[code].name,
                    "model_path": str(ASR_REFERENCE_MODELS[code]),
                    "exists": ASR_REFERENCE_MODELS[code].exists(),
                    "note": "reference/benchmark backend, not the default runtime",
                }
            )
            return base
        paths = ASR_RUNTIME_MODELS[code]
        base.update(
            {
                "runtime": "onnxruntime",
                "model_file": paths["model"].name,
                "model_path": str(paths["model"]),
                "model_bytes": paths["model"].stat().st_size
                if paths["model"].exists()
                else None,
                "exists": paths["model"].exists() and paths["vocab"].exists(),
                "onnx_int8": True,
            }
        )
        if st["model"] is not None:
            desc = st["model"].describe()
            base.update(
                {
                    "quantization": desc["quantization"],
                    "onnx_int8": desc["onnx_int8"],
                    "provider": desc["provider"],
                    "script": desc["script"],
                    "session_load_seconds": desc["session_load_seconds"],
                    "warmup_seconds": desc["warmup_seconds"],
                }
            )
        return base

    return {
        "configured_backend": ASR_BACKEND,
        "default_backend": "onnx",
        "hindi": describe("hi"),
        "santali": describe("sat"),
    }


# ------------------------------------------------------------------ audio util
def to_wav_16k(src: Path, dst: Path) -> None:
    """Normalize any input container to 16 kHz mono PCM WAV using ffmpeg."""
    cmd = [
        "ffmpeg", "-y", "-i", str(src),
        "-ac", "1", "-ar", "16000", "-sample_fmt", "s16", str(dst),
    ]
    try:
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    except FileNotFoundError:
        raise RuntimeError("ffmpeg was not found on PATH.") from None
    if p.returncode != 0 or not dst.exists():
        raise RuntimeError("ffmpeg conversion failed:\n" + (p.stderr or "")[-1200:])


# ------------------------------------------------------------------ transcribe
def _unwrap_text(v) -> str:
    while isinstance(v, (list, tuple)):
        if not v:
            return ""
        v = v[0]
    return str(v).strip() if v is not None else ""


def transcribe_wav(wav_path: Path, source_lang: str) -> dict:
    """Run the configured local ASR over a 16 kHz mono WAV.

    Returns ``{text, latency_s, duration_s, rtf, model_load_s, ...}``. Raises
    rather than inventing a transcript when the backend cannot run.
    """
    from .config import normalize_lang

    code = normalize_lang(source_lang)
    model = get_asr(code)

    t0 = time.perf_counter()
    if ASR_BACKEND == "nemo":
        raw = model.transcribe([str(wav_path)], batch_size=1, language_id=code)
        latency = time.perf_counter() - t0
        text = _unwrap_text(raw[0] if raw else "")
        from .onnx_asr import load_audio_16k_mono

        _wave, duration, _sr = load_audio_16k_mono(Path(wav_path))
        return {
            "text": text,
            "latency_s": round(latency, 4),
            "duration_s": round(duration, 4),
            "rtf": round(latency / duration, 4) if duration > 0 else None,
            "model_load_s": _state[code]["load_seconds"] or 0.0,
            "language_id": code,
            "backend": "nemo",
        }

    result = model.transcribe_file(Path(wav_path))
    result["backend"] = "onnx"
    result["quantization"] = model.quantization
    return result


# ----------------------------------------------------------------- full pipeline
def run_pipeline(wav_path: Path, source_lang: str) -> dict:
    """Full speech-to-speech pipeline for one direction.

    ``source_lang``: ``'hi'`` (Hindi speech -> Santali) or ``'sat'``
    (Santali speech -> Hindi). Every value in the response is produced by the
    local models; nothing is canned.
    """
    from .config import HINDI_TAG, SANTALI_TAG, normalize_lang
    from . import service as translation_service
    from . import tts_engine

    t_total0 = time.perf_counter()
    code = normalize_lang(source_lang)
    is_hi = code == "hi"
    log.info("PIPELINE start source=%s backend=%s", code, ASR_BACKEND)

    # 1) local ASR
    asr = transcribe_wav(wav_path, code)
    transcript = asr["text"]
    if not transcript:
        raise RuntimeError(
            "ASR produced an empty transcript (the audio may be silent or too noisy)."
        )

    # 2) local IndicTrans2
    t_trans0 = time.perf_counter()
    tres = translation_service.translate(transcript, code, "sat" if is_hi else "hi")
    trans_latency = time.perf_counter() - t_trans0
    if not tres.get("ok"):
        raise RuntimeError(f"Translation failed: {tres.get('error')}")
    translation_text = tres["translated_text"]
    tgt_tag = tres["tgt_lang"]

    # 3) local TTS
    tts_info = tts_engine.synthesize(translation_text, tgt_tag)
    if isinstance(tts_info.get("wav_path"), Path):
        tts_info["wav_path"] = str(tts_info["wav_path"])

    total_wall = time.perf_counter() - t_total0
    infer_sum = asr["latency_s"] + round(trans_latency, 4) + tts_info["tts_latency_s"]
    direction = "Hindi -> Santali" if is_hi else "Santali -> Hindi"

    log.info(
        "PIPELINE done direction=%s asr=%.3fs nmt=%.3fs tts=%.3fs total_infer=%.3fs "
        "asr_backend=%s(%s) nmt=%s tts=%s",
        direction,
        asr["latency_s"],
        trans_latency,
        tts_info["tts_latency_s"],
        infer_sum,
        asr.get("backend"),
        asr.get("quantization", "n/a"),
        tres.get("backend"),
        tts_info["model"],
    )

    return {
        "direction": direction,
        "source_lang": code,
        "target_lang": "sat" if is_hi else "hi",
        "source_tag": HINDI_TAG if is_hi else SANTALI_TAG,
        "target_tag": tgt_tag,
        "transcript": transcript,
        "translation": translation_text,
        "asr": asr,
        "translation_latency_s": round(trans_latency, 4),
        "translation_backend": tres.get("backend", "local"),
        "tts": tts_info,
        "latencies": {
            "asr_s": asr["latency_s"],
            "translation_s": round(trans_latency, 4),
            "tts_s": tts_info["tts_latency_s"],
            "total_infer_s": round(infer_sum, 4),
            "total_wall_s": round(total_wall, 4),
        },
        "model_load": {
            "asr_s": asr["model_load_s"],
            "tts_s": tts_info["tts_load_s"],
        },
        "rtf": asr["rtf"],
        "audio_duration_s": asr["duration_s"],
        "tts_audio_url": f"/generated_audio/{tts_info['filename']}",
        "tts_filename": tts_info["filename"],
        "tts_sample_rate": tts_info["sample_rate"],
    }
