import 'dart:io';

import 'package:flutter/services.dart';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/app/app.dart';
import 'package:lingosign_ai/app/local_data_providers.dart';
import 'package:lingosign_ai/app/theme/app_theme.dart';
import 'package:lingosign_ai/features/learning/domain/practice_session.dart';
import 'package:lingosign_ai/features/learning/presentation/learning_page.dart';
import 'package:lingosign_ai/features/dictionary/domain/entities/sign_entry.dart';
import 'package:lingosign_ai/features/dictionary/domain/repositories/sign_dictionary_repository.dart';
import 'package:lingosign_ai/features/dictionary/presentation/dictionary_page.dart';

class SearchFixture implements SignDictionaryRepository {
  SearchFixture([this.entries = const []]);

  final List<SignEntry> entries;
  final queries = <String>[];
  @override
  Future<List<SignEntry>> search(String query) async {
    queries.add(query);
    return entries;
  }

  @override
  Future<SignEntry?> findByCode(String code) async => null;
}

void main() {
  testWidgets('dictionary images open zoom from card and details', (
    tester,
  ) async {
    final repository = SearchFixture(const [
      SignEntry(
        code: 'A',
        label: 'Chữ A',
        imageAsset: 'assets/dictionary/signs/A.png',
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dictionaryRepositoryProvider.overrideWithValue(repository),
          bundledDictionaryProvider.overrideWith((ref) async {}),
          supportedPracticeLabelsProvider.overrideWith((ref) async => {'A'}),
        ],
        child: const MaterialApp(home: Scaffold(body: DictionaryPage())),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      if (i == 1) {
        await tester.tap(find.text('Chữ A'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Phóng to ảnh Chữ A'));
      await tester.pumpAndSettle();
      expect(find.text('Ảnh minh họa Chữ A'), findsOneWidget);
      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer))
            .maxScale,
        5,
      );
      await tester.tap(find.byTooltip('Đóng ảnh'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
    }
  });

  testWidgets(
    'dictionary debounces typing, clears search and cancels on dispose',
    (tester) async {
      final repository = SearchFixture();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dictionaryRepositoryProvider.overrideWithValue(repository),
            bundledDictionaryProvider.overrideWith((ref) async {}),
          ],
          child: const MaterialApp(home: Scaffold(body: DictionaryPage())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), ' A ');
      await tester.pump(const Duration(milliseconds: 200));
      expect(repository.queries, ['']);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();
      expect(repository.queries.last, 'A');
      await tester.tap(find.byTooltip('Xóa tìm kiếm'));
      await tester.pumpAndSettle();
      expect(repository.queries.last, '');
      await tester.enterText(find.byType(TextField), 'B');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 300));
      expect(repository.queries, isNot(contains('B')));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'learning cards reflow and expand on a narrow screen with large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 740);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final date = DateTime(2026, 11, 7, 10);
      final session = PracticeSession(
        id: 'sample',
        startedAt: date,
        targets: ['A'],
        answers: [
          PracticeAnswer(target: 'A', predicted: 'B', confidence: .8, at: date),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learningSessionsProvider.overrideWith(
              (ref) => Stream.value([session]),
            ),
            learningHistoryPageProvider.overrideWith(
              (ref, page) => Stream.value([session]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: LearningPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tổng quan'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final completed = find.text('Đã hoàn thành');
      await tester.scrollUntilVisible(completed, 180);
      await tester.ensureVisible(completed);
      await tester.pumpAndSettle();
      expect(completed.hitTestable(), findsOneWidget);
      await tester.tap(completed);
      await tester.pumpAndSettle();
      final answer = find.text('Yêu cầu A · Sai');
      await tester.scrollUntilVisible(answer, 100);
      expect(answer, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('learning history pages through all practice sessions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = List.generate(
      7,
      (i) => PracticeSession(
        id: 'page-session-$i',
        startedAt: DateTime(2026, 11, 7, 10, 7 - i),
        targets: ['A'],
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningSessionsProvider.overrideWith(
            (ref) => Stream.value(sessions),
          ),
          learningHistoryPageProvider.overrideWith(
            (ref, page) => Stream.value(
              sessions.skip(page.offset).take(page.limit).toList(),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: LearningPage())),
      ),
    );
    await tester.pumpAndSettle();

    final next = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton && widget.tooltip == 'Trang bài luyện sau',
    );
    final previous = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton && widget.tooltip == 'Trang bài luyện trước',
    );
    expect(find.text('Trang 1/2'), findsOneWidget);
    expect(find.byKey(const ValueKey('page-session-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-session-5')), findsNothing);
    expect(tester.widget<IconButton>(previous).onPressed, isNull);

    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Trang 2/2'), findsOneWidget);
    expect(find.byKey(const ValueKey('page-session-6')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-session-4')), findsNothing);
    expect(tester.widget<IconButton>(next).onPressed, isNull);

    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(find.text('Trang 1/2'), findsOneWidget);
  });

  testWidgets('phone layout, large text and reduced motion remain usable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final font = File('C:/Windows/Fonts/segoeui.ttf');
      if (await font.exists()) {
        await (FontLoader('Roboto')..addFont(
              font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
            ))
            .load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: const ProviderScope(child: LingoSignApp()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu camera').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/ui-preview').create(recursive: true);
      await File('build/ui-preview/home.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(320, 740);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cài đặt').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
