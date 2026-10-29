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

      expect(database.schemaVersion, 3);
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
      expect(version.read<int>('user_version'), 3);
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

  test('saves model labels before dictionary content is available', () async {
    final history = LocalRecognitionHistoryRepository(database);
    await history.saveConfirmed(
      RecognitionRecord(
        id: 'invalid',
        signCode: 'MISSING',
        label: 'Unknown',
        confirmedAt: DateTime.utc(2026),
      ),
    );
    expect((await history.watchHistory().first).single.signCode, 'MISSING');
  });

  test('upgrades v1 history without losing existing rows', () async {
    await database.customStatement(
      'CREATE TABLE IF NOT EXISTS sign_entries (code TEXT PRIMARY KEY)',
    );
    // Use a separate v1 database to exercise the real upgrade path.
    final legacyFile = File('${tempDirectory.path}/legacy.sqlite');
    final legacy = NativeDatabase(legacyFile);
    final legacyDb = AppDatabase(legacy);
    await legacyDb.customStatement('SELECT 1');
    await legacyDb.customStatement(
      'ALTER TABLE recognition_history_rows RENAME TO history_v2',
    );
    await legacyDb.customStatement(
      'CREATE TABLE recognition_history_rows (id TEXT NOT NULL PRIMARY KEY, sign_code TEXT NOT NULL REFERENCES sign_entries(code), label_snapshot TEXT NOT NULL, confirmed_at_utc_ms INTEGER NOT NULL, deleted_at_utc_ms INTEGER) STRICT',
    );
    await legacyDb.customStatement('DROP TABLE history_v2');
    await legacyDb.customStatement(
      "INSERT INTO sign_entries (code, label_vi, catalog_version, source_url, license_name, updated_at_utc_ms) VALUES ('TEST', 'Fixture', 'test', 'https://example.test', 'test-only', 0)",
    );
    await legacyDb.customStatement(
      "INSERT INTO recognition_history_rows VALUES ('old', 'TEST', 'Fixture', 0, NULL)",
    );
    await legacyDb.customStatement('PRAGMA user_version = 1');
    await legacyDb.close();
    final upgraded = AppDatabase(NativeDatabase(legacyFile));
    try {
      final history = LocalRecognitionHistoryRepository(upgraded);
      await history.saveConfirmed(
        RecognitionRecord(
          id: 'auto',
          signCode: 'A',
          label: 'A',
          confirmedAt: DateTime.utc(2026),
        ),
      );
      final records = await history.watchHistory().first;
      expect(records.map((record) => record.id), containsAll(['auto', 'old']));
      final keys = await upgraded
          .customSelect('PRAGMA foreign_key_list(recognition_history_rows)')
          .get();
      expect(keys, isEmpty);
    } finally {
      await upgraded.close();
    }
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
