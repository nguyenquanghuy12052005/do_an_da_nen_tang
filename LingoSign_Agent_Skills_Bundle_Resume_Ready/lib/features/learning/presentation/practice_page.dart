import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/camera_gateway.dart';
import '../../../app/local_data_providers.dart';
import '../../../app/design_components.dart';
import '../../recognition/domain/entities/recognition_prediction.dart';
import '../../recognition/domain/usecases/select_window_prediction.dart';
import '../domain/practice_session.dart';

class PracticePage extends ConsumerStatefulWidget {
  const PracticePage({super.key, this.target});
  final String? target;
  @override
  ConsumerState<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends ConsumerState<PracticePage>
    with WidgetsBindingObserver {
  PracticeSession? _session;
  CameraGateway? _camera;
  StreamSubscription<RecognitionPrediction>? _subscription;
  Timer? _timer;
  final _window = SelectWindowPrediction();
  bool _active = false, _busy = false, _feedback = false, _disposed = false;
  String? _message;
  Future<void> _saves = Future.value();
  bool _foreground = true;
  int _generation = 0;
  bool _openingCamera = false;
  String? _selectedTarget;
  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.target;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed) unawaited(_close());
  }

  Future<void> _close() async {
    _generation++;
    _active = false;
    _timer?.cancel();
    _timer = null;
    _window.take();
    await _subscription?.cancel();
    _subscription = null;
    await _camera?.close();
    if (mounted && !_disposed) setState(() => _active = false);
  }

  Future<void> _start(int count) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final labels = (await ref.read(
        supportedPracticeLabelsProvider.future,
      )).toList()..shuffle(Random.secure());
      if (_selectedTarget != null && !labels.contains(_selectedTarget)) {
        throw StateError('Unsupported target');
      }
      final now = DateTime.now();
      final session = PracticeSession(
        id: '${now.microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}',
        startedAt: now,
        targets: _selectedTarget == null
            ? labels.take(count).toList()
            : List.filled(count, _selectedTarget!),
      );
      await ref.read(learningRepositoryProvider).save(session);
      if (!mounted) return;
      setState(() {
        _session = session;
        _feedback = false;
      });
      await _open();
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Không bắt đầu được bài luyện. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open() async {
    if (_openingCamera || _active || !_foreground) return;
    _openingCamera = true;
    try {
      final generation = ++_generation;
      final camera = ref.read(cameraGatewayProvider);
      _camera = camera;
      final result = await camera.open();
      if (!mounted || _disposed || !_foreground || generation != _generation) {
        await camera.close();
        return;
      }
      if (result is! CameraOpened) {
        setState(
          () => _message =
              'Không mở được camera. Kiểm tra quyền camera rồi thử lại.',
        );
        return;
      }
      _subscription = camera.predictions.listen(_collect);
      setState(() {
        _active = true;
        _message = null;
      });
    } on Exception {
      if (mounted && !_disposed) {
        setState(
          () => _message = 'Camera gặp lỗi. Kiểm tra quyền và thử mở lại.',
        );
      }
    } finally {
      _openingCamera = false;
    }
  }

  void _collect(RecognitionPrediction prediction) {
    if (!_active || _feedback || _busy || _session?.complete != false) return;
    _window.add(prediction);
    if (prediction.isUnknown || _timer != null) return;
    setState(() => _message = 'Đang lấy mẫu trong 1 giây…');
    _timer = Timer(const Duration(seconds: 1), () {
      _timer = null;
      final best = _window.take();
      if (!mounted || best == null) return;
      if (!_session!.answer(best, DateTime.now())) {
        setState(
          () => _message =
              'Chưa chắc chắn. Giữ tay rõ trong khung hình và thử lại.',
        );
        return;
      }
      setState(() {
        _feedback = true;
        _message = null;
      });
      _persist();
    });
  }

  void _persist() {
    // Snapshot before later UI actions can mutate the session.
    final snapshot = PracticeSession.fromJson(_session!.toJson());
    final repository = ref.read(learningRepositoryProvider);
    setState(() => _busy = true);
    _saves = _saves.then((_) async {
      try {
        await repository.save(snapshot);
      } catch (_) {
        if (mounted) {
          setState(() => _message = 'Chưa lưu được kết quả. Bấm lưu lại.');
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final labels =
        ref.watch(supportedPracticeLabelsProvider).asData?.value.toList() ??
        <String>[];
    labels.sort();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeading(
          title: 'Luyện ký hiệu',
          accent: Color(0xFF6159BC),
          icon: Icons.flag_outlined,
          subtitle: 'Thực hiện ký hiệu trên màn hình.',
        ),
        if (session == null) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedTarget ?? '',
            decoration: const InputDecoration(
              labelText: 'Chọn ký hiệu để luyện',
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Ngẫu nhiên')),
              for (final label in {...labels, ?_selectedTarget})
                DropdownMenuItem(value: label, child: Text(label)),
            ],
            onChanged: _busy
                ? null
                : (value) => setState(
                    () => _selectedTarget = value == '' ? null : value,
                  ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _busy ? null : () => _start(1),
            child: const Text('Luyện nhanh 1 ký hiệu'),
          ),
          for (final count in [5, 10])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FilledButton(
                onPressed: _busy ? null : () => _start(count),
                child: Text('Bắt đầu $count câu'),
              ),
            ),
        ] else ...[
          LinearProgressIndicator(
            value: session.answers.length / session.targets.length,
          ),
          const SizedBox(height: 16),
          if (!session.complete || _feedback) ...[
            Text(
              'Câu ${_feedback ? session.answers.length : session.answers.length + 1}/${session.targets.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Thực hiện ký hiệu'),
                    Text(
                      _feedback ? session.answers.last.target : session.target!,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_active)
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child:
                      _camera!.preview ??
                      const Center(child: Icon(Icons.videocam_outlined)),
                ),
              ),
            if (!_active)
              FilledButton(
                onPressed: _busy ? null : _open,
                child: const Text('Mở lại camera'),
              ),
            if (_feedback) ...[
              const SizedBox(height: 16),
              Text(
                session.answers.last.skipped
                    ? 'Đã bỏ qua'
                    : session.answers.last.correct
                    ? 'Đúng rồi!'
                    : 'Chưa đúng. Model nhận: ${session.answers.last.predicted}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (session.answers.last.confidence != null)
                Text(
                  'Độ tin cậy model: ${(session.answers.last.confidence! * 100).round()}%',
                ),
              FilledButton(
                onPressed: _busy || _message != null
                    ? null
                    : () {
                        setState(() => _feedback = false);
                        if (session.complete) unawaited(_close());
                      },
                child: Text(
                  session.complete ? 'Xem tổng kết' : 'Câu tiếp theo',
                ),
              ),
            ] else if (!session.complete)
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () {
                        _timer?.cancel();
                        _timer = null;
                        _window.take();
                        session.skip(DateTime.now());
                        setState(() => _feedback = true);
                        _persist();
                      },
                child: const Text('Bỏ qua câu này'),
              ),
          ] else ...[
            const Icon(Icons.emoji_events_outlined, size: 64),
            Text(
              'Hoàn thành bài luyện',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${session.correctCount}/${session.gradedCount} câu đã chấm trả lời đúng · ${session.answers.where((a) => a.skipped).length} bỏ qua',
            ),
            Text(
              'Thời gian: ${session.answers.last.at.difference(session.startedAt).inSeconds} giây',
            ),
            for (final answer in session.answers.where((a) => !a.correct))
              ListTile(
                leading: const Icon(Icons.replay),
                title: Text('Cần luyện lại: ${answer.target}'),
                subtitle: Text(
                  answer.skipped
                      ? 'Đã bỏ qua'
                      : 'Model nhận ${answer.predicted}',
                ),
              ),
            FilledButton(
              onPressed: () => setState(() {
                _session = null;
                _message = null;
              }),
              child: const Text('Bài luyện mới'),
            ),
          ],
        ],
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_message?.startsWith('Chưa lưu') == true)
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    setState(() => _message = null);
                    _persist();
                  },
            child: const Text('Lưu lại'),
          ),
      ],
    );
  }
}
