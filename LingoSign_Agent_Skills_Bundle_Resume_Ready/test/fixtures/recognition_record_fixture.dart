import 'package:lingosign_ai/features/history/domain/entities/recognition_record.dart';

RecognitionRecord record(String id) => RecognitionRecord(
  id: id,
  signCode: 'A',
  label: 'A',
  confirmedAt: DateTime.utc(2026),
);
