import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../features/learning/domain/practice_session.dart';
import '../app_database.dart';
import '../sync_outbox.dart';

class LocalLearningRepository implements LearningRepository {
  const LocalLearningRepository(this.db, {this.syncLearning = false});
  final bool syncLearning;
  final AppDatabase db;
  @override
  Future<void> save(PracticeSession session) => db.transaction(() async {
    final snapshot = session.toJson();
    await db
        .into(db.learningSessions)
        .insertOnConflictUpdate(
          LearningSessionsCompanion.insert(
            id: session.id,
            payloadJson: jsonEncode(snapshot),
            startedAtUtcMs: session.startedAt.toUtc().millisecondsSinceEpoch,
          ),
        );
    if (syncLearning && await isLocalSyncEnabled(db)) {
      await enqueueLearning(db, snapshot);
    }
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
