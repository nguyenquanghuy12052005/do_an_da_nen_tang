/// A verified dictionary item. Media is optional until its source is licensed.
class SignEntry {
  const SignEntry({
    required this.code,
    required this.label,
    this.description,
    this.category = 'Khác',
    this.signSystem = '',
    this.instructions = '',
    this.imageAsset,
    this.videoAsset,
    this.modelLabel,
    this.sourceUrl = '',
    this.licenseName = '',
  });

  final String code;
  final String label;
  final String? description;
  final String category, signSystem, instructions, sourceUrl, licenseName;
  final String? imageAsset, videoAsset, modelLabel;
  Map<String, Object?> get details => {
    'category': category,
    'signSystem': signSystem,
    'instructions': instructions,
    'imageAsset': imageAsset,
    'videoAsset': videoAsset,
    'modelLabel': modelLabel,
  };
}
