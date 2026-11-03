import 'practice_session.dart';

class DayProgress {
  int graded = 0;
  int correct = 0;
  double get rate => graded == 0 ? 0 : correct / graded;
}

class LearningProgress {
  LearningProgress(List<PracticeSession> sessions) {
    completed = sessions.where((session) => session.complete).length;
    for (final session in sessions) {
      for (final answer in session.answers) {
        final local = answer.at.toLocal();
        final date = DateTime(local.year, local.month, local.day);
        activeDays.add(date);
        if (answer.skipped) {
          skipped++;
          continue;
        }
        graded++;
        final day = days.putIfAbsent(date, DayProgress.new);
        day.graded++;
        if (answer.correct) {
          correct++;
          day.correct++;
        } else {
          mistakes.update(
            answer.target,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }
  }
  late final int completed;
  int graded = 0, correct = 0, skipped = 0;
  final activeDays = <DateTime>{};
  final days = <DateTime, DayProgress>{};
  final mistakes = <String, int>{};
  double get rate => graded == 0 ? 0 : correct / graded;
}
