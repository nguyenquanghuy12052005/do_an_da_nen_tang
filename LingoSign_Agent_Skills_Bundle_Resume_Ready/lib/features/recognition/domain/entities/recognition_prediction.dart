/// A model output after adapter-level decoding; null [labelId] means unknown.
class RecognitionPrediction {
  const RecognitionPrediction({
    required this.labelId,
    required this.confidence,
    required this.timestamp,
    required this.isStable,
  });

  final String? labelId;
  final double confidence;
  final DateTime timestamp;
  final bool isStable;

  bool get isUnknown => labelId == null || labelId!.isEmpty;
}
