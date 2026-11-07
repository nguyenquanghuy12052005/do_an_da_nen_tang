import 'dart:async';

import 'package:go_router/go_router.dart';

import 'sign_detail_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/local_data_providers.dart';
import '../../../app/design_components.dart';
import '../domain/entities/sign_entry.dart';

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
          accent: Color(0xFF9A541C),
          icon: Icons.menu_book_outlined,
          subtitle: 'Chữ cái và số',
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
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const gap = 12.0;
                              final scale =
                                  MediaQuery.textScalerOf(context).scale(14) /
                                  14;
                              final columns =
                                  ((constraints.maxWidth + gap) /
                                          (134 * scale + gap))
                                      .floor()
                                      .clamp(1, 4);
                              final width =
                                  (constraints.maxWidth - gap * (columns - 1)) /
                                  columns;
                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  for (final entry in entries.where(
                                    (entry) =>
                                        _category == null ||
                                        entry.category == _category,
                                  ))
                                    SizedBox(
                                      width: width,
                                      child: _SignCard(
                                        entry: entry,
                                        onTap: () => _openSign(entry),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
              ),
        ),
      ],
    );
  }

  Future<void> _openSign(SignEntry entry) async {
    final labels = await ref.read(supportedPracticeLabelsProvider.future);
    if (!mounted) return;
    final target = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SignDetailPage(
          entry: entry,
          canPractice: labels.contains(entry.modelLabel),
        ),
      ),
    );
    if (mounted && target != null) {
      context.push('/practice?target=${Uri.encodeQueryComponent(target)}');
    }
  }
}

class _SignCard extends StatelessWidget {
  const _SignCard({required this.entry, required this.onTap});

  final SignEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppAccents.colors[entry.modelLabel == null ? 1 : 0];
    return Card(
      color: AppAccents.tint(context, accent),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: entry.imageAsset == null
                    ? const SizedBox(
                        height: 82,
                        child: Icon(Icons.sign_language_outlined),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          entry.imageAsset!,
                          width: 82,
                          height: 82,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              Text(entry.label, style: theme.textTheme.titleMedium),
              Text(
                entry.category,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
