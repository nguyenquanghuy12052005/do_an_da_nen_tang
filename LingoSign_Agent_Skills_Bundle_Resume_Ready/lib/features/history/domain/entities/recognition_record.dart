/// A user-confirmed label only. Raw camera data is never part of this entity.
class RecognitionRecord {
  const RecognitionRecord({
    required this.id,
    required this.signCode,
    required this.label,
    required this.confirmedAt,
  });

  final String id;
  final String signCode;
  final String label;
  final DateTime confirmedAt;
}
