#!/usr/bin/env python3
"""PC-SIDE ONLY conversion: AI4Bharat IndicConformer .nemo -> mobile ONNX (CTC).

Runs on a dev PC (Linux/WSL2, Python 3.10/3.11, AI4Bharat NeMo `nemo-v2`
branch, torch). NEVER runs on Android — the APK must never contain
Python or NeMo. Output artifacts are bundled under
`android/app/src/main/assets/models/<lang>_asr/`.

Why CTC: the prototype uses the CTC decoder path first (no RNNT runtime
on device). The hybrid checkpoint contains both decoders; we export the
shared Conformer encoder + CTC head only.

Inputs (existing, never renamed/deleted):
    models/source/hindi/indicconformer_stt_hi_hybrid_rnnt_large.nemo  (lang hi)
    models/source/santhali/indicconformer_stt_sat_hybrid_rnnt_large.nemo (lang sat)

Outputs per language dir:
    model.onnx        FP32 baseline — must load first (accuracy reference)
    model.int8.onnx   INT8 quantized — only after FP32 baseline passes
    tokens.txt        id -> BPE piece mapping used by the Kotlin greedy decoder
    manifest.json     runtime descriptor consumed by OfflineAsrModule

Usage:
    python export_indicconformer_ctc_to_onnx.py --language hi --nemo <path> --out <dir>
    python export_indicconformer_ctc_to_onnx.py --language sat --nemo <path> --out <dir>

Then quantize (baseline verified first):
    python -m onnxruntime.quantization.quantize_dynamic --weight_type Int8 ...
    (see models/conversion/README.md for the exact command)

STOP rule: if export fails, keep the placeholder manifest.json
(status=pending-conversion) in the assets dir so the app honestly reports
"Offline speech recognition is unavailable." Never fake artifacts by
renaming extensions.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

TARGET_SAMPLE_RATE = 16000


def parse_args(argv=None):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--language", required=True, choices=["hi", "sat"])
    p.add_argument("--nemo", required=True, help="Path to source .nemo checkpoint")
    p.add_argument("--out", required=True, help="Output dir, e.g. hindi_asr")
    p.add_argument("--opset", type=int, default=17)
    return p.parse_args(argv)


def main(argv=None) -> int:
    args = parse_args(argv)
    nemo_path = Path(args.nemo)
    out_dir = Path(args.out)
    if not nemo_path.is_file():
        print(f"[FAIL] .nemo not found: {nemo_path}")
        return 2
    out_dir.mkdir(parents=True, exist_ok=True)

    try:
        import torch
        import nemo.collections.asr as nemo_asr  # AI4Bharat NeMo fork, nemo-v2
    except ImportError as e:
        print(f"[FAIL] NeMo/torch import failed: {e!r}. Install the AI4Bharat "
              "NeMo fork first (see models/conversion/README.md). STOP.")
        return 3

    lang = args.language
    print(f"[export] restoring {nemo_path} ...")
    model = nemo_asr.models.EncDecHybridRNNTCTCModel.restore_from(str(nemo_path))
    model.cur_decoder = "ctc"
    model.freeze()
    model.eval()

    # Export encoder + CTC head. Input: 80-dim log-mel frames [B, 80, T].
    # The Kotlin frontend produces exactly this feature layout.
    encoder = model.encoder
    ctc_head = model.ctc_decoder if hasattr(model, "ctc_decoder") else model.decoder
    encoder.eval()

    class CtcExportWrapper(torch.nn.Module):
        def __init__(self, enc, head):
            super().__init__()
            self.enc = enc
            self.head = head

        def forward(self, mel, mel_len):  # mel: [B, 80, T]
            encoded, encoded_len = self.enc(audio_signal=mel, length=mel_len)
            # encoded: [B, D, T'] -> CTC head expects [B, T', D]
            log_probs = self.head(logits=None, encoder_output=encoded.transpose(1, 2))
            if isinstance(log_probs, (tuple, list)):
                log_probs = log_probs[0]
            return log_probs, encoded_len

    wrapper = CtcExportWrapper(encoder, ctc_head).eval()
    dummy_mel = torch.randn(1, 80, 200)
    dummy_len = torch.tensor([200], dtype=torch.int64)
    onnx_path = out_dir / "model.onnx"
    with torch.no_grad():
        torch.onnx.export(
            wrapper,
            (dummy_mel, dummy_len),
            str(onnx_path),
            input_names=["mel", "mel_len"],
            output_names=["log_probs", "out_len"],
            dynamic_axes={
                "mel": {0: "batch", 2: "frames"},
                "mel_len": {0: "batch"},
                "log_probs": {0: "batch", 1: "frames"},
                "out_len": {0: "batch"},
            },
            opset_version=args.opset,
        )
    print(f"[export] wrote {onnx_path}")

    # tokens.txt: vocab id -> piece. Tokenizer lives in the .nemo artifacts.
    tokens_path = out_dir / "tokens.txt"
    try:
        vocab = model.tokenizer.vocab if hasattr(model, "tokenizer") else None
        if vocab is None and hasattr(model, "ctc_decoder"):
            vocab = getattr(model.ctc_decoder, "vocabulary", None)
        pieces = list(vocab) if vocab is not None else []
        if not pieces and hasattr(model, "cfg"):
            # Fallback: BPE model file shipped inside the .nemo; resolved
            # by NeMo during restore. Kept explicit so failures are loud.
            print("[export] WARNING: vocab not introspectable; extract "
                  "tokenizer.model from the .nemo and run "
                  "`sentencepiece --vocab` manually into tokens.txt")
        else:
            with open(tokens_path, "w", encoding="utf-8") as f:
                for i, piece in enumerate(pieces):
                    f.write(f"{piece} {i}\n")
            print(f"[export] wrote {tokens_path} ({len(pieces)} pieces)")
    except Exception as e:
        print(f"[FAIL] token export failed: {e!r}. STOP — fix before bundling.")
        return 4

    manifest = {
        "language": lang,
        "decoder": "ctc",
        "status": "ready-fp32",
        "sampleRate": TARGET_SAMPLE_RATE,
        "channels": 1,
        "features": {"kind": "log-mel", "nMels": 80, "frameMs": 25, "shiftMs": 10},
        "files": {"model": "model.onnx", "tokens": "tokens.txt"},
        "sourceCheckpoint": nemo_path.name,
        "notes": "Validate FP32 on-device first; then add model.int8.onnx and "
                 "flip status to ready-int8.",
    }
    with open(out_dir / "manifest.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print(f"[export] wrote {out_dir / 'manifest.json'}")
    print("[export] DONE. Next: on-device FP32 validation, then INT8 "
          "quantization (see README.md).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
