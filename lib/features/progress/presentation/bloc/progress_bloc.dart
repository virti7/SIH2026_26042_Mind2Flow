import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/models/teacher_activity.dart';
import '../../../../core/repositories/app_repositories.dart';
import '../../../../core/repositories/teacher_activity_repository.dart';

// EVENTS
abstract class ProgressEvent extends Equatable {
  const ProgressEvent();
  @override
  List<Object?> get props => [];
}

class LoadProgressDashboard extends ProgressEvent {}

/// Loads the classroom roster for the isolated class-records screens.
/// Never used by the teacher dashboard, which stays student-free.
class LoadStudentRoster extends ProgressEvent {}

/// Legacy classroom-record navigation, kept isolated from teacher progress:
/// the teacher dashboard never queries student data.
class SelectStudentForDetails extends ProgressEvent {
  final String studentId;
  const SelectStudentForDetails(this.studentId);
  @override
  List<Object?> get props => [studentId];
}

// STATES
abstract class ProgressState extends Equatable {
  const ProgressState();
  @override
  List<Object?> get props => [];
}

class ProgressLoading extends ProgressState {}

/// Teacher-only dashboard: every metric is computed from real on-device
/// activity (lessons taught, assessments conducted, resources generated).
/// Empty when the teacher has not recorded any activity yet.
class ProgressDashboardLoaded extends ProgressState {
  final TeacherActivitySummary summary;

  const ProgressDashboardLoaded({required this.summary});

  @override
  List<Object?> get props => [summary];
}

class ProgressError extends ProgressState {
  final String message;
  const ProgressError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Isolated classroom roster (class-records screens only).
class StudentRosterLoaded extends ProgressState {
  final List<StudentRecord> students;
  const StudentRosterLoaded(this.students);
  @override
  List<Object?> get props => [students];
}

class StudentDetailLoaded extends ProgressState {
  final StudentRecord student;
  final List<StudentRecord> allStudents;

  const StudentDetailLoaded({
    required this.student,
    required this.allStudents,
  });

  @override
  List<Object?> get props => [student, allStudents];
}

// BLOC
class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final TeacherActivityRepository activityRepository;
  final StudentRepository studentRepository;

  ProgressBloc({
    required this.activityRepository,
    required this.studentRepository,
  }) : super(ProgressLoading()) {
    on<LoadProgressDashboard>((event, emit) async {
      emit(ProgressLoading());
      try {
        final summary = await activityRepository.getSummary();
        emit(ProgressDashboardLoaded(summary: summary));
      } catch (e) {
        emit(ProgressError('Could not load teaching progress: $e'));
      }
    });

    on<SelectStudentForDetails>((event, emit) async {
      emit(ProgressLoading());
      final student = await studentRepository.getStudentById(event.studentId);
      final allStudents = await studentRepository.getStudents();
      if (student != null) {
        emit(StudentDetailLoaded(student: student, allStudents: allStudents));
      } else {
        add(LoadProgressDashboard());
      }
    });

    on<LoadStudentRoster>((event, emit) async {
      try {
        final allStudents = await studentRepository.getStudents();
        emit(StudentRosterLoaded(allStudents));
      } catch (e) {
        emit(ProgressError('Could not load class records: $e'));
      }
    });
  }
}
