#!/usr/bin/env python3
"""Isolated test harness for AI4Bharat IndicConformer .nemo models (Hindi + Santali).

Goal (ONLY): prove `.nemo -> local PC inference -> real transcript` for both models.
Does NOT touch the Flutter app, Android, or APK. No mocks: real NeMo inference only.

Usage (run inside the isolated env, e.g. WSL2 Ubuntu, Python 3.10/3.11):
    python test_indicconformer.py --language hi  --audio <path> [--decoder ctc|rnnt|both]
    python test_indicconformer.py --language sat --audio <path> [--decoder ctc|rnnt|both]
    python test_indicconformer.py --language hi  --audio <path> --validate-only

Model resolution order (no hardcoded absolute paths spread across files):
    1. CLI flags  --model-hi / --model-sat
    2. Env vars   INDICCONFORMER_HI_MODEL / INDICCONFORMER_SAT_MODEL
    3. Defaults relative to THIS file:
         <repo>/models/source/hindi/indicconformer_stt_hi_hybrid_rnnt_large.nemo
         <repo>/models/source/santhali/indicconformer_stt_sat_hybrid_rnnt_large.nemo
       (NOTE: on-disk folder is `santhali`, not `santali`. Both spellings are probed.)

Official model contract: 16000 Hz, mono, PCM WAV. CTC first, then RNNT.
Language IDs: Hindi -> "hi", Santali -> "sat".
"""

from __future__ import annotations

import argparse
import os
import sys
import time
import wave
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent.parent  # <repo>/models/asr_test -> <repo>

DEFAULT_HI_CANDIDATES = [
    REPO_ROOT / "models" / "source" / "hindi" / "indicconformer_stt_hi_hybrid_rnnt_large.nemo",
    Path(r"D:\MaatriBhasha\models\source\hindi\indicconformer_stt_hi_hybrid_rnnt_large.nemo"),
]
# On-disk directory in this repo is `santhali` (with an 'h'); probe both spellings.
DEFAULT_SAT_CANDIDATES = [
    REPO_ROOT / "models" / "source" / "santhali" / "indicconformer_stt_sat_hybrid_rnnt_large.nemo",
    REPO_ROOT / "models" / "source" / "santali" / "indicconformer_stt_sat_hybrid_rnnt_large.nemo",
    Path(r"D:\MaatriBhasha\models\source\santali\indicconformer_stt_sat_hybrid_rnnt_large.nemo"),
]

LANG_TO_ID = {"hi": "hi", "hindi": "hi", "sat": "sat", "santali": "sat", "santhali": "sat"}


# ---------------------------------------------------------------- audio check
def validate_wav(path: Path) -> dict:
    """Print + return sample_rate/channels/format/duration. Stdlib only."""
    if not path.is_file():
        raise FileNotFoundError(f"Audio file not found: {path}")
    with wave.open(str(path), "rb") as w:
        n_channels = w.getnchannels()
        sampwidth = w.getsampwidth()
        sample_rate = w.getframerate()
        n_frames = w.getnframes()
        comp_type = w.getcomptype()  # 'NONE' == PCM
        duration = n_frames / sample_rate if sample_rate else 0.0
    # Sample format label
    fmt = {1: "PCM-8", 2: "PCM-16", 3: "PCM-24", 4: "PCM-32"}.get(sampwidth, f"{sampwidth*8}-bit")
    if comp_type != "NONE":
        fmt = f"NON-PCM({comp_type})"
    info = {
        "path": str(path),
        "sample_rate": sample_rate,
        "channels": n_channels,
        "sample_format": fmt,
        "sampwidth_bytes": sampwidth,
        "duration_s": round(duration, 3),
        "frames": n_frames,
    }
    ok = sample_rate == 16000 and n_channels == 1 and comp_type == "NONE"
    print(f"[audio] {path.name}: {sample_rate} Hz, {n_channels} ch, {fmt}, "
          f"{info['duration_s']}s  -> {'OK' if ok else 'MISMATCH (need 16000 Hz / 1 ch / PCM WAV)'}",
          flush=True)
    info["compatible"] = ok
    return info


