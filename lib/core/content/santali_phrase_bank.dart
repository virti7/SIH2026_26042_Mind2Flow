library santali_phrase_bank;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// MASTER OFFLINE SANTALI PHRASE BANK — single source of truth.
///
/// Source file: `assets/prototype_content/translation/phrase_bank/santali_phrase_bank.json`
/// (bundled asset, never fetched over the network).
///
/// Flow: MASTER JSON + local `audio/santali/` folder
///   -> [SantaliPhraseBankRepository]
///   -> Quick Phrase Bank UI
///   -> Speaker / Repeat / Use in Live Lesson.
///
/// The Santali fields are PRE-VERIFIED content supplied by the teacher.
/// Empty Ol Chiki / Roman means "not provided yet" — never fabricated,
/// never filled by an API. Audio paths are local asset paths only.

/// One pre-verified Santali classroom phrase.
///
/// Bidirectional fields ([english], [hindiAudio], [hindiVariants],
/// [santaliVariants]) are optional and default to empty so older bank files
/// keep loading. Empty Ol Chiki / Roman means "not provided yet".
class SantaliPhrase {
  final String id;
  final String category;
  final String hindi;
  final String santaliOlChiki;
  final String santaliRoman;
  final String audio;
  final List<String> tags;

  /// English gloss for Student → Teacher output. Empty = not provided.
  final String english;

  /// Local Hindi classroom clip for Student → Teacher playback.
  /// Empty = not provided (player shows "Could not play translated audio.").
  final String hindiAudio;

  /// Explicitly configured Hindi match variants (Teacher → Student, §15.2).
  final List<String> hindiVariants;

  /// Explicitly configured Santali/Roman match variants (Student → Teacher).
  final List<String> santaliVariants;

  const SantaliPhrase({
    required this.id,
    required this.category,
    required this.hindi,
    required this.santaliOlChiki,
    required this.santaliRoman,
    required this.audio,
    this.tags = const [],
    this.english = '',
    this.hindiAudio = '',
    this.hindiVariants = const [],
    this.santaliVariants = const [],
  });

