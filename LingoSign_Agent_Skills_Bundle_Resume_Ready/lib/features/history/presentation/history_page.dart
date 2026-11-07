import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/local_data_providers.dart';
import '../../../app/design_components.dart';
import '../domain/entities/recognition_record.dart';
import 'history_photo_viewer.dart';
import 'history_review_sheet.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final _cursors = <RecognitionRecord?>[null];
  final _scroll = ScrollController();
  HistoryFilter _filter = const HistoryFilter();
  void _filterBy(HistoryFilter filter) => _move(() {
    _filter = filter;
    _cursors
      ..clear()
      ..add(null);
  });
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
      .watch(
        filteredHistoryPageProvider((before: _cursors.last, filter: _filter)),
      )
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionHeading(
                title: 'Những ký hiệu đã lưu',
                subtitle: 'Chạm ảnh để phóng to.',
                icon: Icons.history_rounded,
                accent: Color(0xFF934D6C),
              ),
              const Text('Không tải được lịch sử.'),
              TextButton(
                onPressed: () => ref.invalidate(
                  filteredHistoryPageProvider((
                    before: _cursors.last,
                    filter: _filter,
                  )),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (records) {
          final visible = records.take(10).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Tìm trong lịch sử',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (query) => _filterBy(
                        HistoryFilter(
                          query: query,
                          day: _filter.day,
                          favoritesOnly: _filter.favoritesOnly,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Yêu thích'),
                          selected: _filter.favoritesOnly,
                          onSelected: (value) => _filterBy(
                            HistoryFilter(
                              query: _filter.query,
                              day: _filter.day,
                              favoritesOnly: value,
                            ),
                          ),
                        ),
                        ActionChip(
                          label: Text(
                            _filter.day == null
                                ? 'Chọn ngày'
                                : '${_filter.day!.day}/${_filter.day!.month}/${_filter.day!.year}',
                          ),
                          avatar: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                          ),
                          onPressed: () async {
                            final day = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              initialDate: _filter.day ?? DateTime.now(),
                            );
                            if (mounted && day != null) {
                              _filterBy(
                                HistoryFilter(
                                  query: _filter.query,
                                  day: day,
                                  favoritesOnly: _filter.favoritesOnly,
                                ),
                              );
                            }
                          },
                        ),
                        if (_filter.day != null)
                          ActionChip(
                            label: const Text('Bỏ lọc ngày'),
                            onPressed: () => _filterBy(
                              HistoryFilter(
                                query: _filter.query,
                                favoritesOnly: _filter.favoritesOnly,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const EmptyPanel(
                        icon: Icons.history_rounded,
                        message: 'Chưa có kết quả. Hãy bắt đầu nhận diện.',
                      )
                    : ListView.separated(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: visible.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final record = visible[index];
                          return ListTile(
                            onTap: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (context) =>
                                  HistoryReviewSheet(record: record),
                            ),
                            tileColor: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            key: ValueKey(record.id),
                            leading: SizedBox(
                              width: 64,
                              height: 64,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: record.imagePath == null
                                    ? ColoredBox(
                                        color: AppAccents.tint(
                                          context,
                                          AppAccents.colors[2],
                                        ),
                                        child: const Icon(
                                          Icons.sign_language_outlined,
                                          semanticLabel: 'Chưa có ảnh',
                                        ),
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
                            title: Text(
                              record.label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
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
