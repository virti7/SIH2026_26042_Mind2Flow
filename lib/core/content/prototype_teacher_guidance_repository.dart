import 'dart:convert';

import 'package:flutter/services.dart';

import 'teacher_guidance_models.dart';

/// Deterministic OFFLINE Teacher Guidance Q&A engine.
///
/// Pipeline:
/// ```text
/// question -> normalize -> tokenize -> keyword scoring
///          + question-pattern matching + intent boost
///          + pronoun-topic resolution + class/subject/topic context
///          -> best predefined knowledge item (or unknown / clarification)
/// ```
///
/// Reads ONLY the bundled asset
/// (`assets/prototype_content/teacher_guidance/teacher_guidance.json`).
/// Never touches FastAPI, Supabase, Sarvam, any LLM, or any network client
/// — safe with airplane mode ON, Wi-Fi OFF, backend stopped.
///
/// The parsed knowledge base is cached in memory after the first load.
class PrototypeTeacherGuidanceRepository {
  static const String assetPath =
      'assets/prototype_content/teacher_guidance/teacher_guidance.json';

  /// Fixed bilingual message shown when nothing matches. Pre-authored,
  /// never generated.
  static const String unknownAnswerHindi =
      'इस प्रश्न के लिए अभी ऑफलाइन मार्गदर्शन उपलब्ध नहीं है।';
  static const String unknownAnswerEnglish =
      'Offline guidance for this question is not available yet.';

  final AssetBundle bundle;

  /// Minimum total score required for a match. Configurable per call.
  final double defaultThreshold;

  List<TeacherGuidanceItem>? _cachedItems;

  PrototypeTeacherGuidanceRepository({
    AssetBundle? bundle,
    this.defaultThreshold = 3.0,
  }) : bundle = bundle ?? rootBundle;

  // ------------------------------------------------------------------
  // Loading (bundled asset only, cached in memory)
  // ------------------------------------------------------------------

  /// Loads and caches the predefined knowledge base. Returns an empty
  /// list (never throws) when the asset is missing or malformed — every
  /// question then resolves to the fixed unknown message.
  Future<List<TeacherGuidanceItem>> loadItems() async {
    if (_cachedItems != null) return _cachedItems!;
    try {
      final raw = await bundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      final list = (decoded is Map<String, dynamic>)
          ? (decoded['items'] as List? ?? const [])
          : const [];
      final items = <TeacherGuidanceItem>[];
      for (final e in list) {
        if (e is! Map) continue;
        try {
          final item = TeacherGuidanceItem.fromJson(
              Map<String, dynamic>.from(e));
          if (item.isValid) items.add(item);
        } catch (_) {}
      }
      _cachedItems = List.unmodifiable(items);
    } catch (_) {
      _cachedItems = const [];
    }
    return _cachedItems!;
  }

  /// For tests / diagnostics.
  bool get isLoaded => _cachedItems != null;

  // ------------------------------------------------------------------
  // Normalization (deterministic, no external libraries)
  // ------------------------------------------------------------------

