import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/usecases/offline_sync_usecases.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/sync_status.dart';

// EVENTS
abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class TriggerSyncOperationEvent extends SyncEvent {}

class SyncProgressChangedEvent extends SyncEvent {
  final SyncProgress progress;
  const SyncProgressChangedEvent(this.progress);
  @override
  List<Object?> get props => [progress];
}

// STATES
abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

class SyncInitialState extends SyncState {}

class SyncActiveState extends SyncState {
  final SyncProgress progress;
  const SyncActiveState(this.progress);
  @override
  List<Object?> get props => [progress];
}

class SyncSuccessState extends SyncState {
  final DateTime lastSyncTime;
  const SyncSuccessState(this.lastSyncTime);
  @override
  List<Object?> get props => [lastSyncTime];
}

class SyncErrorState extends SyncState {
  final String errorMessage;
  final int pendingCount;
  const SyncErrorState(this.errorMessage, this.pendingCount);
  @override
  List<Object?> get props => [errorMessage, pendingCount];
}

// BLOC
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final TriggerSyncUseCase triggerSyncUseCase;
  // Null on web: there is no SQLite sync queue, sync runs via the
  // OfflineRepository (mock) instead.
  final SyncManager? syncManager;
  StreamSubscription<SyncProgress>? _progressSubscription;

  SyncBloc({
    required this.triggerSyncUseCase,
    this.syncManager,
  }) : super(SyncInitialState()) {
    // Listen to SyncManager progress stream
    _progressSubscription = syncManager?.progressStream.listen((progress) {
      add(SyncProgressChangedEvent(progress));
    });

    on<TriggerSyncOperationEvent>((event, emit) async {
      await triggerSyncUseCase.execute();
    });

    on<SyncProgressChangedEvent>((event, emit) {
      final p = event.progress;
      if (p.state == SyncProcessState.syncing) {
        emit(SyncActiveState(p));
      } else if (p.state == SyncProcessState.error) {
        emit(SyncErrorState(p.errorMessage ?? 'Sync failed', p.pendingCount));
      } else if (p.lastSyncTime != null) {
        emit(SyncSuccessState(p.lastSyncTime!));
      } else {
        emit(SyncActiveState(p));
      }
    });
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    return super.close();
  }
}
