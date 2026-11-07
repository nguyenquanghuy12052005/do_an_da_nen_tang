import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/repositories/local_sync_repository.dart';
import '../features/sync/data/http_sync_remote.dart';
import '../features/sync/domain/repositories/sync_repository.dart';
import '../features/sync/domain/entities/sync_result.dart';
import 'local_data_providers.dart';
import 'firebase_session.dart';
import '../features/sync/data/firestore_sync_remote.dart';

const syncUrl = String.fromEnvironment('SYNC_URL');
const syncToken = String.fromEnvironment('SYNC_TOKEN');
const syncConfigured = syncUrl != '' && syncToken != '';
final syncConfiguredProvider = Provider<bool>((ref) {
  final session = ref.watch(firebaseSessionProvider);
  return session == null ? syncConfigured : session.user != null;
});
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final session = ref.watch(firebaseSessionProvider);
  final uid = session?.user?.uid;
  return LocalSyncRepository(
    ref.watch(appDatabaseProvider),
    uid == null
        ? HttpSyncRemote(baseUrl: syncUrl, token: syncToken)
        : FirestoreSyncRemote(session!.firestore, uid),
    syncLearning: uid != null,
  );
});
final pendingSyncCountProvider = StreamProvider<int>(
  (ref) => ref.watch(syncRepositoryProvider).watchPendingCount(),
);
final syncControllerProvider =
    NotifierProvider<SyncController, AsyncValue<SyncResult?>>(
      SyncController.new,
    );

class SyncController extends Notifier<AsyncValue<SyncResult?>> {
  Timer? _retryTimer;
  bool _busy = false;
  int _generation = 0;
  int _consecutiveFailures = 0;
  bool _newWork = false;

  @override
  AsyncValue<SyncResult?> build() {
    final generation = ++_generation;
    _busy = false;
    _consecutiveFailures = 0;
    _newWork = false;
    if (ref.watch(syncConfiguredProvider)) {
      _retryTimer = Timer(Duration.zero, () {
        if (generation == _generation) unawaited(synchronize());
      });
      ref.listen(pendingSyncCountProvider, (previous, next) {
        final before = previous?.asData?.value;
        final after = next.asData?.value;
        if (before == null ||
            after == null ||
            after <= before ||
            _consecutiveFailures > 0) {
          return;
        }
        if (_busy) {
          _newWork = true;
        } else {
          _retryTimer?.cancel();
          _retryTimer = Timer(
            const Duration(seconds: 1),
            () => unawaited(synchronize()),
          );
        }
      });
    }
    ref.onDispose(() {
      _generation++;
      _retryTimer?.cancel();
    });
    return const AsyncData(null);
  }

  Future<void> synchronize() async {
    if (_busy || !ref.read(syncConfiguredProvider)) return;
    _retryTimer?.cancel();
    final generation = _generation;
    _busy = true;
    _newWork = false;
    var failed = false;
    var pending = 0;
    try {
      final result = await ref.read(syncRepositoryProvider).synchronize();
      failed = result.error != null;
      pending = result.pendingCount;
      if (generation == _generation) state = AsyncData(result);
    } catch (error, stack) {
      failed = true;
      if (generation == _generation) state = AsyncError(error, stack);
    } finally {
      if (generation == _generation) {
        _busy = false;
        _consecutiveFailures = failed ? min(_consecutiveFailures + 1, 5) : 0;
        final delay = Duration(
          seconds: failed
              ? min(120, 5 << _consecutiveFailures)
              : _newWork
              ? 1
              : pending > 0
              ? 5
              : 30,
        );
        _retryTimer = Timer(delay, () => unawaited(synchronize()));
      }
    }
  }
}
