import 'dart:typed_data';

import '../entities/recognition_record.dart';

abstract interface class RecognitionHistoryRepository {
  Stream<List<RecognitionRecord>> watchHistory({
    int? limit,
    RecognitionRecord? before,
    HistoryFilter filter = const HistoryFilter(),
  });

  Future<void> saveConfirmed(RecognitionRecord record, {Uint8List? photo});

  Future<void> delete(String id);
  Future<void> updateReview(
    String id, {
    bool? favorite,
    bool? incorrect,
    String? note,
  });
}
