/// Deterministic rule-based intent engine for the offline Teacher Co-Pilot.
///
/// Pipeline:
/// ```text
/// question -> normalize (Roman-Hindi variants) -> score knowledge items
///          -> follow-up check ("haan kholo" reuses last route)
///          -> current lesson context boost -> guidance delegation
///          -> best predefined item | clarification | fixed unknown
/// ```
///
/// Reads ONLY bundled JSON assets. Never touches http, FastAPI, Supabase,
/// Sarvam, any LLM or any network client — safe with airplane mode ON.
///
/// Scoring (per spec):
/// exact pattern/phrase = +5, keyword = +2, Roman-Hindi keyword = +2,
/// current topic = +3, subject = +2, previous-intent continuity = +2.
/// Winner must reach [defaultThreshold] (4.0). Near-ties (gap <= 1.0)
/// return clarification instead of guessing.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import 'copilot_models.dart';
import 'copilot_normalizer.dart';

typedef GuidanceLookup = Future<CopilotGuidanceAnswer?> Function(
    String expandedQuery, CopilotLessonContext lesson);

/// Pre-authored guidance answer supplied by the caller (normally the
/// existing `PrototypeTeacherGuidanceRepository`).
class CopilotGuidanceAnswer {
  final String answerHindi;
  final String answerEnglish;
  final String topic;
  const CopilotGuidanceAnswer({
    required this.answerHindi,
    required this.answerEnglish,
    required this.topic,
  });
}

class CopilotEngine {
  static const String knowledgeAssetPath =
      'assets/prototype_content/copilot/teacher_copilot_knowledge.json';
  static const String quickQuestionsAssetPath =
      'assets/prototype_content/copilot/quick_questions.json';
  static const String navigationIntentsAssetPath =
      'assets/prototype_content/copilot/navigation_intents.json';

  static const double wExact = 5.0;
  static const double wKeyword = 2.0;
  static const double wRomanKeyword = 2.0;
  static const double wTopic = 3.0;
  static const double wSubject = 2.0;
  static const double wContinuity = 2.0;
  static const double wClass = 1.0;

  static const String unknownAnswerHindi =
      'मुझे इस प्रश्न के लिए अभी ऑफलाइन मार्गदर्शन उपलब्ध नहीं है।';
  static const String unknownAnswerEnglish =
      "I don't have offline guidance for that question yet.";

  final AssetBundle bundle;
  final double defaultThreshold;
  final GuidanceLookup? guidanceLookup;

  List<CopilotKnowledgeItem>? _cachedItems;
  List<CopilotQuickQuestion>? _cachedQuickQuestions;

  CopilotEngine({
    AssetBundle? bundle,
    this.defaultThreshold = 4.0,
    this.guidanceLookup,
  }) : bundle = bundle ?? rootBundle;

  /// Test/diagnostic constructor with inline items (no asset read).
  CopilotEngine.withItems(
    List<CopilotKnowledgeItem> items, {
    this.defaultThreshold = 4.0,
    this.guidanceLookup,
    List<CopilotQuickQuestion>? quickQuestions,
  })  : bundle = rootBundle,
        _cachedItems = List.unmodifiable(items),
        _cachedQuickQuestions = quickQuestions == null
            ? null
            : List.unmodifiable(quickQuestions);

  bool get isLoaded => _cachedItems != null;

