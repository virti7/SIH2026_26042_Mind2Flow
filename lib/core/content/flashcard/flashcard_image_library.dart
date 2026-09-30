import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'santali_flashcard_model.dart';
import 'santali_flashcard_repository.dart';

/// Source / provider markers shared with the backend
/// (`backend/app/flashcards/image_library.py`).
const String kSourceImageCatalog = 'IMAGE_CATALOG';
const String kSourceAiGenerated = 'AI_GENERATED';
const String kImageCatalogProvider = 'prototype-catalog';

/// `topic_source` sent when the teacher picked a catalog topic.
const String kTopicSourceCatalog = 'image_catalog';

/// True when a flashcard payload was built from the prototype image catalog.
bool isImageCatalogPayload(Map<String, dynamic> payload) =>
    (payload['source'] ?? '').toString() == kSourceImageCatalog;

/// One topic a teacher can pick from the Santali picture library
/// (a taxonomy category such as "Fruits", or a subcategory such as
/// "Wild Animals").
class FlashcardLibraryTopic {
  final String id;
  final String key;
  final String label;
  final String category;
  final String? subcategory;
  final List<CurriculumFlashcard> cards;
  final List<String> keywords;

  const FlashcardLibraryTopic({
    required this.id,
    required this.key,
    required this.label,
    required this.category,
    this.subcategory,
    required this.cards,
    this.keywords = const [],
  });

  int get cardCount => cards.length;
}

/// Image-first flashcard source: bundled pictures + the Santali word as
/// printed in the source book. Works fully offline. Topics the library
/// does not cover are left to the server (Sarvam) pipeline.
class FlashcardImageLibrary {
  final SantaliFlashcardRepository repository;
  final AssetBundle bundle;

  FlashcardImageLibrary({required this.repository, AssetBundle? bundle})
      : bundle = bundle ?? rootBundle;

  /// Hindi topic hints per library key (the taxonomy is English-only).
  static const Map<String, List<String>> _hindiHints = {
    'animals': ['जानवर', 'पशु'],
    'domestic_animals': ['पालतू'],
    'wild_animals': ['जंगली'],
    'birds': ['पक्षी', 'चिड़िया'],
    'vegetables': ['सब्जी', 'सब्ज़ी', 'सब्जियां', 'सब्जियाँ'],
    'fruits': ['फल'],
    'flowers': ['फूल'],
    'water_animals': ['जलीय', 'पानी के जीव', 'पानी के जानवर'],
    'insects': ['कीड़े', 'कीड़ा', 'कीट'],
    'residence': ['घर', 'आवास', 'निवास'],
    'transport': ['वाहन', 'परिवहन', 'यातायात', 'सवारी'],
    'relations': ['परिवार', 'रिश्ते', 'रिश्तेदार', 'संबंध'],
    'body_parts': ['शरीर', 'अंग'],
    'colours': ['रंग'],
  };

  static const Map<String, List<String>> _englishHints = {
    'colours': ['colors', 'colours'],
    'body_parts': ['body', 'body parts', 'parts of body'],
    'residence': ['house', 'houses', 'homes'],
    'relations': ['family', 'relatives', 'relationships'],
    'transport': ['vehicles', 'means of transport'],
    'water_animals': ['sea animals', 'aquatic animals'],
    'insects': ['insects', 'bugs'],
  };

  List<FlashcardLibraryTopic>? _topics;

  static String _normalize(String text) => text
      .replaceAll('_', ' ')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');

  static bool _keywordIn(String keyword, String haystack) {
    if (keyword.isEmpty) return false;
    final ascii = keyword.codeUnits.every((c) => c < 128);
    if (!ascii) return haystack.contains(keyword);
    return RegExp('(?<![a-z])${RegExp.escape(keyword)}(?![a-z])')
        .hasMatch(haystack);
  }

