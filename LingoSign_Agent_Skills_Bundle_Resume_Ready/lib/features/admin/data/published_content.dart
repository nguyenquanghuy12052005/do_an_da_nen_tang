import 'dart:convert';

import '../../../data/local/app_database.dart';
import '../../dictionary/domain/entities/sign_entry.dart';

typedef ContentItem = Map<String, dynamic>;

class PublishedContent {
  const PublishedContent(this.database);
  final AppDatabase database;

  Future<List<ContentItem>> read(String kind) async {
    final row = await (database.select(
      database.appSettings,
    )..where((t) => t.key.equals('published_$kind'))).getSingleOrNull();
    final local = await (database.select(
      database.appSettings,
    )..where((t) => t.key.equals('local_published_$kind'))).getSingleOrNull();
    final combined = <String, ContentItem>{};
    for (final source in [row, local]) {
      if (source == null) continue;
      for (final item
          in (jsonDecode(source.valueJson) as List).cast<ContentItem>()) {
        combined[item['id'] as String] = item;
      }
    }
    return combined.values.toList();
  }

  Future<void> replace(String kind, List<ContentItem> items) async {
    await database
        .into(database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: 'published_$kind',
            valueJson: jsonEncode(items),
            updatedAtUtcMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<List<SignEntry>> overlay(List<SignEntry> bundled) async {
    final entries = {for (final entry in bundled) entry.code: entry};
    final categories = {
      for (final item in await read('categories'))
        if (item['state'] == 'published') item['id']: item['label'] as String,
    };
    for (final item in await read('signs')) {
      final code = item['id'] as String;
      if (item['state'] == 'hidden') {
        entries.remove(code);
        continue;
      }
      if (item['state'] != 'published') continue;
      String? field(String key) {
        final value = item[key] as String?;
        return value == '' ? null : value;
      }

      entries[code] = SignEntry(
        code: code,
        label: item['label'] as String,
        description: field('description'),
        category: categories[item['categoryId']] ?? field('category') ?? 'Khác',
        signSystem: field('signSystem') ?? '',
        instructions: field('instructions') ?? '',
        imageAsset: field('imageAsset'),
        videoAsset: field('videoAsset'),
        modelLabel: field('modelLabel'),
        sourceUrl: field('sourceUrl') ?? '',
        licenseName: field('licenseName') ?? '',
      );
    }
    return entries.values.toList()..sort((a, b) => a.label.compareTo(b.label));
  }
}
