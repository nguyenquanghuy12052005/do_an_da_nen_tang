import '../entities/recognition_prediction.dart';

class SelectWindowPrediction {
  RecognitionPrediction? _best;

  void add(RecognitionPrediction prediction) {
    if (prediction.isUnknown || !prediction.confidence.isFinite) return;
    if (_best == null || prediction.confidence > _best!.confidence) {
      _best = prediction;
    }
  }

  RecognitionPrediction? take() {
    final result = _best;
    _best = null;
    return result;
  }
}
