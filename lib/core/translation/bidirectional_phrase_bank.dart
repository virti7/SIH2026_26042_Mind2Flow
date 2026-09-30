library bidirectional_phrase_bank;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// MASTER BIDIRECTIONAL PHRASE BANK — single source of truth for the
/// deterministic offline Translator prototype.
///
/// Source file: `assets/prototype_content/translation/bidirectional_phrase_bank.json`
/// (top-level JSON array, bundled asset, never fetched over the network).
///
/// There is NO ASR, NO ONNX, NO model inference anywhere on this path:
/// the Translator uses a preselected record from this bank plus pre-recorded
/// local WAV clips. Translation pairs are NEVER hardcoded in Dart — every
/// string below comes from the JSON through [BidirectionalPhraseBank].
///
/// ```json
/// [
///   {
///     "id": "phrase_001",
///     "hindi": "...",
///     "hindiRoman": "...",
///     "hindiAudio": "assets/prototype_content/translation/audio/hindi/example.wav",
///     "santaliOlChiki": "...",
///     "santaliRoman": "...",
///     "santaliAudio": "assets/prototype_content/translation/audio/santali/example.wav",
///     "category": "classroom",
///     "tags": []
///   }
/// ]
/// ```

/// One bidirectional translation pair (Hindi <-> Santali).
class BidirectionalPhrase {
  final String id;
  final String hindi;
  final String hindiRoman;
  final String hindiAudio;
  final String santaliOlChiki;
  final String santaliRoman;
  final String santaliAudio;
  final String category;
  final List<String> tags;

  /// Demo confidence score (0–100) from the phrase JSON. Deterministic —
  /// never randomly generated; edit the JSON to change it for a demo.
  final int confidenceScore;

  /// Demo review status from the phrase JSON ('pending' | 'approved').
  final String reviewStatus;

  const BidirectionalPhrase({
    required this.id,
    required this.hindi,
    this.hindiRoman = '',
    this.hindiAudio = '',
    required this.santaliOlChiki,
    this.santaliRoman = '',
    this.santaliAudio = '',
    this.category = '',
    this.tags = const [],
    this.confidenceScore = 0,
    this.reviewStatus = 'pending',
  });

