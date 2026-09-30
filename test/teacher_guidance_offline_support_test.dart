import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:maatribhasha/app/router/route_names.dart';
import 'package:maatribhasha/core/content/prototype_content_repository.dart';
import 'package:maatribhasha/core/content/prototype_local_content_data_source.dart';
import 'package:maatribhasha/core/content/prototype_manifests.dart';
import 'package:maatribhasha/core/content/prototype_teacher_guidance_repository.dart';
import 'package:maatribhasha/core/content/teacher_guidance_models.dart';
import 'package:maatribhasha/core/repositories/mock_repositories.dart';
import 'package:maatribhasha/features/teach/presentation/bloc/teach_bloc.dart';
import 'package:maatribhasha/features/teach/presentation/pages/teach_home_screen.dart';
import 'package:maatribhasha/features/teach/presentation/pages/teacher_guidance_screen.dart';
import 'package:maatribhasha/features/teach/presentation/widgets/teacher_guidance_offline_card.dart';

/// AssetBundle that reports no prototype manifests (fresh install, teacher
/// has not added files yet). Never hits the network.
class _EmptyAssetBundle extends AssetBundle {
  _EmptyAssetBundle();

  @override
  Future<ByteData> load(String key) =>
      Future.error(FlutterError('not found: $key'));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      Future.error(FlutterError('not found: $key'));

  @override
  Future<T> loadStructuredData<T>(
          String key, Future<T> Function(String value) parser) =>
      Future.error(FlutterError('not found: $key'));

  @override
  void evict(String key) {}
}

/// Offline fake: returns ONLY bundled-style manifests, never touches
/// FastAPI / Supabase / Sarvam.
class _FakePrototypeRepo extends PrototypeContentRepository {
  final List<PrototypeFlashcardSetManifest> flashSets;
  final List<PrototypeAssessmentManifest> assessmentList;
  final List<PrototypeWorksheetManifest> worksheetList;

  _FakePrototypeRepo({
    this.flashSets = const [],
    this.assessmentList = const [],
    this.worksheetList = const [],
  }) : super(
          local: PrototypeLocalContentDataSource(
              bundle: _EmptyAssetBundle()),
          resources: MockResourceRepository(),
        );

  @override
  Future<List<PrototypeFlashcardSetManifest>>
      getPrototypeFlashcardSets() async => flashSets;

  @override
  Future<List<PrototypeAssessmentManifest>> getPrototypeAssessments() async =>
      assessmentList;

  @override
  Future<List<PrototypeWorksheetManifest>> getPrototypeWorksheets() async =>
      worksheetList;
}

const _matchingFlashcards = PrototypeFlashcardSetManifest(
  setId: 'class2_math_numbers_cards',
  title: 'Numbers up to 100',
  className: 'Class 2',
  subject: 'Mathematics',
  topic: 'Numbers up to 100',
  languagePair: ['Hindi', 'Santali'],
  cardCount: 5,
  coverImage: 'cover.png',
  setFile: 'class2_math_numbers_cards.json',
);

const _decoyFlashcards = PrototypeFlashcardSetManifest(
  setId: 'class5_lang_other',
  title: 'Other class content',
  className: 'Class 5',
  subject: 'Language',
  topic: 'Other',
  languagePair: ['Hindi', 'Santali'],
  cardCount: 9,
  coverImage: 'cover.png',
  setFile: 'class5_lang_other.json',
);

const _matchingAssessment = PrototypeAssessmentManifest(
  assessmentId: 'class2_math_numbers_check',
  className: 'Class 2',
  subject: 'Mathematics',
  topic: 'Numbers up to 100',
  language: 'Hindi + Santali',
  questions: [],
);

const _matchingWorksheet = PrototypeWorksheetManifest(
  id: 'class2_math_numbers',
  title: 'Numbers up to 100',
  className: 'Class 2',
  subject: 'Mathematics',
  topic: 'Numbers up to 100',
  languages: ['Hindi', 'Santali'],
  type: 'bilingual_worksheet',
  asset: 'assets/prototype_content/worksheets/pdf/class2_math_numbers.pdf',
);

