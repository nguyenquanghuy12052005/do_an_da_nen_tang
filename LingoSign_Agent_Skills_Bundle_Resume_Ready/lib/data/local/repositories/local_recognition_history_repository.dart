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

  Future<File> _photoFile(String name) async =>
      _photoFileIn(await photoDirectory(), name);

  static File _photoFileIn(Directory root, String name) {
    if (!RegExp(r'^[a-zA-Z0-9_-]+\.png$').hasMatch(name)) {
      throw ArgumentError('Invalid photo name');
    }
    return File('${root.path}/history_photos/$name');
  }

  @override
  Stream<List<RecognitionRecord>> watchHistory({
    int? limit,
    RecognitionRecord? before,
    HistoryFilter filter = const HistoryFilter(),
  }) {
    if (limit != null && limit < 1) throw ArgumentError.value(limit);
    final table = database.recognitionHistoryRows;
    final reviews = database.historyReviews;
    final query =
        database.select(table).join([
            leftOuterJoin(reviews, reviews.id.equalsExp(table.id)),
          ])
          ..where(table.deletedAtUtcMs.isNull())
          ..orderBy([
            OrderingTerm.desc(table.confirmedAtUtcMs),
            OrderingTerm.desc(table.id),
          ]);
    final search = filter.query.trim();
    if (search.isNotEmpty) {
      query.where(
        table.labelSnapshot.contains(search) | table.signCode.contains(search),
      );
    }
    if (filter.favoritesOnly) query.where(reviews.favorite.equals(true));
    if (filter.day case final day?) {
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day + 1);
      query.where(
        table.confirmedAtUtcMs.isBiggerOrEqualValue(
              start.toUtc().millisecondsSinceEpoch,
            ) &
            table.confirmedAtUtcMs.isSmallerThanValue(
              end.toUtc().millisecondsSinceEpoch,
            ),
      );
    }
    if (before != null) {
      final time = before.confirmedAt.toUtc().millisecondsSinceEpoch;
      query.where(
        table.confirmedAtUtcMs.isSmallerThanValue(time) |
            (table.confirmedAtUtcMs.equals(time) &
                table.id.isSmallerThanValue(before.id)),
      );
    }
    if (limit != null) query.limit(limit);
    return query.watch().asyncMap((rows) async {
      Directory? photoRoot;
      final records = <RecognitionRecord>[];
      for (final row in rows) {
        final history = row.readTable(table);
        final name = history.imageRelativePath;
        final imagePath = name == null
            ? null
            : _photoFileIn(photoRoot ??= await photoDirectory(), name).path;
        records.add(
          _toEntity(history, row.readTableOrNull(reviews), imagePath),
        );
      }
      return records;
    });
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
        await database
            .into(database.historyReviews)
            .insert(
              HistoryReviewsCompanion.insert(
                id: record.id,
                confidence: Value(record.confidence),
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

  @override
  Future<void> updateReview(
    String id, {
    bool? favorite,
    bool? incorrect,
    String? note,
  }) => database.transaction(() async {
    final current = await (database.select(
      database.historyReviews,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    await database
        .into(database.historyReviews)
        .insertOnConflictUpdate(
          HistoryReviewsCompanion.insert(
            id: id,
            confidence: Value(current?.confidence),
            favorite: Value(favorite ?? current?.favorite ?? false),
            incorrect: Value(incorrect ?? current?.incorrect ?? false),
            note: Value(note ?? current?.note),
          ),
        );
  });

  RecognitionRecord _toEntity(
    RecognitionHistoryRow row,
    HistoryReview? review,
    String? imagePath,
  ) => RecognitionRecord(
    id: row.id,
    signCode: row.signCode,
    label: row.labelSnapshot,
    confidence: review?.confidence,
    favorite: review?.favorite ?? false,
    incorrect: review?.incorrect ?? false,
    note: review?.note,
    imagePath: imagePath,
    confirmedAt: DateTime.fromMillisecondsSinceEpoch(
      row.confirmedAtUtcMs,
      isUtc: true,
    ),
  );
}
