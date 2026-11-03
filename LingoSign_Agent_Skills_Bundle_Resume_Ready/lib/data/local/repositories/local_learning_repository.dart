import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../features/learning/domain/practice_session.dart';
import '../app_database.dart';

class LocalLearningRepository implements LearningRepository {
  const LocalLearningRepository(this.db);
  final AppDatabase db;
  @override
  Future<void> save(PracticeSession session) => db.transaction(() async {
    await db
        .into(db.learningSessions)
        .insertOnConflictUpdate(
          LearningSessionsCompanion.insert(
            id: session.id,
            payloadJson: jsonEncode(session.toJson()),
            startedAtUtcMs: session.startedAt.toUtc().millisecondsSinceEpoch,
          ),
        );
  });
  @override
  Stream<List<PracticeSession>> watchSessions() =>
      (db.select(
        db.learningSessions,
      )..orderBy([(row) => OrderingTerm.desc(row.startedAtUtcMs)])).watch().map(
        (rows) => rows
            .map(
              (row) => PracticeSession.fromJson(
                jsonDecode(row.payloadJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
}
