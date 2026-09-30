"""Structured debug logging for translation requests.

Every translation request is logged as one JSON line: source/target language,
source text, generated translations, generation settings used, whether a
retry happened, and the suspicious-expansion verdict. HF tokens, API keys and
other secrets are never written.
"""

from __future__ import annotations

import json
import threading
from datetime import datetime, timezone
from pathlib import Path

from .config import LOGS_DIR

_LOG_FILE = Path(LOGS_DIR) / "translation_debug.log"
_lock = threading.Lock()


def _sanitize(text: str | None) -> str:
    return "" if text is None else str(text)


def log_translation(record: dict) -> None:
    entry = {
        "ts": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
        "src_lang": _sanitize(record.get("src_lang")),
        "tgt_lang": _sanitize(record.get("tgt_lang")),
        "direction": _sanitize(record.get("direction")),
        "src_text": _sanitize(record.get("src_text")),
        "backend": _sanitize(record.get("backend")),
        "candidates": [
            {
                "mode": _sanitize(c.get("mode")),
                "params": c.get("params", {}),
                "text": _sanitize(c.get("text")),
                "suspicious": bool(c.get("suspicious")),
                "reasons": list(c.get("reasons") or []),
            }
            for c in (record.get("candidates") or [])
        ],
        "retried": bool(record.get("retried")),
        "chosen_suspicious": bool(record.get("chosen_suspicious")),
        "chosen_expansion_ratio": float(record.get("chosen_expansion_ratio") or 0.0),
        "latency_ms": round(float(record.get("latency_ms") or 0.0), 1),
    }
    with _lock:
        try:
            _LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
            with _LOG_FILE.open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(entry, ensure_ascii=False) + "\n")
        except Exception:
            pass