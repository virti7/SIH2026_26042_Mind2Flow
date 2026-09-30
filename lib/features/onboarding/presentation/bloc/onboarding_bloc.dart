import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/repositories/app_repositories.dart';

// EVENTS
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

class NextOnboardingSlide extends OnboardingEvent {}
class PrevOnboardingSlide extends OnboardingEvent {}

class UpdateTeacherDetails extends OnboardingEvent {
  final String name;
  final String school;
  final String district;
  final List<int> classes;
  final String teachingLanguage;

  const UpdateTeacherDetails({
    required this.name,
    required this.school,
    required this.district,
    required this.classes,
    required this.teachingLanguage,
  });

  @override
  List<Object?> get props => [name, school, district, classes, teachingLanguage];
}

class ToggleClassroomLanguage extends OnboardingEvent {
  final TribalLanguage language;
  const ToggleClassroomLanguage(this.language);
  @override
  List<Object?> get props => [language];
}

class CompleteOnboarding extends OnboardingEvent {}

// STATES
abstract class OnboardingState extends Equatable {
  const OnboardingState();
  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingSlideState extends OnboardingState {
  final int currentSlideIndex; // 0, 1, 2
  const OnboardingSlideState(this.currentSlideIndex);
  @override
  List<Object?> get props => [currentSlideIndex];
}

class OnboardingTeacherSetupState extends OnboardingState {
  final String name;
  final String school;
  final String district;
  final List<int> selectedClasses;
  final String teachingLanguage;

  const OnboardingTeacherSetupState({
    required this.name,
    required this.school,
    required this.district,
    required this.selectedClasses,
    required this.teachingLanguage,
  });

  @override
  List<Object?> get props => [name, school, district, selectedClasses, teachingLanguage];
}

class OnboardingLanguageSetupState extends OnboardingState {
  final List<TribalLanguage> selectedLanguages;
  final TribalLanguage primaryClassroomLanguage;

  const OnboardingLanguageSetupState({
    required this.selectedLanguages,
    required this.primaryClassroomLanguage,
  });

  @override
  List<Object?> get props => [selectedLanguages, primaryClassroomLanguage];
}

class OnboardingCompletedState extends OnboardingState {}

// BLOC
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final TeacherRepository teacherRepository;

  int _slideIndex = 0;
  // New profiles start empty — no fictional teacher is ever prefilled.
  // Placeholders in the setup form guide first-launch input instead.
  String _teacherName = '';
  String _school = '';
  String _district = '';
  List<int> _classes = [1, 2, 3];
  String _teachingLanguage = 'Hindi';
  List<TribalLanguage> _languages = [TribalLanguage.mundari, TribalLanguage.ho, TribalLanguage.santali];

  OnboardingBloc({required this.teacherRepository}) : super(const OnboardingSlideState(0)) {
    on<NextOnboardingSlide>((event, emit) {
      if (_slideIndex < 2) {
        _slideIndex++;
        emit(OnboardingSlideState(_slideIndex));
      } else {
        emit(OnboardingTeacherSetupState(
          name: _teacherName,
          school: _school,
          district: _district,
          selectedClasses: _classes,
          teachingLanguage: _teachingLanguage,
        ));
      }
    });

    on<PrevOnboardingSlide>((event, emit) {
      if (_slideIndex > 0) {
        _slideIndex--;
        emit(OnboardingSlideState(_slideIndex));
      }
    });

    on<UpdateTeacherDetails>((event, emit) {
      _teacherName = event.name;
      _school = event.school;
      _district = event.district;
      _classes = event.classes;
      _teachingLanguage = event.teachingLanguage;

      emit(OnboardingLanguageSetupState(
        selectedLanguages: _languages,
        primaryClassroomLanguage: _languages.isNotEmpty ? _languages.first : TribalLanguage.mundari,
      ));
    });

    on<ToggleClassroomLanguage>((event, emit) {
      final updated = List<TribalLanguage>.from(_languages);
      if (updated.contains(event.language)) {
        if (updated.length > 1) {
          updated.remove(event.language);
        }
      } else {
        updated.add(event.language);
      }
      _languages = updated;
      emit(OnboardingLanguageSetupState(
        selectedLanguages: _languages,
        primaryClassroomLanguage: _languages.first,
      ));
    });

    on<CompleteOnboarding>((event, emit) async {
      final profile = TeacherProfile(
        id: 'teacher_primary',
        name: _teacherName,
        school: _school,
        district: _district,
        state: 'Jharkhand',
        classesTaught: _classes,
        teachingLanguage: _teachingLanguage,
        supportedClassroomLanguages: _languages,
        activeSessionLanguage: _languages.first,
      );
      await teacherRepository.updateProfile(profile);
      emit(OnboardingCompletedState());
    });
  }
}
