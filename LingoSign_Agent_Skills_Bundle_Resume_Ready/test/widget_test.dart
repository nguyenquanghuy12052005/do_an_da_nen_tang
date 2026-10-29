import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/app/app.dart';
import 'package:lingosign_ai/app/camera_gateway.dart';
import 'package:lingosign_ai/features/recognition/domain/entities/recognition_prediction.dart';
import 'package:lingosign_ai/app/local_data_providers.dart';
import 'package:lingosign_ai/features/history/domain/entities/recognition_record.dart';
import 'package:lingosign_ai/features/history/domain/repositories/recognition_history_repository.dart';

class FakeHistory implements RecognitionHistoryRepository {
  Uint8List? lastPhoto;
  final records = <RecognitionRecord>[];
  @override
  Future<void> saveConfirmed(
    RecognitionRecord record, {
    Uint8List? photo,
  }) async {
    lastPhoto = photo;
    records.add(record);
  }

  @override
  Stream<List<RecognitionRecord>> watchHistory({
    int? limit,
    RecognitionRecord? before,
  }) => Stream.value(
    records
        .where(
          (record) =>
              before == null || record.confirmedAt.isBefore(before.confirmedAt),
        )
        .take(limit ?? records.length)
        .toList(),
  );
  @override
  Future<void> delete(String id) async =>
      records.removeWhere((record) => record.id == id);
}

class FakeCameraGateway implements CameraGateway {
  FakeCameraGateway({this.nextResult = const CameraOpened()});

  CameraOpenResult nextResult;
  int opens = 0;
  int closes = 0;
  int _generation = 0;
  Completer<void>? pendingOpen;
  final predictionEvents = StreamController<RecognitionPrediction>.broadcast();

  @override
  Stream<RecognitionPrediction> get predictions => predictionEvents.stream;

  @override
  Widget? get preview =>
      const ColoredBox(key: Key('fake-camera-preview'), color: Colors.black);

  @override
  Future<CameraOpenResult> open() async {
    opens++;
    final generation = _generation;
    await pendingOpen?.future;
    if (generation != _generation) {
      return const CameraOpenFailed(CameraOpenFailure.unavailable);
    }
    return nextResult;
  }

  @override
  Future<void> close() async {
    closes++;
    _generation++;
  }
}

class FakePhotoCamera extends FakeCameraGateway implements HistoryPhotoCamera {
  @override
  Future<Uint8List?> captureHistoryPhoto() async => Uint8List.fromList([7, 8]);
}

