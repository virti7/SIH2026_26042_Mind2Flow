/// Shared deterministic OFFLINE question engine used by BOTH the
/// Teacher Co-Pilot and the Teacher Guidance page.
///
/// Pipeline:
/// ```text
/// Teacher Question
///        ↓
/// Question Normalizer (trim/lower/collapse/punct/variants, Devanagari-safe)
///        ↓
/// Literal Token / Phrase Matcher (no embeddings, no LLM, no network)
///        ↓
/// Keyword Group Scorer (feature > topic > intent > context > follow-up)
///        ↓
/// Context Resolver (lesson + conversation, never overrides explicit words)
///        ↓
/// Intent Resolver
///        ↓
/// Knowledge Base (predefined Hindi/English answers + optional route)
///        ↓
/// Teacher Co-Pilot / Teacher Guidance UI
/// ```
///
/// Fully offline: reads ONLY the two bundled JSON assets
/// (`assets/prototype_content/copilot/teacher_copilot_knowledge.json` and
/// `assets/prototype_content/teacher_guidance/teacher_guidance.json`),
/// caches them in memory, never touches http/Supabase/Sarvam/LLM/network.
///
/// Scoring (transparent, configurable threshold):
/// * exact multi-word feature phrase: +15
/// * explicit single-word feature keyword: +10
/// * feature + action combination: +5
/// * feature + navigation combination: +5
/// * topic keyword: +4
/// * intent keyword: +3
/// * current subject match: +2
/// * current topic match: +3
/// * previous intent continuity: +2
/// * generic/stop words: 0 (never decide an answer)
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../copilot/copilot_normalizer.dart';

/// Answer language preference (teacher-selected, persisted per account).
enum AnswerLanguage { hindi, english }

AnswerLanguage answerLanguageFromString(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'hindi':
    case 'hi':
    case 'हिंदी':
      return AnswerLanguage.hindi;
    default:
      return AnswerLanguage.english;
  }
}

String answerLanguageToString(AnswerLanguage lang) =>
    lang == AnswerLanguage.hindi ? 'hindi' : 'english';

/// Current lesson context (Class • Subject • Topic). All optional.
class LessonContext {
  final String? className;
  final String? subject;
  final String? topic;

  const LessonContext({this.className, this.subject, this.topic});

  bool get isEmpty =>
      (className ?? '').trim().isEmpty &&
      (subject ?? '').trim().isEmpty &&
      (topic ?? '').trim().isEmpty;
}

/// Lightweight per-account conversation context.
class ConversationContext {
  final String? lastIntent;
  final String? lastTopic;
  final String? lastRoute;
  final String? lastItemId;

  const ConversationContext({
    this.lastIntent,
    this.lastTopic,
    this.lastRoute,
    this.lastItemId,
  });

  bool get isEmpty =>
      lastIntent == null && lastTopic == null && lastRoute == null;

  static const empty = ConversationContext();
}

/// Deterministic result of one engine lookup.
class QuestionResult {
  final bool matched;
  final String? intent;
  final String? knowledgeItemId;
  final String answer;
  final AnswerLanguage answerLanguage;
  /// Predefined bilingual pair (never translated at runtime). The guidance
  /// page shows both; the Co-Pilot shows [answer] per preference.
  final String? answerHindi;
  final String? answerEnglish;
  final String? route;
  final String? routeLabel;
  final double score;
  final double threshold;
  final List<String> matchedKeywords;
  final bool needsClarification;
  final List<QuestionResultOption> clarificationOptions;
  /// 'topic' for the topic picker, 'resource' for resource disambiguation.
  final String clarificationKind;
  /// Original teaching intent carried through topic clarification (e.g.
  /// TEACHING_METHOD from "mujhe ye kaise padhana hai"), so that once the
  /// teacher picks a topic the engine can answer directly. Null when the
  /// original question carried no teaching intent.
  final String? pendingIntent;
  final bool isFollowUpOpen;
  final bool autoNavigate;
  final ConversationContext nextContext;

  const QuestionResult._({
    required this.matched,
    required this.intent,
    required this.knowledgeItemId,
    required this.answer,
    required this.answerLanguage,
    this.answerHindi,
    this.answerEnglish,
    required this.route,
    required this.routeLabel,
    required this.score,
    required this.threshold,
    required this.matchedKeywords,
    required this.needsClarification,
    required this.clarificationOptions,
    this.clarificationKind = 'resource',
    this.pendingIntent,
    required this.isFollowUpOpen,
    required this.autoNavigate,
    required this.nextContext,
  });

  factory QuestionResult.matched({
    required String intent,
    required String knowledgeItemId,
    required String answer,
    required AnswerLanguage answerLanguage,
    String? answerHindi,
    String? answerEnglish,
    String? route,
    String? routeLabel,
    required double score,
    required double threshold,
    List<String> matchedKeywords = const [],
    ConversationContext nextContext = ConversationContext.empty,
    bool autoNavigate = false,
  }) =>
      QuestionResult._(
        matched: true,
        intent: intent,
        knowledgeItemId: knowledgeItemId,
        answer: answer,
        answerLanguage: answerLanguage,
        answerHindi: answerHindi,
        answerEnglish: answerEnglish,
        route: route,
        routeLabel: routeLabel,
        score: score,
        threshold: threshold,
        matchedKeywords: List.unmodifiable(matchedKeywords),
        needsClarification: false,
        clarificationOptions: const [],
        isFollowUpOpen: false,
        autoNavigate: autoNavigate,
        nextContext: nextContext,
      );

  factory QuestionResult.followUpOpen({
    required String route,
    required String answer,
    required AnswerLanguage answerLanguage,
    String? routeLabel,
    required double threshold,
    ConversationContext nextContext = ConversationContext.empty,
  }) =>
      QuestionResult._(
        matched: true,
        intent: 'FOLLOW_UP_OPEN',
        knowledgeItemId: null,
        answer: answer,
        answerLanguage: answerLanguage,
        route: route,
        routeLabel: routeLabel,
        score: threshold,
        threshold: threshold,
        matchedKeywords: const [],
        needsClarification: false,
        clarificationOptions: const [],
        isFollowUpOpen: true,
        autoNavigate: true,
        nextContext: nextContext,
      );

