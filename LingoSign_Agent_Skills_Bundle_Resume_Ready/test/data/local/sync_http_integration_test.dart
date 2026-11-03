import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/data/local/app_database.dart';
import 'package:lingosign_ai/data/local/repositories/local_recognition_history_repository.dart';
import 'package:lingosign_ai/data/local/repositories/local_sync_repository.dart';
import 'package:lingosign_ai/features/sync/data/http_sync_remote.dart';
import 'package:lingosign_ai/features/sync/domain/entities/sync_operation.dart';

import 'offline_sync_test.dart' show record;

void main() {
  test('real HTTP + Python SQLite server: 2 clients, offline writes, retry, pull, tombstones, auth, idempotency and server restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'sync-http-fixture-',
    );
    // Intentionally use real loopback HTTP instead of Flutter's test override.
    final previousOverride = HttpOverrides.current;
    HttpOverrides.global = null;
    const token = 'automated-test-token-only';
    Process? server;
    Future<int> start() async {
      server = await Process.start(
        Platform.isWindows ? 'python' : 'python3',
        [
          'tool/sync_server/server.py',
          '--db',
          '${directory.path}/server.sqlite',
          '--port',
          '0',
        ],
        environment: {'SYNC_TOKEN': token},
      );
      final line = await server!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 10));
      return int.parse(line.split(' ').last);
    }

    final a = AppDatabase(NativeDatabase(File('${directory.path}/a.sqlite')));
    final b = AppDatabase(NativeDatabase(File('${directory.path}/b.sqlite')));
    try {
      final port = await start();
      final remote = HttpSyncRemote(
        baseUrl: 'http://127.0.0.1:$port',
        token: token,
      );
      final historyA = LocalRecognitionHistoryRepository(a);
      final historyB = LocalRecognitionHistoryRepository(b);
      final syncA = LocalSyncRepository(a, remote);
      final syncB = LocalSyncRepository(b, remote);
      await historyA.saveConfirmed(record('fixture'));
      // Before opt-in nothing is transmitted.
      expect((await remote.pull(null)).records, isEmpty);
      await syncA.setEnabled(true);
      await syncB.setEnabled(true);
      expect((await syncA.synchronize()).error, isNull);
      await syncB.synchronize();
      expect((await historyB.watchHistory().first).single.id, 'fixture');
      final operation = SyncOperation(
        id: 'upsert:fixture',
        operation: 'upsert',
        record: {
          'id': 'fixture',
          'signCode': 'A',
          'label': 'A',
          'confirmedAt': DateTime.utc(2026).millisecondsSinceEpoch,
          'deletedAt': null,
        },
      );
      await remote.push(operation); // Exact replay after lost ACK.
      expect((await remote.pull(null)).records.length, 1);
      await historyB.delete('fixture');
      await syncB.synchronize();
      await syncA.synchronize();
      expect(await historyA.watchHistory().first, isEmpty);
      await remote.push(
        SyncOperation(
          id: 'stale-upsert',
          operation: 'upsert',
          record: operation.record,
        ),
      );
      expect((await remote.pull(null)).records.last['deletedAt'], isNotNull);
      final unauthorized = HttpSyncRemote(
        baseUrl: 'http://127.0.0.1:$port',
        token: 'wrong',
      );
      await expectLater(unauthorized.pull(null), throwsA(isA<HttpException>()));
      server!.kill();
      await server!.exitCode;
      await historyA.saveConfirmed(record('while-offline'));
      expect((await syncA.synchronize()).pendingCount, 1);
      final newPort = await start();
      // Advance the injected clock to pass persisted retry backoff.
      final restartedRemote = HttpSyncRemote(
        baseUrl: 'http://127.0.0.1:$newPort',
        token: token,
      );
      final resumed = LocalSyncRepository(
        a,
        restartedRemote,
        now: () => DateTime.now().add(const Duration(minutes: 6)),
      );
      expect((await resumed.synchronize()).pendingCount, 0);
      final page = await restartedRemote.pull(null);
      expect(page.records.any((r) => r['id'] == 'while-offline'), isTrue);
      expect(
        page.records.where((r) => r['id'] == 'fixture').last['deletedAt'],
        isNotNull,
      );
    } finally {
      HttpOverrides.global = previousOverride;
      server?.kill();
      if (server != null) await server!.exitCode;
      await a.close();
      await b.close();
      await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 1)));
}