  Future<List<CopilotKnowledgeItem>> loadItems() async {
    if (_cachedItems != null) return _cachedItems!;
    try {
      final raw = await bundle.loadString(knowledgeAssetPath);
      final decoded = jsonDecode(raw);
      final list = (decoded is Map<String, dynamic>)
          ? (decoded['items'] as List? ?? const [])
          : const [];
      final items = <CopilotKnowledgeItem>[];
      for (final e in list) {
        if (e is! Map) continue;
        try {
          final item = CopilotKnowledgeItem.fromJson(
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

  Future<List<CopilotQuickQuestion>> loadQuickQuestions() async {
    if (_cachedQuickQuestions != null) return _cachedQuickQuestions!;
    try {
      final raw = await bundle.loadString(quickQuestionsAssetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final out = <CopilotQuickQuestion>[];
      for (final e in (decoded['defaultQuestions'] as List? ?? const [])) {
        if (e is Map) {
          out.add(CopilotQuickQuestion.fromJson(
              Map<String, dynamic>.from(e)));
        }
      }
      for (final e in (decoded['contextAwareQuestions'] as List? ?? const [])) {
        if (e is Map) {
          out.add(CopilotQuickQuestion.fromJson(
              Map<String, dynamic>.from(e),
              contextAware: true));
        }
      }
      _cachedQuickQuestions = List.unmodifiable(out);
    } catch (_) {
      _cachedQuickQuestions = const [];
    }
    return _cachedQuickQuestions!;
  }

  static bool _phraseHits(
      String keyword, String normalized, Set<String> tokens) {
    final k = CopilotNormalizer.normalize(keyword);
    if (k.isEmpty) return false;
    if (k.contains(' ')) return normalized.contains(k);
    if (tokens.contains(k)) return true;
    // Fuzzy containment for length >= 4 (plurals / Hindi inflections).
    for (final t in tokens) {
      if (t.length >= 4 && k.length >= 4 && (t.contains(k) || k.contains(t))) {
        return true;
      }
    }
    return false;
  }

  static String _normSimple(String? s) => (s ?? '').trim().toLowerCase();

  static bool _fuzzyEquals(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b || a.contains(b) || b.contains(a)) return true;
    final x = a.length >= 4 ? a.substring(0, 4) : a;
    final y = b.length >= 4 ? b.substring(0, 4) : b;
    return x == y;
  }

  /// Answers one teacher question fully offline.
  Future<CopilotResult> answer(
    String rawQuestion, {
    CopilotLessonContext lesson = const CopilotLessonContext(),
    CopilotConversationContext conversation =
        CopilotConversationContext.empty,
    CopilotAnswerLanguage language = CopilotAnswerLanguage.hindi,
    double? threshold,
  }) async {
    final limit = threshold ?? defaultThreshold;
    final normalized = CopilotNormalizer.normalize(rawQuestion);
    if (normalized.isEmpty) {
      return CopilotResult.unknown(
        answer: _unknownFor(language),
        threshold: limit,
        previous: conversation,
      );
    }
    final items = await loadItems();
    if (items.isEmpty) {
      return CopilotResult.unknown(
        answer: _unknownFor(language),
        threshold: limit,
        previous: conversation,
      );
    }

    // --- Follow-up: "haan kholo" reuses the last suggested route. ---
    if (CopilotNormalizer.isOpenFollowUp(normalized) &&
        (conversation.lastRoute ?? '').isNotEmpty) {
      final route = conversation.lastRoute!;
      return CopilotResult.followUpOpen(
        route: route,
        answer: language == CopilotAnswerLanguage.hindi
            ? 'ठीक है, मैं ${routeLabel(route, items, language)} खोल रही हूँ।'
            : 'Opening ${routeLabel(route, items, language)}.',
        actionLabel: _actionForRoute(route, items, language),
        threshold: limit,
        nextContext: conversation,
      );
    }

    final tokens = CopilotNormalizer.tokenize(normalized).toSet();
    final hasDemonstrative =
        tokens.intersection(copilotDemonstratives).isNotEmpty;
    final wantsOpen =
        tokens.intersection(copilotOpenSignals).isNotEmpty;

    final scored = <_Scored>[];
    for (final item in items) {
      double base = 0;
      double bonus = 0;

      for (final kw in item.keywords) {
        final k = CopilotNormalizer.normalize(kw);
        if (k.isEmpty) continue;
        if (k.contains(' ')) {
          if (normalized == k) {
            base += wExact;
            break;
          } else if (normalized.contains(k)) {
            base += wKeyword;
          }
        } else if (_phraseHits(kw, normalized, tokens)) {
          base += wKeyword;
        }
      }
      for (final kw in item.romanHindiKeywords) {
        final k = CopilotNormalizer.normalize(kw);
        if (k.isEmpty) continue;
        if (k.contains(' ')) {
          if (normalized == k) {
            base += wExact;
            break;
          } else if (normalized.contains(k)) {
            base += wRomanKeyword;
          }
        } else if (_phraseHits(kw, normalized, tokens)) {
          base += wRomanKeyword;
        }
      }
      if (base < 1) continue;

      // Current lesson context boosts (never selects alone: base >= 1).
      final ctxSubject = _normSimple(lesson.subject);
      final ctxTopic = _normSimple(lesson.topic);
      final ctxClass = _normSimple(lesson.className);
      if (ctxTopic.isNotEmpty) {
        final topicHaystack =
            '${item.id} ${item.intent} ${item.keywords.join(' ')} ${item.romanHindiKeywords.join(' ')}'
                .toLowerCase();
        final topicTokens = CopilotNormalizer.tokenize(
            CopilotNormalizer.normalize(lesson.topic ?? ''));
        if (topicTokens.any((t) => t.length >= 4 && topicHaystack.contains(t))) {
          bonus += wTopic;
        }
      }
      if (ctxSubject.isNotEmpty) {
        final subjHaystack =
            '${item.keywords.join(' ')} ${item.romanHindiKeywords.join(' ')}'
                .toLowerCase();
        if (subjHaystack.contains(ctxSubject.substring(
                0, ctxSubject.length >= 4 ? 4 : ctxSubject.length)) &&
            item.isGuidanceTrigger) {
          bonus += wSubject;
        }
      }
      if (ctxClass.isNotEmpty && item.isGuidanceTrigger) bonus += wClass;
      if (hasDemonstrative && item.isGuidanceTrigger) bonus += wTopic;
      if ((conversation.lastIntent ?? '').isNotEmpty &&
          conversation.lastIntent == item.intent) {
        bonus += wContinuity;
      }

      scored.add(_Scored(item, base + bonus));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    if (scored.isEmpty || scored.first.score < limit) {
      // Demonstrative with a lesson topic but no keyword hit: still resolve
      // "ye/this" to the current topic's teaching guidance when available.
      if (hasDemonstrative &&
          (lesson.topic ?? '').trim().isNotEmpty &&
          guidanceLookup != null) {
        final guidance = await guidanceLookup!(
            CopilotNormalizer.expandForGuidance(normalized,
                topic: lesson.topic),
            lesson);
        if (guidance != null) {
          final trigger = items.firstWhere(
            (e) => e.isGuidanceTrigger,
            orElse: () => items.first,
          );
          return _guidanceResult(
            trigger: trigger,
            guidance: guidance,
            language: language,
            limit: limit,
            lesson: lesson,
            conversation: conversation,
            autoNavigate: false,
            score: limit,
          );
        }
      }
      return CopilotResult.unknown(
        answer: _unknownFor(language),
        threshold: limit,
        previous: conversation,
      );
    }

    final top = scored.first;
    final near = scored
        .where((s) =>
            s.item.intent != top.item.intent &&
            s.score >= limit &&
            (top.score - s.score) <= 1.0)
        .take(2)
        .toList();
    if (near.isNotEmpty) {
      final options = [top.item, ...near.map((s) => s.item)];
      final names = options
          .map((e) => language == CopilotAnswerLanguage.hindi
              ? e.actionLabelHindi
              : e.actionLabelEnglish)
          .join(' / ');
      return CopilotResult.clarification(
        options: options,
        answer: language == CopilotAnswerLanguage.hindi
            ? 'क्या आप $names में से चुनना चाहते हैं?'
            : 'Did you mean $names?',
        score: top.score,
        threshold: limit,
        nextContext: conversation,
      );
    }

    final next = CopilotConversationContext(
      lastIntent: top.item.intent,
      lastTopic: (lesson.topic ?? '').trim().isNotEmpty
          ? lesson.topic!.trim()
          : conversation.lastTopic,
      lastRoute: top.item.route,
      lastItemId: top.item.id,
    );

    // Explicit "open karo / kholo" with a fresh match: brief confirmation
    // + direct navigation.
    if (wantsOpen && !top.item.isGuidanceTrigger) {
      return CopilotResult.matched(
        item: top.item,
        answer: language == CopilotAnswerLanguage.hindi
            ? 'ठीक है, मैं ${top.item.actionLabelHindi}।'
            : 'Opening ${top.item.actionLabelEnglish}.',
        language: language,
        score: top.score,
        threshold: limit,
        nextContext: next,
        autoNavigate: true,
      );
    }

    // Teaching guidance: reuse the existing offline guidance repository.
    if (top.item.isGuidanceTrigger) {
      if (guidanceLookup != null) {
        final guidance = await guidanceLookup!(
            CopilotNormalizer.expandForGuidance(normalized,
                topic: lesson.topic),
            lesson);
        if (guidance != null) {
          return _guidanceResult(
            trigger: top.item,
            guidance: guidance,
            language: language,
            limit: limit,
            lesson: lesson,
            conversation: conversation,
            autoNavigate: false,
            score: top.score,
          );
        }
      }
      // No guidance entry matched: fall back to opening the guidance page
      // with the current lesson context (never invent an answer).
      return CopilotResult.matched(
        item: top.item,
        answer: language == CopilotAnswerLanguage.hindi
            ? 'इस विषय पर मार्गदर्शन के लिए Teaching Guidance खोलें।'
            : 'Open Teaching Guidance for this topic.',
        language: language,
        score: top.score,
        threshold: limit,
        nextContext: next,
      );
    }

    return CopilotResult.matched(
      item: top.item,
      answer: top.item.answerFor(language),
      language: language,
      score: top.score,
      threshold: limit,
      nextContext: next,
    );
  }

  CopilotResult _guidanceResult({
    required CopilotKnowledgeItem trigger,
    required CopilotGuidanceAnswer guidance,
    required CopilotAnswerLanguage language,
    required double limit,
    required CopilotLessonContext lesson,
    required CopilotConversationContext conversation,
    required bool autoNavigate,
    required double score,
  }) {
    final answer = language == CopilotAnswerLanguage.hindi
        ? guidance.answerHindi
        : guidance.answerEnglish;
    final next = CopilotConversationContext(
      lastIntent: trigger.intent,
      lastTopic: guidance.topic.isNotEmpty
          ? guidance.topic
          : ((lesson.topic ?? '').trim().isNotEmpty
              ? lesson.topic!.trim()
              : conversation.lastTopic),
      lastRoute: trigger.route,
      lastItemId: trigger.id,
    );
    return CopilotResult.matched(
      item: trigger,
      answer: answer,
      language: language,
      score: score,
      threshold: limit,
      nextContext: next,
      autoNavigate: autoNavigate,
    );
  }

  String _unknownFor(CopilotAnswerLanguage language) =>
      language == CopilotAnswerLanguage.hindi
          ? unknownAnswerHindi
          : unknownAnswerEnglish;

  String routeLabel(
      String route, List<CopilotKnowledgeItem> items, CopilotAnswerLanguage l) {
    for (final e in items) {
      if (e.route == route) return e.actionFor(l);
    }
    return route;
  }

  String _actionForRoute(
      String route, List<CopilotKnowledgeItem> items, CopilotAnswerLanguage l) {
    for (final e in items) {
      if (e.route == route) return e.actionFor(l);
    }
    return l == CopilotAnswerLanguage.hindi ? 'खोलें' : 'Open';
  }
}

class _Scored {
  final CopilotKnowledgeItem item;
  final double score;
  const _Scored(this.item, this.score);
}
