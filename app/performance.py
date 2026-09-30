"""Data-driven performance reporting.

Every number here is read from a real source. There are two clearly separated
kinds of figure:

``runtime``
    Measured in *this* process, by the local models, since startup. Latency
    entries are the median of the requests actually served. A metric that has
    not been exercised yet reports ``None`` and renders as ``--``.

``offline_benchmark``
    Recorded once by the export/benchmark tooling in ``models/reports``.
    Those files carry their own environment block and timestamp, and they are
    reference figures, not live ones.

Nothing is defaulted, guessed or carried over from a previous run.
"""

from __future__ import annotations

import json
import platform
import statistics
import threading
import time
from pathlib import Path
from typing import Any, Optional

from .config import ASR_BACKEND, REPORTS_DIR

# --------------------------------------------------------------------------- #
# live runtime samples
# --------------------------------------------------------------------------- #
_lock = threading.Lock()
_samples: dict[str, list[float]] = {}
_started_at = time.time()

#: metric key -> human label, for the stages we time in the running process.
TRACKED = (
    "asr",
    "translation",
    "tts",
    "speech_pipeline",
)


def record(metric: str, seconds: float) -> None:
    """Record one real measurement."""
    with _lock:
        _samples.setdefault(metric, []).append(float(seconds))


def _stats(metric: str) -> dict:
    with _lock:
        values = list(_samples.get(metric, []))
    if not values:
        return {"samples": 0, "median_s": None, "min_s": None, "max_s": None}
    return {
        "samples": len(values),
        "median_s": round(statistics.median(values), 4),
        "min_s": round(min(values), 4),
        "max_s": round(max(values), 4),
    }


# --------------------------------------------------------------------------- #
# offline benchmark reports
# --------------------------------------------------------------------------- #
def _read(name: str) -> Optional[dict]:
    path: Path = REPORTS_DIR / name
    if not path.is_file():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None


def _asr_benchmark() -> Optional[dict]:
    """Per-language ASR latency/load figures from the recorded ONNX benchmark."""
    doc = _read("onnx_asr_benchmark.json")
    if not doc:
        return None
    languages: dict[str, Any] = {}
    for lang in doc.get("languages", []):
        code = lang.get("language_code")
        if not code:
            continue
        load_s = lang.get("model_load_s") or {}
        clips = lang.get("results") or []
        languages[code] = {
            "language": lang.get("language"),
            "script": lang.get("script"),
            "clips": len(clips),
            "repeats": doc.get("repeats"),
            "load_seconds": {
                "onnx_int8": _r(load_s.get("int8")),
                "onnx_fp32": _r(load_s.get("fp32")),
                "nemo_reference": _r(load_s.get("original")),
            },
            "latency_s": {
                "onnx_int8": _r(_median_of(clips, "onnx_int8_latency_s")),
                "onnx_fp32": _r(_median_of(clips, "onnx_fp32_latency_s")),
                "nemo_reference": _r(_median_of(clips, "original_latency_s")),
            },
            "rtf": {
                "onnx_int8": _r(_median_of(clips, "onnx_int8_rtf")),
                "onnx_fp32": _r(_median_of(clips, "onnx_fp32_rtf")),
                "nemo_reference": _r(_median_of(clips, "original_rtf")),
            },
            # Parity is INT8-vs-FP32/NeMo agreement, NOT accuracy. There are no
            # human-labelled ground-truth transcripts in this project, so no
            # accuracy figure is claimed.
            "int8_parity_vs_nemo": _parity(clips, "parity_int8_vs_nemo"),
            "int8_parity_vs_fp32": _parity(clips, "parity_int8_vs_fp32"),
        }
    return {
        "source": "models/reports/onnx_asr_benchmark.json",
        "generated_at": doc.get("generated_at"),
        "environment": doc.get("environment"),
        "metrics_are": "parity against the .nemo/FP32 reference, not accuracy",
        "languages": languages,
    }


def _median_of(clips: list[dict], key: str) -> Optional[float]:
    values = [c[key] for c in clips if isinstance(c.get(key), (int, float))]
    return statistics.median(values) if values else None


