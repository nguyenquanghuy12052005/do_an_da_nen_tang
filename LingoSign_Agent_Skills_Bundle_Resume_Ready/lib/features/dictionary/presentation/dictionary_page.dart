import 'dart:async';

import 'package:go_router/go_router.dart';

import 'sign_detail_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/local_data_providers.dart';
import '../../../app/design_components.dart';

class DictionaryPage extends ConsumerStatefulWidget {
  const DictionaryPage({super.key});

  @override
  ConsumerState<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends ConsumerState<DictionaryPage> {
  String _query = '';
  String? _category;
  final _search = TextEditingController();
  Timer? _debounce;
  void _submit(String value) {
    _debounce?.cancel();
    setState(() => _query = value.trim());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeading(
          title: 'Khám phá ký hiệu',
          accent: Color(0xFFB84B18),
          subtitle: 'Tra cứu và tìm hiểu ý nghĩa của từng ký hiệu.',
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 250),
                () => _submit(value),
              );
            },
            decoration: InputDecoration(
              labelText: 'Tìm ký hiệu',
              prefixIcon: Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Xóa tìm kiếm',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _search.clear();
                  _submit('');
                },
              ),
            ),
            onSubmitted: _submit,
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
                    ? EmptyPanel(
                        icon: Icons.menu_book_outlined,
                        message: _query.isEmpty
                            ? 'Từ điển chưa có nội dung được xác minh.'
                            : 'Không tìm thấy ký hiệu.',
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Tất cả'),
                                selected: _category == null,
                                onSelected: (_) =>
                                    setState(() => _category = null),
                              ),
                              for (final category
                                  in entries
                                      .map((entry) => entry.category)
                                      .toSet())
                                ChoiceChip(
                                  label: Text(category),
                                  selected: _category == category,
                                  onSelected: (_) =>
                                      setState(() => _category = category),
                                ),
                            ],
                          ),
                          for (final entry in entries.where(
                            (entry) =>
                                _category == null ||
                                entry.category == _category,
                          ))
                            Card(
                              color: AppAccents.tint(
                                context,
                                AppAccents.colors[entry.label.codeUnitAt(
                                      entry.label.length - 1,
                                    ) %
                                    AppAccents.colors.length],
                              ),
                              margin: const EdgeInsets.only(top: 12),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(14),
                                minVerticalPadding: 16,
                                leading: entry.imageAsset == null
                                    ? const Icon(Icons.sign_language_outlined)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.asset(
                                          entry.imageAsset!,
                                          width: 64,
                                          height: 72,
                                          fit: BoxFit.contain,
                                          semanticLabel: entry.label,
                                        ),
                                      ),
                                title: Text(entry.label),
                                subtitle: Text(entry.category),
                                trailing: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surface,
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color:
                                        AppAccents.colors[entry.label
                                                .codeUnitAt(
                                                  entry.label.length - 1,
                                                ) %
                                            AppAccents.colors.length],
                                  ),
                                ),
                                onTap: () async {
                                  final labels = await ref.read(
                                    supportedPracticeLabelsProvider.future,
                                  );
                                  if (!context.mounted) return;
                                  final target = await Navigator.of(context)
                                      .push<String>(
                                        MaterialPageRoute(
                                          builder: (_) => SignDetailPage(
                                            entry: entry,
                                            canPractice: labels.contains(
                                              entry.modelLabel,
                                            ),
                                          ),
                                        ),
                                      );
                                  if (context.mounted && target != null) {
                                    context.push(
                                      '/practice?target=${Uri.encodeQueryComponent(target)}',
                                    );
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
              ),
        ),
      ],
    );
  }
}
