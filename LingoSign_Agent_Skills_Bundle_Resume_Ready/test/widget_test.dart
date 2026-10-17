import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/app/app.dart';
import 'package:lingosign_ai/app/camera_gateway.dart';
import 'package:lingosign_ai/features/recognition/domain/entities/recognition_prediction.dart';

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

void main() {
  testWidgets('shows honest recognition state and navigates between sections', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LingoSignApp()));

    expect(
      find.textContaining('Dự đoán ký hiệu đang thử nghiệm'),
      findsOneWidget,
    );
    await tester.tap(find.text('Từ điển').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Từ điển chưa có nội dung được xác minh.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Lịch sử').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Lịch sử sẽ xuất hiện'), findsOneWidget);
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cameraGatewayProvider.overrideWithValue(camera)],
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
    await tester.scrollUntilVisible(find.text('Dự đoán thử nghiệm: A (75%)'), 300);
    expect(find.text('Dự đoán thử nghiệm: A (75%)'), findsOneWidget);
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
