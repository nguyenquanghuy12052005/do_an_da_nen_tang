import 'package:drift/drift.dart';

import '../../../features/history/domain/entities/recognition_record.dart';
import '../../../features/history/domain/repositories/recognition_history_repository.dart';
import '../app_database.dart';

class LocalRecognitionHistoryRepository
    implements RecognitionHistoryRepository {
  const LocalRecognitionHistoryRepository(this.database);

  final AppDatabase database;

  @override
  Stream<List<RecognitionRecord>> watchHistory() {
    final query = database.select(database.recognitionHistoryRows)
      ..where((table) => table.deletedAtUtcMs.isNull())
      ..orderBy([(table) => OrderingTerm.desc(table.confirmedAtUtcMs)]);
    return query.watch().map(
      (rows) => rows.map(_toEntity).toList(growable: false),
    );
  }

  @override
  Future<void> saveConfirmed(RecognitionRecord record) async {
    await database.transaction(() async {
      await database
          .into(database.recognitionHistoryRows)
          .insert(
            RecognitionHistoryRowsCompanion.insert(
              id: record.id,
              signCode: record.signCode,
              labelSnapshot: record.label,
              confirmedAtUtcMs: record.confirmedAt
                  .toUtc()
                  .millisecondsSinceEpoch,
            ),
          );
    });
  }

  @override
  Future<void> delete(String id) async {
    await database.transaction(() async {
      await (database.update(database.recognitionHistoryRows)..where(
            (table) => table.id.equals(id) & table.deletedAtUtcMs.isNull(),
          ))
          .write(
            RecognitionHistoryRowsCompanion(
              deletedAtUtcMs: Value(
                DateTime.now().toUtc().millisecondsSinceEpoch,
              ),
            ),
          );
    });
  }

  RecognitionRecord _toEntity(RecognitionHistoryRow row) => RecognitionRecord(
    id: row.id,
    signCode: row.signCode,
    label: row.labelSnapshot,
    confirmedAt: DateTime.fromMillisecondsSinceEpoch(
      row.confirmedAtUtcMs,
      isUtc: true,
    ),
  );
}
