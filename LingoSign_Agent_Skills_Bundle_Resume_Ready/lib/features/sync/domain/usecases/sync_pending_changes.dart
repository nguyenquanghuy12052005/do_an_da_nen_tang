import '../entities/sync_result.dart';
import '../repositories/sync_repository.dart';

class SyncPendingChanges {
  const SyncPendingChanges(this._repository);

  final SyncRepository _repository;

  Future<SyncResult> call() => _repository.synchronize();
}
