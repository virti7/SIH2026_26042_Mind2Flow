import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/app/app.dart';
import 'package:maatribhasha/app/di/injection.dart';
import 'package:maatribhasha/app/router/app_router.dart';
import 'package:maatribhasha/app/router/route_names.dart';
import 'package:maatribhasha/core/constants/app_constants.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/repositories/app_repositories.dart';
import 'package:maatribhasha/features/assessment/presentation/bloc/assessment_bloc.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    await setupDependencyInjection();
  });

  testWidgets('MaatribhashaApp launches cleanly with splash and branding', (WidgetTester tester) async {
    await tester.pumpWidget(const MaatribhashaApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Verify app name and tagline on splash
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.appHindiName), findsOneWidget);

    // Fast-forward past splash timer into onboarding
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Navigate to /home
    appRouter.go(AppRoutes.home);
    await tester.pumpAndSettle();

    // Navigate to /teach
    appRouter.go(AppRoutes.teach);
    await tester.pumpAndSettle();
  });

  test('AssessmentBloc executes complete diagnostic, remediation, and re-assessment loop', () async {
    final assessmentRepo = getIt<AssessmentRepository>();
    final studentRepo = getIt<StudentRepository>();

    // Explicit in-memory classroom fixture: production never seeds rosters.
    final db = getIt<AppDatabase>();
    final fixtureNow = DateTime.now();
    await db.studentDao.insertStudents([
      StudentsCompanion(
        id: const Value('stu_1'),
        name: const Value('Test Learner'),
        rollNumber: const Value(4),
        grade: const Value(2),
        motherTongue: const Value('santali'),
        achievedOutcomes: const Value(4),
        developingOutcomes: const Value(2),
        needsSupportOutcomes: const Value(1),
        literacyProgress: const Value(0.78),
        numeracyProgress: const Value(0.62),
        recentEvidence: const Value('Test fixture row for assessment loop.'),
        identifiedGapsJson: const Value('[]'),
        createdAt: Value(fixtureNow),
        updatedAt: Value(fixtureNow),
      ),
    ]);

    final bloc = AssessmentBloc(
      assessmentRepository: assessmentRepo,
      studentRepository: studentRepo,
    );

    // 1. Initial State
    expect(bloc.state, isA<AssessmentInitial>());

    // 2. Start Assessment for M2.1.4
    bloc.add(const StartAssessmentEvent(outcomeCode: 'M2.1.4', studentId: 'stu_1', studentName: 'Test Learner'));
    await Future.delayed(const Duration(milliseconds: 300));
    expect(bloc.state, isA<AssessmentActiveState>());

    final readyState = bloc.state as AssessmentActiveState;
    expect(readyState.questions.length, greaterThan(0));

    // 3. Answer questions (choose wrong answer index 0 to simulate diagnostic gap)
    bloc.add(const SelectAssessmentAnswerEvent(0, 0));
    bloc.add(SubmitAssessmentEvent());
    await Future.delayed(const Duration(milliseconds: 300));

    // 4. Expect AssessmentResultState
    expect(bloc.state, isA<AssessmentResultState>());
    final resultState = bloc.state as AssessmentResultState;
    expect(resultState.result.status, OutcomeStatus.needsSupport);

    // 5. Open Remediation Activity
    bloc.add(OpenRemedialActivityEvent());
    await Future.delayed(const Duration(milliseconds: 300));
    expect(bloc.state, isA<RemediationActiveState>());

    // 6. Start Re-assessment and submit successful demonstration
    bloc.add(StartReassessmentEvent());
    await Future.delayed(const Duration(milliseconds: 300));
    expect(bloc.state, isA<ReassessmentActiveState>());

    bloc.add(const SubmitReassessmentAnswerEvent(true));
    await Future.delayed(const Duration(milliseconds: 300));
    expect(bloc.state, isA<ReassessmentCompleteState>());
    final reState = bloc.state as ReassessmentCompleteState;
    expect(reState.newStatus, OutcomeStatus.achieved);

    // 7. Verify persistence in student repository
    final student = await studentRepo.getStudentById('stu_1');
    expect(student, isNotNull);
    expect(student!.achievedOutcomes, greaterThanOrEqualTo(4));

    await bloc.close();
  });
}
