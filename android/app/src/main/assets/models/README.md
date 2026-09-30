# Android ASR model assets — mobile-runtime artifacts ONLY

Runtime: ONNX Runtime Android (`onnxruntime-android`), driven by
`OfflineAsrModule.kt` over the `maatribhasha/offline_asr` MethodChannel.

## Contract (per language dir)

```
hindi_asr/      Hindi IndicConformer, CTC path (language id "hi")
santali_asr/    Santali IndicConformer, CTC path (language id "sat")
  model.onnx | model.int8.onnx   exported encoder+CTC head (16 kHz mono input frontend in Kotlin)
  tokens.txt                     "<piece> <id>" per line (BPE pieces, ▁ = word boundary)
  manifest.json                  descriptor below
```

`manifest.json` schema:

```json
{
  "language": "hi",
  "decoder": "ctc",
  "status": "ready-fp32 | ready-int8 | pending-conversion",
  "sampleRate": 16000,
  "channels": 1,
  "features": { "kind": "log-mel", "nMels": 80, "frameMs": 25, "shiftMs": 10 },
  "files": { "model": "model.onnx", "tokens": "tokens.txt" },
  "sourceCheckpoint": "indicconformer_stt_hi_hybrid_rnnt_large.nemo"
}
```

## Current state

Both dirs hold **placeholder** manifests (`status: pending-conversion`).
Until real export outputs land here, the app honestly reports
"Offline speech recognition is unavailable." — never a fake transcript.

## Rules

- NEVER copy `*.nemo` here (checkpoints, not runnable on Android).
- NEVER fake conversion by renaming extensions.
- Keep ONE model loaded at a time on the 2 GB target (module enforces this).
- INT8 only after the FP32 baseline passes on-device (see `models/conversion/README.md`).