  factory QuestionResult.clarification({
    required String answer,
    required AnswerLanguage answerLanguage,
    required List<QuestionResultOption> options,
    required double score,
    required double threshold,
    ConversationContext nextContext = ConversationContext.empty,
    String clarificationKind = 'resource',
    String? pendingIntent,
  }) =>
      QuestionResult._(
        matched: false,
        intent: 'CLARIFICATION',
        knowledgeItemId: null,
        answer: answer,
        answerLanguage: answerLanguage,
        route: null,
        routeLabel: null,
        score: score,
        threshold: threshold,
        matchedKeywords: const [],
        needsClarification: true,
        clarificationOptions: List.unmodifiable(options),
        clarificationKind: clarificationKind,
        pendingIntent: pendingIntent,
        isFollowUpOpen: false,
        autoNavigate: false,
        nextContext: nextContext,
      );

  factory QuestionResult.unknown({
    required String answer,
    required AnswerLanguage answerLanguage,
    required double threshold,
    ConversationContext previous = ConversationContext.empty,
  }) =>
      QuestionResult._(
        matched: false,
        intent: 'UNKNOWN',
        knowledgeItemId: null,
        answer: answer,
        answerLanguage: answerLanguage,
        route: null,
        routeLabel: null,
        score: 0,
        threshold: threshold,
        matchedKeywords: const [],
        needsClarification: false,
        clarificationOptions: const [],
        isFollowUpOpen: false,
        autoNavigate: false,
        // Unknown must NOT clobber follow-up context.
        nextContext: previous,
      );

  bool get isUnknown => !matched && !needsClarification;
}

/// One clarification candidate shown as a choice chip/button.
class QuestionResultOption {
  final String knowledgeItemId;
  final String intent;
  final String label;
  final String? route;
  const QuestionResultOption({
    required this.knowledgeItemId,
    required this.intent,
    required this.label,
    required this.route,
  });
}

/// One unified knowledge item (navigation feature OR teaching guidance).
class _Item {
  final String id;
  final String intent;
  final List<String> keywords;
  final List<String> patterns;
  final String answerHindi;
  final String answerEnglish;
  final String? route;
  final String routeLabelHindi;
  final String routeLabelEnglish;
  final String? className;
  final String? subject;
  final String? topic;
  final bool isFeature;

  const _Item({
    required this.id,
    required this.intent,
    required this.keywords,
    required this.patterns,
    required this.answerHindi,
    required this.answerEnglish,
    required this.route,
    required this.routeLabelHindi,
    required this.routeLabelEnglish,
    this.className,
    this.subject,
    this.topic,
    required this.isFeature,
  });
}

class _Scored {
  final _Item item;
  final double score;
  final List<String> hits;
  const _Scored(this.item, this.score, this.hits);
}

/// The ONE shared deterministic offline question engine.
///
/// Used by both Teacher Co-Pilot and Teacher Guidance. Screens only send
/// `question + lesson context + answer language (+ conversation context)`.
class TeacherQuestionEngine {
  static const String copilotAssetPath =
      'assets/prototype_content/copilot/teacher_copilot_knowledge.json';
  static const String guidanceAssetPath =
      'assets/prototype_content/teacher_guidance/teacher_guidance.json';

  /// Fixed pre-authored unavailable messages (never generated).
  static const String unknownAnswerHindi =
      'इस प्रश्न के लिए अभी ऑफलाइन मार्गदर्शन उपलब्ध नहीं है।';
  static const String unknownAnswerEnglish =
      'Offline guidance for this question is not available yet.';

  /// Fixed pre-authored topic-clarification prompts (never translated at
  /// runtime). Asked whenever a teaching question carries no explicit topic
  /// and no explicitly established conversation topic.
  static const String topicClarifyHindi =
      'Aap konsa topic padhana chahte hain?';
  static const String topicClarifyEnglish =
      'Which topic would you like to teach?';

  /// Fixed pre-authored prompt for topic-planning questions
  /// ("mujhe konsa topic padhana hai").
  static const String topicListHindi =
      'Kaunsa topic padhana hai, uske liye neeche available topics dekhein.';
  static const String topicListEnglish =
      'Choose the topic you would like to teach from the available topics below.';

  /// Fixed pre-authored follow-up after a topic is picked without a pending
  /// intent ("What would you like help with?").
  static const String helpChoiceHindi = 'Aapko kis me madad chahiye?';
  static const String helpChoiceEnglish = 'What would you like help with?';

  /// Teaching intents: questions carrying one of these need an explicit
  /// topic (current question or established conversation) before any
  /// topic-specific guidance may be returned.
  static const Set<String> teachingIntents = {
    'TEACHING_METHOD',
    'ACTIVITY',
    'EXAMPLE',
    'EXPLANATION',
    'SIMPLIFY',
    'ASSESSMENT',
    'ASSESSMENT_GUIDANCE',
    'CLASSROOM_ACTIVITY',
    'COMMON_DIFFICULTY',
    'TEACHER_GUIDANCE',
    'CURRENT_TOPIC_GUIDANCE',
    'GENERAL_GUIDANCE',
  };

  /// Anaphoric references that may resolve to the explicitly established
  /// conversation topic ONLY ("iske liye" -> last discussed topic).
  /// Page context alone must never resolve these.
  static const Set<String> anaphoricTokens = {
    'ye',
    'yah',
    'yeh',
    'is',
    'ise',
    'isey',
    'iska',
    'iske',
    'iski',
    'isko',
    'isme',
    'isi',
    'uske',
    'uski',
    'usko',
    'usme',
    'usi',
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
  };

  /// Teaching verbs that mark a question as a teaching question even when
  /// no topic is named. Deliberately excludes bare 'kaise'/'how' so that
  /// unrelated "how to" questions (e.g. train tickets) stay unknown.
  static const Set<String> teachingVerbs = {
    'teach',
    'padhau',
    'sikhau',
    'samjhau',
    'samjhana',
    'sikhana',
    'explain',
    'simplify',
    'simple',
    'activity',
    'game',
    'khel',
    'example',
    'udaharan',
    'assess',
    'assessment',
    'test',
    'quiz',
    'check',
    'evaluat',
    'batao',
    'पढ़ा',
    'सिखा',
    'समझा',
    'बताओ',
    'बताइए',
    'आसान',
    'सरल',
    'गतिविधि',
    'खेल',
    'उदाहरण',
    'जाँच',
    'मूल्यांकन',
    'परख',
    'आकलन',
    'परीक्षा',
  };

  /// Intent priority when several teaching intents are detected: specific
  /// verbs (activity/example/simplify/assess) outrank the generic
  /// TEACHING_METHOD signal ('kaise'/'how to').
  static const List<String> _intentPriority = [
    'ACTIVITY',
    'EXAMPLE',
    'SIMPLIFY',
    'EXPLANATION',
    'ASSESSMENT',
    'ASSESSMENT_GUIDANCE',
    'CLASSROOM_ACTIVITY',
    'COMMON_DIFFICULTY',
    'TEACHING_METHOD',
    'TEACHER_GUIDANCE',
    'CURRENT_TOPIC_GUIDANCE',
    'GENERAL_GUIDANCE',
  ];

