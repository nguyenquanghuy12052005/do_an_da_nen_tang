import '../entities/recognition_prediction.dart';

/// Session policy; confidence is a model score, not measured accuracy.
class RecognitionSavePolicy {
  static const minimumConfidence = 0.45;
  String? _lastLabel;

  bool isConfident(RecognitionPrediction prediction) =>
      !prediction.isUnknown &&
      prediction.confidence.isFinite &&
      prediction.confidence >= minimumConfidence &&
      prediction.confidence <= 1;

  bool isDuplicate(RecognitionPrediction prediction) =>
      prediction.labelId == _lastLabel;

  void saved(RecognitionPrediction prediction) =>
      _lastLabel = prediction.labelId;
  void reset() => _lastLabel = null;
}
