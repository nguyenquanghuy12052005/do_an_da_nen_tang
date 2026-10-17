import '../repositories/sign_recognition_repository.dart';

class StopRecognition {
  const StopRecognition(this._repository);

  final SignRecognitionRepository _repository;

  Future<void> call() => _repository.stop();
}