  /// lowercase (Latin) -> trim -> collapse spaces -> strip punctuation
  /// (keeps Devanagari + letters + digits + spaces) -> single-spaced.
  static String normalizeQuestion(String input) {
    var s = input.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    // Keep letters (incl. Devanagari range), digits and spaces.
    s = s.replaceAll(RegExp(r'[^\u0900-\u097Fa-z0-9 ]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static List<String> tokenize(String normalized) {
    if (normalized.isEmpty) return const [];
    return normalized
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
  }

  static bool _isNumeric(String s) => RegExp(r'^[0-9]+$').hasMatch(s);

  /// Single keyword hit test against the token list:
  /// * multi-word keyword -> normalized question contains the phrase
  /// * numeric keyword   -> exact token equality (so "100" != "1000")
  /// * other keyword     -> token equality, or containment either way for
  ///   tokens/keywords of length >= 4 (covers Hindi plurals like
  ///   संख्या/संख्याएँ and English teach/teaching without a stemmer).
  static bool _keywordHits(
      String keyword, String normalizedQuestion, List<String> tokens) {
    final k = normalizeQuestion(keyword);
    if (k.isEmpty) return false;
    if (k.contains(' ')) return normalizedQuestion.contains(k);
    if (_isNumeric(k)) return tokens.contains(k);
    for (final t in tokens) {
      if (t == k) return true;
      if (t.length >= 4 && k.length >= 4 && (t.contains(k) || k.contains(t))) {
        return true;
      }
    }
    return false;
  }

  // ------------------------------------------------------------------
  // Intent + pronoun helpers
  // ------------------------------------------------------------------

  static const Map<TeacherGuidanceIntent, List<String>> _intentSignals = {
    TeacherGuidanceIntent.teachingMethod: [
      'teach',
      'सिखा',
      'पढ़ा',
      'how to',
      'कैसे'
    ],
    TeacherGuidanceIntent.activity: [
      'activity',
      'गतिविधि',
      'खेल',
      'game',
      'play'
    ],
    TeacherGuidanceIntent.example: ['example', 'उदाहरण', 'मिसाल'],
    TeacherGuidanceIntent.explanation: ['explain', 'समझा', 'बताओ', 'बताइए'],
    TeacherGuidanceIntent.simplify: [
      'simplif',
      'simple',
      'easier',
      'easy',
      'आसान',
      'सरल'
    ],
    TeacherGuidanceIntent.classroomActivity: [
      'classroom',
      'कक्षा',
      'activity',
      'गतिविधि'
    ],
    TeacherGuidanceIntent.assessment: [
      'assess',
      'test',
      'check',
      'evaluat',
      'question',
      'जाँच',
      'मूल्यांकन',
      'परख',
      'आकलन',
      'परीक्षा'
    ],
    TeacherGuidanceIntent.commonDifficulty: [
      'difficult',
      'difficulty',
      'कठिन',
      'मुश्किल',
      'problem',
      'समस्या'
    ],
    TeacherGuidanceIntent.remediation: ['remed', 'सुधार', 'कमजोर', 'पीछे'],
  };

  static const List<String> _demonstratives = [
    'this',
    'that',
    'it',
    'these',
    'इस',
    'यह',
    'ये',
    'उस',
    'वह',
    'इसे',
    'उसे',
    'इसका',
  ];

  static Set<TeacherGuidanceIntent> _detectIntents(List<String> tokens) {
    final found = <TeacherGuidanceIntent>{};
    for (final entry in _intentSignals.entries) {
      for (final signal in entry.value) {
        final hit = tokens.any(
            (t) => t == signal || (t.length >= 3 && t.contains(signal)));
        if (hit) {
          found.add(entry.key);
          break;
        }
      }
    }
    return found;
  }

  // ------------------------------------------------------------------
  // Context helpers
  // ------------------------------------------------------------------

  static String _norm(String? s) => (s ?? '').trim().toLowerCase();

  static bool _fuzzyEquals(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;
    // Tolerate Math/Mathematics-style variants via 4-letter prefix.
    final x = a.length >= 4 ? a.substring(0, 4) : a;
    final y = b.length >= 4 ? b.substring(0, 4) : b;
    return x == y;
  }

  // ------------------------------------------------------------------
  // Scoring weights (deterministic constants)
  // ------------------------------------------------------------------

  static const double _wKeyword = 1.0;
  static const double _wPatternExact = 5.0;
  static const double _wPatternContains = 3.0;
  static const double _wIntent = 2.0;
  static const double _wPronounTopic = 3.0;
  static const double _wContextClass = 2.0;
  static const double _wContextSubject = 2.0;
  static const double _wContextTopic = 3.0;

  /// Answers one teacher question fully offline.
  ///
  /// A candidate needs a *content signal* (keyword / pattern / intent /
  /// pronoun-topic resolution) to be eligible; context alone can never
  /// select an item. The winner must reach [threshold] (default
  /// [defaultThreshold]). Near-ties at/above threshold return a
  /// clarification result instead of guessing.
  Future<TeacherGuidanceResult> answerQuestion(
    String question, {
    TeacherGuidanceContext context = const TeacherGuidanceContext(),
    double? threshold,
  }) async {
    final limit = threshold ?? defaultThreshold;
    final normalized = normalizeQuestion(question);
    if (normalized.isEmpty) {
      return TeacherGuidanceResult.unknown(threshold: limit);
    }
    final items = await loadItems();
    if (items.isEmpty) {
      return TeacherGuidanceResult.unknown(threshold: limit);
    }
    final tokens = tokenize(normalized);
    final intents = _detectIntents(tokens);
    final hasDemonstrative =
        tokens.any((t) => _demonstratives.contains(t));

    final ctxClass = _norm(context.className);
    final ctxSubject = _norm(context.subject);
    final ctxTopic = _norm(context.topic);

    final scored = <_ScoredItem>[];
    for (final item in items) {
      double base = 0; // content signal: keyword + pattern + intent + pronoun
      double bonus = 0; // class / subject / topic context

      for (final kw in item.keywords) {
        if (_keywordHits(kw, normalized, tokens)) base += _wKeyword;
      }

      for (final rawPattern in item.questionPatterns) {
        final p = normalizeQuestion(rawPattern);
        if (p.isEmpty) continue;
        if (normalized == p) {
          base += _wPatternExact;
          break;
        }
        if (normalized.contains(p) || p.contains(normalized)) {
          base += _wPatternContains;
          break;
        }
      }

      if (item.intent != TeacherGuidanceIntent.unknown &&
          intents.contains(item.intent)) {
        base += _wIntent;
      }

      final itemTopic = _norm(item.topic);
      if (hasDemonstrative &&
          ctxTopic.isNotEmpty &&
          itemTopic.isNotEmpty &&
          _fuzzyEquals(itemTopic, ctxTopic)) {
        // "How should I teach THIS?" -> resolve THIS to the current topic.
        base += _wPronounTopic;
      }

      // Context must not invent relevance: it only re-ranks items that
      // already carry a content signal.
      if (base < 1) continue;

      if (ctxClass.isNotEmpty &&
          _fuzzyEquals(_norm(item.className), ctxClass)) {
        bonus += _wContextClass;
      }
      if (ctxSubject.isNotEmpty &&
          _fuzzyEquals(_norm(item.subject), ctxSubject)) {
        bonus += _wContextSubject;
      }
      if (ctxTopic.isNotEmpty &&
          itemTopic.isNotEmpty &&
          _fuzzyEquals(itemTopic, ctxTopic)) {
        bonus += _wContextTopic;
      }

      scored.add(_ScoredItem(item, base + bonus));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    if (scored.isEmpty || scored.first.score < limit) {
      return TeacherGuidanceResult.unknown(threshold: limit);
    }

    final top = scored.first;
    final near = scored
        .where((s) =>
            s.item.id != top.item.id &&
            s.score >= limit &&
            (top.score - s.score) <= 1.0)
        .take(2)
        .toList();
    if (near.isNotEmpty) {
      return TeacherGuidanceResult.clarification(
        [top.item, ...near.map((s) => s.item)],
        score: top.score,
        threshold: limit,
      );
    }
    return TeacherGuidanceResult.matched(
      top.item,
      score: top.score,
      threshold: limit,
    );
  }
}

class _ScoredItem {
  final TeacherGuidanceItem item;
  final double score;
  const _ScoredItem(this.item, this.score);
}

/// Optional per-teacher Q&A history. The knowledge base is shared/static;
/// history is namespaced by [ownerUserId] in memory so Teacher A never
/// sees Teacher B's questions. Nothing here touches the network.
class TeacherGuidanceHistoryStore {
  final Map<String, List<TeacherGuidanceHistoryEntry>> _byOwner = {};

  void record({
    required String ownerUserId,
    required String question,
    required String? matchedItemId,
  }) {
    final list = _byOwner.putIfAbsent(ownerUserId, () => []);
    list.add(TeacherGuidanceHistoryEntry(
      question: question,
      matchedItemId: matchedItemId,
      askedAt: DateTime.now(),
    ));
    if (list.length > 50) list.removeAt(0);
  }

  List<TeacherGuidanceHistoryEntry> recent(String ownerUserId,
      {int limit = 10}) {
    final list = _byOwner[ownerUserId] ?? const [];
    if (list.length <= limit) return List.unmodifiable(list.reversed);
    return List.unmodifiable(list.sublist(list.length - limit).reversed);
  }

  void clear(String ownerUserId) => _byOwner.remove(ownerUserId);
}