def _parity(clips: list[dict], key: str) -> dict:
    entries = [c.get(key) for c in clips if isinstance(c.get(key), dict)]
    if not entries:
        return {"clips": 0}
    cers = [e["cer"] for e in entries if isinstance(e.get("cer"), (int, float))]
    wers = [e["wer"] for e in entries if isinstance(e.get("wer"), (int, float))]
    return {
        "clips": len(entries),
        "exact_match_clips": sum(1 for e in entries if e.get("exact_match")),
        "mean_cer": round(statistics.mean(cers), 6) if cers else None,
        "worst_cer": round(max(cers), 6) if cers else None,
        "mean_wer": round(statistics.mean(wers), 6) if wers else None,
    }


def _r(value: Any) -> Optional[float]:
    return round(float(value), 4) if isinstance(value, (int, float)) else None


def _tts_benchmark() -> Optional[dict]:
    doc = _read("tts_audit.json")
    if not doc:
        return None
    samples = doc.get("samples") or []
    lat = [s["latency_s"] for s in samples if isinstance(s.get("latency_s"), (int, float))]
    rtf = [s["rtf"] for s in samples if isinstance(s.get("rtf"), (int, float))]
    return {
        "source": "models/reports/tts_audit.json",
        "model_id": doc.get("model_id"),
        "device": doc.get("device"),
        "sample_rate": doc.get("sample_rate"),
        "param_count": doc.get("param_count"),
        "load_seconds": _r(doc.get("load_time_s")),
        "rss_after_load_mb": _r(doc.get("rss_after_load_mb")),
        "median_latency_s": _r(statistics.median(lat) if lat else None),
        "median_rtf": _r(statistics.median(rtf) if rtf else None),
        "languages": [
            {
                "lang": s.get("lang"),
                "audio_duration_s": _r(s.get("audio_duration_s")),
                "latency_s": _r(s.get("latency_s")),
                "rtf": _r(s.get("rtf")),
            }
            for s in samples
        ],
    }


def _translation_sanity() -> Optional[dict]:
    """Round-trip sanity check recorded offline. Not a BLEU/accuracy claim."""
    doc = _read("cross_lingual_sanity.json")
    if not doc:
        return None
    pairs = doc.get("hindi_to_santali") or []
    return {
        "source": "models/reports/cross_lingual_sanity.json",
        "note": (
            "Round-trip spot check recorded offline. Not a BLEU or accuracy "
            "measurement; no reference corpus is bundled with this project."
        ),
        "hindi_to_santali_cases": len(pairs),
        "round_trip_exact": sum(
            1 for p in pairs if p.get("hindi", "").strip() == p.get("back_hindi", "").strip()
        ),
        "examples": [
            {
                "hindi": p.get("hindi"),
                "santali": p.get("santali"),
                "back_hindi": p.get("back_hindi"),
            }
            for p in pairs
        ],
    }


# --------------------------------------------------------------------------- #
# report
# --------------------------------------------------------------------------- #
def snapshot() -> dict:
    """Full performance snapshot: live runtime status + offline benchmarks."""
    from . import local_engine, service, speech_service, tts_engine

    asr = speech_service.asr_status()
    runtime_asr: dict[str, Any] = {}
    for code, key in (("hi", "hindi"), ("sat", "santali")):
        entry = dict(asr[key])
        entry["measured"] = {
            m: _stats(m) for m in ("asr",) if m in _samples
        }
        runtime_asr[key] = entry

    return {
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "process_uptime_s": round(time.time() - _started_at, 1),
        "environment": {
            "python": platform.python_version(),
            "platform": platform.platform(),
            "machine": platform.machine(),
            "note": "All inference runs on this machine; no network calls.",
        },
        "offline_mode": True,
        "runtime": {
            "asr_backend_configured": ASR_BACKEND,
            "asr": runtime_asr,
            "translation": {
                **local_engine.engine_status(),
                "measured": _stats("translation"),
            },
            "tts": {
                "model_id": tts_engine.MODEL_ID,
                "speakers": tts_engine.speakers(),
                "measured": _stats("tts"),
                "status": tts_engine.engine_status(),
            },
            "service": service.service_status(),
            "latency": {
                m: _stats(m)
                for m in ("asr", "translation", "tts", "speech_pipeline")
            },
            "note": (
                "'samples' is the number of real requests served since startup. "
                "A metric with 0 samples has not been measured and shows as '--'."
            ),
        },
        "offline_benchmark": {
            "asr": _asr_benchmark(),
            "tts": _tts_benchmark(),
            "translation": _translation_sanity(),
        },
    }
