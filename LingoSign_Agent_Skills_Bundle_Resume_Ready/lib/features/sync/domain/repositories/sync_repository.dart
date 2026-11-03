import '../entities/sync_result.dart';

abstract interface class SyncRepository {
  Stream<int> watchPendingCount();
  Future<bool> isEnabled();
  Future<void> setEnabled(bool value);
  Future<SyncResult> synchronize();
}
