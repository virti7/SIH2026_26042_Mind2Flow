# .nemo → mobile ONNX (CTC) — PC-side preparation only

Source checkpoints (already downloaded — never rename/delete/redownload):

- `models/source/hindi/indicconformer_stt_hi_hybrid_rnnt_large.nemo` (hi)
- `models/source/santhali/indicconformer_stt_sat_hybrid_rnnt_large.nemo` (sat)

Raw `.nemo` files can NEVER ship in the APK. Android runs
ONNX Runtime (`onnxruntime-android`) via `OfflineAsrModule.kt`; the APK
must never contain Python or NeMo.

## 1. Environment (WSL2 Ubuntu, isolated from `backend/venv`)

```bash
sudo apt-get update && sudo apt-get install -y libsndfile1 ffmpeg git
python3.10 -m venv ~/.venv-nemo-export && source ~/.venv-nemo-export/bin/activate
pip install torch --index-url https://download.pytorch.org/whl/cpu  # or CUDA build
git clone https://github.com/AI4Bharat/NeMo.git && cd NeMo && git checkout nemo-v2 && bash reinstall.sh
pip install onnx onnxruntime
```

## 2. Export (CTC path first — no RNNT on device)

```bash
python models/conversion/export_indicconformer_ctc_to_onnx.py \
  --language hi --nemo models/source/hindi/indicconformer_stt_hi_hybrid_rnnt_large.nemo \
  --out /tmp/hindi_asr
python models/conversion/export_indicconformer_ctc_to_onnx.py \
  --language sat --nemo models/source/santhali/indicconformer_stt_sat_hybrid_rnnt_large.nemo \
  --out /tmp/santhali_asr
```

Copy the validated outputs into the app (replacing the placeholders):

- `android/app/src/main/assets/models/hindi_asr/` ← model.onnx, tokens.txt, manifest.json
- `android/app/src/main/assets/models/santali_asr/` ← model.onnx, tokens.txt, manifest.json

## 3. INT8 (only after the FP32 baseline loads on-device)

Do not reduce precision until the baseline mobile-compatible model loads
successfully. Then:

```bash
python - <<'EOF'
from onnxruntime.quantization import quantize_dynamic, QuantType
for d in ("/tmp/hindi_asr", "/tmp/santhali_asr"):
    quantize_dynamic(f"{d}/model.onnx", f"{d}/model.int8.onnx",
                     weight_type=QuantType.QInt8)
EOF
```

Copy `model.int8.onnx` next to `model.onnx`, set `files.model` to
`model.int8.onnx` and `status` to `ready-int8` in each `manifest.json`,
and re-test on the 2 GB device with one model loaded at a time.

## 4. Offline provisioning

Models ship pre-provisioned in the APK (or copied to app-private storage
on first launch by `OfflineAsrModule`). Never download on mic tap.