def convert_copy_to_16k_mono(src: Path, dst: Path | None = None) -> Path:
    """Create a converted *copy* (never alters the original). Needs soundfile/scipy."""
    dst = dst or src.with_name(src.stem + "_16khz_mono.wav")
    try:
        import soundfile as sf  # type: ignore
        data, sr = sf.read(str(src), always_2d=True)
        import numpy as np  # type: ignore
        if data.shape[1] > 1:
            data = data.mean(axis=1, keepdims=True)
        if sr != 16000:
            try:
                from scipy.signal import resample_poly  # type: ignore
                from math import gcd
                g = gcd(sr, 16000)
                data = resample_poly(data, 16000 // g, sr // g, axis=0)
            except ImportError:
                raise RuntimeError("Resampling needs scipy: pip install scipy")
        sf.write(str(dst), data, 16000, subtype="PCM_16")
    except ImportError:
        raise RuntimeError("Conversion needs soundfile+scipy: pip install soundfile scipy "
                           "(or use: ffmpeg -i input.wav -ar 16000 -ac 1 -c:a pcm_s16le out.wav)")
    print(f"[audio] converted copy written (original untouched): {dst}", flush=True)
    return dst


# ------------------------------------------------------------- script detect
def detect_script(text: str) -> str:
    ol_chiki = sum(0x1C50 <= ord(c) <= 0x1C7F for c in text)
    deva = sum(0x0900 <= ord(c) <= 0x097F for c in text)
    latin = sum(c.isascii() and c.isalpha() for c in text)
    total = max(len(text), 1)
    if ol_chiki and ol_chiki >= max(deva, latin, 1):
        return f"Ol Chiki (U+1C50-U+1C7F chars: {ol_chiki}/{total})"
    if deva and deva >= max(ol_chiki, latin):
        return f"Devanagari (U+0900-U+097F chars: {deva}/{total})"
    if latin and latin >= max(ol_chiki, deva):
        return f"Roman/Latin (ASCII letters: {latin}/{total})"
    if not text.strip():
        return "empty output"
    return f"other/mixed (OlChiki={ol_chiki}, Deva={deva}, Latin={latin}, len={total})"


# ------------------------------------------------------------------ versions
def print_versions() -> None:
    import platform
    print(f"[env] python: {platform.python_version()} ({sys.executable})", flush=True)
    for mod in ("torch", "nemo", "soundfile", "scipy", "psutil"):
        try:
            m = __import__(mod)
            print(f"[env] {mod}: {getattr(m, '__version__', '?')}", flush=True)
        except ImportError:
            print(f"[env] {mod}: NOT INSTALLED", flush=True)
    try:
        import torch  # type: ignore
        print(f"[env] torch.cuda.is_available: {torch.cuda.is_available()}", flush=True)
    except ImportError:
        pass


def peak_ram_mb() -> str:
    try:
        import psutil  # type: ignore
        rss = psutil.Process().memory_info().rss / 1e6
        return f"{rss:.0f} MB rss (approx, this process)"
    except ImportError:
        return "n/a (pip install psutil for RAM estimate)"


# ------------------------------------------------------------------ resolve
def resolve_model(language: str, cli_path: str | None) -> Path:
    if cli_path:
        return Path(cli_path)
    if language == "hi":
        env = os.environ.get("INDICCONFORMER_HI_MODEL")
        if env:
            return Path(env)
        for c in DEFAULT_HI_CANDIDATES:
            if c.is_file():
                return c
        return DEFAULT_HI_CANDIDATES[0]
    env = os.environ.get("INDICCONFORMER_SAT_MODEL")
    if env:
        return Path(env)
    for c in DEFAULT_SAT_CANDIDATES:
        if c.is_file():
            return c
    return DEFAULT_SAT_CANDIDATES[0]


# ------------------------------------------------------------------ main
def parse_args(argv=None):
    p = argparse.ArgumentParser(description="IndicConformer isolated .nemo inference test (no mocks).")
    p.add_argument("--language", required=True,
                   choices=["hi", "hindi", "sat", "santali", "santhali"],
                   help="'hi' for Hindi, 'sat' for Santali")
    p.add_argument("--audio", required=True, help="Path to 16kHz mono PCM WAV file")
    p.add_argument("--decoder", default="both", choices=["ctc", "rnnt", "both"],
                   help="CTC first per protocol; 'both' runs CTC then RNNT")
    p.add_argument("--model-hi", default=None, help="Override Hindi .nemo path")
    p.add_argument("--model-sat", default=None, help="Override Santali .nemo path")
    p.add_argument("--device", default="auto", choices=["auto", "cpu", "cuda"],
                   help="auto = cuda if available else cpu")
    p.add_argument("--validate-only", action="store_true",
                   help="Only validate the WAV (§10), skip model load")
    p.add_argument("--auto-convert", action="store_true",
                   help="If WAV is incompatible, write a converted *_16khz_mono.wav copy and use it")
    return p.parse_args(argv)


def main(argv=None) -> int:
    args = parse_args(argv)
    lang = LANG_TO_ID[args.language]
    audio_path = Path(args.audio)
    cli_model = args.model_hi if lang == "hi" else args.model_sat

    print("=" * 70, flush=True)
    print(f"[test] language={lang} decoder={args.decoder} audio={audio_path}", flush=True)
    print_versions()

    # §10: validate WAV before inference
    info = validate_wav(audio_path)
    if not info["compatible"]:
        if args.auto_convert:
            audio_path = convert_copy_to_16k_mono(audio_path)
            info = validate_wav(audio_path)
            if not info["compatible"]:
                print("[FAIL] converted copy still incompatible. STOP.", flush=True)
                return 2
        else:
            print("[WARN] audio incompatible. Re-run with --auto-convert, or convert with:\n"
                  "  ffmpeg -i input.wav -ar 16000 -ac 1 -c:a pcm_s16le out_16khz_mono.wav",
                  flush=True)
            print("[test] continuing anyway (model may still run) ...", flush=True)
    if args.validate_only:
        print("[test] --validate-only: stopping before model load.", flush=True)
        return 0 if info["compatible"] else 2

    # §16: STOP loudly if NeMo/.nemo cannot load — never mock, never auto-convert model
    model_path = resolve_model(lang, cli_model)
    size_mb = model_path.stat().st_size / 1e6 if model_path.is_file() else -1
    print(f"[model] path: {model_path}", flush=True)
    print(f"[model] size: {size_mb:.1f} MB" if size_mb >= 0 else "[model] FILE NOT FOUND", flush=True)
    if not model_path.is_file():
        print(f"[FAIL] .nemo checkpoint missing: {model_path}\n"
              "STOP per protocol: do not convert/invent a pipeline. "
              "Check the path (note: folder on disk is `santhali`) and re-run.", flush=True)
        return 3

    try:
        import torch
        import nemo.collections.asr as nemo_asr  # noqa: F401  (AI4Bharat NeMo fork expected)
    except ImportError as e:
        print(f"[FAIL] NeMo/torch import failed: {e!r}\n"
              "STOP per protocol. This is an environment issue, not a model issue.\n"
              "Install AI4Bharat NeMo (Linux/WSL2):\n"
              "  git clone https://github.com/AI4Bharat/NeMo.git && cd NeMo "
              "&& git checkout nemo-v2 && bash reinstall.sh\n"
              "Native Windows pip is NOT officially supported by NeMo — use WSL2.", flush=True)
        return 4

    if args.device == "cuda" or (args.device == "auto" and torch.cuda.is_available()):
        device = torch.device("cuda")
    else:
        device = torch.device("cpu")
    print(f"[model] device: {device}", flush=True)

    decoders = ["ctc", "rnnt"] if args.decoder == "both" else [args.decoder]
    try:
        t0 = time.perf_counter()
        # Hybrid CTC-RNNT checkpoint; restore_from preserves both decoders.
        model = nemo_asr.models.EncDecHybridRNNTCTCModel.restore_from(str(model_path), map_location=device)
        model.freeze()
        model = model.to(device)
        model.eval()
        load_s = time.perf_counter() - t0
    except Exception as e:
        print(f"[FAIL] NeMo could not load checkpoint: {e!r}\n"
              "STOP per protocol: report this exact error + dependency versions above. "
              "Do not auto-convert the model.", flush=True)
        return 5
    print(f"[perf] model load time: {load_s:.2f}s | RAM: {peak_ram_mb()}", flush=True)

    results = {}
    for dec in decoders:
        try:
            model.cur_decoder = dec
            t1 = time.perf_counter()
            # language_id is required by AI4Bharat multilingual checkpoints
            out = model.transcribe([str(audio_path)], batch_size=1, language_id=lang)
            inf_s = time.perf_counter() - t1
            text = out[0] if isinstance(out, (list, tuple)) else str(out)
            if hasattr(text, "text"):  # Hypothesis object -> unwrap
                text = text.text
            text = text.strip() if isinstance(text, str) else str(text)
        except Exception as e:
            print(f"[FAIL] inference ({dec}) raised: {e!r}", flush=True)
            return 6
        results[dec] = (text, inf_s)
        print(f"[result:{dec}] inference time: {inf_s:.2f}s", flush=True)
        print(f"[result:{dec}] transcript: {text!r}", flush=True)
        print(f"[result:{dec}] script: {detect_script(text)}", flush=True)

    print("-" * 70, flush=True)
    print(f"[summary] language={lang} load={load_s:.2f}s RAM={peak_ram_mb()}", flush=True)
    for dec, (text, inf_s) in results.items():
        print(f"[summary] {dec}: {inf_s:.2f}s -> {text!r}", flush=True)
    print("[test] DONE. For the offline check: disconnect network and re-run this exact command.", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
