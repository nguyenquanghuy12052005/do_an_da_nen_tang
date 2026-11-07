import 'dart:convert';

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
    expect(session.answer(sample('A', .45), at), isTrue);
    expect(session.answer(sample('A', .9), at), isTrue);
    session.skip(at);
    expect(session.complete, isTrue);
    expect(session.correctCount, 1);
    expect(session.gradedCount, 2);
    expect(session.answer(sample('C', 1), at), isFalse);
    expect(PracticeSession.fromJson(session.toJson()).answers.length, 3);
  });
  test('SQLite limits and orders pages with 5000 saved sessions', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalLearningRepository(db);
    final at = DateTime.utc(2026);
    await db.batch((batch) {
      batch.insertAll(
        db.learningSessions,
        List.generate(5000, (i) {
          final id = i.toString().padLeft(4, '0');
          final session = PracticeSession(
            id: id,
            startedAt: at,
            targets: ['A'],
          );
          return LearningSessionsCompanion.insert(
            id: id,
            payloadJson: jsonEncode(session.toJson()),
            startedAtUtcMs: at.millisecondsSinceEpoch,
          );
        }),
      );
    });

    Future<List<String>> ids(int offset) async =>
        (await repository.watchSessions(limit: 5, offset: offset).first)
            .map((session) => session.id)
            .toList();
    expect(await ids(0), ['4999', '4998', '4997', '4996', '4995']);
    expect(await ids(95), ['4904', '4903', '4902', '4901', '4900']);
    expect(await ids(995), ['4004', '4003', '4002', '4001', '4000']);
    expect(await ids(4995), ['0004', '0003', '0002', '0001', '0000']);
    expect(await ids(5000), isEmpty);
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
