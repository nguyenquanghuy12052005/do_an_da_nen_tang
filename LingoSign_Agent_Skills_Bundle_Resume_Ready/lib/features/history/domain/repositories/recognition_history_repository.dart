import '../entities/recognition_record.dart';

abstract interface class RecognitionHistoryRepository {
  Stream<List<RecognitionRecord>> watchHistory();

  Future<void> saveConfirmed(RecognitionRecord record);

  Future<void> delete(String id);
}
