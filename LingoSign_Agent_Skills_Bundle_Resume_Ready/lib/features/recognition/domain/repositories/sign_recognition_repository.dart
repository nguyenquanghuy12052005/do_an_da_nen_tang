import '../entities/recognition_prediction.dart';

abstract interface class SignRecognitionRepository {
  /// Emits typed predictions; camera frames remain in the data adapter.
  Stream<RecognitionPrediction> recognize();

  Future<void> start();

  Future<void> stop();
}
