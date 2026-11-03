import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/local_data_providers.dart';
import '../domain/entities/recognition_record.dart';
import 'history_photo_viewer.dart';

class HistoryReviewSheet extends ConsumerStatefulWidget {
  const HistoryReviewSheet({super.key, required this.record});
  final RecognitionRecord record;
  @override
  ConsumerState<HistoryReviewSheet> createState() => _HistoryReviewSheetState();
}

class _HistoryReviewSheetState extends ConsumerState<HistoryReviewSheet> {
  late bool _favorite = widget.record.favorite;
  late bool _incorrect = widget.record.incorrect;
  late final _note = TextEditingController(text: widget.record.note);
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save({bool? favorite, bool? incorrect}) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(historyRepositoryProvider)
          .updateReview(
            widget.record.id,
            favorite: favorite ?? _favorite,
            incorrect: incorrect ?? _incorrect,
            note: _note.text.trim(),
          );
      if (mounted) {
        setState(() {
          _favorite = favorite ?? _favorite;
          _incorrect = incorrect ?? _incorrect;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không lưu được phản hồi. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kết quả: ${record.label}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(record.confirmedAt.toLocal().toString().split('.').first),
            Text(
              record.confidence == null
                  ? 'Độ tin cậy: Không có dữ liệu'
                  : 'Độ tin cậy model: ${(record.confidence! * 100).round()}%',
            ),
            if (record.imagePath != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: InkWell(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => HistoryPhotoViewer(record: record),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(record.imagePath!),
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Text('Ảnh không khả dụng'),
                    ),
                  ),
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Yêu thích'),
              secondary: const Icon(Icons.favorite_outline),
              value: _favorite,
              onChanged: _saving ? null : (value) => _save(favorite: value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Nhận diện sai'),
              subtitle: const Text(
                'Lưu phản hồi riêng, giữ nguyên dự đoán gốc. Chưa dùng để huấn luyện model.',
              ),
              value: _incorrect,
              onChanged: _saving ? null : (value) => _save(incorrect: value),
            ),
            TextField(
              controller: _note,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Ghi chú ôn tập'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : () => _save(),
              child: Text(_saving ? 'Đang lưu…' : 'Lưu ghi chú'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
