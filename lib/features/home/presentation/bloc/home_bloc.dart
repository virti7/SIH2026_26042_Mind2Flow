import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/repositories/app_repositories.dart';

// EVENTS
abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class LoadHomeDashboard extends HomeEvent {}

class ChangeActiveGrade extends HomeEvent {
  final int grade;
  const ChangeActiveGrade(this.grade);
  @override
  List<Object?> get props => [grade];
}

class TriggerHomeSync extends HomeEvent {}

// STATES
abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final TeacherProfile profile;
  final int activeGrade;
  final NipunOutcome todayOutcome;
  final SyncStatusState syncStatus;
  final bool isOfflineReady;
  final List<ActivityItem> recentActivities;

  const HomeLoaded({
    required this.profile,
    required this.activeGrade,
    required this.todayOutcome,
    required this.syncStatus,
    required this.isOfflineReady,
    required this.recentActivities,
  });

  HomeLoaded copyWith({
    TeacherProfile? profile,
    int? activeGrade,
    NipunOutcome? todayOutcome,
    SyncStatusState? syncStatus,
    bool? isOfflineReady,
    List<ActivityItem>? recentActivities,
  }) {
    return HomeLoaded(
      profile: profile ?? this.profile,
      activeGrade: activeGrade ?? this.activeGrade,
      todayOutcome: todayOutcome ?? this.todayOutcome,
      syncStatus: syncStatus ?? this.syncStatus,
      isOfflineReady: isOfflineReady ?? this.isOfflineReady,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        activeGrade,
        todayOutcome,
        syncStatus,
        isOfflineReady,
        recentActivities,
      ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLOC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TeacherRepository teacherRepository;
  final LessonRepository lessonRepository;
  final OfflineRepository offlineRepository;

  int _currentGrade = 2;

  HomeBloc({
    required this.teacherRepository,
    required this.lessonRepository,
    required this.offlineRepository,
  }) : super(HomeLoading()) {
    on<LoadHomeDashboard>((event, emit) async {
      emit(HomeLoading());
      try {
        final profile = await teacherRepository.getProfile();
        final outcomes = await lessonRepository.getOutcomes(grade: _currentGrade);
        final activities = await lessonRepository.getActivities(grade: _currentGrade);

        emit(HomeLoaded(
          profile: profile,
          activeGrade: _currentGrade,
          todayOutcome: outcomes.isNotEmpty ? outcomes.first : outcomes.first,
          syncStatus: SyncStatusState.synced,
          isOfflineReady: true,
          recentActivities: activities,
        ));
      } catch (e) {
        emit(HomeError('Failed to load dashboard: $e'));
      }
    });

    on<ChangeActiveGrade>((event, emit) async {
      _currentGrade = event.grade;
      add(LoadHomeDashboard());
    });

    on<TriggerHomeSync>((event, emit) async {
      if (state is HomeLoaded) {
        final current = state as HomeLoaded;
        emit(current.copyWith(syncStatus: SyncStatusState.syncing));
        await offlineRepository.syncClassroomData();
        emit(current.copyWith(syncStatus: SyncStatusState.synced));
      }
    });
  }
}
