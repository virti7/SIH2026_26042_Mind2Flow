enum SyncOperation {
  create('CREATE'),
  update('UPDATE'),
  delete('DELETE');

  final String value;
  const SyncOperation(this.value);
}

enum SyncItemStatus {
  pending('PENDING'),
  syncing('SYNCING'),
  synced('SYNCED'),
  failed('FAILED');

  final String value;
  const SyncItemStatus(this.value);
}

enum SyncProcessState {
  idle,
  syncing,
  error,
}

class SyncProgress {
  final int pendingCount;
  final SyncProcessState state;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const SyncProgress({
    required this.pendingCount,
    required this.state,
    this.lastSyncTime,
    this.errorMessage,
  });

  SyncProgress copyWith({
    int? pendingCount,
    SyncProcessState? state,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return SyncProgress(
      pendingCount: pendingCount ?? this.pendingCount,
      state: state ?? this.state,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
