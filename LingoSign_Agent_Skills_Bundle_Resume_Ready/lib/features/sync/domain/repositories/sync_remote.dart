import '../entities/sync_operation.dart';

abstract interface class SyncRemote {
  Future<void> push(SyncOperation operation);
  Future<SyncPage> pull(String? cursor);
}
