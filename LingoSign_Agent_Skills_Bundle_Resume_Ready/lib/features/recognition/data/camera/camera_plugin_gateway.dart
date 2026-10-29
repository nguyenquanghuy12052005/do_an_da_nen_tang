import 'dart:async';
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
  int _lastFrameMs = 0;

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
      final model = await OfflineForestModel.load();
      if (generation != _generation) {
        return const CameraOpenFailed(CameraOpenFailure.unavailable);
      }
      final landmarker = HandLandmarkerPlugin.create(
        numHands: 1,
        delegate: HandLandmarkerDelegate.cpu,
      );
      _model = model;
      _landmarker = landmarker;
      _handSubscription = landmarker.landmarkStream.listen(_onHands);
      await controller.startImageStream(_onCameraImage);
      if (generation != _generation) {
        return const CameraOpenFailed(CameraOpenFailure.unavailable);
      }
      return const CameraOpened();
    } on CameraException catch (error) {
      await close();
      return CameraOpenFailed(_mapFailure(error.code));
    } on Exception {
      await close();
      return const CameraOpenFailed(CameraOpenFailure.unavailable);
    }
  }

  void _onCameraImage(CameraImage image) {
    final landmarker = _landmarker;
    final controller = _controller;
    if (landmarker == null || controller == null || image.planes.length < 3) {
      return;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastFrameMs < 100) return;
    _lastFrameMs = nowMs;
    try {
      landmarker.processFrame(image, controller.description.sensorOrientation);
    } on Exception {
      // Camera preview can continue if a single frame cannot be decoded.
    }
  }

  void _onHands(List<Hand> hands) {
    if (_controller == null || _predictions.isClosed) return;
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
      final features = extractHandFeatures(points);
      final prediction = _model!.predict(features);
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
  Future<void> close() async {
    await _photoTask;
    _generation++;
    final controller = _controller;
    _controller = null;
    final subscription = _handSubscription;
    _handSubscription = null;
    final landmarker = _landmarker;
    _landmarker = null;
    _model = null;
    _lastFrameMs = 0;
    await subscription?.cancel();
    if (controller != null && controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    landmarker?.dispose();
    if (controller != null) await controller.dispose();
  }

  CameraOpenFailure _mapFailure(String code) => switch (code) {
    'CameraAccessDenied' ||
    'CameraAccessDeniedWithoutPrompt' => CameraOpenFailure.denied,
    'CameraAccessRestricted' => CameraOpenFailure.restricted,
    _ => CameraOpenFailure.unavailable,
  };
}
