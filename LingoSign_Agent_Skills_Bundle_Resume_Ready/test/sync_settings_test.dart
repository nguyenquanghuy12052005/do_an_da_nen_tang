import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/app/sync_providers.dart';
import 'package:lingosign_ai/features/sync/domain/entities/sync_result.dart';
import 'package:lingosign_ai/features/sync/domain/repositories/sync_repository.dart';
import 'package:lingosign_ai/features/sync/presentation/sync_settings.dart';

class SettingsSyncFake implements SyncRepository {
  bool enabled = false;
  bool offline = true;
  int attempts = 0;
  int pending = 2;
  Stream<int>? pendingEvents;
  @override
  Future<bool> isEnabled() async => enabled;
  @override
  Future<void> setEnabled(bool value) async {
    enabled = value;
  }

  @override
  Stream<int> watchPendingCount() => pendingEvents ?? Stream.value(pending);
  @override
  Future<SyncResult> synchronize() async {
    attempts++;
    return SyncResult(
      syncedCount: 0,
      pendingCount: pending,
      error: offline ? 'Máy chủ offline (fixture)' : null,
    );
  }
}

void main() {
  testWidgets('sync backs off after errors and resets after manual success', (
    tester,
  ) async {
    final repository = SettingsSyncFake();
    final container = ProviderContainer(
      overrides: [
        syncConfiguredProvider.overrideWithValue(true),
        syncRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final sync = container.read(syncControllerProvider.notifier);
    await tester.pump(Duration.zero);
    expect(repository.attempts, 1);
    await tester.pump(const Duration(seconds: 9));
    expect(repository.attempts, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(repository.attempts, 2);
    await tester.pump(const Duration(seconds: 10));
    expect(repository.attempts, 2);

    repository.offline = false;
    await sync.synchronize();
    expect(repository.attempts, 3);
    await tester.pump(const Duration(seconds: 5));
    expect(repository.attempts, 4);

    // Dispose before the test binding checks for outstanding timers.
    container.invalidate(syncControllerProvider);
  });

  testWidgets('idle sync waits and new outbox data wakes it early', (
    tester,
  ) async {
    final events = StreamController<int>.broadcast();
    final repository = SettingsSyncFake()
      ..offline = false
      ..pending = 0
      ..pendingEvents = events.stream;
    final container = ProviderContainer(
      overrides: [
        syncConfiguredProvider.overrideWithValue(true),
        syncRepositoryProvider.overrideWithValue(repository),
      ],
    );
    try {
      container.listen(syncControllerProvider, (_, _) {});
      events.add(0);
      await tester.pump(Duration.zero);
      expect(repository.attempts, 1);
      await tester.pump(const Duration(seconds: 29));
      expect(repository.attempts, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(repository.attempts, 2);
      events.add(1);
      await tester.pump(Duration.zero);
      await tester.pump(const Duration(seconds: 1));
      expect(repository.attempts, 3);
    } finally {
      container.dispose();
      await events.close();
    }
  });

  testWidgets('unconfigured build explains unavailable sync', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [syncConfiguredProvider.overrideWithValue(false)],
        child: const MaterialApp(home: Scaffold(body: SyncSettings())),
      ),
    );
    expect(find.textContaining('Chưa cấu hình máy chủ'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
  });
  testWidgets('opt-in, pending count, offline error and disabling sync', (
    tester,
  ) async {
    final repository = SettingsSyncFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncConfiguredProvider.overrideWithValue(true),
          syncRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: SyncSettings())),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(find.text('Đang chờ đồng bộ: 2'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(repository.enabled, isTrue);
    expect(find.text('Máy chủ offline (fixture)'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(repository.enabled, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
