import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/data/local/app_database.dart';
import 'package:lingosign_ai/data/local/repositories/local_learning_repository.dart';
import 'package:lingosign_ai/features/learning/domain/practice_session.dart';

void main() {
  test(
    'real v4 upgrade retains history; session survives repeated process reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'learning-migration-',
      );
      final file = File('${directory.path}/fixture.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      try {
        await db.customStatement(
          "INSERT INTO recognition_history_rows(id,sign_code,label_snapshot,confirmed_at_utc_ms) VALUES ('fixture','A','A',0)",
        );
        await db.customStatement('DROP TABLE learning_sessions');
        await db.customStatement('DROP TABLE history_reviews');
        await db.customStatement(
          'ALTER TABLE sign_entries DROP COLUMN details_json',
        );
        await db.customStatement('PRAGMA user_version = 4');
        await db.close();
        db = AppDatabase(NativeDatabase(file));
        expect(
          (await db.select(db.recognitionHistoryRows).getSingle()).id,
          'fixture',
        );
        final session = PracticeSession(
          id: 'fixture',
          startedAt: DateTime.utc(2026),
          targets: ['A'],
        );
        session.skip(DateTime.utc(2026));
        await LocalLearningRepository(db).save(session);
        await db.close();
        db = AppDatabase(NativeDatabase(file));
        expect(
          (await LocalLearningRepository(
            db,
          ).watchSessions().first).single.complete,
          isTrue,
        );
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
