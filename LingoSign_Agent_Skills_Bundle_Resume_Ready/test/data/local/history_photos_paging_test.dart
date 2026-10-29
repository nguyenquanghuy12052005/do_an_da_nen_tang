import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/data/local/app_database.dart';
import 'package:lingosign_ai/data/local/repositories/local_recognition_history_repository.dart';
import 'package:lingosign_ai/features/history/domain/entities/recognition_record.dart';

void main() {
  late AppDatabase db;
  late Directory directory;
  late LocalRecognitionHistoryRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('history-photos-');
    db = AppDatabase(NativeDatabase(File('${directory.path}/test.sqlite')));
    repository = LocalRecognitionHistoryRepository(
      db,
      photoDirectory: () async => directory,
    );
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });
  RecognitionRecord record(String id) => RecognitionRecord(
    id: id,
    signCode: 'A',
    label: 'A',
    confirmedAt: DateTime.utc(2026),
  );

  test(
    'keyset pages handle equal timestamps and do not load entire history',
    () async {
      for (var i = 0; i < 23; i++) {
        await repository.saveConfirmed(record(i.toString().padLeft(3, '0')));
      }
      final first = await repository.watchHistory(limit: 10).first;
      final second = await repository
          .watchHistory(limit: 10, before: first.last)
          .first;
      final third = await repository
          .watchHistory(limit: 10, before: second.last)
          .first;
      expect(first.length, 10);
      expect(second.length, 10);
      expect(third.length, 3);
      expect(
        {
          ...first.map((r) => r.id),
          ...second.map((r) => r.id),
          ...third.map((r) => r.id),
        }.length,
        23,
      );
    },
  );

  test(
    'persists private photo path, resolves bytes after reopen, deletes photo',
    () async {
      await repository.saveConfirmed(
        record('photo'),
        photo: Uint8List.fromList([1, 2, 3]),
      );
      final saved = (await repository.watchHistory().first).single;
      await db.close();
      db = AppDatabase(NativeDatabase(File('${directory.path}/test.sqlite')));
      repository = LocalRecognitionHistoryRepository(
        db,
        photoDirectory: () async => directory,
      );
      expect(
        (await repository.watchHistory().first).single.imagePath,
        saved.imagePath,
      );
      final file = File(saved.imagePath!);
      expect(await file.readAsBytes(), [1, 2, 3]);
      final row = await db.select(db.recognitionHistoryRows).getSingle();
      expect(row.imageRelativePath, isNot(contains(directory.path)));
      await repository.delete('photo');
      expect(await file.exists(), isFalse);
      expect(await repository.watchHistory().first, isEmpty);
    },
  );

  test(
    'failed insert removes its photo and preserves existing snapshot',
    () async {
      await repository.saveConfirmed(record('duplicate'));
      await expectLater(
        repository.saveConfirmed(
          record('duplicate'),
          photo: Uint8List.fromList([1]),
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        await Directory('${directory.path}/history_photos').list().length,
        0,
      );
    },
  );

  test('v2 migration adds nullable photo without losing history', () async {
    await db.customStatement('SELECT 1');
    await db.customStatement(
      'ALTER TABLE recognition_history_rows DROP COLUMN image_relative_path',
    );
    await db.customStatement(
      "INSERT INTO recognition_history_rows VALUES ('legacy', 'A', 'A', 0, NULL)",
    );
    final file = File('${directory.path}/v2.sqlite');
    await db.customStatement('VACUUM INTO ?', [file.path]);
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    // Set the stored old version before reopening through Drift.
    await db.close();
    final executor = NativeDatabase(
      file,
      setup: (raw) => raw.execute('PRAGMA user_version = 2'),
    );
    db = AppDatabase(executor);
    repository = LocalRecognitionHistoryRepository(
      db,
      photoDirectory: () async => directory,
    );
    final migrated = (await repository.watchHistory().first).single;
    expect(migrated.id, 'legacy');
    expect(migrated.imagePath, isNull);
  });
}
