import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../daos/chapter_dao.dart';
import '../daos/download_dao.dart';
import '../daos/extension_dao.dart';
import '../daos/library_dao.dart';
import '../daos/manga_dao.dart';
import '../daos/reading_progress_dao.dart';
import '../daos/search_history_dao.dart';
import '../daos/settings_dao.dart';
import '../daos/sync_queue_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The single Drift database instance for Zenshi.
///
/// All local persistence goes through this class. Obtain it via the
/// Riverpod provider defined in the infrastructure layer.
@DriftDatabase(
  tables: [
    MangaTable,
    ChaptersTable,
    ReadingProgressTable,
    CollectionsTable,
    CollectionMangaTable,
    TagsTable,
    MangaTagsTable,
    DownloadTasksTable,
    ExtensionsTable,
    SyncQueueTable,
    SearchHistoryTable,
    AppSettingsTable,
  ],
  daos: [
    MangaDao,
    ChapterDao,
    ReadingProgressDao,
    LibraryDao,
    DownloadDao,
    ExtensionDao,
    SyncQueueDao,
    SettingsDao,
    SearchHistoryDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  /// Constructor for testing — accepts an in-memory executor.
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  // ---------------------------------------------------------------------------
  // Sub-task 2.3 — Migration strategy
  // ---------------------------------------------------------------------------

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      // Called once when the database is first created.
      onCreate: (Migrator m) async {
        await m.createAll();
      },

      // Called when schemaVersion increases. Empty for v1.
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations will be added here as schemaVersion increases.
        // Example:
        //   if (from < 2) { await m.addColumn(mangaTable, mangaTable.newColumn); }
      },

      // Runs before the database is opened (every launch).
      beforeOpen: (OpeningDetails details) async {
        // Enable foreign key enforcement — SQLite disables it by default.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DAO lazy getters
  // ---------------------------------------------------------------------------

  late final MangaDao mangaDao = MangaDao(this);
  late final ChapterDao chapterDao = ChapterDao(this);
  late final ReadingProgressDao readingProgressDao = ReadingProgressDao(this);
  late final LibraryDao libraryDao = LibraryDao(this);
  late final DownloadDao downloadDao = DownloadDao(this);
  late final ExtensionDao extensionDao = ExtensionDao(this);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this);
  late final SettingsDao settingsDao = SettingsDao(this);
  late final SearchHistoryDao searchHistoryDao = SearchHistoryDao(this);
}

/// Opens the SQLite database file using drift_flutter's default path.
QueryExecutor _openConnection() {
  return driftDatabase(name: 'zenshi_db');
}
