import 'dart:async';
import 'dart:convert';

import 'firebase_session.dart';

import 'package:flutter/services.dart';

import '../features/admin/data/admin_providers.dart';
import '../features/admin/data/published_content.dart';

import '../features/learning/domain/practice_session.dart';
import '../features/learning/domain/learning_progress.dart';
import '../data/local/repositories/local_learning_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/local/repositories/local_recognition_history_repository.dart';
import '../data/local/repositories/local_sign_dictionary_repository.dart';
import '../features/dictionary/domain/repositories/sign_dictionary_repository.dart';
import '../features/dictionary/domain/entities/sign_entry.dart';
import '../features/history/domain/entities/recognition_record.dart';
import '../features/history/domain/repositories/recognition_history_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final user = ref.watch(firebaseSessionProvider)?.user;
  final key = user == null ? null : base64Url.encode(utf8.encode(user.uid));
  final database = AppDatabase.open(accountKey: key);
  ref.onDispose(() => unawaited(database.close()));
  return database;
});
final learningRepositoryProvider = Provider<LearningRepository>(
  (ref) => LocalLearningRepository(
    ref.watch(appDatabaseProvider),
    syncLearning: ref.watch(firebaseSessionProvider)?.user != null,
  ),
);
final learningSessionsProvider =
    StreamProvider.autoDispose<List<PracticeSession>>(
      (ref) => ref.watch(learningRepositoryProvider).watchSessions(),
    );
final learningProgressProvider =
    Provider.autoDispose<AsyncValue<LearningProgress>>(
      (ref) =>
          ref.watch(learningSessionsProvider).whenData(LearningProgress.new),
    );
final learningHistoryPageProvider = StreamProvider.autoDispose
    .family<List<PracticeSession>, ({int limit, int offset})>(
      (ref, page) => ref
          .watch(learningRepositoryProvider)
          .watchSessions(limit: page.limit, offset: page.offset),
    );
final historyRepositoryProvider = Provider<RecognitionHistoryRepository>(
  (ref) => LocalRecognitionHistoryRepository(ref.watch(appDatabaseProvider)),
);
final historyPageProvider = StreamProvider.autoDispose
    .family<List<RecognitionRecord>, RecognitionRecord?>(
      (ref, before) => ref
          .watch(historyRepositoryProvider)
          .watchHistory(limit: 11, before: before),
    );
final filteredHistoryPageProvider = StreamProvider.autoDispose
    .family<
      List<RecognitionRecord>,
      ({RecognitionRecord? before, HistoryFilter filter})
    >(
      (ref, request) => ref
          .watch(historyRepositoryProvider)
          .watchHistory(
            limit: 11,
            before: request.before,
            filter: request.filter,
          ),
    );
final dictionaryRepositoryProvider = Provider<SignDictionaryRepository>(
  (ref) => LocalSignDictionaryRepository(ref.watch(appDatabaseProvider)),
);
final publishedContentProvider = Provider<PublishedContent>(
  (ref) => PublishedContent(ref.watch(appDatabaseProvider)),
);
final publishedRefreshProvider = FutureProvider.autoDispose
    .family<void, String>((ref, kind) async {
      final cache = ref.watch(publishedContentProvider);
      final firestore = ref.watch(firebaseSessionProvider)?.firestore;
      if (firestore == null) return;
      List<ContentItem> items;
      try {
        items = await fetchPublished(firestore, kind);
      } on Exception {
        return; // Keep the last published catalog when offline.
      }
      if (ref.mounted) await cache.replace(kind, items);
    });
final publishedLessonsProvider = FutureProvider.autoDispose<List<ContentItem>>((
  ref,
) async {
  if (ref.watch(firebaseSessionProvider) == null) return [];
  final cache = ref.watch(publishedContentProvider);
  await ref.watch(publishedRefreshProvider('lessons').future);
  final supported = await ref.watch(supportedPracticeLabelsProvider.future);
  return (await cache.read('lessons')).where((item) {
    final targets = item['targets'];
    return item['state'] == 'published' &&
        targets is List &&
        targets.isNotEmpty &&
        targets.every(supported.contains);
  }).toList();
});
final bundledDictionaryProvider = FutureProvider<void>((ref) async {
  final catalog = jsonDecode(
    await rootBundle.loadString('assets/dictionary/catalog.json'),
  ) as Map<String, dynamic>;
  final items = catalog['entries'] as List;
  if (items.isEmpty) return;
  final entries = items.map((raw) {
    final item = (raw as Map).cast<String, dynamic>();
    String? asset(String key) {
      final value = item[key] as String?;
      if (value != null &&
          (!value.startsWith('assets/dictionary/') || value.contains('..'))) {
        throw FormatException('Invalid catalog asset');
      }
      return value;
    }

    return SignEntry(
      code: item['code'] as String,
      label: item['label'] as String,
      description: item['description'] as String?,
      category: item['category'] as String? ?? 'Khác',
      signSystem: item['signSystem'] as String,
      instructions: item['instructions'] as String,
      imageAsset: asset('imageAsset'),
      videoAsset: asset('videoAsset'),
      modelLabel: item['modelLabel'] as String?,
    );
  }).toList();
  await LocalSignDictionaryRepository(ref.read(appDatabaseProvider))
      .upsertVerifiedCatalog(
        entries: entries,
        catalogVersion: catalog['version'] as String,
        sourceUrl: catalog['sourceUrl'] as String,
        licenseName: catalog['licenseName'] as String,
        updatedAt: DateTime.now(),
      );
});
final supportedPracticeLabelsProvider = FutureProvider<Set<String>>((
  ref,
) async {
  final metadata = jsonDecode(
    await rootBundle.loadString('assets/model/model.json'),
  ) as Map<String, dynamic>;
  return (metadata['labels'] as List)
      .cast<String>()
      .where((label) => RegExp(r'^[A-Z]$').hasMatch(label))
      .toSet();
});

final dictionaryProvider = FutureProvider.autoDispose
    .family<List<SignEntry>, String>((ref, query) async {
      final repository = ref.watch(dictionaryRepositoryProvider);
      if (ref.watch(firebaseSessionProvider) == null) {
        await ref.watch(bundledDictionaryProvider.future);
        return repository.search(query);
      }
      final cache = ref.watch(publishedContentProvider);
      await Future.wait([
        ref.watch(bundledDictionaryProvider.future),
        ref.watch(publishedRefreshProvider('signs').future),
        ref.watch(publishedRefreshProvider('categories').future),
      ]);
      final entries = await cache.overlay(await repository.search(''));
      final normalized = query.trim().toLowerCase();
      return entries
          .where(
            (entry) =>
                entry.label.toLowerCase().contains(normalized) ||
                entry.code.toLowerCase().contains(normalized),
          )
          .toList();
    });
