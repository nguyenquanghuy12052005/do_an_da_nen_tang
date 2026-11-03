import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/features/learning/domain/practice_session.dart';
import 'package:lingosign_ai/features/learning/domain/learning_progress.dart';

void main() {
  test('progress excludes skips from accuracy but counts active days and partial answers', () {
    final first = DateTime(2026, 11, 1, 12);
    final second = DateTime(2026, 11, 2, 12);
    final session = PracticeSession(
      id: 'fixture',
      startedAt: first,
      targets: ['A', 'B', 'C'],
      answers: [
        PracticeAnswer(target: 'A', predicted: 'A', confidence: .7, at: first),
        PracticeAnswer(target: 'B', predicted: 'A', confidence: .9, at: first),
        PracticeAnswer(target: 'C', at: second),
      ],
    );
    final stats = LearningProgress([session]);
    expect(stats.completed, 1);
    expect(stats.activeDays.length, 2);
    expect(stats.rate, .5);
    expect(stats.skipped, 1);
    expect(stats.mistakes['B'], 1);
    expect(stats.days[first.copyWith(hour: 0)]!.graded, 2);
    expect(LearningProgress([]).rate, 0);
  });
}
