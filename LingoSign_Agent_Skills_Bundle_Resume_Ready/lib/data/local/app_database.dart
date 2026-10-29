import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('SignEntryRow')
class SignEntries extends Table {
  TextColumn get code => text()();
  TextColumn get labelVi => text()();
  TextColumn get description => text().nullable()();
  TextColumn get mediaLocalPath => text().nullable()();
  TextColumn get catalogVersion => text()();
  TextColumn get sourceUrl => text()();
  TextColumn get licenseName => text()();
  IntColumn get updatedAtUtcMs => integer()();

  @override
  Set<Column> get primaryKey => {code};

  @override
  bool get isStrict => true;
}

@DataClassName('RecognitionHistoryRow')
class RecognitionHistoryRows extends Table {
  TextColumn get id => text()();
  TextColumn get signCode => text()();
  TextColumn get labelSnapshot => text()();
  IntColumn get confirmedAtUtcMs => integer()();
  IntColumn get deletedAtUtcMs => integer().nullable()();
  TextColumn get imageRelativePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  bool get isStrict => true;
}

@DataClassName('PendingSyncOpRow')
class PendingSyncOps extends Table {
  TextColumn get opId => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  IntColumn get createdAtUtcMs => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {opId};

  @override
  bool get isStrict => true;
}

@DataClassName('SyncStateRow')
class SyncStates extends Table {
  TextColumn get collection => text()();
  TextColumn get lastCursor => text().nullable()();
  IntColumn get lastSuccessAtUtcMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {collection};

  @override
  bool get isStrict => true;
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get valueJson => text()();
  IntColumn get updatedAtUtcMs => integer()();

  @override
  Set<Column> get primaryKey => {key};

  @override
  bool get isStrict => true;
}

@DriftDatabase(
  tables: [
    SignEntries,
    RecognitionHistoryRows,
    PendingSyncOps,
    SyncStates,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'lingosign'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.alterTable(
          TableMigration(
            recognitionHistoryRows,
            newColumns: [recognitionHistoryRows.imageRelativePath],
          ),
        );
      } else if (from < 3) {
        await migrator.addColumn(
          recognitionHistoryRows,
          recognitionHistoryRows.imageRelativePath,
        );
      }
      await customStatement(
        'CREATE INDEX IF NOT EXISTS history_page_idx ON recognition_history_rows (confirmed_at_utc_ms DESC, id DESC) WHERE deleted_at_utc_ms IS NULL',
      );
    },
    beforeOpen: (details) async {
      await customStatement(
        'CREATE INDEX IF NOT EXISTS history_page_idx ON recognition_history_rows (confirmed_at_utc_ms DESC, id DESC) WHERE deleted_at_utc_ms IS NULL',
      );
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = FULL');
      await customStatement('PRAGMA busy_timeout = 5000');
    },
  );
}
