class SyncResult {
  const SyncResult({
    required this.syncedCount,
    required this.pendingCount,
    this.error,
  });
  final String? error;

  final int syncedCount;
  final int pendingCount;
}
