/// Saved label and optional app-private thumbnail path (resolved by repository).
class RecognitionRecord {
  const RecognitionRecord({
    required this.id,
    required this.signCode,
    required this.label,
    required this.confirmedAt,
    this.imagePath,
    this.confidence,
    this.favorite = false,
    this.incorrect = false,
    this.note,
  });

  final String id;
  final String signCode;
  final String label;
  final DateTime confirmedAt;
  final String? imagePath;
  final double? confidence;
  final bool favorite;
  final bool incorrect;
  final String? note;
}

class HistoryFilter {
  const HistoryFilter({this.query = '', this.day, this.favoritesOnly = false});
  final String query;
  final DateTime? day;
  final bool favoritesOnly;
}
