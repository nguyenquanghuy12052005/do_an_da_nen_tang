import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/data/local/app_database.dart';
import 'package:lingosign_ai/data/local/repositories/local_recognition_history_repository.dart';
import 'package:lingosign_ai/data/local/repositories/local_sync_repository.dart';

import '../../fixtures/recognition_record_fixture.dart';

import 'package:lingosign_ai/data/local/repositories/local_learning_repository.dart';
import 'package:lingosign_ai/features/learning/domain/practice_session.dart';

import 'package:lingosign_ai/features/sync/domain/entities/sync_operation.dart';
import 'package:lingosign_ai/features/sync/domain/repositories/sync_remote.dart';

class FakeRemote implements SyncRemote {
  bool online = true;
  bool loseAck = false;
  int attempts = 0;
  final operations = <String, SyncOperation>{};
  final records = <String, Map<String, Object?>>{};
  Completer<void>? gate;
  @override
  Future<void> push(SyncOperation operation) async {
    attempts++;
    await gate?.future;
    if (!online) throw const SocketException('offline fixture');
    operations[operation.id] = operation;
    records[operation.record['id'] as String] = operation.record;
    if (loseAck) throw const SocketException('lost ack fixture');
  }

  @override
  Future<SyncPage> pull(String? cursor) async {
    if (!online) throw const SocketException('offline fixture');
    return SyncPage(
      records: records.values.toList(),
      cursor: '1',
      hasMore: false,
    );
  }
}

