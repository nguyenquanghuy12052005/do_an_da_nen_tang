import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingosign_ai/app/firebase_session.dart';
import 'package:lingosign_ai/features/admin/data/firebase_admin_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/data/local/app_database.dart';
import 'package:lingosign_ai/features/admin/data/published_content.dart';
import 'package:lingosign_ai/features/admin/presentation/admin_page.dart';
import 'package:lingosign_ai/features/dictionary/domain/entities/sign_entry.dart';

class TestAuth extends Fake implements FirebaseAuth {}

class TestStore extends Fake implements FirebaseFirestore {}

class TestUser extends Fake implements User {
  @override
  String get uid => 'local-admin';
}

void main() {
  test('local CRUD preserves drafts, rejects stale updates and keeps overrides after cloud refresh', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final gateway = FirebaseAdminGateway(
      FirebaseSession(TestAuth(), TestStore(), TestUser()),
      database: database,
    );
    final cache = PublishedContent(database);
    final request = <String, dynamic>{
      'kind': 'categories',
      'id': 'letters',
      'revision': 0,
      'item': <String, dynamic>{'label': 'Chữ cái'},
    };
    await gateway.call('publish', request);
    expect((await cache.read('categories')).single['label'], 'Chữ cái');
    await gateway.call('save', {
      ...request,
      'revision': 1,
      'item': <String, dynamic>{'label': 'Bản nháp'},
    });
    expect((await cache.read('categories')).single['label'], 'Chữ cái');
    await expectLater(
      gateway.call('publish', request),
      throwsA(isA<AdminFailure>()),
    );
    await cache.replace('categories', []);
    expect((await cache.read('categories')).single['label'], 'Chữ cái');
    await gateway.call('delete', {...request, 'revision': 2});
    expect(
      (await gateway.call('content', {'kind': 'categories'}))['items'],
      isEmpty,
    );
    expect((await cache.read('categories')).single['state'], 'hidden');
  });
  test(
    'the cached catalog replaces, hides and restores bundled signs',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final cache = PublishedContent(database);
      const bundled = [
        SignEntry(code: 'a', label: 'A'),
        SignEntry(code: 'b', label: 'B'),
      ];
      await cache.replace('categories', [
        {'id': 'letters', 'label': 'Chữ cái', 'state': 'published'},
      ]);
      await cache.replace('signs', [
        {'id': 'a', 'state': 'hidden'},
        {
          'id': 'b',
          'state': 'published',
          'label': 'Chữ B',
          'categoryId': 'letters',
        },
      ]);
      final offline = await PublishedContent(database).overlay(bundled);
      expect(offline.single.code, 'b');
      expect(offline.single.label, 'Chữ B');
      expect(offline.single.category, 'Chữ cái');
      await cache.replace('signs', []);
      expect((await cache.overlay(bundled)).map((sign) => sign.code), [
        'a',
        'b',
      ]);
    },
  );

  testWidgets('opening the admin route as a guest displays access denied', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AdminPage())),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Không có quyền quản trị hoặc chưa kết nối.'),
      findsOneWidget,
    );
    expect(find.text('Người dùng'), findsNothing);
  });
}
