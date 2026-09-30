import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/repositories/app_repositories.dart';

// EVENTS
abstract class AssessmentEvent extends Equatable {
  const AssessmentEvent();
  @override
  List<Object?> get props => [];
}

class StartAssessmentEvent extends AssessmentEvent {
  final String outcomeCode;
  final String studentId;
  final String studentName;

  const StartAssessmentEvent({
    this.outcomeCode = 'M2.1.4',
    this.studentId = 'session_learner',
    this.studentName = 'Learner',
  });

  @override
  List<Object?> get props => [outcomeCode, studentId, studentName];
}

class SelectAssessmentAnswerEvent extends AssessmentEvent {
  final int questionIndex;
  final int answerIndex;
  const SelectAssessmentAnswerEvent(this.questionIndex, this.answerIndex);
  @override
  List<Object?> get props => [questionIndex, answerIndex];
}

class NextAssessmentQuestionEvent extends AssessmentEvent {}

class SubmitAssessmentEvent extends AssessmentEvent {}

class OpenRemedialActivityEvent extends AssessmentEvent {}

class StartReassessmentEvent extends AssessmentEvent {}

class SubmitReassessmentAnswerEvent extends AssessmentEvent {
  final bool passed;
  const SubmitReassessmentAnswerEvent(this.passed);
  @override
  List<Object?> get props => [passed];
}

// STATES
abstract class AssessmentState extends Equatable {
  const AssessmentState();
  @override
  List<Object?> get props => [];
}

class AssessmentInitial extends AssessmentState {}
class AssessmentLoading extends AssessmentState {}

class AssessmentActiveState extends AssessmentState {
  final String studentName;
  final String studentId;
  final String outcomeCode;
  final List<AssessmentQuestionItem> questions;
  final int currentQuestionIndex;
  final List<int> selectedAnswers;

  const AssessmentActiveState({
    required this.studentName,
    required this.studentId,
    required this.outcomeCode,
    required this.questions,
    required this.currentQuestionIndex,
    required this.selectedAnswers,
  });

  AssessmentQuestionItem get currentQuestion => questions[currentQuestionIndex];

  @override
  List<Object?> get props => [
        studentName,
        studentId,
        outcomeCode,
        questions,
        currentQuestionIndex,
        selectedAnswers,
      ];
}

class AssessmentResultState extends AssessmentState {
  final AssessmentResultData result;
  const AssessmentResultState(this.result);
  @override
  List<Object?> get props => [result];
}

class RemediationActiveState extends AssessmentState {
  final AssessmentResultData previousResult;
  final ActivityItem remedialActivity;

  const RemediationActiveState({
    required this.previousResult,
    required this.remedialActivity,
  });

  @override
  List<Object?> get props => [previousResult, remedialActivity];
}

class ReassessmentActiveState extends AssessmentState {
  final AssessmentResultData previousResult;
  final List<AssessmentQuestionItem> questions;
  final int currentQuestionIndex;

  const ReassessmentActiveState({
    required this.previousResult,
    required this.questions,
    required this.currentQuestionIndex,
  });

  @override
  List<Object?> get props => [previousResult, questions, currentQuestionIndex];
}

class ReassessmentCompleteState extends AssessmentState {
  final OutcomeStatus previousStatus;
  final OutcomeStatus newStatus;
  final String studentName;
  final String outcomeCode;

  const ReassessmentCompleteState({
    required this.previousStatus,
    required this.newStatus,
    required this.studentName,
    required this.outcomeCode,
  });

  @override
  List<Object?> get props => [previousStatus, newStatus, studentName, outcomeCode];
}

// BLOC
class AssessmentBloc extends Bloc<AssessmentEvent, AssessmentState> {
  final AssessmentRepository assessmentRepository;
  final StudentRepository studentRepository;

  String _currentStudentId = 'session_learner';
  String _currentStudentName = 'Learner';
  String _currentOutcome = 'M2.1.4';
  List<AssessmentQuestionItem> _questions = [];
  List<int> _selectedAnswers = [];
  AssessmentResultData? _lastResult;

