"""Bidirectional Hindi <-> Santali translation orchestrator.

Both directions run through the same local IndicTrans2 model:
    Hindi (hin_Deva)      -> Santali Ol Chiki (sat_Olck)
    Santali Ol Chiki (sat_Olck) -> Hindi (hin_Deva)

Every candidate passes cosmetic normalization and a consistency check. If the
first candidate looks suspicious, exactly one stricter retry runs and the
least-risky / shorter candidate wins. If local inference itself fails the call
returns ``ok: False`` with the real error; nothing is substituted.
"""

from __future__ import annotations

import logging
import time

from . import debuglog, lang, local_engine, normalize, performance
from .config import HINDI_TAG, SANTALI_TAG, SERVICE_PORT

log = logging.getLogger("maatribhasha.translation")


class TranslationServiceError(RuntimeError):
    pass


def _attempt_local(text: str, src_tag: str, tgt_tag: str, mode: str) -> dict:
    engine = local_engine.get_engine()
    raw = engine.translate(text, src_tag, tgt_tag, mode=mode)
    norm = normalize.normalize_translation_output(raw, src_tag, tgt_tag)
    check = normalize.detect_suspicious_output(text, norm)
    return {
        "text": norm,
        "mode": mode,
        "params": local_engine.generation_params(text, mode),
        "backend": "local",
        "suspicious": check["suspicious"],
        "reasons": check["reasons"],
        "ratio": check["ratio"],
    }


def translate(text: str, src_lang: str, tgt_lang: str | None = None) -> dict:
    """Run the fully-local bidirectional pipeline and return the K-format response."""
    t0 = time.perf_counter()
    text = (text or "").strip()
    if not text:
        return {"ok": False, "error": "Input text is empty."}

    try:
        src_tag, tgt_tag = lang.resolve_src_tgt(src_lang, tgt_lang)
    except lang.LanguageError as exc:
        return {"ok": False, "error": str(exc)}

    candidates: list[dict] = []
    retried = False
    backend_used = "local"
    direction = lang.direction_label(src_tag, tgt_tag)

    try:
        cand = _attempt_local(text, src_tag, tgt_tag, mode="default")
        candidates.append(cand)
    except Exception as exc:
        return {
            "ok": False,
            "error": f"Translation failed: {type(exc).__name__}: {exc}",
        }

    first = candidates[0]
    if first["suspicious"]:
        try:
            strict = _attempt_local(text, src_tag, tgt_tag, mode="strict")
        except Exception:
            strict = None
        if strict is not None:
            candidates.append(strict)
            retried = True

    best = normalize.pick_best_candidate(candidates)
    if best is None:
        return {"ok": False, "error": "No translation could be produced."}

    latency = (time.perf_counter() - t0) * 1000.0
    performance.record("translation", latency / 1000.0)
    log.info(
        "NMT %s -> %s (%.0f ms, %s, retried=%s)",
        src_tag,
        tgt_tag,
        latency,
        backend_used,
        retried,
    )
    debuglog.log_translation(
        {
            "src_lang": src_tag,
            "tgt_lang": tgt_tag,
            "direction": direction,
            "src_text": text,
            "backend": backend_used,
            "candidates": [
                {
                    "mode": c.get("mode"),
                    "params": c.get("params", {}),
                    "text": c.get("text"),
                    "suspicious": c.get("suspicious"),
                    "reasons": c.get("reasons"),
                }
                for c in candidates
            ],
            "retried": retried,
            "chosen_suspicious": best["suspicious"],
            "chosen_expansion_ratio": best["ratio"],
            "latency_ms": latency,
        }
    )

    script = normalize.check_script_integrity(best["text"], tgt_tag)
    warnings: list[str] = []
    if best["suspicious"]:
        warnings.append("repetitive-or-expanded-output")
    if not script["ok"]:
        warnings.append(f"output-not-in-{script['expected']}-script")

    return {
        "ok": True,
        "source_text": text,
        "translated_text": best["text"],
        "src_lang": src_tag,
        "tgt_lang": tgt_tag,
        "direction": direction,
        "latency_ms": round(latency, 1),
        "quality": {
            "retried": retried,
            "suspicious_expansion": bool(best["suspicious"]),
            "script_ok": script["ok"],
            "reasons": best.get("reasons") or [],
            # The local 1B model is not reliable on every sentence; this flag
            # tells the UI to ask a teacher to double-check the result.
            "review_needed": bool(warnings),
            "warnings": warnings,
        },
        "backend": backend_used,
    }


def service_status() -> dict:
    return {
        "local": local_engine.engine_status(),
        "backend": "local",
        "pairs": [
            {"source": HINDI_TAG, "target": SANTALI_TAG},
            {"source": SANTALI_TAG, "target": HINDI_TAG},
        ],
        "http_only": f"http://127.0.0.1:{SERVICE_PORT}",
    }