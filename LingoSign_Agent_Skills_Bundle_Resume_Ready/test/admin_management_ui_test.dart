import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/app/firebase_session.dart';
import 'package:lingosign_ai/features/admin/data/admin_providers.dart';
import 'package:lingosign_ai/features/admin/data/firebase_admin_gateway.dart';
import 'package:lingosign_ai/features/admin/domain/account_access.dart';
import 'package:lingosign_ai/features/admin/presentation/admin_page.dart';

import 'admin_content_test.dart' show TestAuth, TestStore, TestUser;

class ManagementGateway extends FirebaseAdminGateway {
  ManagementGateway()
    : super(FirebaseSession(TestAuth(), TestStore(), TestUser()));
  final actions = <String>[];
  bool hidden = false;
  bool deleted = false;
  bool lessonDeleted = false;

  @override
  Stream<List<AdminItem>> watchUsers() async* {
    yield ((await call('users'))['items'] as List).cast<AdminItem>();
  }

  @override
  Stream<Map<String, List<DateTime>>> watchPresence() => Stream.value({
    'learner': [DateTime.now().toUtc()],
  });

  @override
  Future<AdminItem> call(String action, [AdminItem data = const {}]) async {
    actions.add(action);
    if (action == 'profileVisibility') hidden = data['hidden'] as bool;
    if (action == 'profileDelete') deleted = true;
    if (action == 'delete') lessonDeleted = true;
    if (action == 'users') {
      return {
        'items': [
          {
            'id': 'learner',
            'email': 'learner@example.com',
            'label': 'Học viên',
            'role': 'learner',
            'locked': false,
            'hidden': hidden,
            'deleted': deleted,
          },
        ],
      };
    }
    if (action == 'content') {
      return {
        'items': [
          if (!lessonDeleted)
            {
              'id': 'letters',
              'label': 'Luyện A và B',
              'description': 'Bài học mẫu',
              'targets': ['A', 'B', 'A'],
              'state': 'published',
              'revision': 1,
            },
        ],
      };
    }
    return {};
  }
}

Future<void> openManagement(
  WidgetTester tester,
  ManagementGateway gateway,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountAccessProvider.overrideWith(
          (ref) => Stream.value(const AccountAccess(role: AccountRole.admin)),
        ),
        adminGatewayProvider.overrideWith((ref) => gateway),
      ],
      child: const MaterialApp(home: AdminPage()),
    ),
  );
  await tester.pumpAndSettle();
}

class LiveManagementGateway extends ManagementGateway {
  final presenceChanges =
      StreamController<Map<String, List<DateTime>>>.broadcast();
  @override
  Stream<Map<String, List<DateTime>>> watchPresence() => presenceChanges.stream;
}

class ManyUsersGateway extends ManagementGateway {
  @override
  Stream<List<AdminItem>> watchUsers() => Stream.value([
    for (var index = 0; index < 40; index++)
      {
        'id': 'user$index',
        'email': 'user$index@example.com',
        'label': '',
        'role': 'learner',
        'locked': false,
        'hidden': index == 2,
      },
  ]);
}

void main() {
  testWidgets(
    'all users including hidden accounts are loaded beyond the former 30 row limit',
    (tester) async {
      await openManagement(tester, ManyUsersGateway());
      expect(find.text('Người dùng (40)'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Tất cả'), findsOneWidget);
      expect(find.text('Tải thêm'), findsNothing);
    },
  );
  testWidgets('presence changes update Online and Offline without a reload', (
    tester,
  ) async {
    final gateway = LiveManagementGateway();
    addTearDown(gateway.presenceChanges.close);
    await openManagement(tester, gateway);
    expect(find.textContaining('Offline'), findsOneWidget);
    gateway.presenceChanges.add({
      'learner': [DateTime.now().toUtc()],
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Online'), findsOneWidget);
    gateway.presenceChanges.add({});
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline'), findsOneWidget);
  });
  testWidgets(
    'admin can view, hide, restore and delete a user from explicit actions',
    (tester) async {
      final gateway = ManagementGateway();
      await openManagement(tester, gateway);
      expect(find.text('Người dùng'), findsWidgets);
      expect(find.text('Bài học'), findsOneWidget);
      expect(find.textContaining('Online'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Đang hiển thị'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('UID: learner'), findsOneWidget);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ẩn').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ẩn').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Ẩn người dùng'));
      await tester.pumpAndSettle();
      expect(gateway.hidden, isTrue);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('learner@example.com'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Đã ẩn'));
      await tester.pumpAndSettle();
      expect(find.text('learner@example.com'), findsOneWidget);
      await tester.ensureVisible(find.text('Hiện lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hiện lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hiện người dùng'));
      await tester.pumpAndSettle();
      expect(gateway.hidden, isFalse);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Đang hiển thị'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Xóa').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa người dùng'));
      await tester.pumpAndSettle();
      expect(gateway.deleted, isTrue);
      expect(find.text('learner@example.com'), findsNothing);
    },
  );

  testWidgets('lessons show named view, edit, delete and create controls', (
    tester,
  ) async {
    final gateway = ManagementGateway();
    await openManagement(tester, gateway);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Bài học'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm bài học'), findsOneWidget);
    expect(find.text('Sửa'), findsOneWidget);
    await tester.tap(find.text('Xem').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('A, B, A'), findsOneWidget);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Luyện A, B đã sửa',
    );
    await tester.tap(find.text('Lưu nháp'));
    await tester.pumpAndSettle();
    expect(gateway.actions, contains('save'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa bài học'));
    await tester.pumpAndSettle();
    expect(gateway.lessonDeleted, isTrue);
    expect(find.text('Luyện A và B'), findsNothing);
  });
}
