import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/features/recognition/domain/entities/recognition_prediction.dart';
import 'package:lingosign_ai/features/recognition/domain/usecases/select_window_prediction.dart';

void main() {
  test('selects maximum confidence and resets each window', () {
    final window = SelectWindowPrediction();
    RecognitionPrediction sample(String? label, double confidence) =>
        RecognitionPrediction(
          labelId: label,
          confidence: confidence,
          timestamp: DateTime.utc(2026),
          isStable: false,
        );
    window.add(sample('A', 0.5));
    window.add(sample('B', 0.9));
    window.add(sample('A', 0.8));
    window.add(sample(null, 1));
    expect(window.take()?.labelId, 'B');
    expect(window.take(), isNull);
  });
}
