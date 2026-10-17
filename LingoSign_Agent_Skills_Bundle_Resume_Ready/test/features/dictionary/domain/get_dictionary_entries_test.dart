import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/features/dictionary/domain/entities/sign_entry.dart';
import 'package:lingosign_ai/features/dictionary/domain/repositories/sign_dictionary_repository.dart';
import 'package:lingosign_ai/features/dictionary/domain/usecases/get_dictionary_entries.dart';

void main() {
  test('trims surrounding whitespace before searching', () async {
    final repository = _RecordingDictionary();
    final search = GetDictionaryEntries(repository);

    final entries = await search('  xin chào  ');

    expect(repository.lastQuery, 'xin chào');
    expect(entries, isEmpty);
  });

  test('passes an empty query to list all supported signs', () async {
    final repository = _RecordingDictionary();
    final search = GetDictionaryEntries(repository);

    await search('   ');

    expect(repository.lastQuery, '');
  });
}

class _RecordingDictionary implements SignDictionaryRepository {
  String? lastQuery;

  @override
  Future<SignEntry?> findByCode(String code) async => null;

  @override
  Future<List<SignEntry>> search(String query) async {
    lastQuery = query;
    return [];
  }
}
