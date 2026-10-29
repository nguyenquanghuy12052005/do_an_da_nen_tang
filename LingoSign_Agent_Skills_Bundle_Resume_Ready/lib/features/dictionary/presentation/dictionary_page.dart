import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/local_data_providers.dart';

class DictionaryPage extends ConsumerStatefulWidget {
  const DictionaryPage({super.key});

  @override
  ConsumerState<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends ConsumerState<DictionaryPage> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Tìm ký hiệu',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) => setState(() => _query = value.trim()),
          ),
        ),
        Expanded(
          child: ref
              .watch(dictionaryProvider(_query))
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    const Center(child: Text('Không tải được từ điển.')),
                data: (entries) => entries.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty
                              ? 'Từ điển chưa có nội dung được xác minh.'
                              : 'Không tìm thấy ký hiệu.',
                        ),
                      )
                    : ListView(
                        children: [
                          for (final entry in entries)
                            ExpansionTile(
                              title: Text(entry.label),
                              subtitle: Text(entry.code),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    entry.description ?? 'Chưa có mô tả.',
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
              ),
        ),
      ],
    );
  }
}