void main() {
  testWidgets('opens history photo viewer and closes back to same page', (
    tester,
  ) async {
    final history = FakeHistory();
    history.records.add(
      RecognitionRecord(
        id: 'photo',
        signCode: 'A',
        label: 'A',
        confirmedAt: DateTime.utc(2026),
        imagePath: '/missing-history-photo.png',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [historyRepositoryProvider.overrideWithValue(history)],
        child: const LingoSignApp(),
      ),
    );
    await tester.tap(find.text('Lịch sử').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xem ảnh lớn'));
    await tester.pumpAndSettle();
    expect(find.text('Ảnh nhận diện: A'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng ảnh'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.text('Trang 1'), findsOneWidget);
  });
  testWidgets('saves photo with each window while camera remains active', (
    tester,
  ) async {
    final camera = FakePhotoCamera();
    final history = FakeHistory();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cameraGatewayProvider.overrideWithValue(camera),
          historyRepositoryProvider.overrideWithValue(history),
        ],
        child: const LingoSignApp(),
      ),
    );
    await tester.scrollUntilVisible(find.text('Bắt đầu camera'), 300);
    await tester.tap(find.text('Bắt đầu camera'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      camera.predictionEvents.add(
        RecognitionPrediction(
          labelId: 'A',
          confidence: 0.8,
          timestamp: DateTime.utc(2026),
          isStable: false,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
    }
    expect(history.records.length, 2);
    expect(history.lastPhoto, [7, 8]);
    expect(camera.closes, 0);
  });

  testWidgets('history has ten rows per page and supports previous/next', (
    tester,
  ) async {
    final history = FakeHistory();
    for (var i = 0; i < 12; i++) {
      history.records.add(
        RecognitionRecord(
          id: '$i',
          signCode: 'A',
          label: 'Row $i',
          confirmedAt: DateTime.utc(2026).subtract(Duration(seconds: i)),
        ),
      );
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [historyRepositoryProvider.overrideWithValue(history)],
        child: const LingoSignApp(),
      ),
    );
    await tester.tap(find.text('Lịch sử').last);
    await tester.pumpAndSettle();
    expect(find.text('Trang 1'), findsOneWidget);
    await tester.tap(find.byTooltip('Trang sau'));
    await tester.pumpAndSettle();
    expect(find.text('Trang 2'), findsOneWidget);
    expect(find.text('Row 10'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == 'Trang sau',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Trang trước'));
    await tester.pumpAndSettle();
    expect(find.text('Trang 1'), findsOneWidget);
  });
  testWidgets('shows honest recognition state and navigates between sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(FakeHistory()),
          dictionaryProvider('').overrideWith((ref) async => []),
        ],
        child: const LingoSignApp(),
      ),
    );

    expect(find.textContaining('Mỗi giây'), findsOneWidget);
    await tester.tap(find.text('Từ điển').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Từ điển chưa có nội dung được xác minh.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Lịch sử').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có kết quả.'), findsOneWidget);
  });

  testWidgets('switches Material theme to dark mode', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LingoSignApp()));
    await tester.tap(find.text('Cài đặt').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('opens camera only on request and stops it', (tester) async {
    final camera = FakeCameraGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cameraGatewayProvider.overrideWithValue(camera)],
        child: const LingoSignApp(),
      ),
    );

    expect(camera.opens, 0);
    await tester.scrollUntilVisible(find.text('Bắt đầu camera'), 300);
    await tester.tap(find.text('Bắt đầu camera'));
    await tester.pumpAndSettle();
    expect(camera.opens, 1);
    expect(find.byKey(const Key('fake-camera-preview')), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Dừng camera'), 300);
    await tester.drag(find.byType(ListView).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dừng camera'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(camera.closes, greaterThanOrEqualTo(1));
    await tester.scrollUntilVisible(find.text('Bắt đầu camera'), 300);
    expect(find.text('Bắt đầu camera'), findsOneWidget);
  });

  testWidgets('shows a permission denial and allows retry', (tester) async {
    final camera = FakeCameraGateway(
      nextResult: const CameraOpenFailed(CameraOpenFailure.denied),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cameraGatewayProvider.overrideWithValue(camera)],
        child: const LingoSignApp(),
      ),
    );

    await tester.scrollUntilVisible(find.text('Bắt đầu camera'), 300);
    await tester.tap(find.text('Bắt đầu camera'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa được cấp quyền camera'), findsOneWidget);
    expect(find.text('Bắt đầu camera'), findsOneWidget);
  });

  testWidgets('shows an explicitly experimental model prediction', (
    tester,
  ) async {
    final camera = FakeCameraGateway();
    final history = FakeHistory();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cameraGatewayProvider.overrideWithValue(camera),
          historyRepositoryProvider.overrideWithValue(history),
        ],
        child: const LingoSignApp(),
      ),
    );
    await tester.scrollUntilVisible(find.text('Bắt đầu camera'), 300);
    await tester.tap(find.text('Bắt đầu camera'));
    await tester.pumpAndSettle();

    camera.predictionEvents.add(
      RecognitionPrediction(
        labelId: 'A',
        confidence: 0.75,
        timestamp: DateTime.utc(2026, 10, 17),
        isStable: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.scrollUntilVisible(find.text('Kết quả: A (75%)'), 300);
    expect(find.text('Kết quả: A (75%)'), findsOneWidget);
    expect(history.records.single.label, 'A');
    expect(camera.closes, 0);
  });

  testWidgets('closes camera in background and reopens on resume', (
    tester,
  ) async {
    final camera = FakeCameraGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cameraGatewayProvider.overrideWithValue(camera)],
        child: const LingoSignApp(),
      ),
    );
    await tester.scrollUntilVisible(find.text('Bắt đầu camera'), 300);
    await tester.tap(find.text('Bắt đầu camera'));
    await tester.pumpAndSettle();
    expect(camera.opens, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(camera.closes, greaterThanOrEqualTo(1));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(camera.opens, 2);
    expect(find.byKey(const Key('fake-camera-preview')), findsOneWidget);
  });

  testWidgets('recovers when background interrupts camera initialization', (
    tester,
  ) async {
    final camera = FakeCameraGateway()..pendingOpen = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cameraGatewayProvider.overrideWithValue(camera)],
        child: const LingoSignApp(),
      ),
    );
    await tester.scrollUntilVisible(find.text('Bắt đầu camera'), 300);
    await tester.tap(find.text('Bắt đầu camera'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    camera.pendingOpen!.complete();
    await tester.pumpAndSettle();

    expect(camera.opens, 2);
    expect(find.byKey(const Key('fake-camera-preview')), findsOneWidget);
  });
}
