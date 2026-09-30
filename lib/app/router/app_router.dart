import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../features/assessment/presentation/pages/assessment_screens.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/literacy/presentation/pages/foundational_literacy_screen.dart';
import '../../features/literacy/presentation/pages/literacy_screens.dart';
import '../../features/numeracy/presentation/pages/numeracy_screens.dart';
import '../../features/offline/presentation/pages/offline_status_center_screen.dart';
import '../../features/onboarding/presentation/pages/classroom_language_setup_screen.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/onboarding/presentation/pages/splash_screen.dart';
import '../../features/onboarding/presentation/pages/teacher_profile_setup_screen.dart';
import '../../features/profile/presentation/pages/teacher_profile_screen.dart';
import '../../features/progress/presentation/pages/progress_screens.dart';
import '../../features/resources/presentation/pages/resource_screens.dart';
import '../../features/resources/presentation/pages/flashcard_generator_screen.dart';
import '../../features/resources/presentation/pages/generated_flashcard_deck_screen.dart';
import '../../features/resources/presentation/pages/resource_viewer_screens.dart';
import '../../features/resources/presentation/pages/downloads_screen.dart';
import '../../features/settings/presentation/pages/settings_screens.dart';
import '../../features/teach/presentation/pages/class_overview_screen.dart';
import '../../features/teach/presentation/pages/lesson_delivery_screen.dart';
import '../../features/teach/presentation/pages/local_context_library_screen.dart';
import '../../features/teach/presentation/pages/nipun_lesson_planner_screen.dart';
import '../../features/teach/presentation/pages/nipun_outcome_selector_screen.dart';
import '../../features/teach/presentation/pages/teach_home_screen.dart';
import '../../features/teach/presentation/pages/teacher_copilot_screen.dart';
import '../../features/teach/presentation/pages/teacher_guidance_screen.dart';
import '../../features/smartboard/presentation/pages/smartboard_screen.dart';
import '../../features/translation/presentation/pages/translation_screens.dart';
import '../../features/translation/presentation/pages/reviewer/review_queue_screen.dart';
import '../../features/translation/presentation/pages/reviewer/review_detail_screen.dart';
import '../../features/translation/presentation/bloc/review_portal_bloc.dart';
import '../../features/resources/presentation/pages/resource_activity_detail_screen.dart';
import '../../features/translation/presentation/pages/new_sentence_translation_screen.dart';
import '../../features/translation/presentation/teacher_review/screens/teacher_review_screen.dart';
import '../../features/translation/presentation/teacher_review/screens/teacher_review_detail_screen.dart';
import '../../features/translation/presentation/teacher_review/models/teacher_review.dart';
import '../../features/progress/presentation/pages/student_list_screen.dart';
import '../../core/review/review_models.dart';
import '../../core/review/review_stores.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../features/progress/presentation/pages/student_sub_screens.dart';
import '../../features/offline/presentation/pages/offline_management_screens.dart';
import '../../features/settings/presentation/pages/settings_sub_screens.dart';
import '../../core/auth/domain/repositories/auth_repository.dart';
import '../../core/auth/presentation/pages/login_screen.dart';
import '../../core/auth/presentation/pages/signup_screen.dart';
import '../../core/copilot/widgets/copilot_button.dart';
import '../../core/copilot/widgets/copilot_chat_sheet.dart';
import '../di/injection.dart';
import '../../features/resources/presentation/pages/santali_flashcard_browser_screen.dart';
import '../../features/resources/presentation/pages/santali_flashcard_player_screen.dart';
import '../../core/content/teacher_guidance_models.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AuthRouterNotifier extends ChangeNotifier {
  StreamSubscription<bool>? _sub;

  AuthRouterNotifier() {
    if (getIt.isRegistered<AuthRepository>()) {
      _sub = getIt<AuthRepository>().authStateChanges.listen((_) {
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  // TEMPORARY startup-navigation diagnostic: logs every redirect/match so a
  // duplicate-page-key crash can be traced to the exact navigation sequence.
  // Debug builds only; remove once the cold-start crash is root-caused.
  debugLogDiagnostics: kDebugMode,
  refreshListenable: AuthRouterNotifier(),
  redirect: (context, state) {
    if (!getIt.isRegistered<AuthRepository>()) {
      return null;
    }
    // Authentication state is based on the Supabase session only.
    // "FastAPI unavailable" must never be interpreted as unauthenticated:
    // a valid Supabase session always routes to Home.
    final authRepo = getIt<AuthRepository>();
    final isAuth = authRepo.isAuthenticated;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.signup;

    // Authenticated teachers must not remain on login or signup pages
    if (isAuth && isAuthRoute) {
      return AppRoutes.home;
    }

    // Unauthenticated/unprovisioned users cannot access protected routes
    if (!isAuth && !isAuthRoute && loc != AppRoutes.splash && loc != AppRoutes.onboarding) {
      return AppRoutes.login;
    }

    return null;
  },
  routes: [
    // Entry / Onboarding / Auth
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.teacherSetup,
      builder: (context, state) {
        final extra = state.extra;
        final completion = extra is Map && extra['completion'] == true;
        return TeacherProfileSetupScreen(isCompletion: completion);
      },
    ),
    GoRoute(
      path: AppRoutes.languageSetup,
      builder: (context, state) => const ClassroomLanguageSetupScreen(),
    ),

    // Bottom Navigation Shell (6 Primary Tabs)
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) {
        final loc = state.matchedLocation;
        int index = 0;
        if (loc.startsWith(AppRoutes.teach) || loc.startsWith('/literacy') || loc.startsWith('/numeracy')) {
          index = 1;
        } else if (loc.startsWith(AppRoutes.translate)) {
          index = 2;
        } else if (loc.startsWith(AppRoutes.progress)) {
          index = 3;
        } else if (loc.startsWith(AppRoutes.downloads)) {
          index = 4;
        } else if (loc.startsWith(AppRoutes.profile) || loc.startsWith(AppRoutes.settings)) {
          index = 5;
        }

        // Bottom navigation always stays BELOW content on every screen size.
        // Never a side navigation — wide screens simply center the content.
        // The offline Teacher Co-Pilot pill floats bottom-right ABOVE the
        // navigation bar (never overlapping it) on all six primary tabs.
        return Scaffold(
          body: Stack(
            children: [
              child,
              Positioned(
                right: 16,
                bottom: 12,
                child: CopilotButton(
                  onTap: () => showCopilotSheet(context),
                ),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: index,
            onTap: (newIdx) {
              switch (newIdx) {
                case 0:
                  context.go(AppRoutes.home);
                  break;
                case 1:
                  context.go(AppRoutes.teach);
                  break;
                case 2:
                  context.go(AppRoutes.translate);
                  break;
                case 3:
                  context.go(AppRoutes.progress);
                  break;
                case 4:
                  context.go(AppRoutes.downloads);
                  break;
                case 5:
                  context.go(AppRoutes.settings);
                  break;
              }
            },
          ),
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.teach,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const TeachHomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.translate,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const TranslateHomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.progress,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ProgressHomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.downloads,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const DownloadsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
          ),
        ),
      ],
    ),

    // Teach Flow Routes
    GoRoute(
      path: '/teach/class/:classId',
      builder: (context, state) {
        final classId = int.tryParse(state.pathParameters['classId'] ?? '2') ?? 2;
        return ClassOverviewScreen(classId: classId);
      },
    ),
    GoRoute(
      path: '/teach/subject/:subjectId',
      builder: (context, state) {
        final subjectId = state.pathParameters['subjectId'] ?? 'math';
        if (subjectId.toLowerCase() == 'language' || subjectId.toLowerCase() == 'literacy') {
          return const FoundationalLiteracyScreen();
        }
        return SubjectDetailScreen(subjectId: subjectId);
      },
    ),
    GoRoute(
      path: AppRoutes.nipunOutcomes,
      builder: (context, state) => const NipunOutcomeSelectorScreen(),
    ),
    GoRoute(
      path: AppRoutes.lessonPlanner,
      builder: (context, state) => const NipunLessonPlannerScreen(),
    ),
    GoRoute(
      path: '/teach/lesson/:lessonId',
      builder: (context, state) {
        final lessonId = state.pathParameters['lessonId'] ?? 'lp_m2_1_4';
        return LessonDetailScreen(lessonId: lessonId);
      },
    ),
    GoRoute(
      path: '/teach/lesson/:lessonId/delivery',
      builder: (context, state) {
        final lessonId = state.pathParameters['lessonId'] ?? 'lp_m2_1_4';
        return LessonDeliveryScreen(lessonId: lessonId);
      },
    ),
    GoRoute(
      path: AppRoutes.teacherCopilot,
      builder: (context, state) => const TeacherCopilotScreen(),
    ),
    GoRoute(
      // Deterministic offline Teacher Guidance Q&A. Lesson context rides
      // in `extra` (never hardcoded); the screen falls back to the live
      // TeachBloc selection when extra is absent.
      path: AppRoutes.teacherGuidance,
      builder: (context, state) {
        final extra = state.extra;
        TeacherGuidanceContext ctx = const TeacherGuidanceContext();
        if (extra is Map) {
          ctx = TeacherGuidanceContext(
            className: extra['className']?.toString(),
            subject: extra['subject']?.toString(),
            topic: extra['topic']?.toString(),
            learningOutcome: extra['learningOutcome']?.toString(),
          );
        }
        return TeacherGuidanceScreen(initialContext: ctx);
      },
    ),
    GoRoute(
      path: AppRoutes.localContext,
      builder: (context, state) => const LocalContextLibraryScreen(),
    ),
    GoRoute(
      // Maatribhasha SmartBoard: interactive classroom whiteboard prototype
      // (offline Hindi/English → Santali). Same-screen tabs; no subroutes.
      path: AppRoutes.smartboard,
      builder: (context, state) => const SmartBoardScreen(),
    ),

    // Foundational Literacy Routes
    GoRoute(
      path: AppRoutes.literacy,
      builder: (context, state) => const FoundationalLiteracyScreen(),
    ),
    GoRoute(
      path: AppRoutes.oralLanguage,
      builder: (context, state) => const OralLanguageLibraryScreen(),
    ),
    GoRoute(
      path: AppRoutes.decoding,
      builder: (context, state) => const DecodingLibraryScreen(),
    ),
    GoRoute(
      path: AppRoutes.readingComprehension,
      builder: (context, state) => const ReadingComprehensionLibraryScreen(),
    ),
    GoRoute(
      path: AppRoutes.writingExpression,
      builder: (context, state) => const WritingExpressionLibraryScreen(),
    ),
    GoRoute(
      path: '/literacy/activity/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'act_003';
        return LiteracyActivityDetailScreen(activityId: id);
      },
    ),

    // Foundational Numeracy Routes
    GoRoute(
      path: AppRoutes.oralMath,
      builder: (context, state) => const OralMathTalkLibraryScreen(),
    ),
    GoRoute(
      path: AppRoutes.skillsTeaching,
      builder: (context, state) => const SkillsTeachingLibraryScreen(),
    ),
    GoRoute(
      path: AppRoutes.skillsPractice,
      builder: (context, state) => const SkillsPracticeLibraryScreen(),
    ),
    GoRoute(
      path: AppRoutes.mathGames,
      builder: (context, state) => const MathGamesLibraryScreen(),
    ),
    GoRoute(
      path: '/numeracy/activity/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'act_001';
        return NumeracyActivityDetailScreen(activityId: id);
      },
    ),

    // Multilingual Resource Routes
    GoRoute(
      path: AppRoutes.topicDetail,
      builder: (context, state) => const TopicResourceDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.worksheetGenerator,
      builder: (context, state) => const BilingualWorksheetGeneratorScreen(),
    ),
    GoRoute(
      path: AppRoutes.worksheetPreview,
      builder: (context, state) => const WorksheetPreviewScreen(),
    ),
    GoRoute(
      path: AppRoutes.flashcardGenerator,
      builder: (context, state) => const SantaliFlashcardGeneratorScreen(),
    ),
    GoRoute(
      path: AppRoutes.flashcardViewer,
      builder: (context, state) {
        final deckId = state.uri.queryParameters['deck'];
        if (deckId != null && deckId.isNotEmpty) {
          return SantaliFlashcardPlayerScreen(initialDeckId: deckId);
        }
        // Every "Flashcards" entry point opens the same generator as
        // Teach > Flashcards (library pictures offline, AI online).
        return const SantaliFlashcardGeneratorScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.flashcardDeck,
      builder: (context, state) {
        final args = state.extra is GeneratedFlashcardDeckArgs
            ? state.extra as GeneratedFlashcardDeckArgs
            : null;
        return GeneratedFlashcardDeckScreen(
          payload: args?.payload,
          assets: args?.assets,
          contentId: args?.contentId,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.flashcardDeckBrowser,
      builder: (context, state) => const SantaliFlashcardBrowserScreen(),
    ),
    GoRoute(
      path: AppRoutes.flashcardPlayer,
      builder: (context, state) {
        final deckId = state.uri.queryParameters['deck'];
        return SantaliFlashcardPlayerScreen(initialDeckId: deckId);
      },
    ),
    GoRoute(
      path: AppRoutes.flashcardPlayerDetail,
      builder: (context, state) {
        final deckId = state.pathParameters['deckId'];
        return SantaliFlashcardPlayerScreen(initialDeckId: deckId);
      },
    ),
    GoRoute(
      path: AppRoutes.activityLibrary,
      builder: (context, state) => const ActivityLibraryScreen(),
    ),
    GoRoute(
      path: '/resources/activity/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'act_001';
        return ResourceActivityDetailScreen(activityId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.savedMaterials,
      builder: (context, state) => const SavedMaterialsScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.downloads}/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return DownloadDetailsScreen(resourceId: id);
      },
    ),
    GoRoute(
      path: '${AppRoutes.downloads}/:id/read',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return DownloadReaderScreen(resourceId: id);
      },
    ),

    // Assessment & Remediation Loop
    GoRoute(
      path: AppRoutes.assessmentBuilder,
      builder: (context, state) => const AssessmentBuilderScreen(),
    ),
    GoRoute(
      path: AppRoutes.assessmentPlay,
      builder: (context, state) => const AssessmentPlayScreen(),
    ),
    GoRoute(
      path: AppRoutes.assessmentResult,
      builder: (context, state) => const AssessmentResultScreen(),
    ),
    GoRoute(
      path: AppRoutes.learningGap,
      builder: (context, state) => const LearningGapAnalysisScreen(),
    ),
    GoRoute(
      path: AppRoutes.remediation,
      builder: (context, state) => const RemedialActivityScreen(),
    ),
    GoRoute(
      path: AppRoutes.reassessment,
      builder: (context, state) => const ReassessmentScreen(),
    ),

    // Translate Subroutes
    GoRoute(
      path: AppRoutes.translateContext,
      builder: (context, state) => const ContextAwareTranslationScreen(),
    ),
    GoRoute(
      path: AppRoutes.languageRouter,
      builder: (context, state) => const ClassroomLanguageRouterScreen(),
    ),
    GoRoute(
      path: AppRoutes.studentResponse,
      builder: (context, state) => const StudentResponseScreen(),
    ),
    GoRoute(
      path: AppRoutes.twoWayConversation,
      builder: (context, state) => const TwoWayConversationScreen(),
    ),
    GoRoute(
      path: AppRoutes.quickPhrases,
      builder: (context, state) => const QuickPhraseBankScreen(),
    ),
    GoRoute(
      path: AppRoutes.newSentence,
      builder: (context, state) => const NewSentenceTranslationScreen(),
    ),
    GoRoute(
      path: AppRoutes.translationFeedback,
      builder: (context, state) => const TranslationFeedbackScreen(),
    ),

    // Reviewer Portal (Translation Review Loop)
    GoRoute(
      path: AppRoutes.reviewerPortal,
      builder: (context, state) => BlocProvider(
        create: (_) => ReviewPortalBloc(
          queueStore: getIt<ReviewQueueStore>(),
          memoryStore: getIt<TranslationMemoryStore>(),
          noticeStore: getIt<CorrectionNoticeStore>(),
        )..add(const LoadReviewQueue()),
        child: const ReviewQueueScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.reviewDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final item = extra?['item'] as ReviewItem?;
        return ReviewDetailScreen(
          reviewItem: item ?? ReviewItem(
            id: 'RV-000',
            phraseId: 'phrase_001',
            direction: ReviewDirection.santaliToHindi,
            originalText: '',
            originalRoman: '',
            translatedText: '',
            translatedRoman: '',
            confidenceScore: 0,
            priority: ReviewPriority.low,
            context: const ReviewContext(),
            reason: '',
            createdAt: DateTime.now(),
          ),
        );
      },
    ),

    // Teacher Review Portal (Separate from Reviewer Portal)
    GoRoute(
      path: AppRoutes.teacherReview,
      builder: (context, state) => const TeacherReviewScreen(),
    ),
    GoRoute(
      path: AppRoutes.teacherReviewDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        // In a real app, you'd fetch the review by ID from the repository
        // For demo, we'll pass the review in extra
        final review = extra?['review'] as TeacherReview?;
        if (review != null) {
          return TeacherReviewDetailScreen(review: review);
        }
        // Fallback - shouldn't happen in normal flow
        return const TeacherReviewScreen();
      },
    ),

    // Progress Subroutes (Individual Learners Only)
    GoRoute(
      path: AppRoutes.studentList,
      builder: (context, state) => const StudentListScreen(),
    ),
    GoRoute(
      path: '/progress/student/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'stu_1';
        return StudentLearningProfileScreen(studentId: id);
      },
    ),
    GoRoute(
      path: '/progress/student/:id/subject',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'stu_1';
        return SubjectProgressScreen(studentId: id);
      },
    ),
    GoRoute(
      path: '/progress/student/:id/assessments',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'stu_1';
        return AssessmentHistoryScreen(studentId: id);
      },
    ),
    GoRoute(
      path: '/progress/student/:id/gaps',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'stu_1';
        return LearningGapHistoryScreen(studentId: id);
      },
    ),
    GoRoute(
      path: '/progress/student/:id/recommendations',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'stu_1';
        return RecommendedLessonsScreen(studentId: id);
      },
    ),

    // Offline / Device / Settings Subroutes
    GoRoute(
      path: AppRoutes.offlineStatus,
      builder: (context, state) => const OfflineStatusCenterScreen(),
    ),
    GoRoute(
      path: AppRoutes.initialProvisioning,
      builder: (context, state) => const InitialProvisioningScreen(),
    ),
    GoRoute(
      path: AppRoutes.languagePacks,
      builder: (context, state) => const LanguagePackManagerScreen(),
    ),
    GoRoute(
      path: AppRoutes.contentPacks,
      builder: (context, state) => const ContentPackManagerScreen(),
    ),
    GoRoute(
      path: AppRoutes.syncUpdates,
      builder: (context, state) => const SyncUpdatesScreen(),
    ),
    GoRoute(
      path: AppRoutes.offlineStorage,
      builder: (context, state) => const OfflineStorageScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const TeacherProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.languageSettings,
      builder: (context, state) => const LanguageSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.audioSettings,
      builder: (context, state) => const AudioSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.classroomSettings,
      builder: (context, state) => const ClassroomSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.about,
      builder: (context, state) => const AboutHelpScreen(),
    ),
  ],
);
