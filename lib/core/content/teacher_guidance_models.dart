/// Data models for the deterministic OFFLINE Teacher Guidance Q&A system.
///
/// Every answer is a pre-authored string from the bundled knowledge base
/// (`assets/prototype_content/teacher_guidance/teacher_guidance.json`).
/// Nothing is generated, translated, or fetched at runtime.
library;

/// Predefined teacher intents supported by the local matching engine.
enum TeacherGuidanceIntent {
  teachingMethod,
  activity,
  example,
  explanation,
  simplify,
  classroomActivity,
  assessment,
  commonDifficulty,
  remediation,
  unknown;

  static TeacherGuidanceIntent fromJson(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'TEACHING_METHOD':
        return TeacherGuidanceIntent.teachingMethod;
      case 'ACTIVITY':
        return TeacherGuidanceIntent.activity;
      case 'EXAMPLE':
        return TeacherGuidanceIntent.example;
      case 'EXPLANATION':
        return TeacherGuidanceIntent.explanation;
      case 'SIMPLIFY':
        return TeacherGuidanceIntent.simplify;
      case 'CLASSROOM_ACTIVITY':
        return TeacherGuidanceIntent.classroomActivity;
      case 'ASSESSMENT':
        return TeacherGuidanceIntent.assessment;
      case 'COMMON_DIFFICULTY':
        return TeacherGuidanceIntent.commonDifficulty;
      case 'REMEDIATION':
        return TeacherGuidanceIntent.remediation;
      default:
        return TeacherGuidanceIntent.unknown;
    }
  }
}

/// One predefined knowledge-base entry: reviewed Hindi + English answers.
class TeacherGuidanceItem {
  final String id;
  final String className;
  final String subject;
  final String topic;
  final TeacherGuidanceIntent intent;
  final List<String> keywords;
  final List<String> questionPatterns;
  final String answerHindi;
  final String answerEnglish;

  const TeacherGuidanceItem({
    required this.id,
    required this.className,
    required this.subject,
    required this.topic,
    required this.intent,
    required this.keywords,
    required this.questionPatterns,
    required this.answerHindi,
    required this.answerEnglish,
  });

  factory TeacherGuidanceItem.fromJson(Map<String, dynamic> json) {
    List<String> _strings(Object? v) => ((v as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return TeacherGuidanceItem(
      id: (json['id'] ?? '').toString(),
      className: (json['className'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      intent: TeacherGuidanceIntent.fromJson(json['intent']?.toString()),
      keywords: _strings(json['keywords']),
      questionPatterns: _strings(json['questionPatterns']),
      answerHindi: (json['answerHindi'] ?? '').toString(),
      answerEnglish: (json['answerEnglish'] ?? '').toString(),
    );
  }

  bool get isValid =>
      id.isNotEmpty &&
      keywords.isNotEmpty &&
      answerHindi.trim().isNotEmpty &&
      answerEnglish.trim().isNotEmpty;
}

/// Current lesson context from the Teach flow. All fields optional so the
/// engine also works without context (keywords/patterns only).
class TeacherGuidanceContext {
  final String? className;
  final String? subject;
  final String? topic;
  final String? learningOutcome;

  const TeacherGuidanceContext({
    this.className,
    this.subject,
    this.topic,
    this.learningOutcome,
  });

  bool get isEmpty =>
      (className ?? '').trim().isEmpty &&
      (subject ?? '').trim().isEmpty &&
      (topic ?? '').trim().isEmpty &&
      (learningOutcome ?? '').trim().isEmpty;
}

/// Deterministic result of one local Q&A lookup.
class TeacherGuidanceResult {
  /// Matched predefined item; null when unknown or clarification.
  final TeacherGuidanceItem? item;

  /// True when no predefined item reached the confidence threshold
  /// (or the question was empty). The UI must show the fixed
  /// unavailable message — never invent an answer.
  final bool isUnknown;

  /// True when several items scored (near-)identically and the teacher
  /// must pick. Contains the top candidates (2-3 items).
  final bool needsClarification;

  /// Final score of the winning item (0 when unknown).
  final double score;

  /// Threshold that was applied.
  final double threshold;

  /// Candidates for the clarification UI (empty unless needed).
  final List<TeacherGuidanceItem> clarificationOptions;

  const TeacherGuidanceResult._({
    required this.item,
    required this.isUnknown,
    required this.needsClarification,
    required this.score,
    required this.threshold,
    this.clarificationOptions = const [],
  });

  factory TeacherGuidanceResult.matched(
    TeacherGuidanceItem item, {
    required double score,
    required double threshold,
  }) =>
      TeacherGuidanceResult._(
        item: item,
        isUnknown: false,
        needsClarification: false,
        score: score,
        threshold: threshold,
      );

  factory TeacherGuidanceResult.clarification(
    List<TeacherGuidanceItem> options, {
    required double score,
    required double threshold,
  }) =>
      TeacherGuidanceResult._(
        item: null,
        isUnknown: false,
        needsClarification: true,
        score: score,
        threshold: threshold,
        clarificationOptions: List.unmodifiable(options),
      );

  factory TeacherGuidanceResult.unknown({required double threshold}) =>
      TeacherGuidanceResult._(
        item: null,
        isUnknown: true,
        needsClarification: false,
        score: 0,
        threshold: threshold,
      );
}

/// One entry of a teacher's own Q&A history. The knowledge base itself is
/// shared/static; history rows are always stored per owner user id.
class TeacherGuidanceHistoryEntry {
  final String question;
  final String? matchedItemId;
  final DateTime askedAt;

  const TeacherGuidanceHistoryEntry({
    required this.question,
    required this.matchedItemId,
    required this.askedAt,
  });
}
