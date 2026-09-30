/// Data models for the deterministic OFFLINE Teacher Co-Pilot.
/// Pure Dart: no Flutter, no network. Every answer is pre-authored.
library;

/// Supported answer languages. Input may be Roman Hindi / English /
/// Devanagari; this preference only controls the ANSWER language.
enum CopilotAnswerLanguage { hindi, english }

CopilotAnswerLanguage copilotLanguageFromString(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'hindi':
    case 'hi':
    case 'हिंदी':
      return CopilotAnswerLanguage.hindi;
    default:
      return CopilotAnswerLanguage.english;
  }
}

String copilotLanguageToString(CopilotAnswerLanguage lang) =>
    lang == CopilotAnswerLanguage.hindi ? 'hindi' : 'english';

/// One predefined knowledge-base entry (navigation or guidance trigger).
class CopilotKnowledgeItem {
  final String id;
  final String intent;
  final List<String> keywords;
  final List<String> romanHindiKeywords;
  final String answerHindi;
  final String answerEnglish;
  final String route;
  final String actionLabelHindi;
  final String actionLabelEnglish;

  const CopilotKnowledgeItem({
    required this.id,
    required this.intent,
    required this.keywords,
    required this.romanHindiKeywords,
    required this.answerHindi,
    required this.answerEnglish,
    required this.route,
    required this.actionLabelHindi,
    required this.actionLabelEnglish,
  });

  factory CopilotKnowledgeItem.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? v) => ((v as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return CopilotKnowledgeItem(
      id: (json['id'] ?? '').toString(),
      intent: (json['intent'] ?? '').toString().trim().toUpperCase(),
      keywords: strings(json['keywords']),
      romanHindiKeywords: strings(json['romanHindiKeywords']),
      answerHindi: (json['answerHindi'] ?? '').toString(),
      answerEnglish: (json['answerEnglish'] ?? '').toString(),
      route: (json['route'] ?? '').toString().trim(),
      actionLabelHindi:
          (json['actionLabelHindi'] ?? '').toString().trim().isEmpty
              ? 'खोलें'
              : (json['actionLabelHindi'] ?? '').toString(),
      actionLabelEnglish:
          (json['actionLabelEnglish'] ?? '').toString().trim().isEmpty
              ? 'Open'
              : (json['actionLabelEnglish'] ?? '').toString(),
    );
  }

  bool get isValid => id.isNotEmpty && intent.isNotEmpty && route.isNotEmpty;

  /// TEACHER_GUIDANCE items intentionally carry empty answers: the answer
  /// comes from the existing teacher-guidance repository at runtime.
  bool get isGuidanceTrigger => intent == 'TEACHER_GUIDANCE';

  String answerFor(CopilotAnswerLanguage lang) =>
      lang == CopilotAnswerLanguage.hindi ? answerHindi : answerEnglish;

  String actionFor(CopilotAnswerLanguage lang) =>
      lang == CopilotAnswerLanguage.hindi
          ? actionLabelHindi
          : actionLabelEnglish;
}

/// Current lesson context (Class • Subject • Topic), all optional.
class CopilotLessonContext {
  final String? className;
  final String? subject;
  final String? topic;

  const CopilotLessonContext({this.className, this.subject, this.topic});

  bool get isEmpty =>
      (className ?? '').trim().isEmpty &&
      (subject ?? '').trim().isEmpty &&
      (topic ?? '').trim().isEmpty;
}

/// Lightweight per-account conversation context: last intent / topic /
/// route / suggested item. Never a large chat memory.
class CopilotConversationContext {
  final String? lastIntent;
  final String? lastTopic;
  final String? lastRoute;
  final String? lastItemId;

  const CopilotConversationContext({
    this.lastIntent,
    this.lastTopic,
    this.lastRoute,
    this.lastItemId,
  });

  bool get isEmpty =>
      lastIntent == null && lastTopic == null && lastRoute == null;

  CopilotConversationContext copyWith({
    String? lastIntent,
    String? lastTopic,
    String? lastRoute,
    String? lastItemId,
  }) =>
      CopilotConversationContext(
        lastIntent: lastIntent ?? this.lastIntent,
        lastTopic: lastTopic ?? this.lastTopic,
        lastRoute: lastRoute ?? this.lastRoute,
        lastItemId: lastItemId ?? this.lastItemId,
      );

  static const empty = CopilotConversationContext();
}

/// Deterministic result of one rule-engine lookup.
class CopilotResult {
  /// Matched knowledge item; null for unknown / clarification / follow-up.
  final CopilotKnowledgeItem? item;

