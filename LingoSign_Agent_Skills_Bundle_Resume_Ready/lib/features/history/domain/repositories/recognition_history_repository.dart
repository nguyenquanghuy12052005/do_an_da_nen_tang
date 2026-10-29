import 'dart:typed_data';

import '../entities/recognition_record.dart';

abstract interface class RecognitionHistoryRepository {
  Stream<List<RecognitionRecord>> watchHistory({
    int? limit,
    RecognitionRecord? before,
  });

  Future<void> saveConfirmed(RecognitionRecord record, {Uint8List? photo});

  Future<void> delete(String id);
}
