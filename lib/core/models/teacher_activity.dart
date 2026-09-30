/// Teacher-only activity records aggregated from real on-device data.
///
/// Progress answers "What has this teacher actually done?" using only stored
/// application events (lesson delivery, assessments conducted, generated
/// resources, translation sessions). No student identity, scores or
/// performance analytics are ever part of this model.
enum TeacherActivityType {
  lessonTaught,
  assessmentConducted,
  worksheetGenerated,
  worksheetDownloaded,
  flashcardsDownloaded,
  activityDownloaded,
  flashcardSetUsed,
  translationSession,
}

class TeacherActivity {
  final String id;
  final TeacherActivityType type;
  final String title;
  final String subtitle;
  final int? grade;
  final String? subject;
  final String? outcomeCode;
  final String? language;
  final DateTime createdAt;
  final bool isSynced;

  const TeacherActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.grade,
    this.subject,
    this.outcomeCode,
    this.language,
    required this.createdAt,
    this.isSynced = true,
  });
}

class TeacherActivitySummary {
  final int lessonsTaught;
  final int assessmentsConducted;
  final int worksheetsGenerated;
  final int worksheetsDownloaded;
  final int flashcardsDownloaded;
  final int activitiesDownloaded;
  final int flashcardSetsUsed;
  final int translationSessions;
  final List<String> classesTaught;
  final List<String> subjectsTaught;
  final List<String> languagesUsed;
  final List<String> outcomesTaught;
  final Map<String, int> subjectCounts;
  final List<TeacherActivity> recentActivities;
  final int pendingSyncCount;

  const TeacherActivitySummary({
    this.lessonsTaught = 0,
    this.assessmentsConducted = 0,
    this.worksheetsGenerated = 0,
    this.worksheetsDownloaded = 0,
    this.flashcardsDownloaded = 0,
    this.activitiesDownloaded = 0,
    this.flashcardSetsUsed = 0,
    this.translationSessions = 0,
    this.classesTaught = const [],
    this.subjectsTaught = const [],
    this.languagesUsed = const [],
    this.outcomesTaught = const [],
    this.subjectCounts = const {},
    this.recentActivities = const [],
    this.pendingSyncCount = 0,
  });

  int get totalResources => worksheetsGenerated + flashcardSetsUsed;

  bool get isEmpty =>
      lessonsTaught == 0 &&
      assessmentsConducted == 0 &&
      worksheetsGenerated == 0 &&
      worksheetsDownloaded == 0 &&
      flashcardsDownloaded == 0 &&
      activitiesDownloaded == 0 &&
      flashcardSetsUsed == 0 &&
      translationSessions == 0;
}
