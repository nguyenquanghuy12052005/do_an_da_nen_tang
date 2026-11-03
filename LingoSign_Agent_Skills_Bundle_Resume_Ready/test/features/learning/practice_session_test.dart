import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:lingosign_ai/features/learning/domain/practice_session.dart';
import 'package:lingosign_ai/features/recognition/domain/entities/recognition_prediction.dart';
import 'package:lingosign_ai/data/local/app_database.dart';
import 'package:lingosign_ai/data/local/repositories/local_learning_repository.dart';

void main() {
  test('weak/unknown do not consume question; grade, skip and round-trip', () {
    final at = DateTime.utc(2026);
    final session = PracticeSession(
      id: 'fixture',
      startedAt: at,
      targets: ['A', 'B', 'C'],
    );
    RecognitionPrediction sample(String? label, double score) =>
        RecognitionPrediction(
          labelId: label,
          confidence: score,
          timestamp: at,
          isStable: false,
        );
    expect(session.answer(sample(null, 1), at), isFalse);
    expect(session.answer(sample('A', .4), at), isFalse);
    expect(session.answers, isEmpty);
    expect(session.answer(sample('A', .8), at), isTrue);
    expect(session.answer(sample('A', .9), at), isTrue);
    session.skip(at);
    expect(session.complete, isTrue);
    expect(session.correctCount, 1);
    expect(session.gradedCount, 2);
    expect(session.answer(sample('C', 1), at), isFalse);
    expect(PracticeSession.fromJson(session.toJson()).answers.length, 3);
  });
  test(
    'SQLite persists partial session and upserts without duplication',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final repository = LocalLearningRepository(db);
        final session = PracticeSession(
          id: 'fixture',
          startedAt: DateTime.utc(2026),
          targets: ['A'],
        );
        await repository.save(session);
        expect(
          (await repository.watchSessions().first).single.complete,
          isFalse,
        );
        session.skip(DateTime.utc(2026));
        await repository.save(session);
        expect(
          (await repository.watchSessions().first).single.complete,
          isTrue,
        );
      } finally {
        await db.close();
      }
    },
  );
}
