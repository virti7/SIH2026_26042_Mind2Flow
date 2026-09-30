import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'prototype_santali_phrases.dart';

/// Resolution outcome for a recognized Hindi sentence against the local
/// Santali demo phrase bank.
enum SantaliAudioStatus {
  /// Verified Santali text + existing local audio: play immediately.
  hit,

  /// Phrase is listed but not demo-ready (verified text or audio missing):
  /// show "Audio unavailable for this phrase." Never calls Sarvam.
  needsSetup,

  /// Phrase not in the bank: online -> existing pipeline, offline ->
  /// "Translation unavailable offline." Never guesses.
  miss,
}

class SantaliAudioResolution {
  final SantaliAudioStatus status;
  final SantaliDemoPhrase? phrase;

  /// Measured timings (real Stopwatch values, never hardcoded).
  final int lookupMs;
  final int audioResolveMs;

  const SantaliAudioResolution({
    required this.status,
    this.phrase,
    this.lookupMs = 0,
    this.audioResolveMs = 0,
  });
}

/// SUPERSEDED (presentation prototype v2): the live translator no longer
/// matches recognized Hindi against a phrase bank. The active demo scenario
/// ([PrototypeDemoTranslationRepository]) supplies the Santali output/audio
/// directly after final ASR. This file is kept for reference but is NOT
/// wired into the live translation path.
///
/// Reads ONLY the bundled manifest
/// (`assets/prototype_content/translation/phrases/santali_demo_phrases.json`)
/// and checks asset presence via `AssetManifest`. Makes zero network
/// requests — safe with Wi-Fi OFF, FastAPI OFF, Sarvam unavailable.
///
/// Matching is intentionally strict (exact normalized match + explicitly
/// listed variants only). No fuzzy/semantic similarity: playing the wrong
/// classroom sentence is worse than reporting unavailable.
class PrototypeSantaliAudioRepository {
  static const manifestPath =
      'assets/prototype_content/translation/phrases/santali_demo_phrases.json';

  final AssetBundle bundle;
  final List<SantaliDemoPhrase>? seedPhrases;
  final Set<String>? availableAssetsOverride;

  Map<String, SantaliDemoPhrase>? _index;
  Set<String>? _availableAssets;

  PrototypeSantaliAudioRepository({
    AssetBundle? bundle,
    this.seedPhrases,
    this.availableAssetsOverride,
  }) : bundle = bundle ?? rootBundle;

  /// Normalizes recognized Hindi speech before lookup:
  /// trim, collapse repeated whitespace, strip harmless trailing
  /// punctuation (। ? ! . , ; : ॥), unify danda variants.
  ///
  /// "अपनी गणित की किताब खोलो।" and "अपनी गणित की किताब खोलो"
  /// resolve to the same key.
  static String normalizeHindi(String input) {
    var s = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    // Unify double-danda / ASCII runs at the end, then strip one layer of
    // trailing sentence punctuation (interior punctuation is preserved).
    s = s.replaceAll('॥', '।');
    s = s.replaceAll(RegExp(r'[।?!.,;:\u0964\u0965]+$'), '').trim();
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> load() async {
    if (_index != null) return;
    final phrases = await _readPhrases();
    final index = <String, SantaliDemoPhrase>{};
    for (final p in phrases) {
      if (!p.isValid) continue;
      index.putIfAbsent(normalizeHindi(p.hindi), () => p);
      for (final v in p.variants) {
        final key = normalizeHindi(v);
        if (key.isNotEmpty) index.putIfAbsent(key, () => p);
      }
    }
    _index = index;
    _availableAssets = await _readAvailableAssets();
  }

  Future<List<SantaliDemoPhrase>> _readPhrases() async {
    if (seedPhrases != null) return seedPhrases!;
    try {
      final raw = await bundle.loadString(manifestPath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => SantaliDemoPhrase.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('[LocalSantaliAudioDiag] manifestLoadFailed error=$e');
      return const [];
    }
  }

  Future<Set<String>> _readAvailableAssets() async {
    if (availableAssetsOverride != null) {
      return Set<String>.from(availableAssetsOverride!);
    }
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      return manifest
          .listAssets()
          .where((p) =>
              p.startsWith(
                  'assets/prototype_content/translation/audio/santali/') &&
              (p.endsWith('.mp3') || p.endsWith('.wav')))
          .toSet();
    } catch (e) {
      debugPrint('[LocalSantaliAudioDiag] assetIndexFailed error=$e');
      return const {};
    }
  }

  /// All loaded demo phrases (empty until manifest + files are added).
  Future<List<SantaliDemoPhrase>> getPhrases() async {
    await load();
    return _index!.values.toSet().toList();
  }

  /// Validates referenced audio assets at startup/init. Logs missing files,
  /// never crashes; missing phrases fall back to unavailable handling.
  Future<List<String>> validateAssets() async {
    await load();
    final missing = <String>[];
    for (final p in _index!.values.toSet()) {
      if (!_availableAssets!.contains(p.audio)) {
        missing.add(p.audio);
        debugPrint(
            '[LocalSantaliAudioDiag] missingAsset=${p.audio} phraseId=${p.id}');
      }
    }
    return missing;
  }

  /// Resolves recognized Hindi text to a local Santali hit, setup-gap, or
  /// miss. Timings are measured, never fabricated.
  Future<SantaliAudioResolution> resolveHindiText(String hindi) async {
    final t0 = Stopwatch()..start();
    await load();
    final lookupMs = t0.elapsedMilliseconds;
    final key = normalizeHindi(hindi);
    final phrase = key.isEmpty ? null : _index![key];
    if (phrase == null) {
      t0.stop();
      return SantaliAudioResolution(
        status: SantaliAudioStatus.miss,
        lookupMs: lookupMs,
        audioResolveMs: t0.elapsedMilliseconds - lookupMs,
      );
    }
    final audioOk = _availableAssets!.contains(phrase.audio);
    final ready = audioOk && phrase.hasVerifiedText;
    t0.stop();
    return SantaliAudioResolution(
      status:
          ready ? SantaliAudioStatus.hit : SantaliAudioStatus.needsSetup,
      phrase: phrase,
      lookupMs: lookupMs,
      audioResolveMs: t0.elapsedMilliseconds - lookupMs,
    );
  }
}