/// In-memory bundle serving a single predefined guidance item so the
/// card -> Q&A navigation can be verified fully offline.
class _GuidanceBundle extends AssetBundle {
  _GuidanceBundle();

  static const _json = '''
{"version": 1, "items": [{
  "id": "numbers_up_to_100",
  "className": "Class 2",
  "subject": "Mathematics",
  "topic": "Numbers up to 100",
  "intent": "TEACHING_METHOD",
  "keywords": ["numbers", "100", "गिनती"],
  "questionPatterns": ["how should I teach numbers up to 100"],
  "answerHindi": "परीक्षण हिंदी उत्तर।",
  "answerEnglish": "Test English answer."
}]}''';

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (key == PrototypeTeacherGuidanceRepository.assetPath) {
      return Future.value(_json);
    }
    return Future.error(FlutterError('not found: $key'));
  }

  @override
  Future<ByteData> load(String key) =>
      Future.error(FlutterError('not found: $key'));

  @override
  Future<T> loadStructuredData<T>(
          String key, Future<T> Function(String value) parser) =>
      Future.error(FlutterError('not found: $key'));

  @override
  void evict(String key) {}
}

GoRoute _guidanceQaStubRoute() => GoRoute(
      path: AppRoutes.teacherGuidance,
      builder: (context, state) {
        final extra = state.extra;
        final map = extra is Map ? extra : const {};
        return TeacherGuidanceScreen(
          initialContext: TeacherGuidanceContext(
            className: map['className']?.toString(),
            subject: map['subject']?.toString(),
          ),
          repository: PrototypeTeacherGuidanceRepository(
              bundle: _GuidanceBundle()),
        );
      },
    );

