"""Local Indic Parler-TTS engine (ai4bharat/indic-parler-tts-pretrained).

Speakers
--------
    hin_Deva (Hindi)   -> Rohit
    sat_Olck (Santali) -> Arjun

Santali is synthesized natively or the call fails with a clear error. There is
no fallback to a Hindi voice and no cloud/browser TTS. Model load time is kept
separate from synthesis latency so the first (slow) call is not mistaken for
steady-state performance.

Reference: https://huggingface.co/ai4bharat/indic-parler-tts-pretrained
"""

from __future__ import annotations

import logging
import threading
import time
import uuid
from pathlib import Path

import soundfile as sf
import torch

from . import performance
from .config import GENERATED_AUDIO_DIR, HF_TOKEN, HINDI_TAG, SANTALI_TAG

log = logging.getLogger("maatribhasha.tts")

MODEL_ID = "ai4bharat/indic-parler-tts-pretrained"

HINDI_SPEAKER = "Rohit"
SANTALI_SPEAKER = "Arjun"
SANTALI_SPEAKER_ALT = "Pushpa"

# Descriptions pin the speaker and ask for clean, neutral delivery. The model
# card's pattern is "<Name>'s voice is ...".
_HINDI_DESCRIPTION = (
    f"{HINDI_SPEAKER}'s voice is clear and neutral with moderate speed and pitch. "
    "The recording is of very high quality, with the speaker's voice sounding "
    "clear and very close up."
)
_SANTALI_DESCRIPTION = (
    f"{SANTALI_SPEAKER}'s voice is clear and neutral with moderate speed and pitch. "
    "The recording is of very high quality, with the speaker's voice sounding "
    "clear and very close up."
)

SPEAKER_BY_TAG = {
    HINDI_TAG: HINDI_SPEAKER,
    SANTALI_TAG: SANTALI_SPEAKER,
}
DESCRIPTION_BY_TAG = {
    HINDI_TAG: _HINDI_DESCRIPTION,
    SANTALI_TAG: _SANTALI_DESCRIPTION,
}

_lock = threading.Lock()
_infer_lock = threading.Lock()
_model = None
_tokenizer = None
_desc_tokenizer = None
_sampling_rate: int = 24000
_load_seconds: float | None = None
_load_error: Exception | None = None
_device = torch.device("cpu")


def speakers() -> dict:
    """Which local voice synthesizes each language tag."""
    return {
        HINDI_TAG: HINDI_SPEAKER,
        SANTALI_TAG: SANTALI_SPEAKER,
        "santali_alternative": SANTALI_SPEAKER_ALT,
    }


def _explain(exc: Exception) -> str:
    msg = str(exc)
    low = msg.lower()
    gated = (
        "401",
        "403",
        "gated",
        "access denied",
        "repository not found",
        "must provide a token",
        "private",
    )
    if any(k in low for k in gated):
        return (
            f"{type(exc).__name__}: {msg}\n"
            f"{MODEL_ID} is gated. Accept its terms, then set HF_TOKEN (env var "
            "or ~/.cache/huggingface/token) so the weights can be cached locally. "
            "Inference itself never touches the network."
        )
    return f"{type(exc).__name__}: {msg}"


def _load() -> None:
    global _model, _tokenizer, _desc_tokenizer, _sampling_rate
    global _load_seconds, _load_error

    if _model is not None:
        return
    if _load_error is not None:
        raise _load_error
    with _lock:
        if _model is not None:
            return
        if _load_error is not None:
            raise _load_error
        if not HF_TOKEN:
            err = RuntimeError(
                f"No Hugging Face token found (HF_TOKEN env var or "
                f"~/.cache/huggingface/token). {MODEL_ID} is gated; accept its "
                "terms and provide a token so the weights can be cached locally."
            )
            _load_error = err
            raise err
        t0 = time.perf_counter()
        try:
            from parler_tts import ParlerTTSForConditionalGeneration
            from transformers import AutoTokenizer

            mdl = ParlerTTSForConditionalGeneration.from_pretrained(
                MODEL_ID, token=HF_TOKEN
            ).to(_device)
            tok = AutoTokenizer.from_pretrained(MODEL_ID, token=HF_TOKEN)
            desc_name = getattr(mdl.config, "description_tokenizer", None)
            if desc_name is None:
                desc_name = getattr(
                    getattr(mdl.config, "text_encoder", None), "_name_or_path", None
                )
            desc_tok = AutoTokenizer.from_pretrained(desc_name or MODEL_ID, token=HF_TOKEN)
            mdl.eval()
            sr = int(getattr(mdl.config, "sampling_rate", 24000))
        except Exception as exc:
            err = RuntimeError(_explain(exc))
            _load_error = err
            raise err from exc
        _model = mdl
        _tokenizer = tok
        _desc_tokenizer = desc_tok
        _sampling_rate = sr
        _load_seconds = time.perf_counter() - t0
        log.info(
            "TTS loaded local model %s on %s in %.2fs (speakers: %s)",
            MODEL_ID,
            _device,
            _load_seconds,
            speakers(),
        )


