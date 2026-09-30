# Isolated IndicConformer ASR test (PC only — Flutter/Android untouched)

This folder is OUTSIDE the app. Nothing here affects `lib/`, `android/`, `backend/`.

## 0. What was verified in this session (no shell available, so no inference yet)

- Hindi model file EXISTS:
  `models/source/hindi/indicconformer_stt_hi_hybrid_rnnt_large.nemo`
- Santali model file EXISTS (note spelling — folder on disk is **`santhali`**, not `santali`):
  `models/source/santhali/indicconformer_stt_sat_hybrid_rnnt_large.nemo`
- Shell execution is blocked in this agent session
  (`uv_spawn powershell.exe → EPERM`), so model sizes, Python/torch/NeMo
  versions, audio validation, load/inference timing, transcripts, and the
  offline re-run could NOT be executed here. Nothing was mocked — the report
  marks them NOT TESTED instead of inventing outputs.

## 1. Safest supported install (per official docs)

Official model cards: `git clone https://github.com/AI4Bharat/NeMo.git &&
cd NeMo && git checkout nemo-v2 && bash reinstall.sh` (Linux script).
NVIDIA NeMo has NO official native-Windows pip support → use **WSL2 + Ubuntu**.

```bash
# in WSL2 Ubuntu
wsl --install                       # from Windows PowerShell (once)
sudo apt-get update && sudo apt-get install -y libsndfile1 ffmpeg git
python3.10 --version                # want 3.10 or 3.11
python3.10 -m venv ~/.venv-asr && source ~/.venv-asr/bin/activate
pip install torch --index-url https://download.pytorch.org/whl/cpu   # or CUDA build
git clone https://github.com/AI4Bharat/NeMo.git && cd NeMo && git checkout nemo-v2 && bash reinstall.sh
pip install soundfile scipy psutil  # helpers used by the test script
```

Keep this venv SEPARATE from `backend/venv`.

## 2. Test audio (16 kHz mono PCM WAV, real recordings — never fake)

Place (or record) these — originals stay untouched; conversions are copies:

- `models/test_audio/hindi_sun_rises_east_16khz.wav` — speaker says «सूरज पूरब से निकलता है।»
- `models/test_audio/santali_sun_rises_east_16khz.wav` — same sentence in Santali

Record at 16 kHz mono if possible, else convert a copy:

```bash
ffmpeg -i original_recording.wav -ar 16000 -ac 1 -c:a pcm_s16le hindi_sun_rises_east_16khz.wav
```

Validate without loading any model:

```bash
python ../asr_test/test_indicconformer.py --language hi  --audio ../test_audio/hindi_sun_rises_east_16khz.wav --validate-only
python ../asr_test/test_indicconformer.py --language sat --audio ../test_audio/santali_sun_rises_east_16khz.wav --validate-only
```

## 3. Run inference (CTC first, then both) — from `models/asr_test/`

```bash
# Hindi CTC
python test_indicconformer.py --language hi --audio ../test_audio/hindi_sun_rises_east_16khz.wav --decoder ctc
# Hindi CTC+RNNT
python test_indicconformer.py --language hi --audio ../test_audio/hindi_sun_rises_east_16khz.wav --decoder both
# Santali CTC
python test_indicconformer.py --language sat --audio ../test_audio/santali_sun_rises_east_16khz.wav --decoder ctc
# Santali CTC+RNNT
python test_indicconformer.py --language sat --audio ../test_audio/santali_sun_rises_east_16khz.wav --decoder both
```

Overrides (no absolute paths baked into code):

```bash
INDICCONFORMER_HI_MODEL=/path/to/hi.nemo INDICCONFORMER_SAT_MODEL=/path/to/sat.nemo \
  python test_indicconformer.py --language hi --audio <path>
python test_indicconformer.py --language hi --audio <path> --model-hi /path/to/hi.nemo
```

## 4. Offline check (§13)

Load once online (first run may cache HF/config), then disconnect network and
re-run the SAME two commands. PASS = identical behaviour, no network needed.

## 5. If model loading fails (§16)

STOP. Copy the exact `[FAIL]` line + `[env]` versions + command, and fix the
environment separately. Do not convert the `.nemo`, do not invent transcripts.
