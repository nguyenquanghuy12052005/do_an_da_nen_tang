import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import '../../../../app/camera_gateway.dart';
import '../../domain/entities/recognition_prediction.dart';
import '../model/hand_feature_extractor.dart';
import '../model/offline_forest_model.dart';

class CameraPluginGateway implements CameraGateway, HistoryPhotoCamera {
  Future<Uint8List?>? _photoTask;

  @override
  Future<Uint8List?> captureHistoryPhoto() {
    return _photoTask ??= _capturePhoto().whenComplete(() => _photoTask = null);
  }

  Future<Uint8List?> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    final trace = TimelineTask()..start('LingoSign.captureHistoryPhoto');
    File? temporaryFile;
    ui.Codec? codec;
    ui.Image? thumbnail;
    try {
      final photo = await controller.takePicture();
      temporaryFile = File(photo.path);
      codec = await ui.instantiateImageCodec(
        await photo.readAsBytes(),
        targetWidth: 240,
      );
      thumbnail = (await codec.getNextFrame()).image;
      final bytes = await thumbnail.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } catch (_) {
      return null;
    } finally {
      trace.finish();
      thumbnail?.dispose();
      codec?.dispose();
      if (temporaryFile != null) {
        try {
          await temporaryFile.delete();
        } on FileSystemException {
          /* Already removed. */
        }
      }
    }
  }

  CameraController? _controller;
  HandLandmarkerPlugin? _landmarker;
  StreamSubscription<List<Hand>>? _handSubscription;
  OfflineForestModel? _model;
  final _predictions = StreamController<RecognitionPrediction>.broadcast();
  int _generation = 0;
  final _frameClock = Stopwatch();
  Future<OfflineForestModel>? _modelLoad;
  Future<void>? _closing;

  Future<OfflineForestModel> _loadModel() async {
    try {
      return await (_modelLoad ??= OfflineForestModel.load());
    } on Object {
      _modelLoad = null;
      rethrow;
    }
  }

  @override
  Stream<RecognitionPrediction> get predictions => _predictions.stream;

  @override
  Widget? get preview {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    return CameraPreview(controller);
  }

  @override
  Future<CameraOpenResult> open() async {
    if (_controller != null) await close();
    final generation = ++_generation;
    try {
      await _closing;
      if (generation != _generation) {
        return const CameraOpenFailed(CameraOpenFailure.unavailable);
      }
      final cameras = await availableCameras();
      if (generation != _generation) {
        return const CameraOpenFailed(CameraOpenFailure.unavailable);
      }
      if (cameras.isEmpty) {
        return const CameraOpenFailed(CameraOpenFailure.noCamera);
      }
      final description = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      _controller = controller;
      await controller.initialize();
      if (generation != _generation) {
        return const CameraOpenFailed(CameraOpenFailure.unavailable);
      }
      final model = await _loadModel();
      if (generation != _generation) {
        return const CameraOpenFailed(CameraOpenFailure.unavailable);
      }
      // The plugin only drops its JNI reference on dispose. Reuse its
      // MediaPipe graph instead of constructing another one on each open.
      final landmarker = _landmarker ??= HandLandmarkerPlugin.create(
        numHands: 1,
        delegate: HandLandmarkerDelegate.cpu,
      );
      _model = model;
      _handSubscription = landmarker.landmarkStream.listen(
        (hands) {
          if (generation == _generation) _onHands(hands);
        },
        onError: (Object error, StackTrace stack) {
          debugPrint('Hand tracking stream failed: ${error.runtimeType}');
        },
      );
      await controller.startImageStream(_onCameraImage);
      if (generation != _generation) {
        return const CameraOpenFailed(CameraOpenFailure.unavailable);
      }
      return const CameraOpened();
    } on CameraException catch (error) {
      if (generation == _generation) await close();
      return CameraOpenFailed(_mapFailure(error.code));
    } on Exception {
      if (generation == _generation) await close();
      return const CameraOpenFailed(CameraOpenFailure.unavailable);
    }
  }

  void _onCameraImage(CameraImage image) {
    final landmarker = _landmarker;
    final controller = _controller;
    if (landmarker == null || controller == null || image.planes.length < 3) {
      return;
    }
    if (_frameClock.isRunning && _frameClock.elapsedMilliseconds < 100) {
      return;
    }
    _frameClock
      ..reset()
      ..start();
    try {
      Timeline.timeSync('LingoSign.submitCameraFrame', () {
        landmarker.processFrame(
          image,
          controller.description.sensorOrientation,
        );
      });
    } on Exception {
      // Camera preview can continue if a single frame cannot be decoded.
    }
  }

  void _onHands(List<Hand> hands) {
    if (_controller == null ||
        !_frameClock.isRunning ||
        _predictions.isClosed) {
      return;
    }
    if (hands.isEmpty || hands.first.landmarks.length != 21) {
      _predictions.add(
        RecognitionPrediction(
          labelId: null,
          confidence: 0,
          timestamp: DateTime.now(),
          isStable: false,
        ),
      );
      return;
    }
    try {
      final points = hands.first.landmarks
          .map((point) => HandPoint(point.x, point.y))
          .toList(growable: false);
      final prediction = Timeline.timeSync(
        'LingoSign.classifyLandmarks',
        () => _model!.predict(extractHandFeatures(points)),
      );
      _predictions.add(
        RecognitionPrediction(
          labelId: prediction.label,
          confidence: prediction.confidence,
          timestamp: DateTime.now(),
          isStable: false,
        ),
      );
    } on ArgumentError {
      // Ignore degenerate detections rather than publish a misleading label.
    }
  }

  @override
  Future<void> close() {
    _generation++;
    return _closing ??= _releaseCamera().whenComplete(() => _closing = null);
  }

  Future<void> _releaseCamera() async {
    final controller = _controller;
    _controller = null;
    final subscription = _handSubscription;
    _handSubscription = null;
    _model = null;
    _frameClock
      ..stop()
      ..reset();
    try {
      await subscription?.cancel();
      await _photoTask;
      if (controller != null && controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } finally {
      await controller?.dispose();
    }
  }

  CameraOpenFailure _mapFailure(String code) => switch (code) {
    'CameraAccessDenied' ||
    'CameraAccessDeniedWithoutPrompt' => CameraOpenFailure.denied,
    'CameraAccessRestricted' => CameraOpenFailure.restricted,
    _ => CameraOpenFailure.unavailable,
  };
}
