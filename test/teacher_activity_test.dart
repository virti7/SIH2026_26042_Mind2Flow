import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/database/database_seeder.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/models/teacher_activity.dart';
import 'package:maatribhasha/core/repositories/sqlite_repositories.dart';
import 'package:maatribhasha/core/repositories/teacher_activity_repository.dart';
import 'package:maatribhasha/core/sync/worksheet_generation_sync.dart';
import 'package:maatribhasha/features/progress/presentation/bloc/progress_bloc.dart';

void main() {
  late AppDatabase db;
  late SqliteTeacherActivityRepository activityRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await DatabaseSeeder(db).seedIfNeeded();
    activityRepo = SqliteTeacherActivityRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Teacher-only progress from real on-device records', () {
    test('Empty database yields a genuinely empty summary (no invented values)', () async {
      final summary = await activityRepo.getSummary();

      expect(summary.isEmpty, isTrue);
      expect(summary.lessonsTaught, 0);
      expect(summary.assessmentsConducted, 0);
      expect(summary.worksheetsGenerated, 0);
      expect(summary.flashcardSetsUsed, 0);
      expect(summary.recentActivities, isEmpty);
      expect(summary.classesTaught, isEmpty);
      expect(summary.subjectsTaught, isEmpty);
    });

    test('Completed lesson delivery appears as a taught lesson', () async {
      final lessonRepo = SqliteLessonRepository(db: db);
      final plan = await lessonRepo.getLessonPlanForOutcome('M2.1.4');

      await lessonRepo.updateLessonDeliveryProgress(plan.id, plan.steps.length, true);

      final summary = await activityRepo.getSummary();
      expect(summary.lessonsTaught, 1);
      expect(summary.isEmpty, isFalse);
      expect(summary.classesTaught, contains('Class ${plan.grade}'));
      expect(summary.subjectsTaught, contains(plan.subject));
      expect(summary.outcomesTaught, contains('M2.1.4'));
      expect(
        summary.recentActivities.any((a) => a.type == TeacherActivityType.lessonTaught),
        isTrue,
      );
    });

    test('Queued request alone creates no worksheet activity (no fake data)', () async {
      final resourceRepo = SqliteResourceRepository(db: db);
      final queued = await resourceRepo.generateWorksheet(
        grade: 2,
        subject: 'Mathematics',
        outcomeCode: 'M2.1.4',
        targetLanguage: TribalLanguage.mundari,
        difficulty: DifficultyLevel.medium,
        type: WorksheetType.practice,
        questionCount: 3,
      );

      // Request is queued for server generation; nothing fabricated locally.
      expect(queued.requestId, isNotEmpty);
      expect(await db.syncQueueDao.getPendingCount(), 1);
      final summaryBefore = await activityRepo.getSummary();
      expect(summaryBefore.worksheetsGenerated, 0);
    });

    test('Server-completed worksheet appears with real metadata', () async {
      final resourceRepo = SqliteResourceRepository(db: db);
      final queued = await resourceRepo.generateWorksheet(
        grade: 2,
        subject: 'Mathematics',
        outcomeCode: 'M2.1.4',
        targetLanguage: TribalLanguage.mundari,
        difficulty: DifficultyLevel.medium,
        type: WorksheetType.practice,
        questionCount: 3,
      );

      // Simulate the post-sync server result landing in Saved Materials.
      const contentId = 'WS-G2-MATH-M214-unr-sim';
      await db.resourceDao.insertSavedMaterial(
        savedMaterialFromGenerationContent(contentId, {
          'content_id': contentId,
          'title': 'Numbers up to 100 (server)',
          'title_hi': '100 तक की संख्याएं',
          'grade': 2,
          'subject': 'Mathematics',
          'curriculum_id': 'M2.1.4',
          'target_language': 'unr',
          'difficulty': 'medium',
          'content_type': 'worksheet',
          'questions': [
            {
              'questionNumber': 1,
              'promptHindi': 'सर्वर प्रश्न?',
              'promptTribal': 'सर्वर उत्तर',
              'visualIllustration': '',
              'options': ['1'],
              'answer': '1',
            },
          ],
        }),
      );
      expect(queued.requestId, isNotEmpty);

      final summary = await activityRepo.getSummary();
      expect(summary.worksheetsGenerated, 1);
      expect(summary.languagesUsed, contains('unr'));
      expect(
        summary.recentActivities.any((a) => a.type == TeacherActivityType.worksheetGenerated),
        isTrue,
      );
    });

    test('Used flashcard set appears without duplication', () async {
      final resourceRepo = SqliteResourceRepository(db: db);
      final cards = await resourceRepo.getFlashcards(
        topic: 'Numbers',
        language: TribalLanguage.mundari,
      );
      await resourceRepo.saveFlashcardSet(
        topic: 'Numbers',
        language: TribalLanguage.mundari,
        cards: cards,
      );
      // Repeated classroom use updates the same record.
      await resourceRepo.saveFlashcardSet(
        topic: 'Numbers',
        language: TribalLanguage.mundari,
        cards: cards,
      );

      final summary = await activityRepo.getSummary();
      expect(summary.flashcardSetsUsed, 1);
      expect(
        summary.recentActivities.any((a) => a.type == TeacherActivityType.flashcardSetUsed),
        isTrue,
      );
    });

    test('Conducted assessment appears as teacher activity', () async {
      final assessmentRepo = SqliteAssessmentRepository(db: db);
      await assessmentRepo.submitAssessment(
        studentId: 'session_learner_1',
        studentName: 'Session Learner',
        outcomeCode: 'M2.1.4',
        selectedAnswers: [0, 0, 0],
      );

      final summary = await activityRepo.getSummary();
      expect(summary.assessmentsConducted, 1);
      expect(
        summary.recentActivities.any((a) => a.type == TeacherActivityType.assessmentConducted),
        isTrue,
      );
    });

    test('Teacher profile starts empty and persists real data', () async {
      final teacherRepo = SqliteTeacherRepository(db: db);

      final initial = await teacherRepo.getProfile();
      expect(initial.name, isEmpty);
      expect(initial.school, isEmpty);
      expect(initial.district, isEmpty);

      await teacherRepo.updateProfile(initial.copyWith(
        name: 'Repo Test Teacher',
        school: 'Repo Test School',
        district: 'Repo Test District',
      ));

      final reloaded = await teacherRepo.getProfile();
      expect(reloaded.name, 'Repo Test Teacher');
      expect(reloaded.school, 'Repo Test School');
      expect(reloaded.district, 'Repo Test District');
    });

    test('ProgressBloc dashboard is teacher-only and dynamic', () async {
      final lessonRepo = SqliteLessonRepository(db: db);
      final plan = await lessonRepo.getLessonPlanForOutcome('M2.1.4');
      await lessonRepo.updateLessonDeliveryProgress(plan.id, plan.steps.length, true);

      final bloc = ProgressBloc(
        activityRepository: activityRepo,
        studentRepository: SqliteStudentRepository(db: db),
      );
      bloc.add(LoadProgressDashboard());

      final state = await bloc.stream.firstWhere((s) => s is ProgressDashboardLoaded);
      final loaded = state as ProgressDashboardLoaded;
      expect(loaded.summary.lessonsTaught, 1);
      expect(loaded.summary.recentActivities, isNotEmpty);

      await bloc.close();
    });
  });
}
