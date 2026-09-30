"""ONNX Runtime ASR for the exported IndicConformer CTC graphs.

This is the runtime ASR path. It does not import NeMo and never touches a
``.nemo`` checkpoint: it reads the INT8-quantized graph plus the ``vocab.json``
descriptor that sits next to it.

Three pieces live here:

``LogMelFrontend``
    Reproduces NeMo's ``FilterbankFeatures`` log-mel features from the exact
    parameters recorded in ``vocab.json`` under ``features``: 16 kHz mono
    waveform in, ``[B, n_mels, T]`` float32 out. Keeping the numbers in the
    descriptor (instead of hardcoding them here) is what guarantees the runtime
    and the exported graph stay in agreement.

``CTCDecoder``
    The graph emits log-probabilities for all 22 checkpoint languages at once
    (5633 columns). The decoder selects this language's 256 columns plus the
    shared blank column, greedily collapses repeats and maps ids to
    SentencePiece pieces (``U+2581`` -> space), matching NeMo's
    ``CTCBPEDecoding`` fold.

``OnnxAsrModel``
    Session lifecycle (lazy, thread-safe) plus timing, so callers can report
    real load time separately from real inference latency.

The frontend/decoding logic is the implementation that was validated against
the ``.nemo`` reference models (max absolute feature difference 1.7e-05, 0.0
CER on the parity clips); see ``models/reports/onnx_asr_benchmark.json``.
"""

from __future__ import annotations

import json
import re
import threading
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple

import numpy as np

__all__ = [
    "SENTENCEPIECE_SPACE",
    "LogMelFrontend",
    "CTCDecoder",
    "OnnxAsrModel",
    "load_audio_16k_mono",
    "mel_filterbank",
]

#: SentencePiece word-boundary marker; becomes a space once detokenized.
SENTENCEPIECE_SPACE = "\u2581"

# NeMo: nemo/collections/asr/parts/submodules/ctc_decoding.py::decode_hypothesis
_PUNCT_SPACE_RE = re.compile(r"(\s+)([.,?])")


# --------------------------------------------------------------------- audio io
def load_audio_16k_mono(path: Path, target_sr: int = 16000) -> Tuple[np.ndarray, float, int]:
    """Read any audio file as float32 mono at ``target_sr``.

    Returns ``(waveform, duration_seconds, sample_rate)``. Multi-channel input
    is averaged to mono; a mismatched rate is resampled with
    :func:`scipy.signal.resample_poly`.
    """
    import soundfile as sf
    from scipy.signal import resample_poly

    audio, sr = sf.read(str(path), always_2d=False, dtype="float32")
    audio = np.asarray(audio, dtype=np.float32)
    if audio.ndim > 1:
        audio = audio.mean(axis=1)
    if int(sr) != target_sr:
        audio = resample_poly(audio, target_sr, int(sr)).astype(np.float32)
        sr = target_sr
    audio = np.ascontiguousarray(audio, dtype=np.float32)
    return audio, len(audio) / float(sr), int(sr)


# ------------------------------------------------------------------ mel filterbank
def _hz_to_mel_slaney(hz: np.ndarray) -> np.ndarray:
    f_min = 0.0
    f_sp = 200.0 / 3.0
    min_log_hz = 1000.0
    min_log_mel = (min_log_hz - f_min) / f_sp
    logstep = np.log(6.4) / 27.0
    hz = np.asarray(hz, dtype=np.float64)
    return np.where(
        hz < min_log_hz,
        (hz - f_min) / f_sp,
        min_log_mel + np.log(np.maximum(hz, 1e-10) / min_log_hz) / logstep,
    )


def _mel_to_hz_slaney(mel: np.ndarray) -> np.ndarray:
    f_min = 0.0
    f_sp = 200.0 / 3.0
    min_log_hz = 1000.0
    min_log_mel = (min_log_hz - f_min) / f_sp
    logstep = np.log(6.4) / 27.0
    mel = np.asarray(mel, dtype=np.float64)
    return np.where(
        mel < min_log_mel,
        f_min + f_sp * mel,
        min_log_hz * np.exp(logstep * (mel - min_log_mel)),
    )


