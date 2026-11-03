import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:lingosign_ai/data/local/app_database.dart';
import 'package:lingosign_ai/data/local/repositories/local_recognition_history_repository.dart';
import 'package:lingosign_ai/features/history/domain/entities/recognition_record.dart';

void main() {
  test('filters compose before paging; feedback preserves original prediction and confidence', () async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      final repo = LocalRecognitionHistoryRepository(db);
      final date = DateTime(2026, 11, 3, 12);
      for (var i = 0; i < 15; i++) {
        await repo.saveConfirmed(
          RecognitionRecord(
            id: '$i',
            signCode: 'A',
            label: 'A',
            confirmedAt: date.add(Duration(seconds: i)),
            confidence: .8,
          ),
        );
      }
      await repo.updateReview(
        '3',
        favorite: true,
        incorrect: true,
        note: 'fixture',
      );
      final row =
          (await repo
                  .watchHistory(
                    filter: HistoryFilter(
                      query: 'A',
                      day: date,
                      favoritesOnly: true,
                    ),
                    limit: 10,
                  )
                  .first)
              .single;
      expect(row.id, '3');
      expect(row.confidence, .8);
      expect(row.incorrect, isTrue);
      expect(row.label, 'A');
      expect(
        await repo.watchHistory(filter: const HistoryFilter(query: 'B')).first,
        isEmpty,
      );
      final first = await repo.watchHistory(limit: 10).first;
      final second = await repo
          .watchHistory(limit: 10, before: first.last)
          .first;
      expect(first.length, 10);
      expect(second.length, 5);
      expect(
        (await db.select(db.pendingSyncOps).get()).length,
        15,
      ); // Feedback does not change sync/model payload.
    } finally {
      await db.close();
    }
  });
}
