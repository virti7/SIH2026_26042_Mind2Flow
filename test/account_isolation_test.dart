import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/database/account_scope.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/models/app_models.dart';
import 'package:maatribhasha/core/repositories/sqlite_repositories.dart';
import 'package:maatribhasha/core/repositories/teacher_activity_repository.dart';

/// Multi-account isolation regression test:
/// A login -> create data -> logout -> B login sees only B data ->
/// logout -> A login sees only A data.
void main() {
  const userA = 'user-uuid-aaaa-teacher-a';
  const userB = 'user-uuid-bbbb-teacher-b';

  String? activeUser;
  String? owner() => activeUser;

  late AppDatabase db;
  late SqliteTeacherRepository teachers;
  late SqliteResourceRepository resources;
  late SqliteTeacherActivityRepository activity;

  setUp(() async {
    activeUser = null;
    db = AppDatabase(NativeDatabase.memory());
    await ensureAccountIsolation(db);
    teachers =
        SqliteTeacherRepository(db: db, currentUserIdProvider: owner);
    resources =
        SqliteResourceRepository(db: db, currentUserIdProvider: owner);
    activity =
        SqliteTeacherActivityRepository(db: db, currentUserIdProvider: owner);
  });

  tearDown(() async {
    await db.close();
  });

  TeacherProfile profileFor(String id, String name, String school) =>
      TeacherProfile(
        id: id,
        name: name,
        school: school,
        district: 'Ranchi',
        state: 'Jharkhand',
        classesTaught: const [1, 2, 3],
        teachingLanguage: 'Hindi',
        supportedClassroomLanguages: const [TribalLanguage.mundari],
        activeSessionLanguage: TribalLanguage.mundari,
      );

  WorksheetItem worksheet(String id, String title) => WorksheetItem(
        id: id,
        title: title,
        titleHi: title,
        grade: 2,
        subject: 'Math',
        outcomeCode: 'M2.1.4',
        targetLanguage: TribalLanguage.mundari,
        difficulty: DifficultyLevel.easy,
        type: WorksheetType.practice,
        questionCount: 1,
        questions: const [
          WorksheetQuestion(
            questionNumber: 1,
            promptHindi: 'q',
            promptTribal: 'q',
            visualIllustration: '',
            options: ['a'],
            answer: 'a',
          ),
        ],
        createdAt: DateTime(2026, 1, 1),
      );

  test('A -> logout -> B -> logout -> A sees only own data', () async {
    // Login A, create A's data.
    activeUser = userA;
    await teachers.updateProfile(profileFor(userA, 'Teacher A', 'School A'));
    await resources.saveWorksheet(worksheet('ws-a', 'Worksheet A'));
    // Progress via repository (namespaced per owner).
    final lessonRepo =
        SqliteLessonRepository(db: db, currentUserIdProvider: owner);
    await lessonRepo.updateLessonDeliveryProgress('lesson-1', 3, true);

    expect((await teachers.getProfile()).name, 'Teacher A');
    expect((await teachers.getProfile()).school, 'School A');
    expect(
        (await resources.getSavedWorksheets()).map((w) => w.id), contains('ws-a'));
    expect(await lessonRepo.getLessonDeliveryProgress('lesson-1'),
        isNotNull);

    // Logout A (unauthenticated): no account data leaks.
    activeUser = null;
    expect((await teachers.getProfile()).name, isEmpty);
    expect(await resources.getSavedWorksheets(), isEmpty);
    expect(await lessonRepo.getLessonDeliveryProgress('lesson-1'), isNull);
    expect((await activity.getSummary()).worksheetsGenerated, 0);
    expect((await activity.getSummary()).lessonsTaught, 0);

    // Login B: brand-new empty state, none of A's data.
    activeUser = userB;
    expect((await teachers.getProfile()).name, isEmpty);
    expect((await teachers.getProfile()).school, isEmpty);
    expect(await resources.getSavedWorksheets(), isEmpty);
    expect(await lessonRepo.getLessonDeliveryProgress('lesson-1'), isNull);
    final summaryB = await activity.getSummary();
    expect(summaryB.worksheetsGenerated, 0);
    expect(summaryB.lessonsTaught, 0);

    // B creates own data.
    await teachers.updateProfile(profileFor(userB, 'Teacher B', 'School B'));
    await resources.saveWorksheet(worksheet('ws-b', 'Worksheet B'));
    await lessonRepo.updateLessonDeliveryProgress('lesson-1', 1, false);
    expect((await teachers.getProfile()).name, 'Teacher B');
    expect(
        (await resources.getSavedWorksheets()).map((w) => w.id), contains('ws-b'));
    expect((await resources.getSavedWorksheets()).map((w) => w.id),
        isNot(contains('ws-a')));

    // Logout B, login A again: A sees only A data.
    activeUser = null;
    expect(await resources.getSavedWorksheets(), isEmpty);
    activeUser = userA;
    expect((await teachers.getProfile()).name, 'Teacher A');
    expect((await teachers.getProfile()).school, 'School A');
    final aSheets = await resources.getSavedWorksheets();
    expect(aSheets.map((w) => w.id), contains('ws-a'));
    expect(aSheets.map((w) => w.id), isNot(contains('ws-b')));
    final aProgress = await lessonRepo.getLessonDeliveryProgress('lesson-1');
    expect(aProgress, isNotNull);
    expect(aProgress!['isCompleted'], isTrue);
    expect(aProgress['currentStep'], 3);
  });

  test('sync queue rows are tagged per owner', () async {
    activeUser = userA;
    await teachers.updateProfile(profileFor(userA, 'Teacher A', 'School A'));
    activeUser = userB;
    await teachers.updateProfile(profileFor(userB, 'Teacher B', 'School B'));

    final rows = await db.customSelect('SELECT entity_id, owner_user_id FROM sync_queue').get();
    final byEntity = {for (final r in rows) r.data['entity_id'].toString(): r.data['owner_user_id'].toString()};
    expect(byEntity[userA], userA);
    expect(byEntity[userB], userB);
  });
}