  /// Predefined "What would you like help with?" options shown after a
  /// topic is picked without a pending intent. Labels are fixed product
  /// strings (never generated, never translated at runtime).
  static List<QuestionResultOption> helpIntentOptions() => const [
        QuestionResultOption(
          knowledgeItemId: 'intent::TEACHING_METHOD',
          intent: 'INTENT_PICK',
          label: 'How should I teach it?',
          route: null,
        ),
        QuestionResultOption(
          knowledgeItemId: 'intent::ACTIVITY',
          intent: 'INTENT_PICK',
          label: 'Give me an activity',
          route: null,
        ),
        QuestionResultOption(
          knowledgeItemId: 'intent::EXAMPLE',
          intent: 'INTENT_PICK',
          label: 'Give me an example',
          route: null,
        ),
        QuestionResultOption(
          knowledgeItemId: 'intent::SIMPLIFY',
          intent: 'INTENT_PICK',
          label: 'How can I simplify it?',
          route: null,
        ),
        QuestionResultOption(
          knowledgeItemId: 'intent::ASSESSMENT',
          intent: 'INTENT_PICK',
          label: 'How should I assess it?',
          route: null,
        ),
      ];

  // --- Transparent scoring weights (spec §10). ---
  static const double wFeaturePhrase = 15.0;
  static const double wFeatureKeyword = 10.0;
  static const double wFeatureActionCombo = 5.0;
  static const double wFeatureNavCombo = 5.0;
  static const double wPatternExact = 15.0;
  static const double wPatternContains = 5.0;
  static const double wTopic = 4.0;
  static const double wIntent = 3.0;
  static const double wSubjectCtx = 2.0;
  static const double wTopicCtx = 3.0;
  static const double wContinuity = 2.0;

  final AssetBundle bundle;
  final double defaultThreshold;
  final double clarificationMargin;

  List<_Item>? _cached;

  TeacherQuestionEngine({
    AssetBundle? bundle,
    this.defaultThreshold = 8.0,
    this.clarificationMargin = 2.0,
  }) : bundle = bundle ?? rootBundle;

  /// Test/diagnostic constructor with inline items (no asset read).
  TeacherQuestionEngine.withItems(
    List<Map<String, dynamic>> rawItems, {
    this.defaultThreshold = 8.0,
    this.clarificationMargin = 2.0,
  })  : bundle = rootBundle,
        _cached = List.unmodifiable(
            rawItems.map(_itemFromJson).whereType<_Item>().toList());

  bool get isLoaded => _cached != null;

  // ----------------------------------------------------------------
  // Loading (bundled assets only, parsed once, kept in memory)
  // ----------------------------------------------------------------

  Future<List<_Item>> loadItems() async {
    if (_cached != null) return _cached!;
    final items = <_Item>[];
    try {
      final raw = await bundle.loadString(copilotAssetPath);
      final decoded = jsonDecode(raw);
      final list = (decoded is Map<String, dynamic>)
          ? (decoded['items'] as List? ?? const [])
          : const [];
      for (final e in list) {
        if (e is! Map) continue;
        final it = _copilotItem(Map<String, dynamic>.from(e));
        if (it != null) items.add(it);
      }
    } catch (_) {}
    try {
      final raw = await bundle.loadString(guidanceAssetPath);
      final decoded = jsonDecode(raw);
      final list = (decoded is Map<String, dynamic>)
          ? (decoded['items'] as List? ?? const [])
          : const [];
      for (final e in list) {
        if (e is! Map) continue;
        final it = _guidanceItem(Map<String, dynamic>.from(e));
        if (it != null) items.add(it);
      }
    } catch (_) {}
    // Built-in planning fallback (predefined, grade-agnostic — never invents
    // a curriculum sequence; see spec §18).
    items.add(const _Item(
      id: 'subject_sequence',
      intent: 'SUBJECT_PLANNING',
      keywords: [
        'maths ke baad',
        'math ke baad',
        'next subject',
        'konsa subject',
        'kaunsa subject',
        'which subject',
        'agla subject',
        'next kya padhau',
        'ke baad konsa',
        'ke baad kya padhau',
        'subject planning',
        'time table',
        'timetable',
        'समय सारणी',
      ],
      patterns: [
        'mujhe maths ke baad konsa subject padhana chahiye',
        'maths ke baad konsa subject padhana chahiye',
        'math ke baad kya padhau',
        'next subject kya padhau',
      ],
      answerHindi:
          'अपनी कक्षा की समय-सारणी के अनुसार अगला विषय चुनें। यदि समय-सारणी उपलब्ध नहीं है, तो प्रधानाध्यापक से पूछें — ऐप में कोई कक्षा-विशिष्ट विषय-क्रम पहले से तय नहीं है।',
      answerEnglish:
          'Choose the next subject from your class timetable. If no timetable is available, ask your head teacher — the app has no predefined class-specific subject sequence.',
      route: '/teach',
      routeLabelHindi: 'Teach खोलें',
      routeLabelEnglish: 'Open Teach',
      isFeature: true,
    ));
    _cached = List.unmodifiable(items);
    return _cached!;
  }

  static List<String> _strs(Object? v) => ((v as List?) ?? const [])
      .map((e) => e.toString())
      .where((e) => e.trim().isNotEmpty)
      .toList();

  static _Item? _copilotItem(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString().trim();
    final intent = (json['intent'] ?? '').toString().trim().toUpperCase();
    final route = (json['route'] ?? '').toString().trim();
    if (id.isEmpty || intent.isEmpty) return null;
    final kws = [..._strs(json['keywords']), ..._strs(json['romanHindiKeywords'])];
    if (kws.isEmpty) return null;
    return _Item(
      id: id,
      intent: intent,
      keywords: kws,
      patterns: _strs(json['romanHindiKeywords']),
      answerHindi: (json['answerHindi'] ?? '').toString(),
      answerEnglish: (json['answerEnglish'] ?? '').toString(),
      route: route.isEmpty ? null : route,
      routeLabelHindi: (json['actionLabelHindi'] ?? '').toString().trim().isEmpty
          ? 'खोलें'
          : (json['actionLabelHindi'] ?? '').toString(),
      routeLabelEnglish:
          (json['actionLabelEnglish'] ?? '').toString().trim().isEmpty
              ? 'Open'
              : (json['actionLabelEnglish'] ?? '').toString(),
      isFeature: intent != 'TEACHER_GUIDANCE',
    );
  }

