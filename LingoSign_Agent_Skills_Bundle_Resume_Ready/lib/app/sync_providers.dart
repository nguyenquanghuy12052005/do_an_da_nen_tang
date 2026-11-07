import 'dart:async';

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
  bool _busy = false;
  bool _disposed = false;
  @override
  AsyncValue<SyncResult?> build() {
    _disposed = false;
    if (ref.watch(syncConfiguredProvider)) {
      final timer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => unawaited(synchronize()),
      );
      ref.onDispose(timer.cancel);
      Future.microtask(synchronize);
    }
    ref.onDispose(() => _disposed = true);
    return const AsyncData(null);
  }

  Future<void> synchronize() async {
    if (_busy || !ref.read(syncConfiguredProvider)) return;
    _busy = true;
    try {
      final result = await ref.read(syncRepositoryProvider).synchronize();
      if (!_disposed) state = AsyncData(result);
    } catch (error, stack) {
      if (!_disposed) state = AsyncError(error, stack);
    } finally {
      _busy = false;
    }
  }
}
