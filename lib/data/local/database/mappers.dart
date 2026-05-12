/// Extension methods that convert Drift-generated data classes to and from
/// [Map<String, dynamic>] representations.
///
/// These maps are used by repository implementations as a lightweight
/// serialisation layer. Full domain-entity mapping is handled in Task 3.
library;

import 'app_database.dart';

// ---------------------------------------------------------------------------
// MangaTableData
// ---------------------------------------------------------------------------

extension MangaTableDataMapper on MangaTableData {
  Map<String, dynamic> toMap() => {
        'id': id,
        'source_id': sourceId,
        'title': title,
        'cover_url': coverUrl,
        'author': author,
        'artist': artist,
        'description': description,
        'status': status,
        'genres': genres,
        'average_rating': averageRating,
        'is_nsfw': isNsfw,
        'in_library': inLibrary,
        'last_updated': lastUpdated,
        'created_at': createdAt,
      };
}

extension MangaTableDataFromMap on MangaTableCompanion {
  static MangaTableCompanion fromMap(Map<String, dynamic> map) {
    return MangaTableCompanion.insert(
      id: map['id'] as String,
      sourceId: map['source_id'] as String,
      title: map['title'] as String,
      createdAt: map['created_at'] as int,
    );
  }
}

// ---------------------------------------------------------------------------
// ChaptersTableData
// ---------------------------------------------------------------------------

extension ChaptersTableDataMapper on ChaptersTableData {
  Map<String, dynamic> toMap() => {
        'id': id,
        'manga_id': mangaId,
        'source_id': sourceId,
        'chapter_number': chapterNumber,
        'title': title,
        'upload_date': uploadDate,
        'page_count': pageCount,
        'is_read': isRead,
        'is_downloaded': isDownloaded,
        'created_at': createdAt,
      };
}

// ---------------------------------------------------------------------------
// ReadingProgressTableData
// ---------------------------------------------------------------------------

extension ReadingProgressTableDataMapper on ReadingProgressTableData {
  Map<String, dynamic> toMap() => {
        'id': id,
        'manga_id': mangaId,
        'chapter_id': chapterId,
        'page_index': pageIndex,
        'updated_at': updatedAt,
        'synced_at': syncedAt,
      };
}

// ---------------------------------------------------------------------------
// CollectionsTableData
// ---------------------------------------------------------------------------

extension CollectionsTableDataMapper on CollectionsTableData {
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'sort_order': sortOrder,
        'is_private': isPrivate,
        'created_at': createdAt,
      };
}

// ---------------------------------------------------------------------------
// TagsTableData
// ---------------------------------------------------------------------------

extension TagsTableDataMapper on TagsTableData {
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
      };
}

// ---------------------------------------------------------------------------
// DownloadTasksTableData
// ---------------------------------------------------------------------------

extension DownloadTasksTableDataMapper on DownloadTasksTableData {
  Map<String, dynamic> toMap() => {
        'id': id,
        'chapter_id': chapterId,
        'quality': quality,
        'status': status,
        'total_pages': totalPages,
        'downloaded_pages': downloadedPages,
        'created_at': createdAt,
        'completed_at': completedAt,
      };
}

// ---------------------------------------------------------------------------
// ExtensionsTableData
// ---------------------------------------------------------------------------

extension ExtensionsTableDataMapper on ExtensionsTableData {
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'version': version,
        'source_class': sourceClass,
        'allowed_domains': allowedDomains,
        'mirror_url': mirrorUrl,
        'is_nsfw': isNsfw,
        'health_status': healthStatus,
        'consecutive_failures': consecutiveFailures,
        'installed_at': installedAt,
        'updated_at': updatedAt,
      };
}

// ---------------------------------------------------------------------------
// SyncQueueTableData
// ---------------------------------------------------------------------------

extension SyncQueueTableDataMapper on SyncQueueTableData {
  Map<String, dynamic> toMap() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'payload': payload,
        'created_at': createdAt,
        'retry_count': retryCount,
      };
}

// ---------------------------------------------------------------------------
// SearchHistoryTableData
// ---------------------------------------------------------------------------

extension SearchHistoryTableDataMapper on SearchHistoryTableData {
  Map<String, dynamic> toMap() => {
        'id': id,
        'query': query,
        'source_id': sourceId,
        'searched_at': searchedAt,
      };
}

// ---------------------------------------------------------------------------
// AppSettingsTableData
// ---------------------------------------------------------------------------

extension AppSettingsTableDataMapper on AppSettingsTableData {
  Map<String, dynamic> toMap() => {
        'id': id,
        'theme': theme,
        'accent_color': accentColor,
        'reading_mode': readingMode,
        'reader_theme': readerTheme,
        'font_style': fontStyle,
        'animation_speed': animationSpeed,
        'data_saver': dataSaver,
        'wifi_only_download': wifiOnlyDownload,
        'low_ram_mode': lowRamMode,
        'reduced_motion': reducedMotion,
        'high_contrast': highContrast,
        'text_scale': textScale,
        'max_cache_mb': maxCacheMb,
        'analytics_opt_out': analyticsOptOut,
        'notifications_new_chapter': notificationsNewChapter,
        'notifications_downloads': notificationsDownloads,
        'notifications_extensions': notificationsExtensions,
        'notifications_app_updates': notificationsAppUpdates,
        'updated_at': updatedAt,
      };
}
