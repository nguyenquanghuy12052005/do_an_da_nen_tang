import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/local_data_providers.dart';
import '../domain/entities/recognition_record.dart';
import 'history_photo_viewer.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final _cursors = <RecognitionRecord?>[null];
  final _scroll = ScrollController();
  void _move(VoidCallback change) {
    setState(change);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ref
      .watch(historyPageProvider(_cursors.last))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Không tải được lịch sử.'),
              TextButton(
                onPressed: () =>
                    ref.invalidate(historyPageProvider(_cursors.last)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (records) {
          final visible = records.take(10).toList();
          return Column(
            children: [
              Expanded(
                child: visible.isEmpty
                    ? const Center(
                        child: Text('Chưa có kết quả. Hãy bắt đầu nhận diện.'),
                      )
                    : ListView.separated(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: visible.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final record = visible[index];
                          return ListTile(
                            key: ValueKey(record.id),
                            leading: SizedBox(
                              width: 64,
                              height: 64,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: record.imagePath == null
                                    ? const Icon(
                                        Icons.image_not_supported_outlined,
                                        semanticLabel: 'Chưa có ảnh',
                                      )
                                    : InkWell(
                                        onTap: () async {
                                          await showDialog<void>(
                                            context: context,
                                            builder: (context) =>
                                                HistoryPhotoViewer(
                                                  record: record,
                                                ),
                                          );
                                        },
                                        child: Tooltip(
                                          message: 'Xem ảnh lớn',
                                          child: Image.file(
                                            File(record.imagePath!),
                                            fit: BoxFit.cover,
                                            cacheWidth: 160,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stack,
                                                ) => const Icon(
                                                  Icons.broken_image_outlined,
                                                  semanticLabel:
                                                      'Ảnh không khả dụng',
                                                ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(record.label),
                            subtitle: Text(
                              record.confirmedAt
                                  .toLocal()
                                  .toString()
                                  .split('.')
                                  .first,
                            ),
                            trailing: IconButton(
                              tooltip: 'Xóa kết quả',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(historyRepositoryProvider)
                                      .delete(record.id);
                                  if (mounted &&
                                      visible.length == 1 &&
                                      _cursors.length > 1) {
                                    _move(() => _cursors.removeLast());
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Không xóa được kết quả hoặc ảnh.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Trang trước',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _cursors.length == 1
                          ? null
                          : () => _move(() => _cursors.removeLast()),
                    ),
                    Text('Trang ${_cursors.length}'),
                    IconButton(
                      tooltip: 'Trang sau',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: records.length <= 10
                          ? null
                          : () => _move(() => _cursors.add(visible.last)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
}