  factory SantaliPhrase.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) =>
        ((v as List?) ?? const []).map((e) => e.toString()).toList();
    return SantaliPhrase(
      id: (json['id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      hindi: (json['hindi'] ?? '').toString(),
      santaliOlChiki: (json['santaliOlChiki'] ?? '').toString(),
      santaliRoman: (json['santaliRoman'] ?? '').toString(),
      audio: (json['audio'] ?? '').toString(),
      tags: strList(json['tags']),
      english: (json['english'] ?? '').toString(),
      hindiAudio: (json['hindiAudio'] ?? '').toString(),
      hindiVariants: strList(json['hindiVariants']),
      santaliVariants:
          strList(json['santaliVariants'] ?? json['santaliRomanVariants']),
    );
  }

  /// Valid = load-bearing fields present. Empty Ol Chiki / Roman is
  /// allowed (shown as "Not provided") — it does NOT invalidate the record.
  bool get isValid =>
      id.isNotEmpty &&
      category.isNotEmpty &&
      hindi.isNotEmpty &&
      audio.isNotEmpty;

  bool get hasOlChiki => santaliOlChiki.trim().isNotEmpty;
  bool get hasRoman => santaliRoman.trim().isNotEmpty;

  /// Local bundled asset only — remote URLs are never valid here.
  bool get isLocalAudio =>
      audio.startsWith('assets/') && !audio.contains('://');

  bool get hasEnglish => english.trim().isNotEmpty;
  bool get hasHindiAudio => hindiAudio.trim().isNotEmpty;

  /// Local bundled Hindi clip only (Student → Teacher playback).
  bool get isLocalHindiAudio =>
      hasHindiAudio &&
      hindiAudio.startsWith('assets/') &&
      !hindiAudio.contains('://');

  /// Multi-field search: Hindi, Ol Chiki, Roman, tags, category.
  bool matchesQuery(String rawQuery) {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (hindi.contains(rawQuery.trim())) return true;
    if (santaliOlChiki.toLowerCase().contains(q)) return true;
    if (santaliRoman.toLowerCase().contains(q)) return true;
    if (category.toLowerCase().contains(q)) return true;
    for (final tag in tags) {
      if (tag.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}

/// Loads + validates the master phrase-bank JSON once, caches it in memory,
/// and serves search / category filtering / lookup by id.
///
/// Zero network use. Invalid records never crash the bank: they are skipped
/// and their ids are logged in debug mode.
class SantaliPhraseBankRepository {
  static const bankAssetPath =
      'assets/prototype_content/translation/phrase_bank/santali_phrase_bank.json';

  static const audioPrefix =
      'assets/prototype_content/translation/audio/santali/';

  final AssetBundle bundle;

  /// Test seam: parsed seed phrases used instead of the asset bundle
  /// (validation still runs on them exactly as on file content).
  final List<SantaliPhrase>? seedPhrases;

  /// Test seam: bundled-audio lookup override (avoids AssetManifest in tests).
  final Set<String>? availableAssetsOverride;

  List<SantaliPhrase>? _cache;
  List<String>? _invalidIds;
  Set<String>? _availableAudio;

  SantaliPhraseBankRepository({
    AssetBundle? bundle,
    this.seedPhrases,
    this.availableAssetsOverride,
  }) : bundle = bundle ?? rootBundle;

  /// Loads the JSON once; subsequent calls return the in-memory cache.
  Future<List<SantaliPhrase>> load() async {
    if (_cache != null) return List<SantaliPhrase>.from(_cache!);
    final rawPhrases = await _readRawPhrases();
    final valid = <SantaliPhrase>[];
    final invalid = <String>[];
    final seenIds = <String>{};
    for (final p in rawPhrases) {
      if (!p.isValid || seenIds.contains(p.id)) {
        invalid.add(p.id.isEmpty ? '<missing-id>' : p.id);
        debugPrint('[SantaliPhraseBank] invalidRecord id=${p.id}');
        continue;
      }
      seenIds.add(p.id);
      if (!p.hasOlChiki || !p.hasRoman) {
        debugPrint('[SantaliPhraseBank] incompleteText id=${p.id} '
            'olChiki=${p.hasOlChiki} roman=${p.hasRoman}');
      }
      if (!p.isLocalAudio) {
        invalid.add(p.id);
        debugPrint('[SantaliPhraseBank] nonLocalAudio id=${p.id} '
            'audio=${p.audio}');
        continue;
      }
      valid.add(p);
    }
    _cache = valid;
    _invalidIds = invalid;
    _availableAudio = await _readAvailableAudio();
    for (final p in valid) {
      if (!_availableAudio!.contains(p.audio)) {
        debugPrint('[SantaliPhraseBank] missingAsset=${p.audio} '
            'phraseId=${p.id}');
      }
    }
    return List<SantaliPhrase>.from(_cache!);
  }

  Future<List<SantaliPhrase>> _readRawPhrases() async {
    if (seedPhrases != null) return List<SantaliPhrase>.from(seedPhrases!);
    try {
      final raw = await bundle.loadString(bankAssetPath);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final phrases = (decoded['phrases'] as List?) ?? const [];
        return phrases
            .whereType<Map>()
            .map((e) => SantaliPhrase.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => SantaliPhrase.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('[SantaliPhraseBank] bankLoadFailed error=$e');
    }
    return const [];
  }

  Future<Set<String>> _readAvailableAudio() async {
    if (availableAssetsOverride != null) {
      return Set<String>.from(availableAssetsOverride!);
    }
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      return manifest
          .listAssets()
          .where((p) =>
              p.startsWith(audioPrefix) &&
              (p.endsWith('.mp3') || p.endsWith('.wav')))
          .toSet();
    } catch (e) {
      debugPrint('[SantaliPhraseBank] assetIndexFailed error=$e');
      return const {};
    }
  }

  /// Ids of records skipped during validation (empty when all valid).
  Future<List<String>> invalidIds() async {
    await load();
    return List<String>.from(_invalidIds ?? const []);
  }

  /// Categories in first-seen order (never hardcoded in the UI).
  Future<List<String>> categories() async {
    final phrases = await load();
    final cats = <String>[];
    for (final p in phrases) {
      if (!cats.contains(p.category)) cats.add(p.category);
    }
    return cats;
  }

  /// Dynamic search + category filter over the loaded JSON data.
  Future<List<SantaliPhrase>> search({
    String query = '',
    String category = 'All',
  }) async {
    final phrases = await load();
    return phrases.where((p) {
      if (category != 'All' && p.category != category) return false;
      return p.matchesQuery(query);
    }).toList();
  }

  Future<SantaliPhrase?> getById(String id) async {
    final phrases = await load();
    for (final p in phrases) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// True when the phrase's local audio asset is bundled.
  Future<bool> audioExists(SantaliPhrase phrase) async {
    await load();
    return _availableAudio?.contains(phrase.audio) ?? false;
  }
}
