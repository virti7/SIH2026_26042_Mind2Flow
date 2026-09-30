import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/auth/services/account_session.dart';
import '../../../../core/domain/usecases/teacher_usecases.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';

// EVENTS
abstract class TeacherProfileEvent extends Equatable {
  const TeacherProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadTeacherProfile extends TeacherProfileEvent {}

class ClearTeacherProfile extends TeacherProfileEvent {}

class UpdateTeacherProfileEvent extends TeacherProfileEvent {
  final TeacherProfile profile;
  const UpdateTeacherProfileEvent(this.profile);
  @override
  List<Object?> get props => [profile];
}

class UpdateTeacherLanguagesEvent extends TeacherProfileEvent {
  final List<TribalLanguage> languages;
  const UpdateTeacherLanguagesEvent(this.languages);
  @override
  List<Object?> get props => [languages];
}

// STATES
abstract class TeacherProfileState extends Equatable {
  const TeacherProfileState();
  @override
  List<Object?> get props => [];
}

class TeacherProfileInitial extends TeacherProfileState {}

class TeacherProfileLoading extends TeacherProfileState {}

class TeacherProfileLoaded extends TeacherProfileState {
  final TeacherProfile profile;
  final String? successMessage;

  const TeacherProfileLoaded({
    required this.profile,
    this.successMessage,
  });

  TeacherProfileLoaded copyWith({
    TeacherProfile? profile,
    String? successMessage,
  }) {
    return TeacherProfileLoaded(
      profile: profile ?? this.profile,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [profile, successMessage];
}

class TeacherProfileError extends TeacherProfileState {
  final String message;
  const TeacherProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLOC
class TeacherProfileBloc extends Bloc<TeacherProfileEvent, TeacherProfileState> {
  final GetTeacherProfileUseCase getTeacherProfileUseCase;
  final UpdateTeacherProfileUseCase updateTeacherProfileUseCase;
  final UpdateClassroomLanguagesUseCase updateClassroomLanguagesUseCase;
  StreamSubscription<String?>? _sessionSub;

  TeacherProfileBloc({
    required this.getTeacherProfileUseCase,
    required this.updateTeacherProfileUseCase,
    required this.updateClassroomLanguagesUseCase,
  }) : super(TeacherProfileInitial()) {
    // Account switch: never show the previous teacher's profile while the
    // new account loads. Signed out -> clear; signed in -> reload.
    _sessionSub = AccountSession.changes.listen((userId) {
      if (userId == null) {
        add(ClearTeacherProfile());
      } else {
        add(LoadTeacherProfile());
      }
    });
    on<ClearTeacherProfile>((event, emit) {
      emit(TeacherProfileInitial());
    });
    on<LoadTeacherProfile>((event, emit) async {
      emit(TeacherProfileLoading());
      try {
        final profile = await getTeacherProfileUseCase.execute();
        emit(TeacherProfileLoaded(profile: profile));
      } catch (e) {
        emit(TeacherProfileError('Failed to load teacher profile: $e'));
      }
    });

    on<UpdateTeacherProfileEvent>((event, emit) async {
      emit(TeacherProfileLoading());
      try {
        await updateTeacherProfileUseCase.execute(event.profile);
        emit(TeacherProfileLoaded(
          profile: event.profile,
          successMessage: 'Profile updated locally in SQLite and queued for sync.',
        ));
      } catch (e) {
        emit(TeacherProfileError('Failed to update teacher profile: $e'));
      }
    });

    on<UpdateTeacherLanguagesEvent>((event, emit) async {
      emit(TeacherProfileLoading());
      try {
        await updateClassroomLanguagesUseCase.execute(event.languages);
        final profile = await getTeacherProfileUseCase.execute();
        emit(TeacherProfileLoaded(
          profile: profile,
          successMessage: 'Classroom languages updated.',
        ));
      } catch (e) {
        emit(TeacherProfileError('Failed to update languages: $e'));
      }
    });
  }

  @override
  Future<void> close() {
    _sessionSub?.cancel();
    return super.close();
  }
}