  static _Item? _guidanceItem(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString().trim();
    final intent = (json['intent'] ?? '').toString().trim().toUpperCase();
    if (id.isEmpty || intent.isEmpty || intent == 'UNKNOWN') return null;
    final kws = _strs(json['keywords']);
    if (kws.isEmpty) return null;
    if ((json['answerHindi'] ?? '').toString().trim().isEmpty) return null;
    if ((json['answerEnglish'] ?? '').toString().trim().isEmpty) return null;
    return _Item(
      id: id,
      intent: intent,
      keywords: kws,
      patterns: _strs(json['questionPatterns']),
      answerHindi: (json['answerHindi'] ?? '').toString(),
      answerEnglish: (json['answerEnglish'] ?? '').toString(),
      route: '/teach/guidance',
      routeLabelHindi: 'Teaching Guidance खोलें',
      routeLabelEnglish: 'Open Teaching Guidance',
      className: (json['className'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      isFeature: false,
    );
  }

  static _Item? _itemFromJson(Map<String, dynamic> json) {
    if (json.containsKey('className') || json.containsKey('questionPatterns')) {
      return _guidanceItem(json);
    }
    return _copilotItem(json);
  }

  // ----------------------------------------------------------------
  // Keyword groups (spec §5-§7)
  // ----------------------------------------------------------------

  /// Generic words: score 0, never decide an answer (spec §4).
  static const Set<String> genericWords = {
    'main', 'mujhe', 'muje', 'hai', 'hain', 'ho', 'ka', 'ki', 'ko', 'ke',
    'kidhar', // handled as NAV signal, not a feature
    'mein', 'me', 'the', 'is', 'are', 'how', 'what', 'a', 'an', 'to',
    'kya', 'kaun', 'konsa', 'kaunsa', 'chahiye', 'h', 'bhi', 'aur',
    'or', 'and', 'with', 'se', 'sa', 'ye', 'yah', 'yeh', 'it', 'this',
    'that', 'karni', 'karna', 'karu', 'karo', 'haii',
  };

  static const Set<String> actionSignals = {
    'generate', 'create', 'make', 'banana', 'banani', 'banaye', 'banao',
    'bana', 'banau', 'banega', 'banegi', 'banwana', 'chahiye',
    'karna', 'karu', 'kholo', // kholo is both action+nav; counted once
  };

  static const Set<String> navSignals = {
    'kaha', 'kidhar', 'where', 'open', 'kholo', 'khol', 'kholna', 'jau',
    'jana', 'jaye', 'milega', 'milegi', 'dikhao', 'chalao',
  };

  /// intent -> roman/english/hindi signals (spec §7).
  static const Map<String, List<String>> intentSignals = {
    'TEACHING_METHOD': ['teach', 'padhau', 'padhana', 'sikhau', 'sikhana', 'how to', 'kaise', 'कैसे', 'सिखा', 'पढ़ा'],
    'ACTIVITY': ['activity', 'game', 'play', 'khel', 'गतिविधि', 'खेल', 'batao'],
    'EXAMPLE': ['example', 'udaharan', 'उदाहरण', 'मिसाल'],
    'EXPLANATION': ['explain', 'samjhau', 'samjhana', 'batao', 'समझा', 'बताओ', 'बताइए'],
    'SIMPLIFY': ['simplify', 'simple', 'easier', 'easy', 'samjhau', 'aasan', 'asaan', 'saral', 'samas', 'आसान', 'सरल'],
    'ASSESSMENT': ['assess', 'test', 'check', 'evaluat', 'quiz', 'exam', 'pariksha', 'जाँच', 'मूल्यांकन', 'परख', 'आकलन', 'परीक्षा', 'karu'],
    'ASSESSMENT_GUIDANCE': ['assess', 'test', 'check', 'evaluat', 'quiz', 'exam', 'जाँच', 'मूल्यांकन', 'परख', 'आकलन', 'परीक्षा'],
    'NAVIGATE': ['kaha', 'kidhar', 'where', 'kholo', 'open', 'jau', 'कहाँ', 'कहां'],
    'RESOURCE_LOCATION': ['kaha', 'kidhar', 'where', 'milega', 'कहाँ'],
    'RESOURCE_CREATION': ['banana', 'banau', 'generate', 'create', 'make', 'बनाएं', 'बनाओ'],
    'CURRENT_TOPIC_GUIDANCE': ['ye', 'yah', 'this', 'it', 'यह', 'ये', 'इस'],
    'GENERAL_GUIDANCE': ['guidance', 'madad', 'help', 'मार्गदर्शन'],
    'SUBJECT_PLANNING': ['baad', 'next', 'konsa', 'kaunsa', 'agla', 'timetable', 'subject'],
  };

  static const Set<String> demonstratives = {
    'ye', 'yah', 'yeh', 'is', 'ise', 'isey', 'iska', 'this', 'that', 'it',
    'these', 'इस', 'यह', 'ये', 'उस', 'वह', 'इसे', 'उसे',
  };

  // ----------------------------------------------------------------
  // Matching helpers
  // ----------------------------------------------------------------

  static bool _isNumeric(String s) => RegExp(r'^[0-9]+$').hasMatch(s);

  /// Literal keyword hit (spec §2): multi-word -> phrase containment,
  /// numeric -> exact token, else token equality or >=4 containment.
  static bool _hits(String keyword, String normalized, Set<String> tokens) {
    final k = CopilotNormalizer.normalize(keyword);
    if (k.isEmpty) return false;
    if (genericWords.contains(k)) return false;
    if (k.contains(' ')) return normalized.contains(k);
    if (_isNumeric(k)) return tokens.contains(k);
    for (final t in tokens) {
      if (t == k) return true;
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

  Set<String> _detectIntentKeys(Set<String> tokens) {
    final found = <String>{};
    for (final entry in intentSignals.entries) {
      for (final signal in entry.value) {
        final s = CopilotNormalizer.normalize(signal);
        if (s.isEmpty) continue;
        final hit = s.contains(' ')
            ? tokens.join(' ').contains(s)
            : tokens.any((t) => t == s || (t.length >= 3 && s.length >= 3 && t.contains(s)));
        if (hit) {
          found.add(entry.key);
          break;
        }
      }
    }
    // ASSESSMENT and ASSESSMENT_GUIDANCE are aliases for guidance items.
    if (found.contains('ASSESSMENT')) found.add('ASSESSMENT_GUIDANCE');
    if (found.contains('ASSESSMENT_GUIDANCE')) found.add('ASSESSMENT');
    return found;
  }

  /// Preferred guidance intent when the question leans on the current topic
  /// ("ye kaise samjhau" -> SIMPLIFY, "ek activity batao" -> ACTIVITY...).
  String? _preferredGuidanceIntent(Set<String> tokens) {
    if (tokens.intersection({'activity', 'game', 'play', 'khel'}).isNotEmpty) {
      return 'ACTIVITY';
    }
    if (tokens.intersection({'assess', 'assessment', 'test', 'quiz', 'check', 'evaluat'}).isNotEmpty ||
        tokens.contains('karu')) {
      // "numbers ka assessment kaise karu" -> assessment guidance.
      if (tokens.intersection({'number', 'counting', 'ginti', '100', 'place', 'addition', 'jod', 'reading', 'writing', 'vocabulary', 'shabd'}).isNotEmpty ||
          tokens.contains('ka')) {
        return 'ASSESSMENT';
      }
      return 'ASSESSMENT';
    }
    if (tokens.contains('example') || tokens.contains('udaharan')) return 'EXAMPLE';
    if (tokens.intersection({'simple', 'simplify', 'easier', 'easy', 'aasan', 'asaan', 'saral', 'samjhau'}).isNotEmpty) {
      return 'SIMPLIFY';
    }
    if (tokens.intersection({'explain', 'samjhau', 'batao'}).isNotEmpty &&
        tokens.intersection({'number', 'counting', 'ginti', '100'}).isNotEmpty) {
      return 'TEACHING_METHOD';
    }
    return null;
  }

  // ----------------------------------------------------------------
  // Topic source + explicit-signal helpers (no second topic list: every
  // option below comes from the loaded curriculum/knowledge base).
  // ----------------------------------------------------------------

  /// Distinct teaching topics from the knowledge base, optionally filtered
  /// by class/subject (page context filters OPTIONS, never selects one).
  /// Falls back to all topics when the filter matches nothing, so the
  /// picker is never empty.
  Future<List<String>> getAvailableTopics({
    String? className,
    String? subject,
  }) async {
    final items = await loadItems();
    final cls = _normSimple(className);
    final sub = _normSimple(subject);
    final out = <String>[];
    final seen = <String>{};
    for (final item in items) {
      if (item.isFeature) continue;
      final t = (item.topic ?? '').trim();
      if (t.isEmpty || seen.contains(t)) continue;
      if (cls.isNotEmpty && _normSimple(item.className) != cls) continue;
      if (sub.isNotEmpty && _normSimple(item.subject) != sub) continue;
      seen.add(t);
      out.add(t);
    }
    if (out.isEmpty) {
      for (final item in items) {
        if (item.isFeature) continue;
        final t = (item.topic ?? '').trim();
        if (t.isEmpty || seen.contains(t)) continue;
        seen.add(t);
        out.add(t);
      }
    }
    return out;
  }

  static Set<String>? _intentVocab;

  /// Normalized intent/verb vocabulary: words in this set signal HOW the
  /// teacher wants help, never WHICH topic (used to tell explicit topic
  /// anchors apart from intent words).
  static Set<String> get _vocab {
    if (_intentVocab != null) return _intentVocab!;
    final v = <String>{};
    for (final list in intentSignals.values) {
      for (final s in list) {
        final n = CopilotNormalizer.normalize(s);
        if (n.isNotEmpty) v.add(n);
      }
    }
    for (final s in teachingVerbs) {
      final n = CopilotNormalizer.normalize(s);
      if (n.isNotEmpty) v.add(n);
    }
    _intentVocab = v;
    return v;
  }

  /// True when a guidance item is anchored to the question by a
  /// topic-denoting single-word keyword (e.g. 'numbers', 'ginti',
  /// 'संख्याएँ', '100'). Intent words ('activity', 'batao', 'samjhau')
  /// and generic words never count as anchors.
  bool _hasTopicAnchor(_Item item, Set<String> tokens) {
    if (item.isFeature) return false;
    for (final kw in item.keywords) {
      final k = CopilotNormalizer.normalize(kw);
      if (k.isEmpty ||
          k.contains(' ') ||
          genericWords.contains(k) ||
          _vocab.contains(k)) {
        continue;
      }
      if (tokens.contains(k)) return true;
    }
    return false;
  }

  /// Explicit topic named in the current question, matched against real
  /// knowledge-base topic names (longest match wins). Null when the
  /// question names no topic ("ye", "isko", "this" never count).
  String? _explicitTopicIn(String normalized, List<_Item> items) {
    String? best;
    var bestLen = 0;
    for (final item in items) {
      if (item.isFeature) continue;
      final raw = (item.topic ?? '').trim();
      if (raw.isEmpty) continue;
      final t = _normSimple(raw);
      if (t.isEmpty) continue;
      if (normalized.contains(t)) {
        if (t.length > bestLen) {
          best = raw;
          bestLen = t.length;
        }
        continue;
      }
      for (final w in t.split(' ')) {
        if (w.length >= 4 && normalized.contains(w) && w.length > bestLen) {
          best = raw;
          bestLen = w.length;
        }
      }
    }
    return best;
  }

  /// Strongest detected teaching intent in priority order, or null.
  String? _primaryTeachingIntent(Set<String> detected) {
    for (final key in _intentPriority) {
      if (detected.contains(key)) {
        if (key == 'ASSESSMENT_GUIDANCE') return 'ASSESSMENT';
        return key;
      }
    }
    return null;
  }

  /// Topic-planning phrasing ("mujhe konsa topic padhana hai"): lists
  /// available topics instead of choosing one.
  bool _isTopicPlanning(String normalized) {
    if (!normalized.contains('topic')) return false;
    return normalized.contains('konsa') || normalized.contains('kaunsa');
  }

  /// Deterministic lookup of one predefined item for an explicitly
  /// established (topic, intent) pair. Never invents content.
  _Scored? _findTopicIntent(
      List<_Item> items, String topic, String? intent) {
    final t = _normSimple(topic);
    if (t.isEmpty) return null;
    final cands = items
        .where((e) =>
            !e.isFeature && _fuzzyEquals(_normSimple(e.topic), t))
        .toList();
    if (cands.isEmpty) return null;
    if (intent != null) {
      final key = intent.toUpperCase();
      for (final c in cands) {
        final ck = c.intent.toUpperCase();
        if (ck == key ||
            (key == 'ASSESSMENT' && ck == 'ASSESSMENT_GUIDANCE')) {
          return _Scored(
              c, defaultThreshold, ['topic:$topic', 'intent:$intent']);
        }
      }
    }
    return _Scored(cands.first, defaultThreshold, ['topic:$topic']);
  }

  /// Direct predefined answer for an established (topic, intent) pair,
  /// used after the teacher picks a topic and a help option. Fully
  /// offline; unknown when the pair has no predefined item.
  Future<QuestionResult> answerForTopicIntent({
    required String topic,
    required String intent,
    LessonContext context = const LessonContext(),
    AnswerLanguage answerLanguage = AnswerLanguage.hindi,
    ConversationContext conversationContext = ConversationContext.empty,
    double? threshold,
  }) async {
    final limit = threshold ?? defaultThreshold;
    final items = await loadItems();
    final found = _findTopicIntent(items, topic, intent);
    debugPrint('[TeacherQuestionEngine] explicitTopic=$topic '
        'explicitIntent=$intent '
        'conversationTopic=${conversationContext.lastTopic} '
        'pageContextTopic=${context.topic} '
        'decision=${found == null ? 'UNKNOWN' : 'MATCHED'}');
    if (found == null) {
      return QuestionResult.unknown(
        answer: answerLanguage == AnswerLanguage.hindi
            ? unknownAnswerHindi
            : unknownAnswerEnglish,
        answerLanguage: answerLanguage,
        threshold: limit,
        previous: conversationContext,
      );
    }
    return _toMatched(found.item, found.score, limit, answerLanguage,
        context, conversationContext, found.hits);
  }

  void _logDecision({
    required String? explicitTopic,
    required String? explicitIntent,
    required String? conversationTopic,
    required String? pageContextTopic,
    required String decision,
  }) {
    debugPrint('[TeacherQuestionEngine] explicitTopic=$explicitTopic '
        'explicitIntent=$explicitIntent '
        'conversationTopic=$conversationTopic '
        'pageContextTopic=$pageContextTopic '
        'decision=$decision');
  }

  // ----------------------------------------------------------------
  // Main entry point
  // ----------------------------------------------------------------

  /// Resolves one teacher question fully offline.
  Future<QuestionResult> resolve(
    String question, {
    LessonContext context = const LessonContext(),
    AnswerLanguage answerLanguage = AnswerLanguage.hindi,
    ConversationContext conversationContext = ConversationContext.empty,
    double? threshold,
  }) async {
    final limit = threshold ?? defaultThreshold;
    final normalized = CopilotNormalizer.normalize(question);
    String unknownFor(AnswerLanguage l) =>
        l == AnswerLanguage.hindi ? unknownAnswerHindi : unknownAnswerEnglish;

    if (normalized.isEmpty) {
      return QuestionResult.unknown(
          answer: unknownFor(answerLanguage),
          answerLanguage: answerLanguage,
          threshold: limit,
          previous: conversationContext);
    }
    final items = await loadItems();
    if (items.isEmpty) {
      return QuestionResult.unknown(
          answer: unknownFor(answerLanguage),
          answerLanguage: answerLanguage,
          threshold: limit,
          previous: conversationContext);
    }

    // --- Follow-up: "haan kholo" reuses the last suggested route. ---
    if (CopilotNormalizer.isOpenFollowUp(normalized) &&
        (conversationContext.lastRoute ?? '').isNotEmpty) {
      final route = conversationContext.lastRoute!;
      final label = _labelForRoute(route, items, answerLanguage);
      debugPrint('[TeacherQuestionEngine] query=$question '
          'normalized=$normalized intent=FOLLOW_UP_OPEN route=$route');
      return QuestionResult.followUpOpen(
        route: route,
        answer: answerLanguage == AnswerLanguage.hindi
            ? 'ठीक है, मैं $label खोल रही हूँ।'
            : 'Opening $label.',
        answerLanguage: answerLanguage,
        routeLabel: label,
        threshold: limit,
        nextContext: conversationContext,
      );
    }

    final tokens = CopilotNormalizer.tokenize(normalized).toSet();
    // Content tokens exclude generic stop words for eligibility checks.
    final contentTokens =
        tokens.where((t) => !genericWords.contains(t)).toSet();
    final hasDemonstrative =
        tokens.intersection(demonstratives).isNotEmpty;
    final detectedIntents = _detectIntentKeys(tokens);
    final preferredGuidance = _preferredGuidanceIntent(tokens);

    final ctxClass = _normSimple(context.className);
    final ctxSubject = _normSimple(context.subject);
    final ctxTopic = _normSimple(context.topic);

    final scored = <_Scored>[];
    for (final item in items) {
      double score = 0;
      final hits = <String>[];

      // 1) Feature / topic keyword hits.
      var featureHit = false;
      var phraseHit = false;
      for (final kw in item.keywords) {
        final k = CopilotNormalizer.normalize(kw);
        if (k.isEmpty || genericWords.contains(k)) continue;
        if (!_hits(kw, normalized, tokens)) continue;
        featureHit = true;
        hits.add(kw);
        if (k.contains(' ')) {
          score += wFeaturePhrase;
          phraseHit = true;
        } else if (item.isFeature) {
          score += wFeatureKeyword;
        } else {
          score += wTopic;
        }
      }
      // 2) Explicit stored patterns (shortcut inside the rule engine).
      for (final raw in item.patterns) {
        final p = CopilotNormalizer.normalize(raw);
        if (p.isEmpty) continue;
        if (normalized == p) {
          score += wPatternExact;
          if (!phraseHit) hits.add(raw);
          featureHit = true;
          break;
        } else if (p.length >= 4 && normalized.contains(p)) {
          score += wPatternContains;
          featureHit = true;
          break;
        }
      }
      if (!featureHit) continue; // generic words alone never match.

      // 3) Feature + action / navigation combinations (feature items).
      if (item.isFeature) {
        final hasAction = tokens.intersection(actionSignals).isNotEmpty;
        final hasNav = tokens.intersection(navSignals).isNotEmpty;
        if (hasAction) score += wFeatureActionCombo;
        if (hasNav) score += wFeatureNavCombo;
      }

      // 4) Intent keyword match.
      final itemIntentKey = item.intent.toUpperCase();
      if (detectedIntents.contains(itemIntentKey)) {
        score += wIntent;
      } else if (itemIntentKey == 'TEACHER_GUIDANCE' &&
          detectedIntents.intersection({
            'TEACHING_METHOD',
            'ACTIVITY',
            'EXAMPLE',
            'EXPLANATION',
            'SIMPLIFY',
            'GENERAL_GUIDANCE',
            'CURRENT_TOPIC_GUIDANCE',
          }).isNotEmpty) {
        score += wIntent;
      }

      // 5) Current lesson context (boost only; never selects alone).
      if (ctxSubject.isNotEmpty) {
        final hay =
            '${item.keywords.join(' ')} ${item.subject ?? ''}'.toLowerCase();
        final sub4 = ctxSubject.length >= 4
            ? ctxSubject.substring(0, 4)
            : ctxSubject;
        if (sub4.isNotEmpty && hay.contains(sub4)) score += wSubjectCtx;
        if (_fuzzyEquals(_normSimple(item.subject), ctxSubject)) {
          score += wSubjectCtx;
        }
      }
      if (ctxTopic.isNotEmpty) {
        final itemTopic = _normSimple(item.topic);
        final hay =
            '${item.id} ${item.keywords.join(' ')} ${item.topic ?? ''}'
                .toLowerCase();
        final topicTokens = CopilotNormalizer.tokenize(
            CopilotNormalizer.normalize(context.topic ?? ''));
        final topicHit = topicTokens.any(
            (t) => t.length >= 3 && hay.contains(t));
        if (topicHit) score += wTopicCtx;
        if (itemTopic.isNotEmpty && _fuzzyEquals(itemTopic, ctxTopic)) {
          score += wTopicCtx;
        }
        // Demonstrative ("ye/this") resolves to the current topic.
        if (hasDemonstrative &&
            (itemTopic.isNotEmpty && _fuzzyEquals(itemTopic, ctxTopic) ||
                topicHit)) {
          score += wTopicCtx;
        }
        // Preferred guidance intent wins ties on the same topic.
        if (preferredGuidance != null &&
            !item.isFeature &&
            (itemIntentKey == preferredGuidance ||
                (preferredGuidance == 'ASSESSMENT' &&
                    itemIntentKey == 'ASSESSMENT_GUIDANCE'))) {
          final topicRelated = topicHit ||
              (itemTopic.isNotEmpty && _fuzzyEquals(itemTopic, ctxTopic));
          if (topicRelated) score += wIntent;
        }
      } else if (hasDemonstrative && !item.isFeature) {
        // No topic: demonstrative alone is not enough (stays unknown
        // unless another content signal already fired — which it did).
      }

      // 6) Follow-up continuity (explicit words still outrank it by weight).
      if ((conversationContext.lastIntent ?? '').isNotEmpty &&
          conversationContext.lastIntent == item.intent) {
        score += wContinuity;
      }
      // Content-token guard: at least one non-generic token must be present
      // (already ensured by featureHit, but keep explicit for clarity).
      if (contentTokens.isEmpty && !hasDemonstrative) continue;

      scored.add(_Scored(item, score, hits));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    debugPrint('[TeacherQuestionEngine] query=$question normalized=$normalized '
        'top=${scored.isEmpty ? 'none' : '${scored.first.item.intent}:${scored.first.item.id}:${scored.first.score}'} '
        'intents=$detectedIntents');

    // --- Explicit-signal decision (strict priority) -------------------
    // 1. Explicit topic in the current question.
    // 2. Explicit feature/resource keyword.
    // 3. Explicit intent (+ resolvable topic).
    // 4. Explicit topic from the immediate conversation context.
    // 5. Clarification (topic picker).
    // Page context NEVER selects a topic: it only filters the options
    // offered in step 5. Demonstratives ("ye/this/isko") without an
    // established conversation topic fall through to step 5.
    _Scored? bestFeature;
    _Scored? bestGuidance;
    String? anchoredTopic;
    double anchoredBest = -1;
    for (final s in scored) {
      if (s.score < limit) continue;
      if (s.item.isFeature) {
        bestFeature ??= s;
      } else {
        bestGuidance ??= s;
        // Explicit topic anchor: a topic-denoting keyword of this item
        // appears in the question (strongest such item wins).
        if (_hasTopicAnchor(s.item, tokens) && s.score > anchoredBest) {
          final t = (s.item.topic ?? '').trim();
          if (t.isNotEmpty) {
            anchoredBest = s.score;
            anchoredTopic = t;
          }
        }
      }
    }

    final explicitTopic =
        _explicitTopicIn(normalized, items) ?? anchoredTopic;
    final convTopic =
        (conversationContext.lastTopic ?? '').trim().isEmpty
            ? null
            : conversationContext.lastTopic!.trim();
    final hasAnaphor = tokens.intersection(anaphoricTokens).isNotEmpty;
    final explicitIntent = _primaryTeachingIntent(detectedIntents);
    final teachingVerb = tokens.intersection(teachingVerbs).isNotEmpty;
    final topicPlanning = _isTopicPlanning(normalized);
    final pageTopic = (context.topic ?? '').trim().isEmpty
        ? null
        : context.topic!.trim();

    // 2) Explicit feature/resource winner keeps the existing behavior
    // (navigation answers, near-tie resource clarification, auto-open).
    if (bestFeature != null &&
        (bestGuidance == null ||
            bestFeature.score >= bestGuidance.score)) {
      // Guidance triggers carry empty answers: a concrete guidance item with
      // a predefined answer always wins over the generic trigger so the
      // teacher sees "बीज बटोरो..." instead of "Teaching Guidance खोलें".
      _Scored top = bestFeature;
      final concrete = scored.where((s) =>
          s.item.answerHindi.trim().isNotEmpty &&
          s.item.answerEnglish.trim().isNotEmpty);
      if (top.item.answerHindi.trim().isEmpty &&
          top.item.answerEnglish.trim().isEmpty) {
        final bestConcrete = concrete.where((s) => s.score >= limit);
        if (bestConcrete.isNotEmpty) {
          top = bestConcrete.first;
        }
      }
      // Ambiguous: two different intents within the margin -> ask, don't guess.
      final near = scored
          .where((s) =>
              s.item.intent != top.item.intent &&
              s.score >= limit &&
              (top.score - s.score) <= clarificationMargin)
          .take(2)
          .toList();
      if (near.isNotEmpty) {
        final options = [top, ...near];
        debugPrint('[TeacherQuestionEngine] query=$question normalized=$normalized '
            'intent=CLARIFICATION options=${options.map((e) => e.item.intent).join(',')}');
        return QuestionResult.clarification(
          answer: answerLanguage == AnswerLanguage.hindi
              ? 'आप किस resource से शुरू करना चाहते हैं?'
              : 'Which resource do you want to start with?',
          answerLanguage: answerLanguage,
          options: options
              .map((s) => QuestionResultOption(
                    knowledgeItemId: s.item.id,
                    intent: s.item.intent,
                    label: answerLanguage == AnswerLanguage.hindi
                        ? s.item.routeLabelHindi
                        : s.item.routeLabelEnglish,
                    route: s.item.route,
                  ))
              .toList(),
          score: top.score,
          threshold: limit,
          nextContext: conversationContext,
        );
      }

      // Explicit "open/kholo" with a fresh feature match -> auto-navigate.
      final wantsOpen = tokens.intersection(navSignals).contains('kholo') ||
          tokens.intersection(navSignals).contains('open') ||
          tokens.contains('kholna');
      final autoNav =
          wantsOpen && top.item.isFeature && (top.item.route ?? '').isNotEmpty;

      _logDecision(
        explicitTopic: explicitTopic,
        explicitIntent: explicitIntent,
        conversationTopic: convTopic,
        pageContextTopic: pageTopic,
        decision: 'MATCHED',
      );
      return _toMatched(top.item, top.score, limit, answerLanguage, context,
          conversationContext, top.hits,
          autoNavigate: autoNav);
    }

    // 1) Explicit topic in the current question -> constrained match.
    if (explicitTopic != null &&
        (explicitIntent != null || teachingVerb || hasAnaphor)) {
      final found = _findTopicIntent(
          items, explicitTopic, explicitIntent ?? preferredGuidance);
      if (found != null) {
        _logDecision(
          explicitTopic: explicitTopic,
          explicitIntent: explicitIntent,
          conversationTopic: convTopic,
          pageContextTopic: pageTopic,
          decision: 'MATCHED',
        );
        return _toMatched(found.item, found.score, limit, answerLanguage,
            context, conversationContext, found.hits);
      }
    }

    // 4) Anaphoric reference + explicitly established conversation topic.
    if (hasAnaphor && convTopic != null) {
      final found = _findTopicIntent(
          items, convTopic, explicitIntent ?? preferredGuidance);
      if (found != null) {
        _logDecision(
          explicitTopic: explicitTopic,
          explicitIntent: explicitIntent,
          conversationTopic: convTopic,
          pageContextTopic: pageTopic,
          decision: 'MATCHED',
        );
        return _toMatched(found.item, found.score, limit, answerLanguage,
            context, conversationContext, found.hits);
      }
    }

    // 5) Teaching question with no resolvable topic -> ASK. Show the real
    // available topics (page context only filters the list).
    // A lone 'kaise'/'how' signal is not enough on its own (unrelated
    // "how to" questions such as train tickets must stay unknown).
    final qualifiesAlone = explicitIntent != null &&
        explicitIntent != 'TEACHING_METHOD' &&
        explicitIntent != 'CURRENT_TOPIC_GUIDANCE' &&
        explicitIntent != 'GENERAL_GUIDANCE';
    if (qualifiesAlone ||
        teachingVerb ||
        hasAnaphor ||
        topicPlanning ||
        explicitTopic != null) {
      final topics = await getAvailableTopics(
        className: context.className,
        subject: context.subject,
      );
      final answer = answerLanguage == AnswerLanguage.hindi
          ? (topicPlanning ? topicListHindi : topicClarifyHindi)
          : (topicPlanning ? topicListEnglish : topicClarifyEnglish);
      _logDecision(
        explicitTopic: explicitTopic,
        explicitIntent: explicitIntent,
        conversationTopic: convTopic,
        pageContextTopic: pageTopic,
        decision: 'CLARIFICATION_REQUIRED',
      );
      return QuestionResult.clarification(
        answer: answer,
        answerLanguage: answerLanguage,
        options: topics
            .map((t) => QuestionResultOption(
                  knowledgeItemId: 'topic::$t',
                  intent: 'TOPIC_PICK',
                  label: t,
                  route: null,
                ))
            .toList(),
        score: limit,
        threshold: limit,
        nextContext: conversationContext,
        clarificationKind: 'topic',
        pendingIntent: explicitIntent,
      );
    }

    _logDecision(
      explicitTopic: explicitTopic,
      explicitIntent: explicitIntent,
      conversationTopic: convTopic,
      pageContextTopic: pageTopic,
      decision: 'UNKNOWN',
    );
    return QuestionResult.unknown(
        answer: unknownFor(answerLanguage),
        answerLanguage: answerLanguage,
        threshold: limit,
        previous: conversationContext);
  }

  QuestionResult _toMatched(
    _Item item,
    double score,
    double limit,
    AnswerLanguage lang,
    LessonContext ctx,
    ConversationContext conv,
    List<String> hits, {
    bool autoNavigate = false,
  }) {
    final answer =
        lang == AnswerLanguage.hindi ? item.answerHindi : item.answerEnglish;
    // Conversation topic comes ONLY from explicitly established topics:
    // the matched item's own topic, else the previous conversation topic.
    // Page context (ctx.topic) must never seed it.
    final topic = (item.topic ?? '').trim().isNotEmpty
        ? item.topic!.trim()
        : conv.lastTopic;
    // Guidance trigger with empty answer must never surface empty text:
    // fall back to opening the guidance page (never invent an answer).
    if (answer.trim().isEmpty) {
      final fallback = lang == AnswerLanguage.hindi
          ? 'इस विषय पर मार्गदर्शन के लिए Teaching Guidance खोलें।'
          : 'Open Teaching Guidance for this topic.';
      return QuestionResult.matched(
        intent: item.intent,
        knowledgeItemId: item.id,
        answer: fallback,
        answerLanguage: lang,
        answerHindi: fallback,
        answerEnglish: fallback,
        route: item.route,
        routeLabel: lang == AnswerLanguage.hindi
            ? item.routeLabelHindi
            : item.routeLabelEnglish,
        score: score,
        threshold: limit,
        matchedKeywords: hits,
        nextContext: ConversationContext(
          lastIntent: item.intent,
          lastTopic: topic,
          lastRoute: item.route,
          lastItemId: item.id,
        ),
        autoNavigate: false,
      );
    }
    debugPrint('[TeacherQuestionEngine] intent=${item.intent} '
        'matchedKeywords=$hits score=$score route=${item.route}');
    return QuestionResult.matched(
      intent: item.intent,
      knowledgeItemId: item.id,
      answer: answer,
      answerLanguage: lang,
      answerHindi: item.answerHindi,
      answerEnglish: item.answerEnglish,
      route: item.route,
      routeLabel: lang == AnswerLanguage.hindi
          ? item.routeLabelHindi
          : item.routeLabelEnglish,
      score: score,
      threshold: limit,
      matchedKeywords: hits,
      nextContext: ConversationContext(
        lastIntent: item.intent,
        lastTopic: topic,
        lastRoute: item.route,
        lastItemId: item.id,
      ),
      autoNavigate: autoNavigate,
    );
  }

  String _labelForRoute(
      String route, List<_Item> items, AnswerLanguage lang) {
    for (final e in items) {
      if (e.route == route) {
        return lang == AnswerLanguage.hindi
            ? e.routeLabelHindi
            : e.routeLabelEnglish;
      }
    }
    return route;
  }
}
