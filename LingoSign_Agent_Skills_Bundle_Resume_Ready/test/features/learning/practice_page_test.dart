import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/app/camera_gateway.dart';
import 'package:lingosign_ai/app/local_data_providers.dart';
import 'package:lingosign_ai/features/learning/domain/practice_session.dart';
import 'package:lingosign_ai/features/learning/presentation/practice_page.dart';
import 'package:lingosign_ai/features/recognition/domain/entities/recognition_prediction.dart';

class PracticeCamera implements CameraGateway {
  Completer<CameraOpenResult>? pending;
  int closes = 0;
  int opens = 0;
  final events = StreamController<RecognitionPrediction>.broadcast();
  @override
  Stream<RecognitionPrediction> get predictions => events.stream;
  @override
  Widget get preview =>
      const ColoredBox(key: Key('practice-preview'), color: Colors.black);
  @override
  Future<CameraOpenResult> open() async {
    opens++;
    return pending == null ? const CameraOpened() : await pending!.future;
  }

  @override
  Future<void> close() async {
    closes++;
  }
}

class LearningFake implements LearningRepository {
  PracticeSession? saved;
  @override
  Future<void> save(PracticeSession session) async {
    saved = session;
  }

  @override
  Stream<List<PracticeSession>> watchSessions() =>
      Stream.value(saved == null ? [] : [saved!]);
}

void main() {
  testWidgets(
    'background during camera opening cannot reactivate a hidden camera',
    (tester) async {
      final camera = PracticeCamera()..pending = Completer<CameraOpenResult>();
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportedPracticeLabelsProvider.overrideWith(
              (ref) async => {'A', 'B'},
            ),
            cameraGatewayProvider.overrideWithValue(camera),
            learningRepositoryProvider.overrideWithValue(LearningFake()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PracticePage(target: 'A')),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Bắt đầu 5 câu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu 5 câu'));
      for (var i = 0; i < 10 && camera.opens == 0; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(camera.opens, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      camera.pending!.complete(const CameraOpened());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('practice-preview')), findsNothing);
      expect(camera.closes, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox());
      await camera.events.close();
    },
  );
  testWidgets(
    'camera practice freezes each answer until next; saves and completes 5 questions',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final camera = PracticeCamera();
      final repository = LearningFake();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportedPracticeLabelsProvider.overrideWith(
              (ref) async => {'A', 'B'},
            ),
            cameraGatewayProvider.overrideWithValue(camera),
            learningRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PracticePage(target: 'A')),
          ),
        ),
      );
      await tester.tap(find.text('Bắt đầu 5 câu'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        camera.events.add(
          RecognitionPrediction(
            labelId: 'A',
            confidence: .9,
            timestamp: DateTime.utc(2026),
            isStable: false,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(repository.saved!.answers.length, i + 1);
        camera.events.add(
          RecognitionPrediction(
            labelId: 'B',
            confidence: .95,
            timestamp: DateTime.utc(2026),
            isStable: false,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(repository.saved!.answers.length, i + 1);
        await tester.tap(find.text(i == 4 ? 'Xem tổng kết' : 'Câu tiếp theo'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Hoàn thành bài luyện'), findsOneWidget);
      expect(repository.saved!.correctCount, 5);
      await tester.pumpWidget(const SizedBox());
      await camera.events.close();
    },
  );
}
