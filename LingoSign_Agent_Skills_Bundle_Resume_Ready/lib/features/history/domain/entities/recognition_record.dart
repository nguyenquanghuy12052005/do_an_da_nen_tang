/// Saved label and optional app-private thumbnail path (resolved by repository).
class RecognitionRecord {
  const RecognitionRecord({
    required this.id,
    required this.signCode,
    required this.label,
    required this.confirmedAt,
    this.imagePath,
  });

  final String id;
  final String signCode;
  final String label;
  final DateTime confirmedAt;
  final String? imagePath;
}
