import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingosign_ai/app/camera_gateway.dart';
import 'package:lingosign_ai/features/recognition/domain/entities/recognition_prediction.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  bool _opening = false;
  bool _active = false;
  bool _resumeWhenForeground = false;
  bool _foreground = true;
  bool _interruptedByBackground = false;
  String? _message;
  CameraGateway? _gateway;
  StreamSubscription<RecognitionPrediction>? _predictionSubscription;
  RecognitionPrediction? _latestPrediction;
  Future<void>? _openingTask;
  Future<void> _backgroundClose = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _foreground = false;
      _interruptedByBackground = true;
      _backgroundClose = _closeForBackground();
      unawaited(_backgroundClose);
    } else if (state == AppLifecycleState.resumed) {
      _foreground = true;
      if (_resumeWhenForeground) unawaited(_resumeCamera());
    }
  }

  void _startCamera() {
    if (_opening || _active) return;
    _resumeWhenForeground = true;
    _openingTask = _openCamera();
    unawaited(_openingTask);
  }

  Future<void> _resumeCamera() async {
    await _backgroundClose;
    await _openingTask;
    if (!mounted || !_foreground || !_resumeWhenForeground || _active) return;
    _interruptedByBackground = false;
    _startCamera();
  }

  Future<void> _openCamera() async {
    setState(() {
      _opening = true;
      _message = null;
      _latestPrediction = null;
    });
    CameraOpenResult result;
    try {
      final CameraGateway gateway = ref.read(cameraGatewayProvider);
      _gateway = gateway;
      result = await gateway.open();
    } on Exception {
      result = const CameraOpenFailed(CameraOpenFailure.unavailable);
    }
    if (!mounted) return;
    if (!_foreground && result is CameraOpened) {
      try {
        await _gateway?.close();
      } on Exception catch (error, stack) {
        debugPrint('Camera cleanup after background failed: $error\n$stack');
      }
      if (!mounted) return;
      result = const CameraOpenFailed(CameraOpenFailure.unavailable);
    }
    if (result is CameraOpened) {
      _predictionSubscription = _gateway!.predictions.listen((prediction) {
        if (mounted && _active) {
          setState(() => _latestPrediction = prediction);
        }
      });
    }
    setState(() {
      _opening = false;
      _active = result is CameraOpened;
      if (result case CameraOpenFailed(:final reason)) {
        if (!_interruptedByBackground) _resumeWhenForeground = false;
        _message = switch (reason) {
          CameraOpenFailure.denied => 'Chưa được cấp quyền camera. Bạn có thể bật quyền trong Cài đặt thiết bị rồi thử lại.',
          CameraOpenFailure.restricted =>
            'Quyền camera đang bị giới hạn trên thiết bị này.',
          CameraOpenFailure.noCamera => 'Thiết bị không có camera khả dụng.',
          CameraOpenFailure.unavailable =>
            'Không thể mở camera lúc này. Vui lòng thử lại.',
        };
      }
    });
  }

  void _stopCamera() {
    _resumeWhenForeground = false;
    unawaited(_closeCamera());
  }

  Future<void> _closeCamera() async {
    if (mounted) {
      setState(() {
        _active = false;
        _latestPrediction = null;
      });
    }
    final closeTask = _gateway?.close();
    final subscription = _predictionSubscription;
    _predictionSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    try {
      await closeTask;
    } on Exception {
      if (mounted) setState(() => _message = 'Không thể đóng camera an toàn.');
    }
  }

  Future<void> _closeForBackground() async {
    if (!_active && !_opening) return;
    if (mounted) setState(() => _active = false);
    await _closeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final subscription = _predictionSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    final gateway = _gateway;
    if (gateway != null) {
      unawaited(
        gateway.close().catchError((Object error) {
          debugPrint('Camera close failed on dispose: $error');
        }),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _active ? _gateway?.preview : null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Nhận diện ký hiệu',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Camera chỉ mở khi bạn nhấn bắt đầu. Dự đoán ký hiệu đang thử nghiệm vì cách tạo dữ liệu huấn luyện chưa được xác minh.',
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child:
                  preview ??
                  const Center(
                    child: Icon(Icons.videocam_off_outlined, size: 56),
                  ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_active) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              _latestPrediction == null
                  ? 'Đưa bàn tay vào khung hình'
                  : _latestPrediction!.isUnknown
                  ? 'Chưa thấy bàn tay'
                  : 'Dự đoán thử nghiệm: ${_latestPrediction!.labelId} '
                        '(${(_latestPrediction!.confidence * 100).toStringAsFixed(0)}%)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_opening) const Center(child: CircularProgressIndicator()),
        if (_message != null) ...[
          Text(
            _message!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
        ],
        if (_active)
          FilledButton.icon(
            onPressed: _stopCamera,
            icon: const Icon(Icons.stop),
            label: const Text('Dừng camera'),
          )
        else
          FilledButton.icon(
            onPressed: _opening ? null : _startCamera,
            icon: const Icon(Icons.videocam),
            label: const Text('Bắt đầu camera'),
          ),
      ],
    );
  }
}
