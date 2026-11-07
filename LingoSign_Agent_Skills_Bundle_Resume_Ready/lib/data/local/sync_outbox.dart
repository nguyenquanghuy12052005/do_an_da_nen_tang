import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';

/// Call inside the same transaction as the history mutation.
Future<void> enqueueHistory(
  AppDatabase db,
  Map<String, Object?> record, {
  required bool deleted,
}) async {
  final id = record['id'] as String;
  final operation = deleted ? 'delete' : 'upsert';
  await db
      .into(db.pendingSyncOps)
      .insert(
        PendingSyncOpsCompanion.insert(
          opId: deleted
              ? '$operation:$id:${record['deletedAt']}'
              : '$operation:$id',
          entity: 'history',
          entityId: id,
          operation: operation,
          payloadJson: jsonEncode(record),
          createdAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        ),
        mode: InsertMode.insertOrIgnore,
      );
}

Map<String, Object?> historyPayload(RecognitionHistoryRow row) => {
  'id': row.id,
  'signCode': row.signCode,
  'label': row.labelSnapshot,
  'confirmedAt': row.confirmedAtUtcMs,
  'deletedAt': row.deletedAtUtcMs,
};

/// Call inside the same transaction as the practice mutation.
Future<void> enqueueLearning(
  AppDatabase db,
  Map<String, Object?> snapshot,
) async {
  final id = snapshot['id'] as String;
  final count = (snapshot['answers'] as List).length;
  await db
      .into(db.pendingSyncOps)
      .insert(
        PendingSyncOpsCompanion.insert(
          opId: 'learning:$id:$count',
          entity: 'learning',
          entityId: id,
          operation: 'upsert',
          payloadJson: jsonEncode({'id': id, 'learning': snapshot}),
          createdAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        ),
        mode: InsertMode.insertOrIgnore,
      );
}

Future<bool> isLocalSyncEnabled(AppDatabase db) async =>
    (await (db.select(
          db.appSettings,
        )..where((t) => t.key.equals('sync_enabled'))).getSingleOrNull())
        ?.valueJson ==
    'true';
