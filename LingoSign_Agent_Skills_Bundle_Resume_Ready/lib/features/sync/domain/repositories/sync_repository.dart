import '../entities/sync_result.dart';

abstract interface class SyncRepository {
  Future<SyncResult> synchronize();
}