  AssessmentBloc({
    required this.assessmentRepository,
    required this.studentRepository,
  }) : super(AssessmentInitial()) {
    on<StartAssessmentEvent>((event, emit) async {
      emit(AssessmentLoading());
      _currentStudentId = event.studentId;
      _currentStudentName = event.studentName;
      _currentOutcome = event.outcomeCode;

      _questions = await assessmentRepository.getQuestionsForOutcome(event.outcomeCode);
      _selectedAnswers = List.filled(_questions.length, -1);

      emit(AssessmentActiveState(
        studentName: _currentStudentName,
        studentId: _currentStudentId,
        outcomeCode: _currentOutcome,
        questions: _questions,
        currentQuestionIndex: 0,
        selectedAnswers: _selectedAnswers,
      ));
    });

    on<SelectAssessmentAnswerEvent>((event, emit) {
      if (state is AssessmentActiveState) {
        final current = state as AssessmentActiveState;
        final updated = List<int>.from(current.selectedAnswers);
        updated[event.questionIndex] = event.answerIndex;
        _selectedAnswers = updated;

        emit(AssessmentActiveState(
          studentName: current.studentName,
          studentId: current.studentId,
          outcomeCode: current.outcomeCode,
          questions: current.questions,
          currentQuestionIndex: current.currentQuestionIndex,
          selectedAnswers: updated,
        ));
      }
    });

    on<NextAssessmentQuestionEvent>((event, emit) {
      if (state is AssessmentActiveState) {
        final current = state as AssessmentActiveState;
        if (current.currentQuestionIndex < current.questions.length - 1) {
          emit(AssessmentActiveState(
            studentName: current.studentName,
            studentId: current.studentId,
            outcomeCode: current.outcomeCode,
            questions: current.questions,
            currentQuestionIndex: current.currentQuestionIndex + 1,
            selectedAnswers: current.selectedAnswers,
          ));
        } else {
          add(SubmitAssessmentEvent());
        }
      }
    });

    on<SubmitAssessmentEvent>((event, emit) async {
      emit(AssessmentLoading());
      final result = await assessmentRepository.submitAssessment(
        studentId: _currentStudentId,
        studentName: _currentStudentName,
        outcomeCode: _currentOutcome,
        selectedAnswers: _selectedAnswers,
      );
      _lastResult = result;
      emit(AssessmentResultState(result));
    });

    on<OpenRemedialActivityEvent>((event, emit) async {
      if (_lastResult != null) {
        emit(AssessmentLoading());
        final activity = await assessmentRepository.getRemedialActivityForOutcome(_lastResult!.outcomeCode);
        emit(RemediationActiveState(
          previousResult: _lastResult!,
          remedialActivity: activity,
        ));
      }
    });

    on<StartReassessmentEvent>((event, emit) async {
      if (_lastResult != null) {
        emit(AssessmentLoading());
        final questions = await assessmentRepository.getQuestionsForOutcome(_lastResult!.outcomeCode);
        emit(ReassessmentActiveState(
          previousResult: _lastResult!,
          questions: questions.take(2).toList(),
          currentQuestionIndex: 0,
        ));
      }
    });

    on<SubmitReassessmentAnswerEvent>((event, emit) async {
      emit(AssessmentLoading());
      await studentRepository.updateOutcomeStatus(
        _currentStudentId,
        _currentOutcome,
        event.passed ? OutcomeStatus.achieved : OutcomeStatus.developing,
      );

      final prev = _lastResult != null ? _lastResult!.status : OutcomeStatus.needsSupport;
      emit(ReassessmentCompleteState(
        previousStatus: prev,
        newStatus: event.passed ? OutcomeStatus.achieved : OutcomeStatus.developing,
        studentName: _currentStudentName,
        outcomeCode: _currentOutcome,
      ));
    });
  }
}
