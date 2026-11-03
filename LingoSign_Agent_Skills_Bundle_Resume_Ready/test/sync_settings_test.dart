import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/app/sync_providers.dart';
import 'package:lingosign_ai/features/sync/domain/entities/sync_result.dart';
import 'package:lingosign_ai/features/sync/domain/repositories/sync_repository.dart';
import 'package:lingosign_ai/features/sync/presentation/sync_settings.dart';

class SettingsSyncFake implements SyncRepository {
  bool enabled = false;
  @override
  Future<bool> isEnabled() async => enabled;
  @override
  Future<void> setEnabled(bool value) async {
    enabled = value;
  }

  @override
  Stream<int> watchPendingCount() => Stream.value(2);
  @override
  Future<SyncResult> synchronize() async => const SyncResult(
    syncedCount: 0,
    pendingCount: 2,
    error: 'Máy chủ offline (fixture)',
  );
}

void main() {
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