void main() {
  late Directory directory;
  late AppDatabase db;
  late FakeRemote remote;
  late LocalRecognitionHistoryRepository history;
  late LocalSyncRepository sync;
  late DateTime now;
  void wire() {
    history = LocalRecognitionHistoryRepository(db);
    sync = LocalSyncRepository(db, remote, now: () => now);
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sync-fixture-');
    db = AppDatabase(NativeDatabase(File('${directory.path}/test.sqlite')));
    remote = FakeRemote();
    now = DateTime.utc(2026, 11, 3);
    wire();
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test(
    'account learning stays local offline and restores after sync',
    () async {
      final otherDevice = AppDatabase(NativeDatabase.memory());
      final differentAccount = AppDatabase(NativeDatabase.memory());
      addTearDown(otherDevice.close);
      addTearDown(differentAccount.close);
      final learning = LocalLearningRepository(db, syncLearning: true);
      final accountSync = LocalSyncRepository(
        db,
        remote,
        now: () => now,
        syncLearning: true,
      );
      final session = PracticeSession(
        id: 'practice-test',
        startedAt: now,
        targets: ['A', 'B'],
        answers: [PracticeAnswer(target: 'A', at: now)],
      );
      await learning.save(session);
      expect(await accountSync.watchPendingCount().first, 0);
      await accountSync.setEnabled(true);
      remote.online = false;
      expect((await accountSync.synchronize()).pendingCount, 1);
      session.skip(now);
      await learning.save(session);
      expect((await learning.watchSessions().first).single.complete, isTrue);
      expect(
        await LocalLearningRepository(differentAccount).watchSessions().first,
        isEmpty,
      );

      remote.online = true;
      now = now.add(const Duration(seconds: 3));
      expect((await accountSync.synchronize()).pendingCount, 0);
      final restore = LocalSyncRepository(
        otherDevice,
        remote,
        syncLearning: true,
      );
      await restore.setEnabled(true);
      expect((await restore.synchronize()).error, isNull);
      final restored = (await LocalLearningRepository(
        otherDevice,
      ).watchSessions().first).single;
      expect(restored.complete, isTrue);
      expect(restored.answers.length, 2);
    },
  );

  test('disabled by default; history and durable queue survive restart; backoff retries after reconnect', () async {
    await history.saveConfirmed(record('offline'));
    expect(await sync.isEnabled(), isFalse);
    expect((await sync.synchronize()).pendingCount, 1);
    expect(remote.attempts, 0);
    await sync.setEnabled(true);
    remote.online = false;
    expect((await sync.synchronize()).error, isNotNull);
    final failed = await db.select(db.pendingSyncOps).getSingle();
    expect(failed.retryCount, 1);
    expect(failed.nextAttemptAtUtcMs, now.millisecondsSinceEpoch + 2000);
    await db.close();
    db = AppDatabase(NativeDatabase(File('${directory.path}/test.sqlite')));
    wire();
    expect(await sync.isEnabled(), isTrue);
    expect((await history.watchHistory().first).single.id, 'offline');
    remote.online = true;
    await sync.synchronize();
    expect(
      remote.attempts,
      1,
    ); // Retry deadline persists across process restart.
    now = now.add(const Duration(seconds: 2));
    expect((await sync.synchronize()).pendingCount, 0);
    expect(remote.operations.length, 1);
  });

  test('lost acknowledgement retries same op id without duplicating; concurrent sync serializes', () async {
    await history.saveConfirmed(record('ack'));
    await sync.setEnabled(true);
    remote.loseAck = true;
    await sync.synchronize();
    expect(remote.operations.length, 1);
    remote.loseAck = false;
    remote.gate = Completer<void>();
    now = now.add(const Duration(seconds: 3));
    final first = sync.synchronize();
    final second = sync.synchronize();
    await Future<void>.delayed(Duration.zero);
    remote.gate!.complete();
    await Future.wait([first, second]);
    expect(remote.attempts, 2);
    expect(remote.operations.length, 1);
    expect(await db.select(db.pendingSyncOps).get(), isEmpty);
  });

  test('history and outbox rollback together if queue insert fails', () async {
    await db.customStatement(
      "CREATE TRIGGER fail_outbox BEFORE INSERT ON pending_sync_ops BEGIN SELECT RAISE(ABORT, 'fixture'); END",
    );
    await expectLater(
      history.saveConfirmed(record('rollback')),
      throwsA(isA<Exception>()),
    );
    expect(await history.watchHistory().first, isEmpty);
    expect(await db.select(db.pendingSyncOps).get(), isEmpty);
  });

  test('delete is queued once; stale remote upsert cannot resurrect local tombstone; pull makes no outbox loop', () async {
    await history.saveConfirmed(record('deleted'));
    await sync.setEnabled(true);
    await sync.synchronize();
    await history.delete('deleted');
    await history.delete('deleted');
    expect((await db.select(db.pendingSyncOps).get()).length, 1);
    // Block push with a persisted retry deadline; pull still sees old upsert.
    remote.online = false;
    await sync.synchronize();
    remote.online = true;
    await sync.synchronize();
    expect(await history.watchHistory().first, isEmpty);
    now = now.add(const Duration(seconds: 3));
    expect((await sync.synchronize()).pendingCount, 0);
    expect(remote.records['deleted']!['deletedAt'], isNotNull);
    await sync.synchronize();
    expect(await db.select(db.pendingSyncOps).get(), isEmpty);
    expect((await db.select(db.syncStates).getSingle()).lastCursor, '1');
  });

  test(
    'schema v3 upgrade preserves pending operations and enables retry column',
    () async {
      await history.saveConfirmed(record('legacy'));
      await db.customStatement(
        'ALTER TABLE pending_sync_ops DROP COLUMN next_attempt_at_utc_ms',
      );
      await db.customStatement('PRAGMA user_version = 3');
      await db.close();
      db = AppDatabase(NativeDatabase(File('${directory.path}/test.sqlite')));
      wire();
      expect(
        (await db.select(db.pendingSyncOps).getSingle()).nextAttemptAtUtcMs,
        0,
      );
      expect((await history.watchHistory().first).single.id, 'legacy');
    },
  );
  test('invalid pull rolls back records and cursor together', () async {
    await sync.setEnabled(true);
    remote.records['valid'] = {
      'id': 'valid',
      'signCode': 'A',
      'label': 'A',
      'confirmedAt': 0,
      'deletedAt': null,
    };
    remote.records['invalid'] = {
      'id': 'invalid',
      'confirmedAt': 'invalid fixture',
    };
    expect((await sync.synchronize()).error, isNotNull);
    expect(await history.watchHistory().first, isEmpty);
    expect(await db.select(db.syncStates).get(), isEmpty);
    remote.records.remove('invalid');
    expect((await sync.synchronize()).error, isNull);
    expect((await history.watchHistory().first).single.id, 'valid');
    expect(await db.select(db.pendingSyncOps).get(), isEmpty);
  });
}
