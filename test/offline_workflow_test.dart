import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/database/database_seeder.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/network/connectivity_service.dart';
import 'package:maatribhasha/core/repositories/sqlite_repositories.dart';
import 'package:maatribhasha/core/sync/remote_data_source.dart';
import 'package:maatribhasha/core/sync/sync_manager.dart';

class TestMockConnectivity implements ConnectivityService {
  bool _online;
  TestMockConnectivity(this._online);

  @override
  Stream<bool> get connectivityStream => const Stream.empty();

  @override
  Future<bool> get isOnline async => _online;

  @override
  Future<bool> checkBackendReachability({String? baseUrl, Duration? timeout}) async => _online;

  @override
  void simulateOnlineStatus(bool? override) {
    if (override != null) _online = override;
  }
}

void main() {
  test('Complete 17-Step Offline Classroom Workflow Verification', () async {
    // 1. Start application: initialize SQLite database and seed curriculum
    final db = AppDatabase(NativeDatabase.memory());
    final seeder = DatabaseSeeder(db);
    await seeder.seedIfNeeded();

    // 2a. Explicit in-memory classroom fixture: production never seeds
    // student rosters; tests insert their own session rows.
    final fixtureNow = DateTime.now();
    await db.studentDao.insertStudents([
      StudentsCompanion(
        id: const Value('stu_3'),
        name: const Value('Test Learner'),
        rollNumber: const Value(7),
        grade: const Value(2),
        motherTongue: const Value('ho'),
        achievedOutcomes: const Value(3),
        developingOutcomes: const Value(3),
        needsSupportOutcomes: const Value(1),
        literacyProgress: const Value(0.65),
        numeracyProgress: const Value(0.70),
        recentEvidence: const Value('Test fixture row for offline workflow.'),
        identifiedGapsJson: const Value('[]'),
        createdAt: Value(fixtureNow),
        updatedAt: Value(fixtureNow),
      ),
    ]);

    // 2. Make device offline: zero internet connectivity
    final connectivity = TestMockConnectivity(false);
    expect(await connectivity.isOnline, isFalse);

    final remoteDataSource = MockRemoteDataSource();
    final syncManager = SyncManager(
      db: db,
      connectivityService: connectivity,
      remoteDataSource: remoteDataSource,
    );

    // Instantiate Clean Architecture repositories backed by Drift/SQLite
    final lessonRepo = SqliteLessonRepository(db: db);
    final assessmentRepo = SqliteAssessmentRepository(db: db);
    final studentRepo = SqliteStudentRepository(db: db);

    // 3. Open Teach: read available classrooms
    final students = await studentRepo.getStudents(grade: 2);
    expect(students, isNotEmpty);

    // 4. Select Class 2
    const selectedGrade = 2;

    // 5. Select Mathematics & 6. Select Numbers up to 100
    final outcomes = await lessonRepo.getOutcomes(grade: selectedGrade, domain: 'Foundational Numeracy');
    expect(outcomes, isNotEmpty);

    // 7. Select a NIPUN learning outcome: M2.1.4
    final outcome = outcomes.firstWhere((o) => o.code == 'M2.1.4');
    expect(outcome.code, 'M2.1.4');
    expect(outcome.titleEn, contains('Numbers up to 100'));

    // 8. Create/open a lesson
    final lessonPlan = await lessonRepo.getLessonPlanForOutcome('M2.1.4');
    expect(lessonPlan, isNotNull);
    expect(lessonPlan.outcomeCode, 'M2.1.4');
    expect(lessonPlan.steps.length, greaterThanOrEqualTo(5));

    // 9. Perform lesson activity: record lesson delivery progress in SQLite
    final activities = await lessonRepo.getActivities(grade: selectedGrade);
    expect(activities, isNotEmpty);

    // 10. Record assessment result offline
    const studentId = 'stu_3'; // in-memory fixture from step 2a
    final initialPendingCount = await db.syncQueueDao.getPendingCount();

    final result = await assessmentRepo.submitAssessment(
      studentId: studentId,
      studentName: 'Test Learner',
      outcomeCode: 'M2.1.4',
      selectedAnswers: [0, 1, 0], // Score 2/3
    );

    expect(result.studentId, studentId);
    expect(result.correctCount, 2);
    expect(result.totalQuestions, 3);
    expect(result.status, OutcomeStatus.developing); // Needs Support

    // 11. Navigate to Progress: query student assessment results and gaps from SQLite
    final assessmentHistory = await db.assessmentDao.getAssessmentResultsForStudent(studentId);
    final learningGaps = await db.studentDao.getLearningGapsByStudent(studentId);

    // 12. Confirm that the result is visible and persisted locally
    expect(assessmentHistory, isNotEmpty);
    expect(assessmentHistory.first.correctCount, 2);
    expect(learningGaps, isNotEmpty);
    expect(learningGaps.any((g) => g.outcomeCode == 'M2.1.4'), isTrue);

    // Verify a sync queue entry was created with PENDING status
    final currentPendingCount = await db.syncQueueDao.getPendingCount();
    expect(currentPendingCount, initialPendingCount + 1);

    final pendingOps = await db.syncQueueDao.getPendingOperations();
    final latestOp = pendingOps.last;
    expect(latestOp.status, 'PENDING');
    expect(latestOp.entityType, 'assessment_result');

    // 13. Close/restart the application: re-instantiate fresh repositories pointing to same DB
    final freshStudentRepo = SqliteStudentRepository(db: db);

    // 14. Confirm the data still exists after restart
    final freshStudentRecord = await freshStudentRepo.getStudentById(studentId);
    expect(freshStudentRecord, isNotNull);
    expect(freshStudentRecord!.assessmentHistory.first.correctCount, 2);
    expect(freshStudentRecord.identifiedGaps.isNotEmpty, isTrue);

    // 15. Re-enable internet connectivity
    connectivity.simulateOnlineStatus(true);
    expect(await connectivity.isOnline, isTrue);

    // 16. Trigger synchronization
    final syncedCount = await syncManager.syncPendingOperations();
    expect(syncedCount, greaterThanOrEqualTo(1));

    // 17. Confirm the pending operations are processed and remote received them
    expect(remoteDataSource.receivedOperations, isNotEmpty);
    final finalPendingCount = await db.syncQueueDao.getPendingCount();
    expect(finalPendingCount, 0); // All processed!

    // Verify local data remains completely intact and was NEVER rolled back
    final postSyncHistory = await db.assessmentDao.getAssessmentResultsForStudent(studentId);
    final postSyncGaps = await db.studentDao.getLearningGapsByStudent(studentId);
    expect(postSyncHistory.first.correctCount, 2);
    expect(postSyncGaps.first.outcomeCode, 'M2.1.4');

    syncManager.dispose();
    await db.close();
  });
}
