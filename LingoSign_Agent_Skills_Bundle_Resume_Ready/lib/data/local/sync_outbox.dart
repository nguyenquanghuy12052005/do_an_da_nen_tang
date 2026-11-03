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
