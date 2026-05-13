import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// MangaTable
// ---------------------------------------------------------------------------

/// Stores manga metadata (local cache from extension sources).
class MangaTable extends Table {
  @override
  String get tableName => 'manga';

  TextColumn get id => text()();
  TextColumn get sourceId => text().named('source_id')();
  TextColumn get title => text()();
  TextColumn get coverUrl => text().named('cover_url').nullable()();
  TextColumn get author => text().nullable()();
  TextColumn get artist => text().nullable()();
  TextColumn get description => text().nullable()();

  /// One of: ongoing | completed | hiatus | unknown
  TextColumn get status => text().nullable()();

  /// JSON-encoded list of genre strings.
  TextColumn get genres => text().nullable()();

  RealColumn get averageRating =>
      real().named('average_rating').nullable()();

  BoolColumn get isNsfw =>
      boolean().named('is_nsfw').withDefault(const Constant(false))();

  BoolColumn get inLibrary =>
      boolean().named('in_library').withDefault(const Constant(false))();

  /// Unix milliseconds.
  IntColumn get lastUpdated => integer().named('last_updated').nullable()();

  /// Unix milliseconds.
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// ChaptersTable
// ---------------------------------------------------------------------------

/// Stores chapter metadata for each manga.
class ChaptersTable extends Table {
  @override
  String get tableName => 'chapters';

