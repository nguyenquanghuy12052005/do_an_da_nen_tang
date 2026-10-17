/// A verified dictionary item. Media is optional until its source is licensed.
class SignEntry {
  const SignEntry({required this.code, required this.label, this.description});

  final String code;
  final String label;
  final String? description;
}
