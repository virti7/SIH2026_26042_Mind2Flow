import 'package:drift/drift.dart';
import 'database_connection.dart' as impl;
import 'tables/activities.dart';
import 'tables/assessment_results.dart';
import 'tables/assessments.dart';
import 'tables/classrooms.dart';
import 'tables/content_packs.dart';
import 'tables/language_packs.dart';
import 'tables/learning_gaps.dart';
import 'tables/lesson_delivery_progress.dart';
import 'tables/lessons.dart';
import 'tables/local_contexts.dart';
import 'tables/nipun_outcomes.dart';
import 'tables/quick_phrases.dart';
import 'tables/remedial_recommendations.dart';
import 'tables/saved_materials.dart';
import 'tables/students.dart';
import 'tables/downloaded_resources.dart';
import 'tables/sync_queue.dart';
import 'tables/teachers.dart';
import 'tables/translation_feedback.dart';
import 'tables/translation_history.dart';
import '../content/flashcard/flashcard_progress_store.dart';

import 'daos/assessment_dao.dart';
import 'daos/curriculum_dao.dart';
import 'daos/lesson_dao.dart';
import 'daos/offline_dao.dart';
import 'daos/resource_dao.dart';
import 'daos/student_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/teacher_dao.dart';
import 'daos/translation_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Teachers,
    Classrooms,
    NipunOutcomes,
    Lessons,
    Activities,
    LessonDeliveryProgress,
    LocalContexts,
    Students,
    AssessmentQuestions,
    AssessmentResults,
    LearningGaps,
    RemedialRecommendations,
    SavedMaterials,
    TranslationHistory,
    TranslationFeedback,
    QuickPhrases,
    LanguagePacks,
    ContentPacks,
    SyncQueue,
  ],
  daos: [
    TeacherDao,
    CurriculumDao,
    LessonDao,
    StudentDao,
    AssessmentDao,
    ResourceDao,
    TranslationDao,
    OfflineDao,
    SyncQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? impl.connectDatabase());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Codegen-free table (no build_runner step required): canonical
          // DDL from DownloadedResourcesSchema (account-scoped
          // UNIQUE(teacher_id, resource_id)).
          await customStatement(DownloadedResourcesSchema.createTable);
          for (final idx in DownloadedResourcesSchema.indexes) {
            await customStatement(idx);
          }
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement(DownloadedResourcesSchema.createTable);
            for (final idx in DownloadedResourcesSchema.indexes) {
              await customStatement(idx);
            }
          } else if (from < 3) {
            // v3: authoritative download record gains resource_type so
            // worksheets, flashcards, activities and quizzes stay distinct.
            try {
              await customStatement(
                "ALTER TABLE downloaded_resources ADD COLUMN resource_type TEXT NOT NULL DEFAULT 'worksheet'",
              );
            } catch (_) {}
            try {
              await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_downloads_resource_type ON downloaded_resources (resource_type)',
              );
            } catch (_) {}
          }
          if (from < 4) {
            // v4: per-account download isolation — UNIQUE(resource_id) becomes
            // UNIQUE(teacher_id, resource_id). Data-preserving; legacy
            // unowned rows stay hidden from every account.
            try {
              await migrateDownloadedResourcesToOwnerScoped(this);
            } catch (_) {}
          }
        },
        beforeOpen: (details) async {
          // Idempotent setup of flashcard learning progress table
          try {
            await customStatement(SqliteFlashcardProgressStore.createTableSql);
            await customStatement(SqliteFlashcardProgressStore.createIndexSql);
          } catch (_) {}
        },
      );
}
