import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../../features/sync/domain/entities/sync_operation.dart';
import '../../../features/sync/domain/entities/sync_result.dart';
import '../../../features/sync/domain/repositories/sync_remote.dart';
import '../../../features/sync/domain/repositories/sync_repository.dart';
import '../app_database.dart';
import '../sync_outbox.dart';

class LocalSyncRepository implements SyncRepository {
  LocalSyncRepository(this.db, this.remote, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final AppDatabase db;
  final SyncRemote remote;
  final DateTime Function() now;
  Future<SyncResult>? _running;

  @override
  Stream<int> watchPendingCount() {
    final count = db.pendingSyncOps.opId.count();
    return (db.selectOnly(
      db.pendingSyncOps,
    )..addColumns([count])).watchSingle().map((row) => row.read(count) ?? 0);
  }

  @override
  Future<bool> isEnabled() async =>
      (await (db.select(
            db.appSettings,
          )..where((t) => t.key.equals('sync_enabled'))).getSingleOrNull())
          ?.valueJson ==
      'true';

  @override
  Future<void> setEnabled(bool value) => db.transaction(() async {
    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: 'sync_enabled',
            valueJson: jsonEncode(value),
            updatedAtUtcMs: now().toUtc().millisecondsSinceEpoch,
          ),
        );
    if (value) {
      for (final row in await db.select(db.recognitionHistoryRows).get()) {
        await enqueueHistory(
          db,
          historyPayload(row),
          deleted: row.deletedAtUtcMs != null,
        );
      }
    }
  });

  @override
  Future<SyncResult> synchronize() {
    if (_running case final running?) return running;
    final task = _synchronize();
    _running = task;
    return task.whenComplete(() => _running = null);
  }

  Future<SyncResult> _synchronize() async {
    var count = 0;
    String? error;
    if (await isEnabled()) {
      final pending =
          await (db.select(db.pendingSyncOps)
                ..orderBy([
                  (t) => OrderingTerm.asc(t.createdAtUtcMs),
                  (t) => OrderingTerm.asc(t.opId),
                ])
                ..limit(100))
              .get();
      for (final op in pending) {
        if (!await isEnabled()) break;
        // Preserve operation ordering across failures and retries.
        if (op.nextAttemptAtUtcMs > now().toUtc().millisecondsSinceEpoch) {
          error = op.lastError;
          break;
        }
        try {
          await remote.push(
            SyncOperation(
              id: op.opId,
              operation: op.operation,
              record: (jsonDecode(op.payloadJson) as Map)
                  .cast<String, Object?>(),
            ),
          );
          await (db.delete(
            db.pendingSyncOps,
          )..where((t) => t.opId.equals(op.opId))).go();
          count++;
        } catch (_) {
          error = 'Không kết nối được máy chủ hoặc máy chủ từ chối dữ liệu. Sẽ tự thử lại.';
          await (db.update(
            db.pendingSyncOps,
          )..where((t) => t.opId.equals(op.opId))).write(
            PendingSyncOpsCompanion(
              retryCount: Value(op.retryCount + 1),
              lastError: Value(error),
              nextAttemptAtUtcMs: Value(
                now().toUtc().millisecondsSinceEpoch +
                    min(300, 2 * pow(2, min(op.retryCount, 8)).toInt()) * 1000,
              ),
            ),
          );
          break;
        }
      }
      // A failed push must not prevent downloading remote tombstones.
      if (await isEnabled()) {
        try {
          var state = await (db.select(
            db.syncStates,
          )..where((t) => t.collection.equals('history'))).getSingleOrNull();
          var cursor = state?.lastCursor;
          for (var i = 0; i < 10 && await isEnabled(); i++) {
            final page = await remote.pull(cursor);
            await db.transaction(() async {
              for (final record in page.records) {
                final id = record['id'] as String;
                final local = await (db.select(
                  db.recognitionHistoryRows,
                )..where((t) => t.id.equals(id))).getSingleOrNull();
                final deletedAt = record['deletedAt'] as int?;
                // Deletion wins; an older upsert never resurrects a record.
                if (local?.deletedAtUtcMs != null && deletedAt == null) {
                  continue;
                }
                await db
                    .into(db.recognitionHistoryRows)
                    .insertOnConflictUpdate(
                      RecognitionHistoryRowsCompanion.insert(
                        id: id,
                        signCode: record['signCode'] as String,
                        labelSnapshot: record['label'] as String,
                        confirmedAtUtcMs: record['confirmedAt'] as int,
                        deletedAtUtcMs: Value(deletedAt),
                        imageRelativePath: Value(local?.imageRelativePath),
                      ),
                    );
              }
              await db
                  .into(db.syncStates)
                  .insertOnConflictUpdate(
                    SyncStatesCompanion.insert(
                      collection: 'history',
                      lastCursor: Value(page.cursor),
                      lastSuccessAtUtcMs: Value(
                        now().toUtc().millisecondsSinceEpoch,
                      ),
                    ),
                  );
            });
            if (!page.hasMore) break;
            if (cursor == page.cursor) {
              throw StateError('Cursor did not advance');
            }
            cursor = page.cursor;
          }
        } catch (_) {
          error ??= 'Chưa tải được thay đổi từ máy chủ. Sẽ tự thử lại.';
        }
      }
    }
    return SyncResult(
      syncedCount: count,
      pendingCount: await watchPendingCount().first,
      error: error,
    );
  }
}
