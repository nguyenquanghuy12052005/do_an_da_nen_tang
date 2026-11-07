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
  Stream<List<PracticeSession>> watchSessions({int? limit, int offset = 0}) {
    final query = db.select(db.learningSessions)
      ..orderBy([
        (row) => OrderingTerm.desc(row.startedAtUtcMs),
        (row) => OrderingTerm.desc(row.id),
      ]);
    if (limit != null) query.limit(limit, offset: offset);
    // Keep only the latest snapshot for each row in this subscription.
    // Drift may re-emit the whole result when a single session changes.
    var decoded = <String, (String, PracticeSession)>{};
    return query.watch().map((rows) {
      final current = <String, (String, PracticeSession)>{};
      for (final row in rows) {
        final previous = decoded[row.id];
        current[row.id] = previous != null && previous.$1 == row.payloadJson
            ? previous
            : (
                row.payloadJson,
                PracticeSession.fromJson(
                  jsonDecode(row.payloadJson) as Map<String, dynamic>,
                ),
              );
      }
      decoded = current;
      return current.values.map((entry) => entry.$2).toList();
    });
  }
}
