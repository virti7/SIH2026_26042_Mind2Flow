import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/account_scope.dart';
import '../database/app_database.dart';
import '../models/teacher_activity.dart';
import '../sync/worksheet_download_store.dart';

/// Reads teacher-only progress from real on-device records.
///
/// Sources (all local SQLite via Drift, works fully offline):
/// - [LessonDeliveryProgress]: completed rows count as "lessons taught".
/// - [AssessmentResults]: every row counts as an assessment the teacher
///   conducted (aggregated counts only — no student analytics surface here).
/// - [SavedMaterials]: rows of type `worksheet` / `flashcard` count as
///   generated/used resources with class, subject, language metadata. Only
///   server-generated completions land here — queued offline requests never
///   do, so "generated" is never inflated.
/// - Downloaded worksheets ([DriftWorksheetDownloadStore]): rows count as
///   "downloaded" only after the file is actually saved locally.
/// - [TranslationHistory]: message count surfaces translation sessions.
/// - [SyncQueue]: pending rows surface the offline/sync state.
///
/// No student names, scores, gaps or charts are produced by this repository.
abstract class TeacherActivityRepository {
  Future<TeacherActivitySummary> getSummary();
  Future<List<TeacherActivity>> getRecentActivities({int limit});
}

/// Fallback used where no on-device database exists (e.g. web demo):
/// reports genuinely empty activity instead of invented values.
class EmptyTeacherActivityRepository implements TeacherActivityRepository {
  @override
  Future<TeacherActivitySummary> getSummary() async =>
      const TeacherActivitySummary();

  @override
  Future<List<TeacherActivity>> getRecentActivities({int limit = 20}) async =>
      const [];
}

class SqliteTeacherActivityRepository implements TeacherActivityRepository {
  final AppDatabase db;
  final String? Function()? currentUserIdProvider;

  SqliteTeacherActivityRepository({required this.db, this.currentUserIdProvider});