def _mel_frequencies(n_mels: int, fmin: float, fmax: float) -> np.ndarray:
    min_mel = _hz_to_mel_slaney(np.array([fmin], dtype=np.float64))[0]
    max_mel = _hz_to_mel_slaney(np.array([fmax], dtype=np.float64))[0]
    return _mel_to_hz_slaney(np.linspace(min_mel, max_mel, n_mels))


def mel_filterbank(
    sr: int = 16000,
    n_fft: int = 512,
    n_mels: int = 80,
    fmin: float = 0.0,
    fmax: Optional[float] = None,
    norm: str = "slaney",
) -> np.ndarray:
    """Slaney-scaled mel filterbank for a single-sided ``n_fft``-point FFT.

    Returns ``[n_mels, n_fft // 2 + 1]``. Uses :mod:`librosa` when importable
    (it is what NeMo used to build the checkpoint) and otherwise an equivalent
    NumPy implementation.
    """
    if fmax is None:
        fmax = sr / 2.0
    try:
        import librosa

        fb = librosa.filters.mel(
            sr=sr, n_fft=n_fft, n_mels=n_mels, fmin=fmin, fmax=fmax, norm=norm
        )
        return np.ascontiguousarray(fb, dtype=np.float32)
    except Exception:
        pass

    fft_freqs = np.fft.rfftfreq(n=n_fft, d=1.0 / float(sr))
    mel_f = _mel_frequencies(n_mels + 2, fmin, fmax)
    fdiff = np.diff(mel_f)
    ramps = mel_f[:, None] - fft_freqs[None, :]
    lower = -ramps[:-2] / fdiff[:-1, None]
    upper = ramps[2:] / fdiff[1:, None]
    weights = np.maximum(0.0, np.minimum(lower, upper))
    if norm == "slaney":
        enorm = 2.0 / (mel_f[2 : n_mels + 2] - mel_f[:n_mels])
        weights = weights * enorm[:, None]
    return np.ascontiguousarray(weights, dtype=np.float32)


