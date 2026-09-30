import 'dart:convert';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/database/database_seeder.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final seeder = DatabaseSeeder(db);
    await seeder.seedIfNeeded();
  });

  tearDown(() async {
    await db.close();
  });

  group('Database CRUD & Persistence Tests', () {
    test('Teacher profile: starts empty, saves and persists across reopen/read', () async {
      // 1. Fresh database has NO teacher profile: production never seeds identity.
      final initial = await db.teacherDao.getProfile();
      expect(initial, isNull);

      // 2. Save a real teacher profile (first-launch onboarding flow)
      final now = DateTime.now();
      await db.teacherDao.insertOrUpdateProfile(
        TeachersCompanion(
          id: const Value('teacher_primary'),
          name: const Value('Test Teacher'),
          school: const Value('Test School'),
          district: const Value('Test District'),
          state: const Value('Jharkhand'),
          classesTaughtJson: Value(jsonEncode([1, 2, 3])),
          teachingLanguage: const Value('Hindi'),
          supportedLanguagesJson: Value(jsonEncode(['mundari', 'ho', 'santali'])),
          activeSessionLanguage: const Value('mundari'),
          updatedAt: Value(now),
        ),
      );

      // 3. Close/reopen semantics: read it back from SQLite
      final reloaded = await db.teacherDao.getProfile();
      expect(reloaded, isNotNull);
      expect(reloaded!.name, 'Test Teacher');
      expect(reloaded.school, 'Test School');

      // 4. Update teacher profile and verify persistence
      await db.teacherDao.insertOrUpdateProfile(
        TeachersCompanion(
          id: const Value('teacher_primary'),
          name: const Value('Test Teacher (Updated)'),
          school: const Value('Govt. Model School, Test District'),
          district: const Value('Test District'),
          state: const Value('Jharkhand'),
          classesTaughtJson: Value(jsonEncode([1, 2, 3, 4])),
          teachingLanguage: const Value('Hindi'),
          supportedLanguagesJson: Value(jsonEncode(['mundari', 'ho', 'santali'])),
          activeSessionLanguage: const Value('ho'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final updated = await db.teacherDao.getProfile();
      expect(updated!.name, 'Test Teacher (Updated)');
      expect(updated.activeSessionLanguage, 'ho');
    });

    test('Classrooms & NIPUN Curriculum: query outcomes and activities', () async {
      final classrooms = await db.select(db.classrooms).get();
      expect(classrooms.length, 5);

      final mathOutcomes = await db.curriculumDao.getOutcomes(grade: 2, domain: 'Foundational Numeracy');
      expect(mathOutcomes, isNotEmpty);
      expect(mathOutcomes.first.code, 'M2.1.4');

      final singleOutcome = await db.curriculumDao.getOutcomeByCode('M2.1.4');
      expect(singleOutcome, isNotNull);
      expect(singleOutcome!.titleEn, contains('100'));
    });

    test('Lessons & Delivery Progress: insert offline lesson and record step progress', () async {
      final now = DateTime.now();
      await db.lessonDao.insertOrUpdateLesson(
        LessonsCompanion(
          id: const Value('lp_test_01'),
          title: const Value('Tens and Ones with Seeds'),
          titleHi: const Value('दहाई और इकाई की समझ'),
          outcomeCode: const Value('M2.1.4'),
          outcomeTitle: const Value('Numbers up to 100'),
          grade: const Value(2),
          subject: const Value('Mathematics'),
          durationMinutes: const Value(40),
          learningObjective: const Value('Student counts in tens using tamarind seeds'),
          prerequisiteKnowledge: const Value('Counting 1-20'),
          teacherMoves: const Value('Demonstrate grouping in tens'),
          activityOverview: const Value('Hands on grouping'),
          assessmentStrategy: const Value('Oral check'),
          remediationOption: const Value('Bundle sticks with rubber bands'),
          tribalVocabularyJson: const Value('{"ten": "gel"}'),
          requiredMaterialsJson: const Value('["seeds", "chalk"]'),
          stepsJson: Value(jsonEncode([
            {'stepNumber': 1, 'title': 'Hook'},
            {'stepNumber': 2, 'title': 'Direct Instruction'},
          ])),
          createdAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value('PENDING'),
        ),
      );

      final lesson = await db.lessonDao.getLessonById('lp_test_01');
      expect(lesson, isNotNull);

      // Record delivery progress
      await db.lessonDao.updateDeliveryProgress(
        LessonDeliveryProgressCompanion(
          lessonId: const Value('lp_test_01'),
          currentStep: const Value(2),
          isCompleted: const Value(true),
          startedAt: Value(now),
          completedAt: Value(now),
        ),
      );

      final progress = await db.lessonDao.getDeliveryProgress('lp_test_01');
      expect(progress, isNotNull);
      expect(progress!.currentStep, 2);
      expect(progress.isCompleted, isTrue);
    });

    test('Assessments, Results & Learning Gaps: transactional write and query', () async {
      final now = DateTime.now();

      // Perform a transactional write: Assessment Result + Learning Gap + SyncQueue entry
      await db.transaction(() async {
        await db.assessmentDao.insertAssessmentResult(
          AssessmentResultsCompanion(
            id: const Value('res_test_01'),
            studentId: const Value('stu_1'),
            studentName: const Value('Birsa Munda'),
            outcomeCode: const Value('M2.1.4'),
            outcomeTitle: const Value('Numbers up to 100'),
            totalQuestions: const Value(4),
            correctCount: const Value(2),
            status: const Value('Emerging (Needs Support)'),
            unfinishedSkill: const Value('Regrouping tens and ones'),
            recommendedRemediation: const Value('Visual bundles of 10'),
            completedAt: Value(now),
            syncStatus: const Value('PENDING'),
          ),
        );

        await db.studentDao.insertOrUpdateLearningGap(
          LearningGapsCompanion(
            id: const Value('gap_test_01'),
            studentId: const Value('stu_1'),
            outcomeCode: const Value('M2.1.4'),
            skill: const Value('Numbers up to 100'),
            rootCause: const Value('Language confusion between Hindi and Mundari numerals'),
            remediationUsed: const Value('Concrete counters and bilingual audio scaffold'),
            status: const Value('Ongoing Intervention'),
            isResolved: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await db.syncQueueDao.enqueue(
          SyncQueueCompanion(
            id: const Value('sync_op_01'),
            entityType: const Value('assessment_result'),
            entityId: const Value('res_test_01'),
            operation: const Value('CREATE'),
            payload: const Value('{"score": 2, "passed": false}'),
            createdAt: Value(now),
            updatedAt: Value(now),
            status: const Value('PENDING'),
          ),
        );
      });

      // Verify Assessment Result
      final results = await db.assessmentDao.getAssessmentResultsForStudent('stu_1');
      expect(results.any((r) => r.id == 'res_test_01'), isTrue);

      // Verify Learning Gap
      final gaps = await db.studentDao.getLearningGapsByStudent('stu_1');
      expect(gaps.any((g) => g.id == 'gap_test_01'), isTrue);

      // Verify Sync Queue
      final pendingOps = await db.syncQueueDao.getPendingOperations();
      expect(pendingOps.any((op) => op.id == 'sync_op_01'), isTrue);
    });

    test('Saved Materials: insert worksheet and query', () async {
      final now = DateTime.now();
      await db.resourceDao.insertSavedMaterial(
        SavedMaterialsCompanion(
          id: const Value('mat_test_01'),
          type: const Value('worksheet'),
          title: const Value('Place Value Worksheet - Class 2'),
          titleHi: const Value('स्थान-मान कार्यपत्रक - कक्षा 2'),
          subject: const Value('Mathematics'),
          outcomeCode: const Value('M2.1.4'),
          difficulty: const Value('medium'),
          grade: const Value(2),
          language: const Value('mundari'),
          contentJson: const Value('{"items": [1, 2, 3]}'),
          createdAt: Value(now),
          isFavorite: const Value(true),
        ),
      );

      final materials = await db.resourceDao.getSavedMaterials(type: 'worksheet');
      expect(materials.any((m) => m.id == 'mat_test_01'), isTrue);
      expect(materials.firstWhere((m) => m.id == 'mat_test_01').isFavorite, isTrue);

      final totalCount = await db.resourceDao.getSavedMaterialsCount();
      expect(totalCount, greaterThanOrEqualTo(1));
    });
  });
}
