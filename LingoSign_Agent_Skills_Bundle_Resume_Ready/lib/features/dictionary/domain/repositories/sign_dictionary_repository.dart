import '../entities/sign_entry.dart';

abstract interface class SignDictionaryRepository {
  /// An empty query returns the complete supported catalog.
  Future<List<SignEntry>> search(String query);

  Future<SignEntry?> findByCode(String code);
}
