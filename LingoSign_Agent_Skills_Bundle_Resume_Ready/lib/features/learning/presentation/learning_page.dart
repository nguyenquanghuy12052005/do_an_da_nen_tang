import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/local_data_providers.dart';
import '../../../app/design_components.dart';
import '../domain/learning_progress.dart';

class LearningPage extends ConsumerWidget {
  const LearningPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(learningSessionsProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyPanel(
          icon: Icons.error_outline,
          message: 'Chưa tải được tiến độ học tập.',
        ),
        data: (sessions) {
          final progress = LearningProgress(sessions);
          final days = progress.days.keys.toList()..sort();
          final mistakes = progress.mistakes.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              const SectionHeading(
                title: 'Mỗi ngày một bước tiến',
                accent: Color(0xFF287364),
                icon: Icons.school_outlined,
                subtitle: 'Tiến độ luyện tập',
                margin: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push('/practice'),
                icon: const Icon(Icons.school_outlined),
                label: const Text('Bắt đầu bài luyện'),
              ),
              const SizedBox(height: 24),
              const PanelHeading('Tổng quan'),
              _ProgressMetrics(progress: progress),
              if (progress.graded > 0 || progress.skipped > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                  child: Text(
                    '${progress.correct}/${progress.graded} câu đúng · ${progress.skipped} bỏ qua',
                  ),
                ),
              const SizedBox(height: 24),
              const PanelHeading('Kết quả theo ngày'),
              if (days.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.bar_chart_outlined),
                    title: Text('Chưa có kết quả theo ngày.'),
                  ),
                ),
              for (final (index, date) in days.reversed.take(14).indexed) ...[
                if (index > 0) const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${date.day}/${date.month}/${date.year} · ${progress.days[date]!.correct}/${progress.days[date]!.graded} câu đúng',
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress.days[date]!.rate,
                          semanticsLabel:
                              'Tỷ lệ trả lời đúng ngày ${date.day}/${date.month}',
                          semanticsValue:
                              '${(progress.days[date]!.rate * 100).round()}%',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const PanelHeading('Ký hiệu cần luyện thêm'),
              if (mistakes.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Chưa có câu trả lời sai.'),
                  ),
                ),
              for (final (index, entry) in mistakes.indexed) ...[
                if (index > 0) const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(child: Text(entry.key)),
                    title: Text('${entry.value} lần trả lời sai'),
                    subtitle: const Text('Luyện lại'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/practice?target=${Uri.encodeQueryComponent(entry.key)}',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const PanelHeading('Các bài gần đây'),
              if (sessions.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.history),
                    title: Text('Chưa có bài luyện.'),
                  ),
                ),
              for (final (index, session) in sessions.take(20).indexed) ...[
                if (index > 0) const SizedBox(height: 10),
                Card(
                  key: ValueKey(session.id),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: AccentIcon(
                      session.complete
                          ? Icons.check_circle_outline
                          : Icons.schedule_outlined,
                      accent: AppAccents.colors[session.complete ? 4 : 1],
                    ),
                    title: Text(
                      session.complete ? 'Đã hoàn thành' : 'Chưa hoàn thành',
                    ),
                    subtitle: Text(
                      '${session.startedAt.toLocal().day}/${session.startedAt.toLocal().month} · '
                      '${TimeOfDay.fromDateTime(session.startedAt.toLocal()).format(context)}\n'
                      '${session.answers.length}/${session.targets.length} câu · ${session.correctCount} đúng',
                    ),
                    children: [
                      for (final answer in session.answers)
                        ListTile(
                          title: Text(
                            'Yêu cầu ${answer.target} · ${answer.skipped
                                ? 'Bỏ qua'
                                : answer.correct
                                ? 'Đúng'
                                : 'Sai'}',
                          ),
                          subtitle: Text(
                            answer.predicted == null
                                ? 'Chưa có đáp án'
                                : 'Nhận ra ${answer.predicted}'
                                      '${answer.confidence == null ? '' : ' · ${(answer.confidence! * 100).round()}% tin cậy'}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      );
}

class _ProgressMetrics extends StatelessWidget {
  const _ProgressMetrics({required this.progress});

  final LearningProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = [
      (
        Icons.emoji_events_outlined,
        '${progress.completed}',
        'Bài đã xong',
        AppAccents.colors[0],
      ),
      (
        Icons.calendar_today_outlined,
        '${progress.activeDays.length}',
        'Ngày luyện',
        AppAccents.colors[1],
      ),
      (
        Icons.check_circle_outline,
        progress.graded == 0 ? '—' : '${(progress.rate * 100).round()}%',
        'Tỷ lệ đúng',
        AppAccents.colors[4],
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = ((constraints.maxWidth + gap) / (100 * scale + gap))
            .floor()
            .clamp(1, 3);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (icon, value, label, accent) in metrics)
              SizedBox(
                width: width,
                child: Card(
                  color: AppAccents.tint(context, accent),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: theme.brightness == Brightness.dark
                              ? theme.colorScheme.onSurface
                              : accent,
                        ),
                        const SizedBox(height: 8),
                        Text(value, style: theme.textTheme.headlineSmall),
                        Text(label, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
