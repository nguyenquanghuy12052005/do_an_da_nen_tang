import '../entities/sign_entry.dart';
import '../repositories/sign_dictionary_repository.dart';

class GetDictionaryEntries {
  const GetDictionaryEntries(this._repository);

  final SignDictionaryRepository _repository;

  Future<List<SignEntry>> call(String query) =>
      _repository.search(query.trim());
}
