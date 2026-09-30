import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/constants/app_constants.dart';
import '../core/content/prototype_demo_translation.dart';
import '../core/content/santali_audio_player.dart';
import '../core/repositories/app_repositories.dart';
import '../core/repositories/teacher_activity_repository.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/domain/usecases/lesson_usecases.dart';
import '../core/review/review_stores.dart';
import '../features/assessment/presentation/bloc/assessment_bloc.dart';
import '../features/home/presentation/bloc/home_bloc.dart';
import '../features/offline/presentation/bloc/offline_bloc.dart';
import '../features/offline/presentation/bloc/sync_bloc.dart';
import '../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../features/profile/presentation/bloc/teacher_profile_bloc.dart';
import '../features/progress/presentation/bloc/progress_bloc.dart';
import '../features/resources/presentation/bloc/flashcard_bloc.dart';
import '../features/resources/presentation/bloc/santali_flashcard_bloc.dart';
import '../features/resources/presentation/bloc/worksheet_bloc.dart';
import '../features/teach/presentation/bloc/lesson_delivery_bloc.dart';
import '../core/auth/presentation/bloc/auth_bloc.dart';
import '../core/copilot/copilot_store.dart';
import '../core/teacher_assist/teacher_question_engine.dart';
import '../core/translation/bidirectional_phrase_bank.dart';
import '../features/teach/presentation/bloc/teach_bloc.dart';
import '../features/teach/presentation/bloc/teacher_copilot_bloc.dart';
import '../features/translation/presentation/bloc/translation_bloc.dart';

class MaatribhashaApp extends StatelessWidget {
  const MaatribhashaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(const AuthInitializeEvent()),
        ),
        BlocProvider<OnboardingBloc>(
          create: (context) => OnboardingBloc(
            teacherRepository: getIt<TeacherRepository>(),
          ),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(
            teacherRepository: getIt<TeacherRepository>(),
            lessonRepository: getIt<LessonRepository>(),
            offlineRepository: getIt<OfflineRepository>(),
          )..add(LoadHomeDashboard()),
        ),
        BlocProvider<TeachBloc>(
          create: (context) => TeachBloc(
            lessonRepository: getIt<LessonRepository>(),
          )..add(const LoadCurriculumData(grade: 2)),
        ),
        BlocProvider<LessonPlannerBloc>(
          create: (context) => LessonPlannerBloc(
            lessonRepository: getIt<LessonRepository>(),
          ),
        ),
        BlocProvider<LessonDeliveryBloc>(
          create: (context) => LessonDeliveryBloc(
            updateDeliveryProgressUseCase: getIt<UpdateLessonDeliveryProgressUseCase>(),
          ),
        ),
        BlocProvider<TeacherCopilotBloc>(
          // Shared deterministic offline engine (same instance family as
          // the Teacher Guidance page): no per-screen rule copies.
          create: (context) {
            try {
              if (getIt.isRegistered<TeacherQuestionEngine>() &&
                  getIt.isRegistered<CopilotStore>()) {
                return TeacherCopilotBloc(
                  engine: getIt<TeacherQuestionEngine>(),
                  store: getIt<CopilotStore>(),
                );
              }
            } catch (_) {}
            return TeacherCopilotBloc();
          },
        ),
        BlocProvider<WorksheetBloc>(
          create: (context) => WorksheetBloc(
            resourceRepository: getIt<ResourceRepository>(),
          ),
        ),
        BlocProvider<FlashcardBloc>(
          create: (context) => FlashcardBloc(
            resourceRepository: getIt<ResourceRepository>(),
          ),
        ),
        BlocProvider<SantaliFlashcardBloc>(
          create: (context) => getIt<SantaliFlashcardBloc>()..add(const LoadSantaliDecksEvent()),
        ),
        BlocProvider<AssessmentBloc>(
          create: (context) => AssessmentBloc(
            assessmentRepository: getIt<AssessmentRepository>(),
            studentRepository: getIt<StudentRepository>(),
          ),
        ),
        BlocProvider<TranslationBloc>(
          // Deterministic offline prototype: JSON phrase bank + local audio
          // only. No ASR service, no model, no network is wired here.
          create: (context) => TranslationBloc(
            translationRepository: getIt<TranslationRepository>(),
            demoTranslation: getIt<PrototypeDemoTranslationRepository>(),
            santaliAudioPlayer: getIt<SantaliAudioPlayer>(),
            bidirectionalBank: getIt<BidirectionalPhraseBank>(),
            reviewQueue: getIt<ReviewQueueStore>(),
            translationMemory: getIt<TranslationMemoryStore>(),
            correctionNotices: getIt<CorrectionNoticeStore>(),
          ),
        ),
        BlocProvider<ProgressBloc>(
          create: (context) => ProgressBloc(
            activityRepository: getIt<TeacherActivityRepository>(),
            studentRepository: getIt<StudentRepository>(),
          )..add(LoadProgressDashboard()),
        ),
        BlocProvider<TeacherProfileBloc>(
          create: (context) => getIt<TeacherProfileBloc>()..add(LoadTeacherProfile()),
        ),
        BlocProvider<SyncBloc>(
          create: (context) => getIt<SyncBloc>(),
        ),
        BlocProvider<OfflineBloc>(
          create: (context) => OfflineBloc(
            offlineRepository: getIt<OfflineRepository>(),
          )..add(LoadOfflineData()),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
