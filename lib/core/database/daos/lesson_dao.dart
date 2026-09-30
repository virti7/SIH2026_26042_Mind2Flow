import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/lesson_delivery_progress.dart';
import '../tables/lessons.dart';

part 'lesson_dao.g.dart';

@DriftAccessor(tables: [Lessons, LessonDeliveryProgress])
class LessonDao extends DatabaseAccessor<AppDatabase> with _$LessonDaoMixin {
  LessonDao(super.db);

  Future<LessonData?> getLessonByOutcomeCode(String outcomeCode) {
    return (select(lessons)
          ..where((tbl) => tbl.outcomeCode.equals(outcomeCode))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<LessonData?> getLessonById(String id) {
    return (select(lessons)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertOrUpdateLesson(LessonsCompanion lesson) {
    return into(lessons).insertOnConflictUpdate(lesson);
  }

  Future<LessonDeliveryProgressData?> getDeliveryProgress(String lessonId) {
    return (select(lessonDeliveryProgress)..where((tbl) => tbl.lessonId.equals(lessonId))).getSingleOrNull();
  }

  /// All delivery records, newest first — backing teacher-only progress.
  Future<List<LessonDeliveryProgressData>> getAllDeliveryProgress({int limit = 100}) {
    return (select(lessonDeliveryProgress)
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit))
        .get();
  }

  /// Completed lessons only ("lessons taught"), newest first.
  Future<List<LessonDeliveryProgressData>> getCompletedDeliveryProgress({int limit = 100}) {
    return (select(lessonDeliveryProgress)
          ..where((tbl) => tbl.isCompleted.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
          ..limit(limit))
        .get();
  }

  Future<void> updateDeliveryProgress(LessonDeliveryProgressCompanion progress) {
    return into(lessonDeliveryProgress).insertOnConflictUpdate(progress);
  }
}
