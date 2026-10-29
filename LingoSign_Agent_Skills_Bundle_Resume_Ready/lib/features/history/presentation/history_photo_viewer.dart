import 'dart:io';

import 'package:flutter/material.dart';

import '../domain/entities/recognition_record.dart';

class HistoryPhotoViewer extends StatelessWidget {
  const HistoryPhotoViewer({super.key, required this.record});

  final RecognitionRecord record;

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Đóng ảnh',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Ảnh nhận diện: ${record.label}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ClipRect(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: SizedBox.expand(
                    child: Image.file(
                      File(record.imagePath!),
                      fit: BoxFit.contain,
                      semanticLabel: 'Ảnh nhận diện ${record.label}',
                      errorBuilder: (context, error, stack) => const Center(
                        child: Text('Ảnh không còn khả dụng trên thiết bị.'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${record.confirmedAt.toLocal().toString().split('.').first}\n'
                'Dùng hai ngón tay để phóng to và kéo ảnh để di chuyển.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
