"""FastAPI service: local Hindi <-> Santali classroom translator.

API only. The standalone web UI was removed; the Flutter app and the
`/docs` page are the clients.

Pipelines
---------
TEACHER  Hindi speech   -> Santali text + Santali audio (Parler Arjun)
STUDENT  Santali speech -> Hindi text + Hindi audio (Parler Rohit)

Each pipeline runs entirely on this machine:
    local ONNX INT8 ASR -> local IndicTrans2 -> local Indic Parler-TTS

No external API, no browser/cloud TTS, no hardcoded results. Models load
lazily on first use (or eagerly via STARTUP_PRELOAD), and model-load time is
always reported separately from inference latency.
"""

from __future__ import annotations

import logging
import tempfile
from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel, Field

from . import local_engine, performance, service, speech_service, tts_engine
from .config import GENERATED_AUDIO_DIR, SERVICE_HOST, SERVICE_PORT, normalize_lang

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
log = logging.getLogger("maatribhasha.api")

#: Warm the models during startup instead of on the first request.
STARTUP_PRELOAD = True

app = FastAPI(title="MaatriBhasha Local Translator", version="2.0.0")


# ------------------------------------------------------------------ schemas
class TranslateRequest(BaseModel):
    text: str = Field(..., description="Source text to translate")
    src_lang: str = Field(..., description="Source language alias (hi, hin, hindi, sat, santali)")
    tgt_lang: str | None = Field(None, description="Target lang alias; defaults to opposite of src")


# ------------------------------------------------------------------ startup
@app.on_event("startup")
def _startup() -> None:
    log.info("Starting local service on %s:%s", SERVICE_HOST, SERVICE_PORT)
    if not STARTUP_PRELOAD:
        return
    report = speech_service.preload_all()
    for code, info in report.items():
        if info["loaded"]:
            log.info("Startup preload: ASR[%s] ready (%.2fs)", code, info.get("load_seconds") or 0.0)
        else:
            log.error("Startup preload: ASR[%s] FAILED: %s", code, info["error"])
    nmt = local_engine.preload()
    if nmt["status"] == "loaded":
        log.info("Startup preload: translation ready (%.2fs)", nmt["load_seconds"])
    else:
        log.error("Startup preload: translation FAILED: %s", nmt["error"])
    tts = tts_engine.preload()
    if tts["status"] == "loaded":
        log.info("Startup preload: TTS ready (%.2fs)", tts["load_seconds"])
    else:
        log.error("Startup preload: TTS FAILED: %s", tts["error"])


# ------------------------------------------------------------------ health
@app.get("/api/health")
def health():
    return {
        "status": "ok",
        "offline_mode": True,
        "translation": service.service_status(),
        "asr": speech_service.asr_status(),
        "tts": tts_engine.engine_status(),
        "base_url": f"http://{SERVICE_HOST}:{SERVICE_PORT}",
    }


# ------------------------------------------------------------------ performance
@app.get("/api/performance")
def performance_report():
    """Live runtime measurements plus the recorded offline benchmark figures.

    Unmeasured metrics come back as ``null`` and display as ``--``. Every value
    is read from a real measurement; nothing is hardcoded.
    """
    return performance.snapshot()


# ------------------------------------------------------------------ text translation
@app.post("/api/translate")
def translate(req: TranslateRequest):
    result = service.translate(req.text, req.src_lang, req.tgt_lang)
    if not result.get("ok"):
        raise HTTPException(400, detail=result.get("error", "translation failed"))
    return result


# ------------------------------------------------------------------ TTS (text -> local WAV)
@app.post("/api/tts")
def tts(text: str = Form(...), lang: str = Form("sat")):
    """Direct local text-to-speech. ``lang``: ``hi`` or ``sat``."""
    try:
        code = normalize_lang(lang)
    except ValueError as exc:
        raise HTTPException(400, detail=str(exc)) from exc
    tag = "sat_Olck" if code == "sat" else "hin_Deva"
    try:
        info = tts_engine.synthesize(text, tag)
    except Exception as exc:
        raise HTTPException(400, detail=f"{type(exc).__name__}: {exc}") from exc
    return {
        "ok": True,
        "text": text,
        "lang": code,
        "audio_url": f"/generated_audio/{info['filename']}",
        "filename": info["filename"],
        "sample_rate": info["sample_rate"],
        "audio_duration_s": info["audio_duration_s"],
        "tts_latency_s": info["tts_latency_s"],
        "tts_load_s": info["tts_load_s"],
        "speaker": info["speaker"],
        "model": info["model"],
    }


# ------------------------------------------------------------------ speech-to-speech
@app.post("/api/speech/translate")
async def speech_translate(audio: UploadFile = File(...), source_lang: str = Form(...)):
    """One-shot speech-to-speech: audio + source_lang -> transcript + translation + TTS audio."""
    try:
        src_norm = normalize_lang(source_lang)
    except ValueError as exc:
        raise HTTPException(400, detail=str(exc)) from exc

    tmp_in = tmp_wav = None
    try:
        suffix = Path(audio.filename or "recording.webm").suffix or ".webm"
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as f:
            tmp_in = Path(f.name)
            f.write(await audio.read())
        if tmp_in.stat().st_size == 0:
            raise HTTPException(400, detail="Empty audio file.")
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as f:
            tmp_wav = Path(f.name)
        speech_service.to_wav_16k(tmp_in, tmp_wav)
        result = speech_service.run_pipeline(tmp_wav, src_norm)
        performance.record("speech_pipeline", result["latencies"]["total_infer_s"])
        return JSONResponse(result)
    except HTTPException:
        raise
    except Exception as exc:
        log.exception("speech pipeline failed")
        raise HTTPException(400, detail=f"{type(exc).__name__}: {exc}") from exc
    finally:
        for p in (tmp_in, tmp_wav):
            if p:
                try:
                    p.unlink(missing_ok=True)
                except Exception:
                    pass


# ------------------------------------------------------------------ generated audio
@app.get("/generated_audio/{filename}")
def get_audio(filename: str):
    if ".." in filename or "/" in filename or "\\" in filename:
        raise HTTPException(400, detail="Invalid filename")
    fpath = GENERATED_AUDIO_DIR / filename
    if not fpath.exists():
        raise HTTPException(404, detail="Audio not found")
    return FileResponse(str(fpath), media_type="audio/wav", filename=filename)


if __name__ == "__main__":
    import uvicorn

    print("=" * 70)
    print("MaatriBhasha Local Translator - fully local, API only")
    print(f"  API docs : http://{SERVICE_HOST}:{SERVICE_PORT}/docs")
    print(f"  Health   : http://{SERVICE_HOST}:{SERVICE_PORT}/api/health")
    print(f"  Perf     : http://{SERVICE_HOST}:{SERVICE_PORT}/api/performance")
    print("  ASR : ONNX INT8 IndicConformer (hi + sat)")
    print("  NMT : IndicTrans2 (local)")
    print("  TTS : Indic Parler-TTS, Rohit (hi) / Arjun (sat)")
    print("=" * 70)
    uvicorn.run(app, host=SERVICE_HOST, port=SERVICE_PORT, reload=False)
