import 'package:drift/drift.dart';

import '../../../features/dictionary/domain/entities/sign_entry.dart';
import '../../../features/dictionary/domain/repositories/sign_dictionary_repository.dart';
import '../app_database.dart';

class LocalSignDictionaryRepository implements SignDictionaryRepository {
  const LocalSignDictionaryRepository(this.database);

  final AppDatabase database;

  @override
  Future<List<SignEntry>> search(String query) async {
    final rows = await (database.select(
      database.signEntries,
    )..orderBy([(table) => OrderingTerm.asc(table.labelVi)])).get();
    final normalized = query.trim().toLowerCase();
    return rows
        .where(
          (row) =>
              normalized.isEmpty ||
              row.labelVi.toLowerCase().contains(normalized) ||
              row.code.toLowerCase().contains(normalized),
        )
        .map(_toEntity)
        .toList(growable: false);
  }

  @override
  Future<SignEntry?> findByCode(String code) async {
    final row = await (database.select(
      database.signEntries,
    )..where((table) => table.code.equals(code))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  /// Imports only a catalog whose provenance has been supplied and checked.
  Future<void> upsertVerifiedCatalog({
    required List<SignEntry> entries,
    required String catalogVersion,
    required String sourceUrl,
    required String licenseName,
    required DateTime updatedAt,
  }) async {
    if (catalogVersion.trim().isEmpty ||
        sourceUrl.trim().isEmpty ||
        licenseName.trim().isEmpty) {
      throw ArgumentError('Catalog version, source, and license are required');
    }
    final codes = <String>{};
    for (final entry in entries) {
      if (entry.code.trim().isEmpty ||
          entry.label.trim().isEmpty ||
          !codes.add(entry.code)) {
        throw ArgumentError('Catalog entries need unique codes and labels');
      }
    }

    await database.transaction(() async {
      for (final entry in entries) {
        await database
            .into(database.signEntries)
            .insertOnConflictUpdate(
              SignEntriesCompanion.insert(
                code: entry.code,
                labelVi: entry.label,
                description: Value(entry.description),
                catalogVersion: catalogVersion,
                sourceUrl: sourceUrl,
                licenseName: licenseName,
                updatedAtUtcMs: updatedAt.toUtc().millisecondsSinceEpoch,
              ),
            );
      }
    });
  }

  SignEntry _toEntity(SignEntryRow row) => SignEntry(
    code: row.code,
    label: row.labelVi,
    description: row.description,
  );
}
