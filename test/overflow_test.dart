import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/app/app.dart';
import 'package:maatribhasha/app/di/injection.dart';
import 'package:maatribhasha/app/router/app_router.dart';
import 'package:maatribhasha/app/router/route_names.dart';

import 'dart:async';
import 'package:maatribhasha/core/network/connectivity_service.dart';

class TestConnectivityService implements ConnectivityService {
  final _ctrl = StreamController<bool>.broadcast();
  @override
  Stream<bool> get connectivityStream => _ctrl.stream;
  @override
  Future<bool> get isOnline async => false;
  @override
  Future<bool> checkBackendReachability({String? baseUrl, Duration? timeout}) async => false;
  @override
  void simulateOnlineStatus(bool? override) {}
}

void main() {
  setUp(() async {
    await getIt.reset();
    await setupDependencyInjection(
      connectivityService: TestConnectivityService(),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  const routesToTest = [
    AppRoutes.home,
    AppRoutes.teach,
    AppRoutes.translate,
    AppRoutes.progress,
    AppRoutes.settings,
    '/teach/class/2',
    '/teach/subject/math',
    AppRoutes.nipunOutcomes,
    AppRoutes.lessonPlanner,
    '/teach/lesson/lp_m2_1_4',
    '/teach/lesson/lp_m2_1_4/delivery',
    AppRoutes.teacherCopilot,
    AppRoutes.teacherGuidance,
    AppRoutes.localContext,
    AppRoutes.literacy,
    AppRoutes.oralLanguage,
    AppRoutes.decoding,
    AppRoutes.readingComprehension,
    AppRoutes.writingExpression,
    '/literacy/activity/act_lit_1',
    AppRoutes.oralMath,
    AppRoutes.skillsTeaching,
    AppRoutes.skillsPractice,
    AppRoutes.mathGames,
    '/numeracy/activity/act_num_1',
    AppRoutes.topicDetail,
    AppRoutes.worksheetGenerator,
    AppRoutes.worksheetPreview,
    AppRoutes.flashcardGenerator,
    AppRoutes.flashcardViewer,
    AppRoutes.activityLibrary,
    '/resources/activity/act_1',
    AppRoutes.savedMaterials,
    AppRoutes.assessmentBuilder,
    AppRoutes.assessmentPlay,
    AppRoutes.assessmentResult,
    AppRoutes.learningGap,
    AppRoutes.remediation,
    AppRoutes.reassessment,
    AppRoutes.translateContext,
    AppRoutes.languageRouter,
    AppRoutes.studentResponse,
    AppRoutes.twoWayConversation,
    AppRoutes.quickPhrases,
    AppRoutes.newSentence,
    AppRoutes.translationFeedback,
    AppRoutes.studentList,
    '/progress/student/stu_1',
    '/progress/student/stu_1/subject',
    '/progress/student/stu_1/assessments',
    '/progress/student/stu_1/gaps',
    '/progress/student/stu_1/recommendations',
    AppRoutes.initialProvisioning,
    AppRoutes.languagePacks,
    AppRoutes.contentPacks,
    AppRoutes.syncUpdates,
    AppRoutes.offlineStorage,
    AppRoutes.languageSettings,
    AppRoutes.audioSettings,
    AppRoutes.classroomSettings,
    AppRoutes.about,
    AppRoutes.profile,
    AppRoutes.offlineStatus,
    AppRoutes.teacherSetup,
    AppRoutes.languageSetup,
  ];

  for (final size in [
    const Size(400, 823),  // User device viewport (reported failure)
    const Size(390, 844),  // Mobile Phone
    const Size(430, 932),  // Large Mobile Phone
    const Size(768, 1024), // Standard Tablet
    const Size(800, 1280), // Tablet Portrait
    const Size(1024, 1366), // Large Tablet / Desktop
  ]) {
    testWidgets('Check all screens for overflows at ${size.width}x${size.height}', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaatribhashaApp());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump();

      for (final route in routesToTest) {
        appRouter.go(route);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });
  }
}
