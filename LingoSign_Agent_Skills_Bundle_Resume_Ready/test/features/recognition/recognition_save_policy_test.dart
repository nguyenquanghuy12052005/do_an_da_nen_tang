import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/features/recognition/domain/entities/recognition_prediction.dart';
import 'package:lingosign_ai/features/recognition/domain/usecases/recognition_save_policy.dart';

RecognitionPrediction sample(String? label, double score) =>
    RecognitionPrediction(
      labelId: label,
      confidence: score,
      timestamp: DateTime.utc(2026),
      isStable: false,
    );

void main() {
  test('rejects unknown, weak and invalid scores, accepts threshold', () {
    final policy = RecognitionSavePolicy();
    for (final prediction in [
      sample(null, 1),
      sample('A', .449),
      sample('A', double.nan),
      sample('A', 1.1),
    ]) {
      expect(policy.isConfident(prediction), isFalse);
    }
    expect(policy.isConfident(sample('A', .45)), isTrue);
  });
  test('suppresses repeated label until another label or reset', () {
    final policy = RecognitionSavePolicy();
    policy.saved(sample('A', .8));
    expect(policy.isDuplicate(sample('A', .9)), isTrue);
    expect(policy.isDuplicate(sample('B', .9)), isFalse);
    policy.saved(sample('B', .9));
    expect(policy.isDuplicate(sample('A', .8)), isFalse);
    policy.reset();
    expect(policy.isDuplicate(sample('B', .9)), isFalse);
  });
}
