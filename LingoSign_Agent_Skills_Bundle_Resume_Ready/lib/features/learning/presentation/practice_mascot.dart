import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/practice_session.dart';

enum MascotMood { welcome, correct, retry, complete }

class PracticeMascotCard extends StatelessWidget {
  const PracticeMascotCard({
    super.key,
    required this.mood,
    required this.title,
    required this.message,
    this.animate = true,
  });

  final MascotMood mood;
  final String title;
  final String message;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final celebrate = mood == MascotMood.correct || mood == MascotMood.complete;
    final mascot = Image.asset(
      'assets/practice_mascot/${mood.name}.png',
      width: 78,
      height: 86,
      excludeFromSemantics: true,
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Card(
      color: mood == MascotMood.retry
          ? colors.tertiaryContainer
          : colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 102,
              height: 94,
              child: !animate || reduceMotion
                  ? mascot
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 580),
                      child: mascot,
                      builder: (context, progress, child) {
                        final bounce = math.sin(progress * math.pi);
                        return Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Transform.translate(
                              offset: Offset(
                                0,
                                (1 - progress) * 10 -
                                    bounce * (celebrate ? 11 : 3),
                              ),
                              child: Transform.scale(
                                scale: 1 - (1 - progress) * .12 + bounce * .07,
                                child: child,
                              ),
                            ),
                            if (celebrate && progress > 0 && progress < 1)
                              for (var i = 0; i < 4; i++)
                                Transform.translate(
                                  offset: Offset(
                                    (i.isEven ? -1 : 1) * (30 + progress * 17),
                                    (i < 2 ? -1 : 1) * (16 + progress * 18),
                                  ),
                                  child: Opacity(
                                    opacity: bounce,
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: i < 2 ? 17 : 12,
                                      color: colors.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                liveRegion: mood != MascotMood.welcome,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(message),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PracticeProgress extends StatelessWidget {
  const PracticeProgress({
    super.key,
    required this.total,
    required this.answers,
    required this.current,
  });

  final int total;
  final List<PracticeAnswer> answers;
  final int? current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    final correct = dark ? const Color(0xFF9DE6CA) : const Color(0xFF246A50);
    final retry = dark ? const Color(0xFFFFBD91) : const Color(0xFF965125);
    return Semantics(
      label: 'Tiến độ bài luyện',
      value: '${answers.length}/$total câu đã trả lời hoặc bỏ qua',
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (var i = 0; i < total; i++)
              _StepDot(
                active: i == current,
                answer: i < answers.length ? answers[i] : null,
                correct: correct,
                retry: retry,
              ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.active,
    required this.answer,
    required this.correct,
    required this.retry,
  });

  final bool active;
  final PracticeAnswer? answer;
  final Color correct;
  final Color retry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final result = answer;
    final tint = result == null || result.skipped
        ? colors.outline
        : result.correct
        ? correct
        : retry;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tint.withValues(alpha: .16),
        border: Border.all(
          color: active ? colors.primary : tint,
          width: active ? 2 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: .35),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: result == null
          ? null
          : Icon(
              result.skipped
                  ? Icons.remove_rounded
                  : result.correct
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              color: tint,
              size: 13,
            ),
    );
  }
}
