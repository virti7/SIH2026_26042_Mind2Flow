package com.maatribhasha.app.maatribhasha

// RETIRED — deterministic offline prototype.
//
// The Translator now uses a local JSON phrase bank plus pre-recorded audio
// (no ONNX, no ASR model, no microphone inference). This file is kept as an
// inert placeholder so the source history stays readable; it registers no
// MethodChannel, runs no inference, and must not be referenced from
// MainActivity or anywhere else.
class OfflineAsrModule {
    companion object {
        const val RETIRED = true
    }
}