# ---------------------------------------------------------------- log-mel frontend
@dataclass
class LogMelFrontend:
    """NeMo-compatible log-mel feature extractor (CPU, no NeMo required)."""

    sample_rate: int = 16000
    n_fft: int = 512
    win_length: int = 400
    hop_length: int = 160
    n_mels: int = 80
    window: str = "hann"
    window_periodic: bool = False
    center: bool = True
    pad_mode: str = "reflect"
    fmin: float = 0.0
    fmax: Optional[float] = None
    mel_norm: str = "slaney"
    mag_power: float = 2.0
    use_log: bool = True
    log_zero_guard_type: str = "add"
    log_zero_guard_value: float = 2.0**-24
    preemph: Optional[float] = 0.97
    dither: float = 0.0
    normalize: str = "per_feature"
    normalize_eps: float = 1e-5
    frame_splicing: int = 1
    pad_to: int = 0
    pad_value: float = 0.0

    @classmethod
    def from_spec(cls, spec: Dict[str, Any]) -> "LogMelFrontend":
        fields = {f: spec[f] for f in cls.__dataclass_fields__ if f in spec}
        # NeMo only adds dither while training, so inference is always deterministic.
        fields["dither"] = 0.0
        return cls(**fields)

    def _build(self):
        import torch

        window_fn = {
            "hann": torch.hann_window,
            "hamming": torch.hamming_window,
            "blackman": torch.blackman_window,
            "bartlett": torch.bartlett_window,
            "none": None,
        }[self.window]
        win = (
            window_fn(self.win_length, periodic=self.window_periodic).float()
            if window_fn
            else None
        )
        fb = mel_filterbank(
            sr=self.sample_rate,
            n_fft=self.n_fft,
            n_mels=self.n_mels,
            fmin=self.fmin,
            fmax=self.fmax,
            norm=self.mel_norm,
        )
        return win, torch.from_numpy(fb)

    def num_frames(self, num_samples: int) -> int:
        """STFT frame count, matching ``FilterbankFeatures.get_seq_len``."""
        if self.center:
            return int(num_samples // self.hop_length) + 1
        return max(0, (num_samples - self.n_fft) // self.hop_length + 1)

    def __call__(self, wave_1d: np.ndarray) -> Tuple[np.ndarray, int]:
        """``wave_1d`` float32 mono at ``sample_rate`` -> ``(features, n_frames)``."""
        import torch

        if not hasattr(self, "_win"):
            self._win, self._fb = self._build()

        x = torch.from_numpy(
            np.ascontiguousarray(wave_1d, dtype=np.float32)
        ).unsqueeze(0)
        if self.dither and self.dither > 0:
            x = x + self.dither * torch.randn_like(x)
        if self.preemph is not None:
            x = torch.cat((x[:, 0:1], x[:, 1:] - self.preemph * x[:, :-1]), dim=1)

        spec = torch.stft(
            x,
            n_fft=self.n_fft,
            hop_length=self.hop_length,
            win_length=self.win_length,
            window=self._win,
            center=self.center,
            pad_mode=self.pad_mode,
            return_complex=True,
        )
        mag = torch.view_as_real(spec).pow(2).sum(-1).sqrt()
        if self.mag_power != 1.0:
            mag = mag.pow(self.mag_power)
        feats = torch.matmul(self._fb, mag)  # [1, n_mels, T]
        if self.use_log:
            if self.log_zero_guard_type == "add":
                feats = torch.log(feats + self.log_zero_guard_value)
            else:
                feats = torch.log(torch.clamp(feats, min=self.log_zero_guard_value))

        n_frames = self.num_frames(x.shape[-1])
        valid = feats[:, :, :n_frames]
        if self.normalize == "per_feature":
            mean = valid.mean(dim=2, keepdim=True)
            std = valid.std(dim=2, keepdim=True) + self.normalize_eps
            feats = (feats - mean) / std
        elif self.normalize == "all_features":
            mean = valid.mean()
            std = valid.std() + self.normalize_eps
            feats = (feats - mean) / std
        if feats.shape[-1] > n_frames:
            feats[:, :, n_frames:] = self.pad_value
        return feats.numpy().astype(np.float32), n_frames


# -------------------------------------------------------------------- CTC decoding
class CTCDecoder:
    """Language-aware greedy CTC decoder driven purely by ``vocab.json``."""

    def __init__(self, spec: Dict[str, Any], lang_id: str):
        if lang_id not in spec["all_languages"]:
            raise KeyError(f"language {lang_id!r} is not present in vocab.json")
        self.lang_id = lang_id
        self.blank_global = int(spec["ctc"]["blank_index_global"])
        self.offset = int(spec["all_languages"][lang_id]["offset"])
        self.n_tokens = int(spec["all_languages"][lang_id]["size"])
        self.vocab: List[str] = spec["vocab"]
        # Global columns: this language's tokens, then the shared blank column.
        self.columns = np.arange(
            self.offset, self.offset + self.n_tokens, dtype=np.int64
        ).tolist()
        self.columns.append(self.blank_global)
        self.blank_local = self.n_tokens

    def select_columns(self, logprobs: np.ndarray) -> np.ndarray:
        """``[B, T, C_global]`` -> ``[B, T, n_tokens + 1]`` for this language."""
        return logprobs[..., self.columns]

    def collapse(self, ids: Sequence[int]) -> List[int]:
        """NeMo ``decode_hypothesis`` fold: drop blanks, collapse repeats."""
        out: List[int] = []
        previous = self.blank_local
        for p in ids:
            if (p != previous or previous == self.blank_local) and p != self.blank_local:
                out.append(int(p))
            previous = p
        return out

    def detokenize(self, ids: Iterable[int]) -> str:
        text = "".join(self.vocab[int(i)] for i in ids).replace(
            SENTENCEPIECE_SPACE, " "
        )
        return _PUNCT_SPACE_RE.sub(r"\2", text)

    def decode(self, logprobs: np.ndarray, length: Optional[int] = None) -> str:
        """``logprobs``: ``[B, T, C_global]`` (or ``[T, C_global]``) -> text."""
        lp = logprobs[0] if logprobs.ndim == 3 else logprobs
        ids = np.argmax(self.select_columns(lp), axis=-1)
        if length is not None:
            ids = ids[: int(length)]
        return self.detokenize(self.collapse(ids.tolist()))


# ----------------------------------------------------------------- onnx recognizer
class OnnxAsrModel:
    """Feature extraction + ONNX Runtime forward + greedy CTC decode.

    Loading is explicit and timed so a caller can report a real one-time load
    cost separately from real per-utterance inference latency.
    """

    def __init__(
        self,
        model_path: Path,
        vocab_path: Path,
        lang_id: str,
        intra_op_threads: int = 0,
    ):
        import onnxruntime as ort

        model_path = Path(model_path)
        vocab_path = Path(vocab_path)
        if not model_path.is_file():
            raise FileNotFoundError(f"ONNX model not found: {model_path}")
        if not vocab_path.is_file():
            raise FileNotFoundError(f"vocab.json not found: {vocab_path}")

        self.spec: Dict[str, Any] = json.loads(
            vocab_path.read_text(encoding="utf-8")
        )
        if self.spec.get("language_code") != lang_id:
            raise ValueError(
                f"{vocab_path} describes language "
                f"{self.spec.get('language_code')!r}, not {lang_id!r}"
            )

        opts = ort.SessionOptions()
        opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        opts.log_severity_level = 3
        if intra_op_threads and intra_op_threads > 0:
            opts.intra_op_num_threads = int(intra_op_threads)
            opts.inter_op_num_threads = 1

        self.model_path = model_path
        self.vocab_path = vocab_path
        self.lang_id = lang_id
        self.language = self.spec.get("language", lang_id)
        self.quantization = self._detect_quantization(model_path)

        t0 = time.perf_counter()
        self.session = ort.InferenceSession(
            str(model_path), sess_options=opts, providers=["CPUExecutionProvider"]
        )
        self.session_load_seconds = time.perf_counter() - t0
        self.load_seconds = self.session_load_seconds

        self.input_names = [i.name for i in self.session.get_inputs()]
        self.output_names = [o.name for o in self.session.get_outputs()]
        self.audio_input = (
            "audio_signal" if "audio_signal" in self.input_names else self.input_names[0]
        )
        self.length_input = (
            "length"
            if "length" in self.input_names
            else (self.input_names[1] if len(self.input_names) > 1 else None)
        )

        self.frontend = LogMelFrontend.from_spec(self.spec["features"])
        self.decoder = CTCDecoder(self.spec, lang_id)
        self._lock = threading.Lock()
        self._warmed = False
        self._warmup_seconds = 0.0
        self._finalize_load_seconds()

    def _finalize_load_seconds(self) -> None:
        """Run one full synthetic pass so setup is billed to load, not inference.

        The first call into ONNX Runtime, the mel filterbank construction and the
        SciPy resampler each pay a one-time initialization cost (measured here at
        ~0.4 s, ~9 s and ~4 s respectively). Warming the *whole* path with a
        throwaway waveform keeps the first real classroom utterance from being
        charged for setup it did not cause. The synthetic result is discarded.
        """
        t0 = time.perf_counter()
        try:
            sr = int(self.spec["audio_input"]["sample_rate_hz"])
            # ~0.4 s of silence, so the encoder sees a realistic shape.
            n = sr * 2 // 5
            warm = np.zeros(n, dtype=np.float32)
            # Warm the resampler too: request a non-native rate, then use it.
            try:
                from scipy.signal import resample_poly

                resample_poly(warm[: (n // 2) * 2], 16000, 22050)
            except Exception:
                pass
            self.transcribe(warm)
            # Warm the real file-read path too (soundfile's first open/read).
            try:
                import tempfile

                import soundfile as sf

                with tempfile.TemporaryDirectory() as td:
                    probe = Path(td) / "warm.wav"
                    sf.write(str(probe), np.zeros(sr // 10, dtype=np.float32), sr)
                    load_audio_16k_mono(probe)
            except Exception:
                pass
            self._warmed = True
        except Exception:
            # A failed warm-up is not fatal; the first real call simply pays it.
            self._warmed = False
        self._warmup_seconds = time.perf_counter() - t0
        self.load_seconds = self.session_load_seconds + self._warmup_seconds

    @staticmethod
    def _detect_quantization(model_path: Path) -> str:
        """Read the real precision from the graph, never from the filename."""
        try:
            import onnx

            m = onnx.load(str(model_path), load_external_data=False)
            ops = {n.op_type for n in m.graph.node}
            quant_ops = {
                "MatMulInteger",
                "DynamicQuantizeLinear",
                "QLinearMatMul",
                "ConvInteger",
                "QGemm",
            }
            if ops & quant_ops:
                return "INT8"
            declared = {onnx.TensorProto.FLOAT, onnx.TensorProto.FLOAT16}
            has_float_init = any(
                t.data_type in declared for t in m.graph.initializer
            )
            return "FP32" if has_float_init else "UNKNOWN"
        except Exception:
            return "UNKNOWN"

    def features(self, wave_1d: np.ndarray) -> Tuple[np.ndarray, int]:
        return self.frontend(wave_1d)

    def forward(self, feats: np.ndarray, n_frames: int) -> np.ndarray:
        feed: Dict[str, np.ndarray] = {
            self.audio_input: np.ascontiguousarray(feats, dtype=np.float32)
        }
        if self.length_input:
            feed[self.length_input] = np.array([n_frames], dtype=np.int64)
        return self.session.run(self.output_names, feed)[0]

    def encoder_frames(self, n_frames: int) -> int:
        """Valid encoder steps for ``n_frames`` log-mel frames.

        The graph returns the padded encoder time axis and no length tensor, so
        the runtime crops with NeMo's own ``ceil(frames / subsampling_factor)``
        rule (the encoder's ``get_seq_len``).
        """
        factor = int(self.spec.get("encoder", {}).get("subsampling_factor", 1) or 1)
        return int(-(-int(n_frames) // factor))

    def transcribe(self, wave_1d: np.ndarray) -> Dict[str, Any]:
        """Transcribe a float32 mono 16 kHz waveform.

        Returns text plus real timings. ``latency_s`` covers feature extraction,
        the ONNX forward pass and the CTC decode. ``load_seconds`` is the
        one-time session cost and is reported separately on purpose.
        """
        duration = len(wave_1d) / float(self.spec["audio_input"]["sample_rate_hz"])
        t0 = time.perf_counter()
        with self._lock:
            feats, n_frames = self.features(wave_1d)
            logprobs = self.forward(feats, n_frames)
            enc_len = min(self.encoder_frames(n_frames), int(logprobs.shape[1]))
            text = self.decoder.decode(logprobs, length=enc_len)
        latency = time.perf_counter() - t0
        return {
            "text": text.strip(),
            "latency_s": round(latency, 4),
            "duration_s": round(duration, 4),
            "rtf": round(latency / duration, 4) if duration > 0 else None,
            "model_load_s": round(self.load_seconds, 4),
            "mel_frames": int(n_frames),
            "encoder_frames": int(enc_len),
            "language_id": self.lang_id,
        }

    def transcribe_file(self, wav_path: Path) -> Dict[str, Any]:
        wave, _duration, _sr = load_audio_16k_mono(Path(wav_path))
        return self.transcribe(wave)

    def describe(self) -> Dict[str, Any]:
        return {
            "runtime": "onnxruntime",
            "language": self.language,
            "language_id": self.lang_id,
            "script": self.spec.get("script"),
            "model_file": self.model_path.name,
            "model_path": str(self.model_path),
            "model_bytes": self.model_path.stat().st_size,
            "quantization": self.quantization,
            "onnx_int8": self.quantization == "INT8",
            "provider": self.session.get_providers()[0]
            if self.session.get_providers()
            else None,
            "load_seconds": round(self.load_seconds, 4),
            "session_load_seconds": round(self.session_load_seconds, 4),
            "warmup_seconds": round(self._warmup_seconds, 4),
            "n_tokens": self.decoder.n_tokens,
            "logit_columns": len(self.decoder.columns),
            "source_nemo_model": self.spec.get("source_nemo_model"),
        }