/// Builds a minimal router hosting the card (or Teach screen) plus stub
/// destinations for the three existing-route actions.
Widget _cardHarness({
  int grade = 2,
  String subject = 'Mathematics',
  int outcomeCount = 3,
  PrototypeContentRepository? repo,
}) {
  final router = GoRouter(
    initialLocation: '/card',
    routes: [
      GoRoute(
        path: '/card',
        builder: (context, state) => Scaffold(
          body: SingleChildScrollView(
            child: TeacherGuidanceOfflineCard(
              selectedGrade: grade,
              selectedSubject: subject,
              outcomeCount: outcomeCount,
              prototypeRepository: repo,
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.nipunOutcomes,
        builder: (context, state) =>
            const Scaffold(body: Text('NIPUN Outcomes stub')),
      ),
      _guidanceQaStubRoute(),
      GoRoute(
        path: AppRoutes.downloads,
        builder: (context, state) =>
            const Scaffold(body: Text('Downloads stub')),
      ),
      GoRoute(
        path: AppRoutes.lessonPlanner,
        builder: (context, state) =>
            const Scaffold(body: Text('Lesson Planner stub')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

Widget _teachHarness(TeachBloc bloc) {
  final router = GoRouter(
    initialLocation: AppRoutes.teach,
    routes: [
      GoRoute(
        path: AppRoutes.teach,
        builder: (context, state) => BlocProvider.value(
          value: bloc,
          child: const TeachHomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.nipunOutcomes,
        builder: (context, state) =>
            const Scaffold(body: Text('NIPUN Outcomes stub')),
      ),
      _guidanceQaStubRoute(),
      GoRoute(
        path: AppRoutes.downloads,
        builder: (context, state) =>
            const Scaffold(body: Text('Downloads stub')),
      ),
      GoRoute(
        path: AppRoutes.lessonPlanner,
        builder: (context, state) =>
            const Scaffold(body: Text('Lesson Planner stub')),
      ),
    ],
  );
  return BlocProvider.value(
    value: bloc,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('TeacherGuidanceOfflineCard content', () {
    testWidgets('shows title, subtitle, offline indicator and context',
        (tester) async {
      await tester.pumpWidget(_cardHarness(repo: _FakePrototypeRepo()));
      await tester.pumpAndSettle();

      expect(find.text('Teacher Guidance & Offline Support'),
          findsOneWidget);
      expect(
          find.text(
              'Plan, teach and create classroom resources offline.'),
          findsOneWidget);
      expect(find.byKey(const Key('offlineReadyIndicator')), findsOneWidget);
      expect(find.text('Offline Ready'), findsOneWidget);
      expect(find.textContaining('Class 2'), findsWidgets);
      expect(find.textContaining('Mathematics'), findsWidgets);
      expect(find.text('NIPUN-aligned'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty local catalog shows "No offline materials yet"',
        (tester) async {
      await tester.pumpWidget(_cardHarness(repo: _FakePrototypeRepo()));
      await tester.pumpAndSettle();

      expect(find.text('No offline materials yet'), findsOneWidget);
      // No fake counts anywhere.
      expect(find.textContaining(RegExp(r'\d+ flashcards')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows real bundled counts filtered by class + subject',
        (tester) async {
      await tester.pumpWidget(_cardHarness(
        repo: _FakePrototypeRepo(
          flashSets: const [_matchingFlashcards, _decoyFlashcards],
          assessmentList: const [_matchingAssessment],
          worksheetList: const [_matchingWorksheet],
        ),
      ));
      await tester.pumpAndSettle();

      // Decoy (Class 5 / Language, 9 cards) must not leak in.
      expect(find.text('5 flashcards \u2022 1 visuals \u2022 1 assessments'),
          findsOneWidget);
      expect(find.text('No offline materials yet'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('TeacherGuidanceOfflineCard actions (existing routes, offline-safe)',
      () {
    testWidgets('Teaching Guidance opens offline Q&A with lesson context',
        (tester) async {
      await tester.pumpWidget(_cardHarness(repo: _FakePrototypeRepo()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('getTeachingGuidanceButton')));
      await tester.pumpAndSettle();
      // Q&A screen receives Class 2 • Mathematics via route extra.
      expect(find.text('Ask for teaching support'), findsOneWidget);
      expect(find.text('Class 2 • Mathematics'), findsOneWidget);
    });

    testWidgets('Offline Materials opens local downloads hub',
        (tester) async {
      await tester.pumpWidget(_cardHarness(repo: _FakePrototypeRepo()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
          find.byKey(const Key('offlineMaterialsButton')), 100);
      await tester.tap(find.byKey(const Key('offlineMaterialsButton')));
      await tester.pumpAndSettle();
      expect(find.text('Downloads stub'), findsOneWidget);
    });

    testWidgets('Continue Lesson opens guided lesson planner',
        (tester) async {
      await tester.pumpWidget(_cardHarness(repo: _FakePrototypeRepo()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
          find.byKey(const Key('continueLessonButton')), 100);
      await tester.tap(find.byKey(const Key('continueLessonButton')));
      await tester.pumpAndSettle();
      expect(find.text('Lesson Planner stub'), findsOneWidget);
    });

    testWidgets(
        'actions work with no repository registered (no backend needed)',
        (tester) async {
      // Null repo -> generic copy, navigation still fully local.
      await tester.pumpWidget(_cardHarness());
      await tester.pumpAndSettle();

      expect(
          find.text(
              'Flashcards \u2022 Visuals \u2022 Assessments'),
          findsOneWidget);
      await tester.tap(find.byKey(const Key('getTeachingGuidanceButton')));
      await tester.pumpAndSettle();
      expect(find.text('Ask for teaching support'), findsOneWidget);
    });
  });

  group('TeachHomeScreen integration', () {
    testWidgets('guidance section appears on Teach with live class context',
        (tester) async {
      final bloc = TeachBloc(lessonRepository: MockLessonRepository())
        ..add(const LoadCurriculumData(grade: 2));
      await tester.pumpWidget(_teachHarness(bloc));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('teacherGuidanceCard')), findsOneWidget);
      expect(find.text('Teacher Guidance & Offline Support'),
          findsOneWidget);
      // Existing Teach content is untouched.
      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Quick Access'), findsOneWidget);
      // Live context, not hardcoded: Class 2 + selected subject.
      expect(find.textContaining('Class 2'), findsWidgets);
      expect(find.textContaining('Mathematics'), findsWidgets);
      await bloc.close();
    });

    testWidgets('selected class context is preserved on class change',
        (tester) async {
      final bloc = TeachBloc(lessonRepository: MockLessonRepository())
        ..add(const LoadCurriculumData(grade: 2));
      await tester.pumpWidget(_teachHarness(bloc));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Class 4'), 200);
      await tester.tap(find.text('Class 4'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Class 4'), findsWidgets);
      await bloc.close();
    });

    testWidgets('selected subject context is preserved on subject tap',
        (tester) async {
      final bloc = TeachBloc(lessonRepository: MockLessonRepository())
        ..add(const LoadCurriculumData(grade: 2));
      await tester.pumpWidget(_teachHarness(bloc));
      await tester.pumpAndSettle();

      // Subject cards dispatch SelectSubject before navigating; the bloc
      // state (and therefore the card context) must reflect the choice.
      bloc.add(const SelectSubject('Language'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Language'), findsWidgets);
      await bloc.close();
    });

    testWidgets('card sits between Subjects and Quick Access in scroll order',
        (tester) async {
      final bloc = TeachBloc(lessonRepository: MockLessonRepository())
        ..add(const LoadCurriculumData(grade: 2));
      await tester.pumpWidget(_teachHarness(bloc));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
          find.byKey(const Key('teacherGuidanceCard')), 300);
      await tester.pumpAndSettle();
      final cardTop =
          tester.getTopLeft(find.byKey(const Key('teacherGuidanceCard'))).dy;
      final quickTop = tester.getTopLeft(find.text('Quick Access')).dy;
      expect(cardTop, lessThan(quickTop));
      await bloc.close();
    });

    testWidgets('card is never hidden behind the bottom navigation bar',
        (tester) async {
      final bloc = TeachBloc(lessonRepository: MockLessonRepository())
        ..add(const LoadCurriculumData(grade: 2));
      final router = GoRouter(
        initialLocation: AppRoutes.teach,
        routes: [
          GoRoute(
            path: AppRoutes.teach,
            builder: (context, state) => Scaffold(
              body: BlocProvider.value(
                value: bloc,
                child: const TeachHomeScreen(),
              ),
              bottomNavigationBar:
                  const BottomAppBar(child: Text('NavBar stub')),
            ),
          ),
        ],
      );
      await tester.pumpWidget(BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
          find.byKey(const Key('teacherGuidanceCard')), 300);
      await tester.pumpAndSettle();
      final cardBottom =
          tester.getBottomRight(find.byKey(const Key('teacherGuidanceCard')))
              .dy;
      final navTop = tester.getTopLeft(find.text('NavBar stub')).dy;
      expect(cardBottom, lessThanOrEqualTo(navTop));
      await bloc.close();
    });
  });

  group('responsive layout (no RenderFlex overflow)', () {
    for (final size in [
      const Size(360, 740), // narrow Android phone
      const Size(800, 1280), // tablet portrait
    ]) {
      testWidgets('guidance card fits ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_cardHarness(
          repo: _FakePrototypeRepo(
            flashSets: const [_matchingFlashcards],
            assessmentList: const [_matchingAssessment],
            worksheetList: const [_matchingWorksheet],
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('getTeachingGuidanceButton')),
            findsOneWidget);
        expect(find.byKey(const Key('offlineMaterialsButton')),
            findsOneWidget);
        expect(find.byKey(const Key('continueLessonButton')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Teach screen with card fits narrow phone', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = TeachBloc(lessonRepository: MockLessonRepository())
        ..add(const LoadCurriculumData(grade: 2));
      await tester.pumpWidget(_teachHarness(bloc));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('teacherGuidanceCard')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await bloc.close();
    });
  });
}
