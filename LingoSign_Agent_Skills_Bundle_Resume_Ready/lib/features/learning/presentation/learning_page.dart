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
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeading(
                title: 'Mỗi ngày một bước tiến',
                accent: Color(0xFF087C70),
                subtitle:
                    'Ôn lại, thực hành và theo dõi kết quả của chính bạn.',
              ),
              FilledButton.icon(
                onPressed: () => context.push('/practice'),
                icon: const Icon(Icons.school_outlined),
                label: const Text('Bắt đầu bài luyện'),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Chip(
                    backgroundColor: AppAccents.tint(
                      context,
                      AppAccents.colors[0],
                    ),
                    avatar: const Icon(Icons.emoji_events_outlined),
                    label: Text('${progress.completed} bài hoàn thành'),
                  ),
                  Chip(
                    backgroundColor: AppAccents.tint(
                      context,
                      AppAccents.colors[1],
                    ),
                    avatar: const Icon(Icons.local_fire_department_outlined),
                    label: Text('${progress.activeDays.length} ngày luyện tập'),
                  ),
                  Chip(
                    backgroundColor: AppAccents.tint(
                      context,
                      AppAccents.colors[4],
                    ),
                    avatar: const Icon(Icons.check_circle_outline),
                    label: Text(
                      '${(progress.rate * 100).round()}% trả lời đúng',
                    ),
                  ),
                ],
              ),
              Text(
                '${progress.correct}/${progress.graded} câu đã chấm đúng · ${progress.skipped} câu bỏ qua. Đây là tỷ lệ làm bài đúng, không phải độ tin cậy model.',
              ),
              const SizedBox(height: 24),
              Text(
                'Kết quả theo ngày',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (days.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Hoàn thành một lượt trả lời để bắt đầu theo dõi tiến độ.',
                  ),
                ),
              for (final date in days.reversed.take(14))
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
              const SizedBox(height: 24),
              Text(
                'Ký hiệu cần luyện thêm',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (mistakes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có câu trả lời sai.'),
                ),
              for (final entry in mistakes)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(entry.key)),
                    title: Text('${entry.value} lần trả lời sai'),
                    trailing: TextButton(
                      onPressed: () => context.push(
                        '/practice?target=${Uri.encodeQueryComponent(entry.key)}',
                      ),
                      child: const Text('Luyện lại'),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Các bài gần đây',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final session in sessions.take(20))
                Card(
                  child: ExpansionTile(
                    title: Text(
                      '${session.complete ? 'Đã hoàn thành' : 'Chưa hoàn thành'} · ${session.answers.length}/${session.targets.length} câu',
                    ),
                    subtitle: Text(
                      '${session.startedAt.toLocal().toString().split('.').first} · ${session.correctCount} câu đúng',
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
                                : 'Model nhận ${answer.predicted} · tin cậy ${(answer.confidence! * 100).round()}%',
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      );
}