  factory BidirectionalPhrase.fromJson(Map<String, dynamic> json) {
    return BidirectionalPhrase(
      id: (json['id'] ?? '').toString(),
      hindi: (json['hindi'] ?? '').toString(),
      hindiRoman: (json['hindiRoman'] ?? '').toString(),
      hindiAudio: (json['hindiAudio'] ?? '').toString(),
      santaliOlChiki: (json['santaliOlChiki'] ?? '').toString(),
      santaliRoman: (json['santaliRoman'] ?? '').toString(),
      santaliAudio: (json['santaliAudio'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      confidenceScore: _parseConfidence(json['confidenceScore']),
      reviewStatus: (json['reviewStatus'] ?? 'pending').toString(),
    );
  }

  /// Accepts int or numeric string; anything else (or out of range) clamps
  /// to a sane 0–100 value so a typo in the JSON never crashes the demo.
  static int _parseConfidence(dynamic raw) {
    final v = raw is num ? raw : int.tryParse('${raw ?? ''}');
    if (v == null) return 0;
    return v.clamp(0, 100).toInt();
  }

  /// Load-bearing fields: id + both vernacular strings. Audio paths may be
  /// placeholders (missing clips surface an honest playback message, never
  /// unrelated audio).
  bool get isValid =>
      id.isNotEmpty && hindi.isNotEmpty && santaliOlChiki.isNotEmpty;

  bool get hasHindiAudio => hindiAudio.trim().isNotEmpty;

  bool get hasSantaliAudio => santaliAudio.trim().isNotEmpty;

  /// Local bundled asset only — remote URLs are never valid here.
  static bool isLocalAudio(String path) =>
      path.startsWith('assets/') && !path.contains('://');
}

/// Loads the master JSON array once, caches it in memory, serves records.
///
/// Zero network use. Invalid records are skipped (logged in debug mode) and
/// never crash the Translator. Test seam: [seedJson] replaces the asset
/// bundle content (validation still runs exactly as on file content).
class BidirectionalPhraseBank {
  static const bankAssetPath =
      'assets/prototype_content/translation/bidirectional_phrase_bank.json';

  /// Id of the preselected prototype record. Falls back to the first valid
  /// record when absent.
  static const defaultSelectedId = 'phrase_001';

  /// Deterministic demo mapping (data-driven, resolved via firstWhere on the
  /// loaded JSON — never hardcoded sentences in Dart):
  /// single tap (Hindi → Santali) uses [hindiToSantaliId];
  /// double tap (Santali → Hindi) uses [santaliToHindiId].
  static const hindiToSantaliId = 'phrase_002';
  static const santaliToHindiId = 'phrase_001';

  final AssetBundle bundle;

  /// Test seam: raw decoded JSON (List or Map) used instead of the bundle.
  final dynamic seedJson;

  List<BidirectionalPhrase>? _cache;

  BidirectionalPhraseBank({AssetBundle? bundle, this.seedJson})
      : bundle = bundle ?? rootBundle;

  /// Loads the JSON array once; subsequent calls return the in-memory cache.
  Future<List<BidirectionalPhrase>> load() async {
    if (_cache != null) return List<BidirectionalPhrase>.from(_cache!);
    final raw = await _readRawJson();
    final valid = <BidirectionalPhrase>[];
    final seenIds = <String>{};
    final items = _asItemList(raw);
    for (final item in items) {
      final phrase = BidirectionalPhrase.fromJson(item);
      if (!phrase.isValid || seenIds.contains(phrase.id)) {
        debugPrint('[BidirectionalBank] invalidRecord id=${phrase.id}');
        continue;
      }
      seenIds.add(phrase.id);
      valid.add(phrase);
    }
    _cache = valid;
    return List<BidirectionalPhrase>.from(_cache!);
  }

  /// Accepts a top-level array (the documented schema); tolerates a
  /// `{"phrases": [...]}` wrapper defensively.
  List<Map<String, dynamic>> _asItemList(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (decoded is Map<String, dynamic>) {
      final phrases = decoded['phrases'];
      if (phrases is List) {
        return phrases
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }

  Future<dynamic> _readRawJson() async {
    if (seedJson != null) return seedJson;
    try {
      final raw = await bundle.loadString(bankAssetPath);
      return jsonDecode(raw);
    } catch (e) {
      debugPrint('[BidirectionalBank] bankLoadFailed error=$e');
      return const [];
    }
  }

  Future<BidirectionalPhrase?> getById(String id) async {
    final phrases = await load();
    for (final p in phrases) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// The preselected prototype record: [defaultSelectedId] when present,
  /// otherwise the first valid record, otherwise null.
  BidirectionalPhrase? selected(List<BidirectionalPhrase> phrases) {
    if (phrases.isEmpty) return null;
    for (final p in phrases) {
      if (p.id == defaultSelectedId) return p;
    }
    return phrases.first;
  }

  /// Single tap (Hindi → Santali) record, resolved data-driven from the
  /// loaded JSON (`phrases.firstWhere((p) => p.id == 'phrase_002')`).
  /// Null when `phrase_002` is absent (caller shows the unavailable
  /// message instead of crashing or guessing).
  BidirectionalPhrase? hindiToSantali(List<BidirectionalPhrase> phrases) {
    try {
      return phrases.firstWhere((p) => p.id == hindiToSantaliId);
    } catch (_) {
      return null;
    }
  }

  /// Double tap (Santali → Hindi) record, resolved data-driven from the
  /// loaded JSON (`phrases.firstWhere((p) => p.id == 'phrase_001')`).
  /// Null when `phrase_001` is absent (caller shows the unavailable
  /// message instead of crashing or guessing).
  BidirectionalPhrase? santaliToHindi(List<BidirectionalPhrase> phrases) {
    try {
      return phrases.firstWhere((p) => p.id == santaliToHindiId);
    } catch (_) {
      return null;
    }
  }
}
