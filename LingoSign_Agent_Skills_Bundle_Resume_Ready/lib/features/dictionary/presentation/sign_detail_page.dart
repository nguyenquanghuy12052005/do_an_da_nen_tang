import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../domain/entities/sign_entry.dart';

class SignDetailPage extends StatefulWidget {
  const SignDetailPage({
    super.key,
    required this.entry,
    required this.canPractice,
  });
  final SignEntry entry;
  final bool canPractice;
  @override
  State<SignDetailPage> createState() => _SignDetailPageState();
}

class _SignDetailPageState extends State<SignDetailPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _video;
  String? _videoError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.entry.videoAsset case final asset?) {
      final controller = VideoPlayerController.asset(asset);
      _video = controller;
      controller
          .initialize()
          .then((_) {
            if (mounted) setState(() {});
          })
          .catchError((Object _) {
            if (mounted) {
              setState(() => _videoError = 'Không tải được video hướng dẫn.');
            }
          });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_video?.pause());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_video?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final video = _video;
    return Scaffold(
      appBar: AppBar(title: Text(entry.label)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(entry.category)),
              if (entry.signSystem.isNotEmpty)
                Chip(label: Text(entry.signSystem)),
            ],
          ),
          Text(entry.label, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(entry.description ?? 'Chưa có mô tả.'),
          if (entry.imageAsset case final asset?)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  asset,
                  semanticLabel: 'Minh họa ${entry.label}',
                  errorBuilder: (_, _, _) =>
                      const Text('Ảnh hướng dẫn chưa khả dụng.'),
                ),
              ),
            ),
          if (video != null) ...[
            if (_videoError != null)
              Text(_videoError!)
            else if (!video.value.isInitialized)
              const Center(child: CircularProgressIndicator())
            else ...[
              AspectRatio(
                aspectRatio: video.value.aspectRatio,
                child: VideoPlayer(video),
              ),
              VideoProgressIndicator(video, allowScrubbing: true),
              Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: video.value.isPlaying
                        ? 'Tạm dừng video'
                        : 'Phát video',
                    icon: Icon(
                      video.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () async {
                      if (video.value.isPlaying) {
                        await video.pause();
                      } else {
                        await video.play();
                      }
                      if (mounted) setState(() {});
                    },
                  ),
                  TextButton(
                    onPressed: () async {
                      await video.seekTo(Duration.zero);
                      await video.play();
                      if (mounted) setState(() {});
                    },
                    child: const Text('Xem lại từ đầu'),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 24),
          Text('Cách thực hiện', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            entry.instructions.isEmpty
                ? 'Chưa có hướng dẫn được xác minh.'
                : entry.instructions,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: widget.canPractice
                ? () => Navigator.of(context).pop(entry.modelLabel)
                : null,
            icon: const Icon(Icons.school_outlined),
            label: const Text('Luyện ký hiệu này'),
          ),
          if (!widget.canPractice)
            const Text('Chưa hỗ trợ luyện ký hiệu này bằng model hiện tại.'),
          const SizedBox(height: 24),
          Text(
            'Nguồn: ${entry.sourceUrl}\nGiấy phép: ${entry.licenseName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
