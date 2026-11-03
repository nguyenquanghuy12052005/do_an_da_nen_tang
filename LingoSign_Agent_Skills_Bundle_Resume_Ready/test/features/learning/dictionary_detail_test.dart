import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:lingosign_ai/data/local/app_database.dart';
import 'package:lingosign_ai/data/local/repositories/local_sign_dictionary_repository.dart';
import 'package:lingosign_ai/features/dictionary/domain/entities/sign_entry.dart';
import 'package:lingosign_ai/features/dictionary/presentation/sign_detail_page.dart';

void main() {
  test('catalog retains system, instructions, assets and provenance', () async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      final repo = LocalSignDictionaryRepository(db);
      await repo.upsertVerifiedCatalog(
        entries: [
          const SignEntry(
            code: 'fixture',
            label: 'Fixture only',
            category: 'Test',
            signSystem: 'Fixture system',
            instructions: 'Fixture instruction',
            imageAsset: 'assets/dictionary/fixture.png',
            modelLabel: 'A',
          ),
        ],
        catalogVersion: 'test',
        sourceUrl: 'https://example.test/fixture',
        licenseName: 'test-only',
        updatedAt: DateTime.utc(2026),
      );
      final entry = (await repo.search('fixture')).single;
      expect(entry.category, 'Test');
      expect(entry.signSystem, 'Fixture system');
      expect(entry.modelLabel, 'A');
      expect(entry.sourceUrl, 'https://example.test/fixture');
      expect(entry.instructions, 'Fixture instruction');
    } finally {
      await db.close();
    }
  });
  testWidgets(
    'unsupported sign cannot launch camera practice; detail explains missing media',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignDetailPage(
            entry: SignEntry(
              code: 'fixture',
              label: 'Fixture',
              description: 'Fixture meaning',
            ),
            canPractice: false,
          ),
        ),
      );
      expect(find.text('Fixture meaning'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Luyện ký hiệu này'), 200);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Luyện ký hiệu này'),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.text('Chưa hỗ trợ luyện ký hiệu này bằng model hiện tại.'),
        findsOneWidget,
      );
    },
  );
}
