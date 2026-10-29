import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/local/repositories/local_recognition_history_repository.dart';
import '../data/local/repositories/local_sign_dictionary_repository.dart';
import '../features/dictionary/domain/repositories/sign_dictionary_repository.dart';
import '../features/dictionary/domain/entities/sign_entry.dart';
import '../features/history/domain/entities/recognition_record.dart';
import '../features/history/domain/repositories/recognition_history_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.open();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});
final historyRepositoryProvider = Provider<RecognitionHistoryRepository>(
  (ref) => LocalRecognitionHistoryRepository(ref.watch(appDatabaseProvider)),
);
final historyProvider = StreamProvider<List<RecognitionRecord>>(
  (ref) => ref.watch(historyRepositoryProvider).watchHistory(),
);
final historyPageProvider = StreamProvider.autoDispose
    .family<List<RecognitionRecord>, RecognitionRecord?>(
      (ref, before) => ref
          .watch(historyRepositoryProvider)
          .watchHistory(limit: 11, before: before),
    );
final dictionaryRepositoryProvider = Provider<SignDictionaryRepository>(
  (ref) => LocalSignDictionaryRepository(ref.watch(appDatabaseProvider)),
);
final dictionaryProvider = FutureProvider.family<List<SignEntry>, String>(
  (ref, query) => ref.watch(dictionaryRepositoryProvider).search(query),
);