  /// Pre-authored answer already resolved to the teacher's language
  /// (or the fixed unknown message). Empty for pure follow-up opens.
  final String answer;

  /// Route the action button should open (may be null for unknown).
  final String? route;
  final String actionLabel;

  /// True when the engine auto-navigates (explicit "kholo" or affirmed
  /// follow-up). The UI shows a brief confirmation, then navigates.
  final bool autoNavigate;

  /// True when nothing reached the threshold: UI shows the fixed fallback
  /// + quick questions. Never invent an answer.
  final bool isUnknown;

  /// True when two intents scored (near-)identically: UI shows the choice.
  final bool needsClarification;
  final List<CopilotKnowledgeItem> clarificationOptions;

  /// True for "haan kholo" style follow-ups reusing the last route.
  final bool isFollowUpOpen;

  final double score;
  final double threshold;

  /// New conversation context the caller should persist (per account).
  final CopilotConversationContext nextContext;

  const CopilotResult._({
    required this.item,
    required this.answer,
    required this.route,
    required this.actionLabel,
    required this.autoNavigate,
    required this.isUnknown,
    required this.needsClarification,
    required this.clarificationOptions,
    required this.isFollowUpOpen,
    required this.score,
    required this.threshold,
    required this.nextContext,
  });

  factory CopilotResult.matched({
    required CopilotKnowledgeItem item,
    required String answer,
    required CopilotAnswerLanguage language,
    required double score,
    required double threshold,
    required CopilotConversationContext nextContext,
    bool autoNavigate = false,
  }) =>
      CopilotResult._(
        item: item,
        answer: answer,
        route: item.route,
        actionLabel: item.actionFor(language),
        autoNavigate: autoNavigate,
        isUnknown: false,
        needsClarification: false,
        clarificationOptions: const [],
        isFollowUpOpen: false,
        score: score,
        threshold: threshold,
        nextContext: nextContext,
      );

  factory CopilotResult.followUpOpen({
    required String route,
    required String answer,
    required String actionLabel,
    required double threshold,
    required CopilotConversationContext nextContext,
  }) =>
      CopilotResult._(
        item: null,
        answer: answer,
        route: route,
        actionLabel: actionLabel,
        autoNavigate: true,
        isUnknown: false,
        needsClarification: false,
        clarificationOptions: const [],
        isFollowUpOpen: true,
        score: threshold,
        threshold: threshold,
        nextContext: nextContext,
      );

  factory CopilotResult.clarification({
    required List<CopilotKnowledgeItem> options,
    required String answer,
    required double score,
    required double threshold,
    required CopilotConversationContext nextContext,
  }) =>
      CopilotResult._(
        item: null,
        answer: answer,
        route: null,
        actionLabel: '',
        autoNavigate: false,
        isUnknown: false,
        needsClarification: true,
        clarificationOptions: List.unmodifiable(options),
        isFollowUpOpen: false,
        score: score,
        threshold: threshold,
        nextContext: nextContext,
      );

  factory CopilotResult.unknown({
    required String answer,
    required double threshold,
    required CopilotConversationContext previous,
  }) =>
      CopilotResult._(
        item: null,
        answer: answer,
        route: null,
        actionLabel: '',
        autoNavigate: false,
        isUnknown: true,
        needsClarification: false,
        clarificationOptions: const [],
        isFollowUpOpen: false,
        score: 0,
        threshold: threshold,
        // Unknown questions must NOT clobber the follow-up context.
        nextContext: previous,
      );
}

/// One quick-question chip (label shown, [query] sent through the engine).
class CopilotQuickQuestion {
  final String id;
  final String labelHindi;
  final String labelEnglish;
  final String query;
  final bool contextAware;

  const CopilotQuickQuestion({
    required this.id,
    required this.labelHindi,
    required this.labelEnglish,
    required this.query,
    required this.contextAware,
  });

  factory CopilotQuickQuestion.fromJson(Map<String, dynamic> json,
      {bool contextAware = false}) {
    return CopilotQuickQuestion(
      id: (json['id'] ?? '').toString(),
      labelHindi: (json['labelHindi'] ?? '').toString(),
      labelEnglish: (json['labelEnglish'] ?? '').toString(),
      query: (json['query'] ?? '').toString(),
      contextAware: contextAware,
    );
  }

  String labelFor(CopilotAnswerLanguage lang) =>
      lang == CopilotAnswerLanguage.hindi ? labelHindi : labelEnglish;
}
