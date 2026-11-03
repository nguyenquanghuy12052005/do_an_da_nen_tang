import 'package:drift/drift.dart';

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../features/history/domain/entities/recognition_record.dart';
import '../../../features/history/domain/repositories/recognition_history_repository.dart';
import '../app_database.dart';
import '../sync_outbox.dart';

class LocalRecognitionHistoryRepository
    implements RecognitionHistoryRepository {
  const LocalRecognitionHistoryRepository(
    this.database, {
    this.photoDirectory = getApplicationSupportDirectory,
  });

  final AppDatabase database;
  final Future<Directory> Function() photoDirectory;

  Future<File> _photoFile(String name) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]+\.png$').hasMatch(name)) {
      throw ArgumentError('Invalid photo name');
    }
    final root = await photoDirectory();
    return File('${root.path}/history_photos/$name');
  }

  @override
  Stream<List<RecognitionRecord>> watchHistory({
    int? limit,
    RecognitionRecord? before,
  }) {
    if (limit != null && limit < 1) throw ArgumentError.value(limit);
    final query = database.select(database.recognitionHistoryRows)
      ..where((table) => table.deletedAtUtcMs.isNull())
      ..orderBy([
        (table) => OrderingTerm.desc(table.confirmedAtUtcMs),
        (table) => OrderingTerm.desc(table.id),
      ]);
    if (before != null) {
      final time = before.confirmedAt.toUtc().millisecondsSinceEpoch;
      query.where(
        (table) =>
            table.confirmedAtUtcMs.isSmallerThanValue(time) |
            (table.confirmedAtUtcMs.equals(time) &
                table.id.isSmallerThanValue(before.id)),
      );
    }
    if (limit != null) query.limit(limit);
    return query.watch().asyncMap(
      (rows) async => [for (final row in rows) await _toEntity(row)],
    );
  }

  @override
  Future<void> saveConfirmed(
    RecognitionRecord record, {
    Uint8List? photo,
  }) async {
    File? image;
    String? name;
    try {
      if (photo != null) {
        name =
            '${DateTime.now().microsecondsSinceEpoch}-${record.id.hashCode.abs()}.png';
        image = await _photoFile(name);
        await image.parent.create(recursive: true);
        await image.writeAsBytes(photo, flush: true);
      }
      await database.transaction(() async {
        await database
            .into(database.recognitionHistoryRows)
            .insert(
              RecognitionHistoryRowsCompanion.insert(
                id: record.id,
                signCode: record.signCode,
                imageRelativePath: Value(name),
                labelSnapshot: record.label,
                confirmedAtUtcMs: record.confirmedAt
                    .toUtc()
                    .millisecondsSinceEpoch,
              ),
            );
        await enqueueHistory(database, {
          'id': record.id,
          'signCode': record.signCode,
          'label': record.label,
          'confirmedAt': record.confirmedAt.toUtc().millisecondsSinceEpoch,
          'deletedAt': null,
        }, deleted: false);
      });
    } catch (_) {
      if (image != null && await image.exists()) await image.delete();
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    final row = await (database.select(
      database.recognitionHistoryRows,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    final image = row?.imageRelativePath == null
        ? null
        : await _photoFile(row!.imageRelativePath!);
    await database.transaction(() async {
      if (row == null || row.deletedAtUtcMs != null) return;
      final deletedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (database.update(database.recognitionHistoryRows)..where(
            (table) => table.id.equals(id) & table.deletedAtUtcMs.isNull(),
          ))
          .write(
            RecognitionHistoryRowsCompanion(
              deletedAtUtcMs: Value(deletedAt),
              imageRelativePath: const Value(null),
            ),
          );
      await enqueueHistory(database, {
        ...historyPayload(row),
        'deletedAt': deletedAt,
      }, deleted: true);
    });
    if (image != null && await image.exists()) await image.delete();
  }

  Future<RecognitionRecord> _toEntity(RecognitionHistoryRow row) async =>
      RecognitionRecord(
        id: row.id,
        signCode: row.signCode,
        label: row.labelSnapshot,
        imagePath: row.imageRelativePath == null
            ? null
            : (await _photoFile(row.imageRelativePath!)).path,
        confirmedAt: DateTime.fromMillisecondsSinceEpoch(
          row.confirmedAtUtcMs,
          isUtc: true,
        ),
      );
}