  TextColumn get id => text()();
  TextColumn get mangaId =>
      text().named('manga_id').references(MangaTable, #id)();
  TextColumn get sourceId => text().named('source_id')();
  RealColumn get chapterNumber => real().named('chapter_number')();
  TextColumn get title => text().nullable()();

  /// Unix milliseconds.
  IntColumn get uploadDate => integer().named('upload_date').nullable()();
  IntColumn get pageCount => integer().named('page_count').nullable()();

  BoolColumn get isRead =>
      boolean().named('is_read').withDefault(const Constant(false))();

  BoolColumn get isDownloaded =>
      boolean().named('is_downloaded').withDefault(const Constant(false))();

  /// Unix milliseconds.
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// ReadingProgressTable
// ---------------------------------------------------------------------------

/// Tracks the user's reading position per manga (one row per manga).
class ReadingProgressTable extends Table {
  @override
  String get tableName => 'reading_progress';

  TextColumn get id => text()();
  TextColumn get mangaId =>
      text().named('manga_id').references(MangaTable, #id)();
  TextColumn get chapterId =>
      text().named('chapter_id').references(ChaptersTable, #id)();
  IntColumn get pageIndex =>
      integer().named('page_index').withDefault(const Constant(0))();

  /// Unix milliseconds.
  IntColumn get updatedAt => integer().named('updated_at')();

  /// Unix milliseconds; null until synced to remote.
  IntColumn get syncedAt => integer().named('synced_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// CollectionsTable
// ---------------------------------------------------------------------------

/// User-defined library collections (folders).
class CollectionsTable extends Table {
  @override
  String get tableName => 'collections';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  BoolColumn get isPrivate =>
      boolean().named('is_private').withDefault(const Constant(false))();

  /// Unix milliseconds.
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// CollectionMangaTable
// ---------------------------------------------------------------------------

/// Join table: many-to-many between collections and manga.
class CollectionMangaTable extends Table {
  @override
  String get tableName => 'collection_manga';

  TextColumn get collectionId =>
      text().named('collection_id').references(CollectionsTable, #id)();
  TextColumn get mangaId =>
      text().named('manga_id').references(MangaTable, #id)();

  @override
  Set<Column> get primaryKey => {collectionId, mangaId};
}

// ---------------------------------------------------------------------------
// TagsTable
// ---------------------------------------------------------------------------

/// User-defined tags with optional color.
class TagsTable extends Table {
  @override
  String get tableName => 'tags';

  TextColumn get id => text()();
  TextColumn get name => text().unique()();

  /// Hex color string, e.g. '#7C3AED'. Nullable.
  TextColumn get color => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// MangaTagsTable
// ---------------------------------------------------------------------------

/// Join table: many-to-many between manga and tags.
class MangaTagsTable extends Table {
  @override
  String get tableName => 'manga_tags';

  TextColumn get mangaId =>
      text().named('manga_id').references(MangaTable, #id)();
  TextColumn get tagId =>
      text().named('tag_id').references(TagsTable, #id)();

  @override
  Set<Column> get primaryKey => {mangaId, tagId};
}

// ---------------------------------------------------------------------------
// DownloadTasksTable
// ---------------------------------------------------------------------------

/// Persists the download queue across app restarts.
class DownloadTasksTable extends Table {
  @override
  String get tableName => 'download_tasks';

  TextColumn get id => text()();
  TextColumn get chapterId =>
      text().named('chapter_id').references(ChaptersTable, #id)();

  /// One of: original | high | medium | low
  TextColumn get quality => text()();

  /// One of: queued | downloading | paused | completed | failed
  TextColumn get status => text()();

  IntColumn get totalPages =>
      integer().named('total_pages').withDefault(const Constant(0))();
  IntColumn get downloadedPages =>
      integer().named('downloaded_pages').withDefault(const Constant(0))();

  /// Unix milliseconds.
  IntColumn get createdAt => integer().named('created_at')();

  /// Unix milliseconds; null until completed.
  IntColumn get completedAt => integer().named('completed_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// ExtensionsTable
// ---------------------------------------------------------------------------

/// Installed extension metadata and health tracking.
class ExtensionsTable extends Table {
  @override
  String get tableName => 'extensions';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get version => text()();
  TextColumn get sourceClass => text().named('source_class')();

  /// JSON-encoded list of allowed domain strings.
  TextColumn get allowedDomains => text().named('allowed_domains')();

  TextColumn get mirrorUrl => text().named('mirror_url').nullable()();

  BoolColumn get isNsfw =>
      boolean().named('is_nsfw').withDefault(const Constant(false))();

  /// One of: healthy | degraded | unavailable
  TextColumn get healthStatus =>
      text().named('health_status').withDefault(const Constant('healthy'))();

  TextColumn get sourceType => text().named('source_type')();
  TextColumn get language => text()();

  IntColumn get consecutiveFailures => integer()
      .named('consecutive_failures')
      .withDefault(const Constant(0))();

  /// Unix milliseconds.
  IntColumn get installedAt => integer().named('installed_at')();

  /// Unix milliseconds.
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// SyncQueueTable
// ---------------------------------------------------------------------------

/// Pending remote-sync operations (offline-first write buffer).
class SyncQueueTable extends Table {
  @override
  String get tableName => 'sync_queue';

  TextColumn get id => text()();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();

  /// One of: upsert | delete
  TextColumn get operation => text()();

  /// JSON-encoded payload.
  TextColumn get payload => text()();

  /// Unix milliseconds.
  IntColumn get createdAt => integer().named('created_at')();

  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// SearchHistoryTable
// ---------------------------------------------------------------------------

/// Recent search queries (capped at 20 by the DAO layer).
class SearchHistoryTable extends Table {
  @override
  String get tableName => 'search_history';

  TextColumn get id => text()();
  TextColumn get query => text()();

  /// Null for global searches.
  TextColumn get sourceId => text().named('source_id').nullable()();

  /// Unix milliseconds.
  IntColumn get searchedAt => integer().named('searched_at')();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// AppSettingsTable
// ---------------------------------------------------------------------------

/// Single-row settings table (id is always 1).
class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  /// Always 1 — enforced by the DAO.
  IntColumn get id =>
      integer().withDefault(const Constant(1))();

  TextColumn get theme =>
      text().withDefault(const Constant('amoled_dark'))();
  TextColumn get accentColor =>
      text().named('accent_color').withDefault(const Constant('#7C3AED'))();
  TextColumn get readingMode =>
      text().named('reading_mode').withDefault(const Constant('horizontal_rtl'))();
  TextColumn get readerTheme =>
      text().named('reader_theme').withDefault(const Constant('amoled'))();
  TextColumn get fontStyle =>
      text().named('font_style').withDefault(const Constant('inter'))();
  TextColumn get animationSpeed =>
      text().named('animation_speed').withDefault(const Constant('normal'))();

  BoolColumn get dataSaver =>
      boolean().named('data_saver').withDefault(const Constant(false))();
  BoolColumn get wifiOnlyDownload =>
      boolean().named('wifi_only_download').withDefault(const Constant(false))();
  BoolColumn get lowRamMode =>
      boolean().named('low_ram_mode').withDefault(const Constant(false))();
  BoolColumn get reducedMotion =>
      boolean().named('reduced_motion').withDefault(const Constant(false))();
  BoolColumn get highContrast =>
      boolean().named('high_contrast').withDefault(const Constant(false))();

  RealColumn get textScale =>
      real().named('text_scale').withDefault(const Constant(1.0))();
  IntColumn get maxCacheMb =>
      integer().named('max_cache_mb').withDefault(const Constant(2048))();

  BoolColumn get analyticsOptOut =>
      boolean().named('analytics_opt_out').withDefault(const Constant(false))();
  BoolColumn get notificationsNewChapter =>
      boolean().named('notifications_new_chapter').withDefault(const Constant(true))();
  BoolColumn get notificationsDownloads =>
      boolean().named('notifications_downloads').withDefault(const Constant(true))();
  BoolColumn get notificationsExtensions =>
      boolean().named('notifications_extensions').withDefault(const Constant(true))();
  BoolColumn get notificationsAppUpdates =>
      boolean().named('notifications_app_updates').withDefault(const Constant(true))();

  /// Unix milliseconds.
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
