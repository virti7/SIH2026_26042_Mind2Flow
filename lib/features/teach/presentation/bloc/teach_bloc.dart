import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/repositories/app_repositories.dart';

// EVENTS
abstract class TeachEvent extends Equatable {
  const TeachEvent();
  @override
  List<Object?> get props => [];
}

class LoadCurriculumData extends TeachEvent {
  final int grade;
  const LoadCurriculumData({this.grade = 2});
  @override
  List<Object?> get props => [grade];
}

class SelectSubject extends TeachEvent {
  final String subject;
  const SelectSubject(this.subject);
  @override
  List<Object?> get props => [subject];
}

class SearchCurriculum extends TeachEvent {
  final String query;
  const SearchCurriculum(this.query);
  @override
  List<Object?> get props => [query];
}

// STATES
abstract class TeachState extends Equatable {
  const TeachState();
  @override
  List<Object?> get props => [];
}

class TeachLoading extends TeachState {}

class TeachLoaded extends TeachState {
  final int selectedGrade;
  final String selectedSubject;
  final List<NipunOutcome> outcomes;
  final List<LocalContextItem> localContextItems;
  final String searchQuery;

  const TeachLoaded({
    required this.selectedGrade,
    required this.selectedSubject,
    required this.outcomes,
    required this.localContextItems,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [
        selectedGrade,
        selectedSubject,
        outcomes,
        localContextItems,
        searchQuery,
      ];
}

class TeachError extends TeachState {
  final String message;
  const TeachError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLOC
class TeachBloc extends Bloc<TeachEvent, TeachState> {
  final LessonRepository lessonRepository;

  TeachBloc({required this.lessonRepository}) : super(TeachLoading()) {
    on<LoadCurriculumData>((event, emit) async {
      emit(TeachLoading());
      try {
        final outcomes = await lessonRepository.getOutcomes(grade: event.grade);
        final contextItems = await lessonRepository.getLocalContextItems();
        emit(TeachLoaded(
          selectedGrade: event.grade,
          selectedSubject: 'Mathematics',
          outcomes: outcomes,
          localContextItems: contextItems,
        ));
      } catch (e) {
        emit(TeachError('Error loading curriculum: $e'));
      }
    });

    on<SelectSubject>((event, emit) async {
      if (state is TeachLoaded) {
        final current = state as TeachLoaded;
        final outcomes = await lessonRepository.getOutcomes(grade: current.selectedGrade);
        emit(TeachLoaded(
          selectedGrade: current.selectedGrade,
          selectedSubject: event.subject,
          outcomes: outcomes,
          localContextItems: current.localContextItems,
        ));
      }
    });

    on<SearchCurriculum>((event, emit) async {
      if (state is TeachLoaded) {
        final current = state as TeachLoaded;
        final allOutcomes = await lessonRepository.getOutcomes(grade: current.selectedGrade);
        final filtered = event.query.isEmpty
            ? allOutcomes
            : allOutcomes.where((o) =>
                o.titleEn.toLowerCase().contains(event.query.toLowerCase()) ||
                o.titleHi.contains(event.query) ||
                o.code.toLowerCase().contains(event.query.toLowerCase())).toList();

        emit(TeachLoaded(
          selectedGrade: current.selectedGrade,
          selectedSubject: current.selectedSubject,
          outcomes: filtered,
          localContextItems: current.localContextItems,
          searchQuery: event.query,
        ));
      }
    });
  }
}
