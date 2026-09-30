import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/usecases/lesson_usecases.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/repositories/app_repositories.dart';

// --- LESSON PLANNER BLOC ---
abstract class LessonPlannerEvent extends Equatable {
  const LessonPlannerEvent();
  @override
  List<Object?> get props => [];
}

class LoadLessonPlan extends LessonPlannerEvent {
  final String outcomeCode;
  const LoadLessonPlan(this.outcomeCode);
  @override
  List<Object?> get props => [outcomeCode];
}

class ChangeTribalLanguage extends LessonPlannerEvent {
  final TribalLanguage language;
  const ChangeTribalLanguage(this.language);
  @override
  List<Object?> get props => [language];
}

abstract class LessonPlannerState extends Equatable {
  const LessonPlannerState();
  @override
  List<Object?> get props => [];
}

class LessonPlannerLoading extends LessonPlannerState {}

class LessonPlannerLoaded extends LessonPlannerState {
  final LessonPlan plan;
  final TribalLanguage selectedLanguage;

  const LessonPlannerLoaded({
    required this.plan,
    this.selectedLanguage = TribalLanguage.mundari,
  });

  @override
  List<Object?> get props => [plan, selectedLanguage];
}

class LessonPlannerBloc extends Bloc<LessonPlannerEvent, LessonPlannerState> {
  final LessonRepository lessonRepository;

  LessonPlannerBloc({required this.lessonRepository}) : super(LessonPlannerLoading()) {
    on<LoadLessonPlan>((event, emit) async {
      emit(LessonPlannerLoading());
      final plan = await lessonRepository.getLessonPlanForOutcome(event.outcomeCode);
      emit(LessonPlannerLoaded(plan: plan));
    });

    on<ChangeTribalLanguage>((event, emit) {
      if (state is LessonPlannerLoaded) {
        final current = state as LessonPlannerLoaded;
        emit(LessonPlannerLoaded(
          plan: current.plan,
          selectedLanguage: event.language,
        ));
      }
    });
  }
}

// --- LESSON DELIVERY BLOC ---
abstract class LessonDeliveryEvent extends Equatable {
  const LessonDeliveryEvent();
  @override
  List<Object?> get props => [];
}

class StartLessonDelivery extends LessonDeliveryEvent {
  final LessonPlan plan;
  const StartLessonDelivery(this.plan);
  @override
  List<Object?> get props => [plan];
}

class NextDeliveryStage extends LessonDeliveryEvent {}
class PrevDeliveryStage extends LessonDeliveryEvent {}
class JumpToDeliveryStage extends LessonDeliveryEvent {
  final int stageIndex;
  const JumpToDeliveryStage(this.stageIndex);
  @override
  List<Object?> get props => [stageIndex];
}

abstract class LessonDeliveryState extends Equatable {
  const LessonDeliveryState();
  @override
  List<Object?> get props => [];
}

class LessonDeliveryInitial extends LessonDeliveryState {}

class LessonDeliveryActive extends LessonDeliveryState {
  final LessonPlan plan;
  final int currentStageIndex; // 0..5
  final bool isCompleted;

  const LessonDeliveryActive({
    required this.plan,
    required this.currentStageIndex,
    this.isCompleted = false,
  });

  LessonStep get currentStep => plan.steps[currentStageIndex];

  @override
  List<Object?> get props => [plan, currentStageIndex, isCompleted];
}

class LessonDeliveryBloc extends Bloc<LessonDeliveryEvent, LessonDeliveryState> {
  final UpdateLessonDeliveryProgressUseCase? updateDeliveryProgressUseCase;

  LessonDeliveryBloc({this.updateDeliveryProgressUseCase}) : super(LessonDeliveryInitial()) {
    on<StartLessonDelivery>((event, emit) async {
      emit(LessonDeliveryActive(
        plan: event.plan,
        currentStageIndex: 0,
      ));
      await updateDeliveryProgressUseCase?.execute(
        lessonId: event.plan.id,
        currentStep: 1,
        isCompleted: false,
      );
    });

    on<NextDeliveryStage>((event, emit) async {
      if (state is LessonDeliveryActive) {
        final current = state as LessonDeliveryActive;
        if (current.currentStageIndex < current.plan.steps.length - 1) {
          final nextIdx = current.currentStageIndex + 1;
          emit(LessonDeliveryActive(
            plan: current.plan,
            currentStageIndex: nextIdx,
          ));
          await updateDeliveryProgressUseCase?.execute(
            lessonId: current.plan.id,
            currentStep: nextIdx + 1,
            isCompleted: false,
          );
        } else {
          emit(LessonDeliveryActive(
            plan: current.plan,
            currentStageIndex: current.currentStageIndex,
            isCompleted: true,
          ));
          await updateDeliveryProgressUseCase?.execute(
            lessonId: current.plan.id,
            currentStep: current.plan.steps.length,
            isCompleted: true,
          );
        }
      }
    });

    on<PrevDeliveryStage>((event, emit) async {
      if (state is LessonDeliveryActive) {
        final current = state as LessonDeliveryActive;
        if (current.currentStageIndex > 0) {
          final prevIdx = current.currentStageIndex - 1;
          emit(LessonDeliveryActive(
            plan: current.plan,
            currentStageIndex: prevIdx,
          ));
          await updateDeliveryProgressUseCase?.execute(
            lessonId: current.plan.id,
            currentStep: prevIdx + 1,
            isCompleted: false,
          );
        }
      }
    });

    on<JumpToDeliveryStage>((event, emit) async {
      if (state is LessonDeliveryActive) {
        final current = state as LessonDeliveryActive;
        if (event.stageIndex >= 0 && event.stageIndex < current.plan.steps.length) {
          emit(LessonDeliveryActive(
            plan: current.plan,
            currentStageIndex: event.stageIndex,
          ));
          await updateDeliveryProgressUseCase?.execute(
            lessonId: current.plan.id,
            currentStep: event.stageIndex + 1,
            isCompleted: event.stageIndex == current.plan.steps.length - 1,
          );
        }
      }
    });
  }
}
