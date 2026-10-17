import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/data/local/app_database.dart';
import 'package:lingosign_ai/data/local/repositories/local_recognition_history_repository.dart';
import 'package:lingosign_ai/data/local/repositories/local_sign_dictionary_repository.dart';
import 'package:lingosign_ai/features/dictionary/domain/entities/sign_entry.dart';
import 'package:lingosign_ai/features/history/domain/entities/recognition_record.dart';

void main() {
  late Directory tempDirectory;
  late File databaseFile;
  late AppDatabase database;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('lingosign-db-');
    databaseFile = File('${tempDirectory.path}/lingosign.sqlite');
    database = AppDatabase(NativeDatabase(databaseFile));
  });

  tearDown(() async {
    await database.close();
    await tempDirectory.delete(recursive: true);
  });

  test(
    'creates schema v1 and persists catalog and history after restart',
    () async {
      final dictionary = LocalSignDictionaryRepository(database);
      final history = LocalRecognitionHistoryRepository(database);
      final timestamp = DateTime.utc(2026, 10, 17);
      const fixture = SignEntry(code: 'TEST_01', label: 'Ký hiệu thử nghiệm');

      await dictionary.upsertVerifiedCatalog(
        entries: [fixture],
        catalogVersion: 'test-only',
        sourceUrl: 'https://example.test/test-fixture',
        licenseName: 'test-fixture-only',
        updatedAt: timestamp,
      );
      await history.saveConfirmed(
        RecognitionRecord(
          id: 'record-1',
          signCode: fixture.code,
          label: fixture.label,
          confirmedAt: timestamp,
        ),
      );

      expect(database.schemaVersion, 1);
      expect((await dictionary.search('thử nghiệm')).single.code, fixture.code);
      expect((await history.watchHistory().first).single.id, 'record-1');
      await database.close();

      database = AppDatabase(NativeDatabase(databaseFile));
      final reopenedDictionary = LocalSignDictionaryRepository(database);
      final reopenedHistory = LocalRecognitionHistoryRepository(database);
      expect(
        (await reopenedDictionary.findByCode(fixture.code))?.label,
        fixture.label,
      );
      expect(
        (await reopenedHistory.watchHistory().first).single.id,
        'record-1',
      );
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), 1);
    },
  );

  test(
    'rejects catalog without provenance and leaves database empty',
    () async {
      final dictionary = LocalSignDictionaryRepository(database);
      await expectLater(
        dictionary.upsertVerifiedCatalog(
          entries: [const SignEntry(code: 'TEST_01', label: 'Fixture')],
          catalogVersion: '',
          sourceUrl: '',
          licenseName: '',
          updatedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
      expect(await dictionary.search(''), isEmpty);
    },
  );

  test('foreign key rejects history for an unknown sign', () async {
    final history = LocalRecognitionHistoryRepository(database);
    await expectLater(
      history.saveConfirmed(
        RecognitionRecord(
          id: 'invalid',
          signCode: 'MISSING',
          label: 'Unknown',
          confirmedAt: DateTime.utc(2026),
        ),
      ),
      throwsA(isA<Exception>()),
    );
    expect(await history.watchHistory().first, isEmpty);
  });

  test('delete hides history with tombstone and preserves catalog', () async {
    final dictionary = LocalSignDictionaryRepository(database);
    final history = LocalRecognitionHistoryRepository(database);
    await dictionary.upsertVerifiedCatalog(
      entries: [const SignEntry(code: 'TEST_01', label: 'Fixture')],
      catalogVersion: 'test-only',
      sourceUrl: 'https://example.test/test-fixture',
      licenseName: 'test-fixture-only',
      updatedAt: DateTime.utc(2026),
    );
    await history.saveConfirmed(
      RecognitionRecord(
        id: 'record-1',
        signCode: 'TEST_01',
        label: 'Fixture',
        confirmedAt: DateTime.utc(2026),
      ),
    );

    await history.delete('record-1');
    expect(await history.watchHistory().first, isEmpty);
    expect(await dictionary.findByCode('TEST_01'), isNotNull);
    final rows = await database.select(database.recognitionHistoryRows).get();
    expect(rows.single.deletedAtUtcMs, isNotNull);
  });
}
