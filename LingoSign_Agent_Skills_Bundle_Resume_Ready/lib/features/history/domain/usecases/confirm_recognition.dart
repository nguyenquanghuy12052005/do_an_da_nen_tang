import '../../../dictionary/domain/repositories/sign_dictionary_repository.dart';
import '../../../recognition/domain/entities/recognition_prediction.dart';
import '../entities/recognition_record.dart';
import '../repositories/recognition_history_repository.dart';

enum RecognitionFailureReason { unknown, unstable, unsupportedSign }

class RecognitionException implements Exception {
  const RecognitionException(this.reason);

  final RecognitionFailureReason reason;
}

class ConfirmRecognition {
  const ConfirmRecognition({
    required this.dictionary,
    required this.history,
    required this.nextId,
    required this.now,
  });

  final SignDictionaryRepository dictionary;
  final RecognitionHistoryRepository history;
  final String Function() nextId;
  final DateTime Function() now;

  Future<RecognitionRecord> call(RecognitionPrediction prediction) async {
    if (prediction.isUnknown) {
      throw const RecognitionException(RecognitionFailureReason.unknown);
    }
    if (!prediction.isStable) {
      throw const RecognitionException(RecognitionFailureReason.unstable);
    }

    final entry = await dictionary.findByCode(prediction.labelId!);
    if (entry == null) {
      throw const RecognitionException(
        RecognitionFailureReason.unsupportedSign,
      );
    }

    final record = RecognitionRecord(
      id: nextId(),
      signCode: entry.code,
      label: entry.label,
      confirmedAt: now(),
    );
    await history.saveConfirmed(record);
    return record;
  }
}
