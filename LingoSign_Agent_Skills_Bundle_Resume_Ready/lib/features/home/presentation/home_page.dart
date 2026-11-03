import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingosign_ai/app/camera_gateway.dart';
import 'package:lingosign_ai/app/local_data_providers.dart';
import 'package:lingosign_ai/features/history/domain/entities/recognition_record.dart';
import 'package:lingosign_ai/features/recognition/domain/usecases/select_window_prediction.dart';
import 'package:lingosign_ai/features/recognition/domain/usecases/recognition_save_policy.dart';
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
  final _window = SelectWindowPrediction();
  Timer? _windowTimer;
  Future<void> _saveQueue = Future<void>.value();
  int _recordSequence = 0;
  final _savePolicy = RecognitionSavePolicy();
  bool _avoidDuplicates = false;
  bool _noHand = true;
  String? _recognitionStatus;
  double _progress = 0;
  Timer? _progressTimer;
  Timer? _absenceTimer;

  void _collectPrediction(RecognitionPrediction prediction) {
    if (!mounted || !_active) return;
    setState(() => _noHand = prediction.isUnknown);
    if (prediction.isUnknown) {
      _absenceTimer ??= Timer(const Duration(seconds: 1), () {
        _absenceTimer = null;
        _savePolicy.reset();
        _resetWindow();
        if (mounted) setState(() => _recognitionStatus = null);
      });
    } else {
      _absenceTimer?.cancel();
      _absenceTimer = null;
    }
    _window.add(prediction);
    if (!prediction.isUnknown && _windowTimer == null) {
      setState(() {
        _progress = 0;
        _recognitionStatus = 'Đang lấy mẫu trong 1 giây…';
      });
      _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (
        timer,
      ) {
        if (mounted) setState(() => _progress = (timer.tick / 20).clamp(0, 1));
      });
      _windowTimer = Timer(const Duration(seconds: 1), _finishWindow);
    }
  }

  void _finishWindow() {
    _windowTimer = null;
    _progressTimer?.cancel();
    _progressTimer = null;
    final best = _window.take();
    if (!mounted || !_active || best == null) return;
    setState(() {
      _progress = 1;
      _latestPrediction = best;
    });
    if (!_savePolicy.isConfident(best)) {
      setState(
        () => _recognitionStatus =
            'Chưa chắc chắn, hãy thử lại. Không lưu kết quả này.',
      );
      return;
    }
    if (_avoidDuplicates && _savePolicy.isDuplicate(best)) {
      setState(
        () => _recognitionStatus = 'Ký hiệu này đã được lưu. Đổi ký hiệu hoặc rút tay khoảng 1 giây để nhận diện lại.',
      );
      return;
    }
    setState(() => _recognitionStatus = 'Đang lưu kết quả…');
    _savePolicy.saved(best);
    final now = DateTime.now();
    final record = RecognitionRecord(
      id: '${now.microsecondsSinceEpoch}-${_recordSequence++}',
      signCode: best.labelId!,
      label: best.labelId!,
      confirmedAt: now,
    );
    final repository = ref.read(historyRepositoryProvider);
    final camera = _gateway;
    final photo = camera is HistoryPhotoCamera
        ? (camera as HistoryPhotoCamera).captureHistoryPhoto()
        : null;
    _saveQueue = _saveQueue.then((_) async {
      try {
        final bytes = await photo;
        await repository.saveConfirmed(record, photo: bytes);
        if (mounted && _active && identical(_latestPrediction, best)) {
          setState(() => _recognitionStatus = 'Đã lưu kết quả vào lịch sử.');
        }
        if (photo != null && bytes == null && mounted) {
          setState(
            () => _message = 'Đã lưu kết quả nhưng không chụp được ảnh.',
          );
        }
      } catch (_) {
        if (identical(_latestPrediction, best)) _savePolicy.reset();
        if (mounted) setState(() => _message = 'Không lưu được lịch sử.');
      }
    });
  }

  void _resetWindow() {
    _windowTimer?.cancel();
    _windowTimer = null;
    _progressTimer?.cancel();
    _progressTimer = null;
    _progress = 0;
    _window.take();
  }

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
      _noHand = true;
      _recognitionStatus = null;
      _savePolicy.reset();
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
      _predictionSubscription = _gateway!.predictions.listen(
        _collectPrediction,
      );
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
    _resetWindow();
    _absenceTimer?.cancel();
    _absenceTimer = null;
    _savePolicy.reset();
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
    _absenceTimer?.cancel();
    _resetWindow();
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
          'Giữ toàn bộ bàn tay trong khung hình, đủ sáng và tránh che các ngón tay. Mỗi lượt lấy mẫu 1 giây; kết quả có độ tin cậy từ 60% được lưu cùng ảnh. Camera tiếp tục chạy cho đến khi bạn bấm dừng.',
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
              _noHand
                  ? 'Chưa thấy bàn tay — đưa toàn bộ bàn tay vào khung hình'
                  : _latestPrediction == null
                  ? 'Giữ tay trong khung hình'
                  : _latestPrediction!.isUnknown
                  ? 'Chưa thấy bàn tay'
                  : 'Kết quả: ${_latestPrediction!.labelId} '
                        '(${(_latestPrediction!.confidence * 100).toStringAsFixed(0)}%)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _progress,
            semanticsLabel: 'Tiến trình lấy mẫu 1 giây',
          ),
          if (_recognitionStatus != null) Text(_recognitionStatus!),
          const SizedBox(height: 16),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Tránh lưu ký hiệu trùng liên tiếp'),
          subtitle: const Text(
            'Áp dụng trong phiên camera này. Rút tay 1 giây hoặc đổi ký hiệu để lưu lại.',
          ),
          value: _avoidDuplicates,
          onChanged: (value) => setState(() {
            _avoidDuplicates = value;
            _savePolicy.reset();
          }),
        ),
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
