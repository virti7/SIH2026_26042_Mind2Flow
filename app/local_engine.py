"""Local IndicTrans2 engine (ai4bharat/indictrans2-indic-indic-1B).

Serves BOTH directions through the same model:
    Hindi (hin_Deva)   -> Santali Ol Chiki (sat_Olck)
    Santali Ol Chiki   -> Hindi (hin_Deva)

Generation is deliberately constrained and deterministic by default to avoid
the model appending unrelated trailing clauses to short classroom sentences:
        num_beams > 1, do_sample=False, early_stopping=True,
        no_repeat_ngram_size>=3, and a max_new_tokens budget tied to the
        source length (short source in -> short output budget).
"""

from __future__ import annotations

import logging
import threading
import time

import torch
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

from .config import HF_TOKEN, SANTALI_TAG, HINDI_TAG, TRANSLATION_MODEL_ID
from .indic_processor import IndicProcessor

log = logging.getLogger("maatribhasha.nmt")


class TranslationEngineError(RuntimeError):
    pass


# Generation profiles. "default" is the everyday deterministic setting;
# "strict" is used for the single retry when the consistency check fires.
GEN_PROFILE_DEFAULT = {
    "num_beams": 5,
    "do_sample": False,
    "use_cache": True,
    "early_stopping": True,
    "no_repeat_ngram_size": 3,
    "length_penalty": 0.6,
}
GEN_PROFILE_STRICT = {
    "num_beams": 4,
    "do_sample": False,
    "use_cache": True,
    "early_stopping": True,
    "no_repeat_ngram_size": 4,
    "length_penalty": 0.3,
}


def max_new_tokens_for(source_text: str, mode: str = "default") -> int:
    """A reasonable, source-length-aware output budget (never generous)."""
    words = len(str(source_text or "").split()) or 1
    if mode == "strict":
        budget = max(16, int(words * 1.5) + 6)
        return min(budget, 160)
    budget = max(24, int(words * 2.0) + 12)
    return min(budget, 200)


def generation_params(source_text: str, mode: str = "default") -> dict:
    profile = GEN_PROFILE_STRICT if mode == "strict" else GEN_PROFILE_DEFAULT
    params = dict(profile)
    params["max_new_tokens"] = max_new_tokens_for(source_text, mode)
    params["min_new_tokens"] = 1
    return params


class LocalEngine:
    def __init__(self, model_id: str = TRANSLATION_MODEL_ID, token: str | None = HF_TOKEN):
        if not token:
            raise TranslationEngineError(
                "No Hugging Face token available (set HF_TOKEN or place the token in "
                "~/.cache/huggingface/token). The IndicTrans2 model is gated."
            )
        self.model_id = model_id
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self._lock = threading.Lock()
        try:
            self.processor = IndicProcessor(inference=True)
            self.tokenizer = AutoTokenizer.from_pretrained(
                model_id, trust_remote_code=True, token=token
            )
            dtype = torch.float16 if self.device == "cuda" else torch.float32
            self.model = AutoModelForSeq2SeqLM.from_pretrained(
                model_id,
                trust_remote_code=True,
                torch_dtype=dtype,
                token=token,
            ).to(self.device)
            self.model.eval()
        except Exception as exc:  # actionable message for setup problems
            raise TranslationEngineError(self._explain(exc)) from exc

    @staticmethod
    def _explain(exc: Exception) -> str:
        msg = str(exc)
        if any(code in msg for code in ("401", "403", "gated", "authorization", "Repository Not Found")):
            return (
                f"{type(exc).__name__}: {msg}\n"
                "The IndicTrans2 model is gated on Hugging Face. Accept its terms at "
                "https://huggingface.co/ai4bharat/indictrans2-indic-indic-1B and set HF_TOKEN."
            )
        if "youtokentome" in msg:
            return (
                f"{type(exc).__name__}: {msg}\n"
                "This model's tokenizer needs the 'youtokentome' package."
            )
        return f"{type(exc).__name__}: {msg}"

    @staticmethod
    def _is_valid_pair(src_tag: str, tgt_tag: str) -> bool:
        return {src_tag, tgt_tag} == {HINDI_TAG, SANTALI_TAG}

    def _models_params(self, source_text: str, mode: str):
        params = generation_params(source_text, mode)
        return params

    @torch.inference_mode()
    def translate(
        self,
        text: str,
        src_tag: str,
        tgt_tag: str,
        mode: str = "default",
    ) -> str:
        """Local IndicTrans2 translation between hin_Deva and sat_Olck."""
        if not self._is_valid_pair(src_tag, tgt_tag):
            raise TranslationEngineError(
                f"Unsupported language pair: {src_tag} -> {tgt_tag}"
            )
        text = (text or "").strip()
        if not text:
            raise TranslationEngineError("Input text is empty.")

        with self._lock:
            batch = self.processor.preprocess_batch(
                [text], src_lang=src_tag, tgt_lang=tgt_tag
            )
            inputs = self.tokenizer(
                batch,
                truncation=True,
                padding="longest",
                max_length=192,
                return_tensors="pt",
                return_attention_mask=True,
            ).to(self.device)
            params = self._models_params(text, mode)
            generated = self.model.generate(
                **inputs,
                num_return_sequences=1,
                **params,
            )
            decoded = self.tokenizer.batch_decode(
                generated,
                skip_special_tokens=True,
                clean_up_tokenization_spaces=True,
            )
            out = self.processor.postprocess_batch(decoded, lang=tgt_tag)
            return (out[0] if out else "").strip()


# ------------------------- lazy singleton -----------------------------------
_lock = threading.Lock()
_engine: LocalEngine | None = None
_error: Exception | None = None


def get_engine() -> LocalEngine:
    global _engine, _error
    if _engine is None and _error is None:
        with _lock:
            if _engine is None and _error is None:
                try:
                    _engine = LocalEngine()
                except Exception as exc:
                    _error = exc
    if _error is not None:
        raise _error
    return _engine


def preload() -> dict:
    """Eagerly build the model so its load cost is not charged to a request.

    Best-effort: reports the real error instead of raising, so a missing local
    cache surfaces at startup rather than on the teacher's first utterance.
    """
    t0 = time.perf_counter()
    try:
        engine = get_engine()
    except Exception as exc:
        log.error("Translation model failed to load: %s", exc)
        return {"status": "failed", "error": str(exc)}
    load_s = time.perf_counter() - t0
    engine.load_seconds = load_s
    log.info(
        "Translation model %s loaded on %s in %.2fs",
        engine.model_id,
        engine.device,
        load_s,
    )
    return {"status": "loaded", "load_seconds": round(load_s, 4)}


def engine_status() -> dict:
    if _engine is not None:
        return {
            "loaded": True,
            "model_id": _engine.model_id,
            "device": _engine.device,
            "processor": "indic_processor (pure Python port)",
            "load_seconds": round(getattr(_engine, "load_seconds", 0.0) or 0.0, 4),
        }
    if _error is not None:
        return {"loaded": False, "error": str(_error)}
    return {"loaded": False}