  Future<Map<String, List<String>>> _taxonomyKeywords() async {
    try {
      final raw = await bundle
          .loadString('${repository.assetRoot}/config/taxonomy.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final kw = (json['keywords'] as Map<String, dynamic>? ?? const {});
      return kw.map((k, v) =>
          MapEntry(k, (v as List).map((e) => e.toString()).toList()));
    } catch (_) {
      return const {};
    }
  }

  /// All selectable library topics (only those with pictures).
  Future<List<FlashcardLibraryTopic>> topics() async {
    if (_topics != null) return _topics!;
    final categories = await repository.getCategories();
    final taxonomyKeywords = await _taxonomyKeywords();

    final raw = <FlashcardLibraryTopic>[];
    for (final cat in categories) {
      final subDecks = cat.decks.where((d) => d.subcategoryKey != null).toList();
      if (subDecks.isNotEmpty) {
        for (final d in subDecks) {
          raw.add(FlashcardLibraryTopic(
            id: d.id,
            key: d.subcategoryKey!,
            label: d.title,
            category: cat.key,
            subcategory: d.subcategoryKey,
            cards: d.cards,
          ));
        }
        // Parent topic ("Animals") spans all its subcategories.
        raw.add(FlashcardLibraryTopic(
          id: cat.key,
          key: cat.key,
          label: cat.label,
          category: cat.key,
          cards: [for (final d in subDecks) ...d.cards],
        ));
      } else {
        for (final d in cat.decks) {
          raw.add(FlashcardLibraryTopic(
            id: d.id,
            key: cat.key,
            label: d.title,
            category: cat.key,
            cards: d.cards,
          ));
        }
      }
    }

    final words = <String, Set<String>>{};
    for (final t in raw) {
      final w = <String>{_normalize(t.label), _normalize(t.key)};
      w.addAll((taxonomyKeywords[t.key] ?? const []).map(_normalize));
      w.addAll((_englishHints[t.key] ?? const []).map(_normalize));
      w.addAll(_hindiHints[t.key] ?? const []);
      // Singular forms: "fruits" -> "fruit".
      w.addAll(w
          .where((x) =>
              x.codeUnits.every((c) => c < 128) &&
              x.endsWith('s') &&
              x.length > 3)
          .map((x) => x.substring(0, x.length - 1))
          .toList());
      words[t.id] = w..removeWhere((x) => x.isEmpty);
    }
    // A keyword shared by several topics ("food", "plant") is ambiguous.
    final owners = <String, int>{};
    for (final w in words.values) {
      for (final x in w) {
        owners[x] = (owners[x] ?? 0) + 1;
      }
    }

    _topics = [
      for (final t in raw)
        if (t.cards.isNotEmpty)
          FlashcardLibraryTopic(
            id: t.id,
            key: t.key,
            label: t.label,
            category: t.category,
            subcategory: t.subcategory,
            cards: t.cards,
            keywords: (words[t.id]!.where((x) => owners[x] == 1).toList()
              ..sort()),
          ),
    ];
    return _topics!;
  }

  /// Resolves a teacher topic (or a library topic id) to a library topic.
  /// Returns null when the library does not cover it.
  Future<FlashcardLibraryTopic?> findTopic(String topic,
      {String? topicId}) async {
    await topics();
    return matchLoaded(topic, topicId: topicId);
  }

  /// Synchronous [findTopic] over already-loaded topics (null before
  /// [topics] has completed). Used for live availability hints in the UI.
  FlashcardLibraryTopic? matchLoaded(String topic, {String? topicId}) {
    final all = _topics;
    if (all == null) return null;
    if (topicId != null) {
      for (final t in all) {
        if (t.id == topicId || t.key == topicId) return t;
      }
    }
    final hay = _normalize(topic);
    if (hay.isEmpty) return null;
    FlashcardLibraryTopic? best;
    var bestScore = 0;
    for (final t in all) {
      for (final w in t.keywords) {
        if (w.length > bestScore && _keywordIn(w, hay)) {
          best = t;
          bestScore = w.length;
        }
      }
    }
    return best;
  }

  String _assetPath(String relative) {
    final rel = relative.replaceAll(r'\', '/');
    return '${repository.assetRoot}/${rel.startsWith('/') ? rel.substring(1) : rel}';
  }

  /// Pictures usable for [languageMode]: the printed Santali word is
  /// required, plus the Hindi label when Hindi is shown. Nothing is
  /// translated or invented.
  List<CurriculumFlashcard> usableCards(
      FlashcardLibraryTopic topic, String languageMode) {
    final needsHindi = languageMode != 'en_sat';
    final seen = <String>{};
    final out = <CurriculumFlashcard>[];
    for (final c in topic.cards) {
      final santali = c.santali.value?.trim() ?? '';
      if (santali.isEmpty || c.relativeImagePath.isEmpty) continue;
      if (needsHindi && (c.hindiMeaning ?? '').trim().isEmpty) continue;
      if (!seen.add('${c.displayEnglish.toLowerCase()}|$santali')) continue;
      out.add(c);
    }
    return out;
  }

  static String _english(CurriculumFlashcard c) {
    final e = c.displayEnglish.replaceAll('_', ' ').trim();
    return e.isEmpty ? e : e[0].toUpperCase() + e.substring(1);
  }

  /// Builds a flashcard payload in the same shape the server returns, so
  /// preview, PDF and Downloads treat both sources identically.
  Map<String, dynamic> buildPayload({
    required FlashcardLibraryTopic topic,
    required int grade,
    required String section,
    required String subject,
    required String topicLabel,
    String topicSource = kTopicSourceCatalog,
    String? nipunOutcome,
    required String languageMode,
    required String flashcardType,
    required int cardCount,
    required String difficulty,
    required String visualStyle,
    required bool pronunciation,
    String? requestId,
  }) {
    final usable = usableCards(topic, languageMode);
    final picked = usable.take(cardCount).toList();
    final showHindi = languageMode != 'en_sat';
    final showEnglish = languageMode != 'hi_sat';
    final reqId = requestId ?? const Uuid().v4();
    final contentId = 'FC-LIB-G$grade-${topic.key.toUpperCase()}-'
        '$languageMode-${reqId.substring(0, 8)}';
    final generatedAt = DateTime.now().toUtc().toIso8601String();

    final cards = <Map<String, dynamic>>[];
    for (var i = 0; i < picked.length; i++) {
      final c = picked[i];
      final english = _english(c);
      final page = c.source.printedPageNumber ?? c.source.page;
      cards.add({
        'id': 'card_${(i + 1).toString().padLeft(2, '0')}',
        'number': i + 1,
        'concept': english,
        'type': flashcardType,
        'hindi': showHindi ? c.hindiMeaning : null,
        'english': showEnglish ? english : null,
        'santali': c.santali.value!.trim(),
        'santali_source': '${c.source.document} p.$page',
        'santali_source_lang': 'sat',
        'visual': {
          'kind': 'image',
          'source': kSourceImageCatalog,
          'image': _assetPath(c.relativeImagePath),
          if (c.santali.hasLabelImage)
            'label_image': _assetPath(c.santali.labelImage!),
          'asset_id': c.id,
          'visual_type': c.visualType,
          'description_en': c.caption,
        },
        'provider': kImageCatalogProvider,
        'translated': false,
      });
    }

    final metadata = <String, dynamic>{
      'grade': grade,
      'section': section,
      'subject': subject,
      'topic': topicLabel,
      'topic_source': topicSource,
      'topic_id': topic.id,
      'nipun_outcome': nipunOutcome,
      'language_mode': languageMode,
      'target_language': 'sat',
      'target_language_code': 'sat-IN',
      'flashcard_type': flashcardType,
      'difficulty': difficulty,
      'visual_style': visualStyle,
      'pronunciation': pronunciation,
      'provider': kImageCatalogProvider,
      'source': kSourceImageCatalog,
      'library_deck_id': topic.id,
      'library_deck_label': topic.label,
      'requested_card_count': cardCount,
      'generated_at': generatedAt,
      'version': 1,
    };

    return {
      'content_id': contentId,
      'request_id': reqId,
      'title': '$topicLabel (${cards.length} cards)',
      'grade': grade,
      'section': section,
      'subject': subject,
      'topic': topicLabel,
      'topic_source': topicSource,
      'nipun_outcome': nipunOutcome,
      'language_mode': languageMode,
      'target_language': 'sat',
      'target_language_code': 'sat-IN',
      'content_type': 'flashcard',
      'flashcard_type': flashcardType,
      'card_count': cards.length,
      'difficulty': difficulty,
      'visual_style': visualStyle,
      'pronunciation': pronunciation,
      'generated_at': generatedAt,
      'cards': cards,
      'source': kSourceImageCatalog,
      'translation': {'provider': kImageCatalogProvider, 'complete': true},
      'metadata': metadata,
    };
  }
}
