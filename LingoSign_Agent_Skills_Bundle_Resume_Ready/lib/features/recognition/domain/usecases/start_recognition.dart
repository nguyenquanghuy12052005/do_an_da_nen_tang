import '../repositories/sign_recognition_repository.dart';

class StartRecognition {
  const StartRecognition(this._repository);

  final SignRecognitionRepository _repository;

  Future<void> call() => _repository.start();
}