  String? get _ownerId {
    try {
      final id = currentUserIdProvider?.call()?.trim();
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (_) {
      return null;
    }
  }

  bool get _legacy => currentUserIdProvider == null;

  @override
  Future<TeacherActivitySummary> getSummary() async {
    final ownerId = _ownerId;
    // Unauthenticated: empty progress, never another teacher's counts.
    // Legacy mode (no provider wired) aggregates globally as before.
    if (!_legacy && ownerId == null) return const TeacherActivitySummary();
    await ensureAccountIsolation(db);
    final ownedResults = _legacy
        ? null
        : await ownedEntityIds(db, entityType: 'assessment_result', ownerId: ownerId);
    final ownedMaterials = _legacy
        ? null
        : await ownedEntityIds(db, entityType: 'saved_material', ownerId: ownerId);
    final ownedHistory = _legacy
        ? null
        : await ownedEntityIds(db, entityType: 'translation_history', ownerId: ownerId);
    // Lesson progress keys are namespaced `$ownerId::$lessonId` (scoped
    // mode); legacy rows use plain lessonIds.
    final progressPrefix = _legacy ? '' : '$ownerId::';
    final allCompleted =
        await db.lessonDao.getCompletedDeliveryProgress(limit: 500);
    final completedLessons = _legacy
        ? allCompleted
        : allCompleted.where((p) => p.lessonId.startsWith(progressPrefix)).toList();
    final allResults = await db.assessmentDao.getAllAssessmentResults();
    final assessmentResults = _legacy
        ? allResults
        : allResults.where((r) => ownedResults!.contains(r.id)).toList();
    final allMaterials = await db.resourceDao.getSavedMaterials();
    final savedMaterials = _legacy
        ? allMaterials
        : allMaterials.where((m) => ownedMaterials!.contains(m.id)).toList();
    final allTranslations = await db.translationDao.getRecentHistory(limit: 500);
    final translations = _legacy
        ? allTranslations
        : allTranslations.where((t) => ownedHistory!.contains(t.id)).toList();
    final pendingSync =
        _legacy ? await db.syncQueueDao.getPendingCount() : await _ownedPendingCount(ownerId!);

    // Resolve lesson metadata for completed deliveries.
    final lessonById = <String, LessonData>{};
    for (final progress in completedLessons) {
      final rawId = (!_legacy && progress.lessonId.startsWith(progressPrefix))
          ? progress.lessonId.substring(progressPrefix.length)
          : progress.lessonId;
      final lesson = await db.lessonDao.getLessonById(rawId);
      if (lesson != null) lessonById[progress.lessonId] = lesson;
    }

    final worksheets =
        savedMaterials.where((m) => m.type == 'worksheet').toList();
    final flashcardSets =
        savedMaterials.where((m) => m.type == 'flashcard').toList();

    final classes = <String>{};
    final subjects = <String>{};
    final languages = <String>{};
    final outcomes = <String>{};
    final subjectCounts = <String, int>{};
    void countSubject(String? subject) {
      final key = (subject ?? '').trim();
      if (key.isEmpty) return;
      subjects.add(key);
      subjectCounts[key] = (subjectCounts[key] ?? 0) + 1;
    }

    final activities = <TeacherActivity>[];

    for (final progress in completedLessons) {
      final lesson = lessonById[progress.lessonId];
      final grade = lesson?.grade;
      final subject = lesson?.subject;
      if (grade != null) classes.add('Class $grade');
      countSubject(subject);
      if ((lesson?.outcomeCode ?? '').isNotEmpty) {
        outcomes.add(lesson!.outcomeCode);
      }
      final at = progress.completedAt ?? progress.startedAt;
      activities.add(TeacherActivity(
        id: 'lesson_${progress.lessonId}',
        type: TeacherActivityType.lessonTaught,
        title: 'Taught "${lesson?.title ?? progress.lessonId}"',
        subtitle: [
          if (grade != null) 'Class $grade',
          if ((subject ?? '').isNotEmpty) subject!,
          if ((lesson?.outcomeCode ?? '').isNotEmpty) lesson!.outcomeCode,
        ].join(' • '),
        grade: grade,
        subject: subject,
        outcomeCode: lesson?.outcomeCode,
        createdAt: at,
        isSynced: true,
      ));
    }

    for (final result in assessmentResults) {
      final at = result.completedAt;
      activities.add(TeacherActivity(
        id: 'assessment_${result.id}',
        type: TeacherActivityType.assessmentConducted,
        title: 'Conducted assessment (${result.totalQuestions} questions)',
        subtitle: result.outcomeCode.isNotEmpty
            ? 'Outcome ${result.outcomeCode}'
            : 'Classroom assessment',
        outcomeCode: result.outcomeCode.isNotEmpty ? result.outcomeCode : null,
        createdAt: at,
        isSynced: result.syncStatus == 'synced',
      ));
      if (result.outcomeCode.isNotEmpty) outcomes.add(result.outcomeCode);
    }

    for (final material in worksheets) {
      if (material.grade > 0) classes.add('Class ${material.grade}');
      countSubject(material.subject);
      if (material.language.isNotEmpty) languages.add(material.language);
      if (material.outcomeCode.isNotEmpty) outcomes.add(material.outcomeCode);
      activities.add(TeacherActivity(
        id: 'worksheet_${material.id}',
        type: TeacherActivityType.worksheetGenerated,
        title: 'Generated worksheet "${material.title}"',
        subtitle: [
          if (material.grade > 0) 'Class ${material.grade}',
          if (material.subject.isNotEmpty) material.subject,
          if (material.language.isNotEmpty) material.language,
        ].join(' • '),
        grade: material.grade > 0 ? material.grade : null,
        subject: material.subject.isNotEmpty ? material.subject : null,
        outcomeCode:
            material.outcomeCode.isNotEmpty ? material.outcomeCode : null,
        language: material.language.isNotEmpty ? material.language : null,
        createdAt: material.createdAt,
        isSynced: true,
      ));
    }

    // Downloads count only after the file is actually saved locally.
    // Split by resource_type so Progress never inflates one category.
    // Account-scoped: only this teacher's downloads.
    var worksheetsDownloaded = 0;
    var flashcardsDownloaded = 0;
    var activitiesDownloaded = 0;
    try {
      final store = DriftWorksheetDownloadStore(db, currentUserIdProvider: currentUserIdProvider);
      final downloads = await store.listDownloads();
      for (final d in downloads) {
        if (d.grade > 0) classes.add('Class ${d.grade}');
        countSubject(d.subject);
        if (d.language1.isNotEmpty) languages.add(d.language1);
        if (d.language2.isNotEmpty) languages.add(d.language2);
        if ((d.nipunOutcome ?? '').isNotEmpty) outcomes.add(d.nipunOutcome!);
        final type = d.resourceType;
        final activityType = type == 'flashcard'
            ? TeacherActivityType.flashcardsDownloaded
            : type == 'activity'
                ? TeacherActivityType.activityDownloaded
                : TeacherActivityType.worksheetDownloaded;
        if (activityType == TeacherActivityType.worksheetDownloaded) {
          worksheetsDownloaded++;
        } else if (activityType == TeacherActivityType.flashcardsDownloaded) {
          flashcardsDownloaded++;
        } else {
          activitiesDownloaded++;
        }
        final kindLabel = type == 'flashcard'
            ? 'flashcard set'
            : type == 'activity'
                ? 'activity'
                : 'worksheet';
        activities.add(TeacherActivity(
          id: 'download_${d.downloadId}',
          type: activityType,
          title: 'Downloaded $kindLabel "${d.title}"',
          subtitle: [
            if (d.grade > 0) 'Class ${d.grade}',
            if (d.section.isNotEmpty) 'Section ${d.section}',
            if (d.subject.isNotEmpty) d.subject,
            '${d.language1} + ${d.language2}',
            if (d.questionCount > 0) '${d.questionCount} questions',
          ].join(' • '),
          grade: d.grade > 0 ? d.grade : null,
          subject: d.subject.isNotEmpty ? d.subject : null,
          outcomeCode: (d.nipunOutcome ?? '').isNotEmpty
              ? d.nipunOutcome
              : null,
          language: '${d.language1} + ${d.language2}',
          createdAt: d.downloadedAt,
          isSynced: true,
        ));
      }
    } catch (_) {
      // Download metadata unreadable: progress stays honest without it.
    }

    for (final material in flashcardSets) {
      if (material.language.isNotEmpty) languages.add(material.language);
      if (material.subject.isNotEmpty) {
        subjects.add(material.subject);
      }
      activities.add(TeacherActivity(
        id: 'flashcards_${material.id}',
        type: TeacherActivityType.flashcardSetUsed,
        title: 'Used flashcard set "${material.title}"',
        subtitle: [
          if (material.subject.isNotEmpty) material.subject,
          if (material.language.isNotEmpty) material.language,
        ].join(' • '),
        subject: material.subject.isNotEmpty ? material.subject : null,
        language: material.language.isNotEmpty ? material.language : null,
        createdAt: material.createdAt,
        isSynced: true,
      ));
    }

    if (translations.isNotEmpty) {
      final latest = translations.first.timestamp;
      final langs = translations.map((t) => t.targetLanguage).toSet();
      activities.add(TeacherActivity(
        id: 'translation_latest',
        type: TeacherActivityType.translationSession,
        title: 'Translation session (${translations.length} messages)',
        subtitle: langs.join(', '),
        language: langs.isNotEmpty ? langs.first : null,
        createdAt: latest,
        isSynced: true,
      ));
    }

    activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return TeacherActivitySummary(
      lessonsTaught: completedLessons.length,
      assessmentsConducted: assessmentResults.length,
      worksheetsGenerated: worksheets.length,
      worksheetsDownloaded: worksheetsDownloaded,
      flashcardsDownloaded: flashcardsDownloaded,
      activitiesDownloaded: activitiesDownloaded,
      flashcardSetsUsed: flashcardSets.length,
      translationSessions: translations.length,
      classesTaught: classes.toList()..sort(),
      subjectsTaught: subjects.toList()..sort(),
      languagesUsed: languages.toList()..sort(),
      outcomesTaught: outcomes.toList()..sort(),
      subjectCounts: subjectCounts,
      recentActivities: activities.take(20).toList(),
      pendingSyncCount: pendingSync,
    );
  }

  @override
  Future<List<TeacherActivity>> getRecentActivities({int limit = 20}) async {
    final summary = await getSummary();
    return summary.recentActivities.take(limit).toList();
  }

  /// Account-scoped pending sync count via raw SQL (typed DAO has no
  /// owner column; see [ensureAccountIsolation]).
  Future<int> _ownedPendingCount(String ownerId) async {
    try {
      final rows = await db.customSelect(
        'SELECT COUNT(*) AS c FROM sync_queue WHERE owner_user_id = ? '
        'AND (status = ? OR status = ?)',
        variables: [
          Variable.withString(ownerId),
          Variable.withString('PENDING'),
          Variable.withString('FAILED'),
        ],
      ).get();
      if (rows.isEmpty) return 0;
      return (rows.first.data['c'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // Column missing on very old DBs: fall back to payload-owner scan.
      try {
        final pending = await db.syncQueueDao.getPendingOperations(limit: 500);
        var count = 0;
        for (final op in pending) {
          try {
            final payload =
                jsonDecode(op.payload) as Map<String, dynamic>;
            final owner = (payload['owner_user_id'] ?? '').toString();
            if (owner == ownerId) count++;
          } catch (_) {}
        }
        return count;
      } catch (_) {
        return 0;
      }
    }
  }
}
