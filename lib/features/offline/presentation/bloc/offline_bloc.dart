import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/repositories/app_repositories.dart';

// EVENTS
abstract class OfflineEvent extends Equatable {
  const OfflineEvent();
  @override
  List<Object?> get props => [];
}

class LoadOfflineData extends OfflineEvent {}

class InstallLanguagePackEvent extends OfflineEvent {
  final String packId;
  const InstallLanguagePackEvent(this.packId);
  @override
  List<Object?> get props => [packId];
}

class TriggerManualSyncEvent extends OfflineEvent {}

// STATES
abstract class OfflineState extends Equatable {
  const OfflineState();
  @override
  List<Object?> get props => [];
}

class OfflineLoading extends OfflineState {}

class OfflineDataLoaded extends OfflineState {
  final List<LanguagePackInfo> languagePacks;
  final List<ContentPackInfo> contentPacks;
  final SyncStatusState syncStatus;
  final int pendingSyncCount;
  final int totalStorageMb;
  final int usedStorageMb;
  final int freeStorageMb;
  final DateTime lastSync;

  const OfflineDataLoaded({
    required this.languagePacks,
    required this.contentPacks,
    required this.syncStatus,
    this.pendingSyncCount = 0,
    required this.totalStorageMb,
    required this.usedStorageMb,
    required this.freeStorageMb,
    required this.lastSync,
  });

  OfflineDataLoaded copyWith({
    List<LanguagePackInfo>? languagePacks,
    List<ContentPackInfo>? contentPacks,
    SyncStatusState? syncStatus,
    int? pendingSyncCount,
    int? totalStorageMb,
    int? usedStorageMb,
    int? freeStorageMb,
    DateTime? lastSync,
  }) {
    return OfflineDataLoaded(
      languagePacks: languagePacks ?? this.languagePacks,
      contentPacks: contentPacks ?? this.contentPacks,
      syncStatus: syncStatus ?? this.syncStatus,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      totalStorageMb: totalStorageMb ?? this.totalStorageMb,
      usedStorageMb: usedStorageMb ?? this.usedStorageMb,
      freeStorageMb: freeStorageMb ?? this.freeStorageMb,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  List<Object?> get props => [
        languagePacks,
        contentPacks,
        syncStatus,
        pendingSyncCount,
        totalStorageMb,
        usedStorageMb,
        freeStorageMb,
        lastSync,
      ];
}

// BLOC
class OfflineBloc extends Bloc<OfflineEvent, OfflineState> {
  final OfflineRepository offlineRepository;

  OfflineBloc({
    required this.offlineRepository,
  }) : super(OfflineLoading()) {
    on<LoadOfflineData>((event, emit) async {
      emit(OfflineLoading());
      final langPacks = await offlineRepository.getLanguagePacks();
      final contentPacks = await offlineRepository.getContentPacks();
      final pendingCount = await offlineRepository.getPendingSyncCount();
      final syncStatus = await offlineRepository.getSyncStatus();
      final lastSync = await offlineRepository.getLastSyncTime() ??
          DateTime.now().subtract(const Duration(hours: 3));

      emit(OfflineDataLoaded(
        languagePacks: langPacks,
        contentPacks: contentPacks,
        syncStatus: syncStatus,
        pendingSyncCount: pendingCount,
        totalStorageMb: 32768, // 32 GB Android Tablet
        usedStorageMb: 4210, // 4.2 GB used
        freeStorageMb: 28558,
        lastSync: lastSync,
      ));
    });

    on<InstallLanguagePackEvent>((event, emit) async {
      if (state is OfflineDataLoaded) {
        final current = state as OfflineDataLoaded;
        // Mark as downloading
        final updatedPacks = current.languagePacks.map((p) {
          if (p.id == event.packId) {
            return p.copyWith(status: PackStatus.downloading, progress: 0.5);
          }
          return p;
        }).toList();
        emit(current.copyWith(languagePacks: updatedPacks));

        await offlineRepository.downloadLanguagePack(event.packId);
        final finalPacks = await offlineRepository.getLanguagePacks();
        emit(current.copyWith(languagePacks: finalPacks));
      }
    });

    on<TriggerManualSyncEvent>((event, emit) async {
      if (state is OfflineDataLoaded) {
        final current = state as OfflineDataLoaded;
        emit(current.copyWith(syncStatus: SyncStatusState.syncing));
        await offlineRepository.syncClassroomData();
        final remaining = await offlineRepository.getPendingSyncCount();
        final finalStatus = await offlineRepository.getSyncStatus();
        final lastSync = await offlineRepository.getLastSyncTime() ?? DateTime.now();

        emit(current.copyWith(
          syncStatus: finalStatus,
          pendingSyncCount: remaining,
          lastSync: lastSync,
        ));
      }
    });
  }
}