def synthesize(text: str, lang_tag: str) -> dict:
    """Synthesize text to a local WAV via Indic Parler-TTS.

    ``lang_tag`` is ``hin_Deva`` or ``sat_Olck``. Raises rather than substituting
    a different language or voice.
    """
    text = (text or "").strip()
    if not text:
        raise RuntimeError("TTS input text is empty.")
    if lang_tag not in SPEAKER_BY_TAG:
        raise RuntimeError(f"TTS does not support language tag: {lang_tag}")

    _load()
    assert _model is not None and _tokenizer is not None and _desc_tokenizer is not None

    speaker = SPEAKER_BY_TAG[lang_tag]
    description = DESCRIPTION_BY_TAG[lang_tag]

    t0 = time.perf_counter()
    try:
        with _infer_lock:
            desc_ids = _desc_tokenizer(description, return_tensors="pt").to(_device)
            prompt_ids = _tokenizer(text, return_tensors="pt").to(_device)
            with torch.inference_mode():
                gen = _model.generate(
                    input_ids=desc_ids.input_ids,
                    attention_mask=desc_ids.attention_mask,
                    prompt_input_ids=prompt_ids.input_ids,
                    prompt_attention_mask=prompt_ids.attention_mask,
                )
        import numpy as np

        audio = np.asarray(gen.cpu().numpy().squeeze(), dtype=np.float32).reshape(-1)
        if audio.size == 0:
            raise RuntimeError("TTS produced an empty waveform.")
    except Exception as exc:
        raise RuntimeError(_explain(exc)) from exc

    tts_latency = time.perf_counter() - t0
    performance.record("tts", tts_latency)

    GENERATED_AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    fname = f"tts_{lang_tag}_{uuid.uuid4().hex[:10]}.wav"
    fpath = GENERATED_AUDIO_DIR / fname
    sr = _sampling_rate
    sf.write(str(fpath), audio, sr, subtype="PCM_16")
    duration = float(len(audio) / sr) if sr else 0.0
    log.info(
        "TTS synth tag=%s speaker=%s chars=%d -> %.2fs audio (%.2fs wall)",
        lang_tag,
        speaker,
        len(text),
        duration,
        tts_latency,
    )

    return {
        "wav_path": fpath,
        "filename": fname,
        "sample_rate": sr,
        "audio_duration_s": round(duration, 4),
        "tts_latency_s": round(tts_latency, 4),
        "rtf": round(tts_latency / duration, 4) if duration > 0 else None,
        "tts_load_s": round(float(_load_seconds or 0.0), 4),
        "speaker": speaker,
        "model": MODEL_ID,
        "language_tag": lang_tag,
    }


def engine_status() -> dict:
    base = {"model_id": MODEL_ID, "device": str(_device), "loaded": _model is not None}
    if _model is not None:
        return {
            **base,
            "sample_rate": _sampling_rate,
            "load_seconds": round(_load_seconds or 0.0, 4),
            "speakers": speakers(),
        }
    if _load_error is not None:
        return {**base, "error": str(_load_error), "speakers": speakers()}
    return {**base, "speakers": speakers()}


def preload() -> dict:
    try:
        _load()
        return {"status": "loaded", "load_seconds": round(_load_seconds or 0.0, 4)}
    except Exception as exc:
        return {"status": "failed", "error": str(exc)}
