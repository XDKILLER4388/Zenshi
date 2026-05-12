import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/extension_info.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/page.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/repositories/extension_repository.dart';
import '../../domain/repositories/manga_repository.dart';
import '../../domain/repositories/reader_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../infrastructure/auth/secure_storage_service.dart';

// ── Auth ───────────────────────────────────────────────────────────────────────

/// Provides the [AuthRepository] implementation.
///
/// Wired to [AuthRepositoryImpl] backed by Supabase Auth and
/// [SecureStorageService]. Real Supabase initialisation happens in main.dart;
/// this provider assumes [Supabase.instance] is available.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    supabase: Supabase.instance.client,
    storage: SecureStorageService(),
  );
});

// ── Manga ──────────────────────────────────────────────────────────────────────

/// Stub [MangaRepository] — real implementation added in a later task.
final mangaRepositoryProvider = Provider<MangaRepository>((ref) {
  return _StubMangaRepository();
});

// ── Reader ─────────────────────────────────────────────────────────────────────

/// Stub [ReaderRepository] — real implementation added in a later task.
final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  return _StubReaderRepository();
});

// ── Download ───────────────────────────────────────────────────────────────────

/// Stub [DownloadRepository] — real implementation added in a later task.
final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return _StubDownloadRepository();
});

// ── Sync ───────────────────────────────────────────────────────────────────────

/// Stub [SyncRepository] — real implementation added in a later task.
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return _StubSyncRepository();
});

// ── Extension ──────────────────────────────────────────────────────────────────

/// Stub [ExtensionRepository] — real implementation added in a later task.
final extensionRepositoryProvider = Provider<ExtensionRepository>((ref) {
  return _StubExtensionRepository();
});

// ── Settings ───────────────────────────────────────────────────────────────────

/// Stub [SettingsRepository] — real implementation added in a later task.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return _StubSettingsRepository();
});

// ── Stub implementations ───────────────────────────────────────────────────────
// These throw [UnimplementedError] for all methods. They exist so that the
// provider layer compiles and can be wired up before the concrete data-layer
// implementations are complete.

class _StubMangaRepository implements MangaRepository {
  @override
  Stream<List<Manga>> watchLibrary() => throw UnimplementedError();

  @override
  Future<Manga?> getMangaById(String id, String sourceId) =>
      throw UnimplementedError();

  @override
  Future<List<Manga>> searchManga(SearchQuery query) =>
      throw UnimplementedError();

  @override
  Future<void> addToLibrary(Manga manga) => throw UnimplementedError();

  @override
  Future<void> removeFromLibrary(String mangaId) =>
      throw UnimplementedError();

  @override
  Future<List<Chapter>> getChapterList(String mangaId, String sourceId) =>
      throw UnimplementedError();

  @override
  Future<List<Page>> getPages(Chapter chapter) => throw UnimplementedError();
}

class _StubReaderRepository implements ReaderRepository {
  @override
  Future<List<Page>> getPages(Chapter chapter) => throw UnimplementedError();

  @override
  Future<void> saveReadingProgress(ReadingProgress progress) =>
      throw UnimplementedError();

  @override
  Stream<ReadingProgress?> watchProgress(String mangaId) =>
      throw UnimplementedError();

  @override
  Future<ReadingProgress?> getProgress(String mangaId) =>
      throw UnimplementedError();
}

class _StubDownloadRepository implements DownloadRepository {
  @override
  Stream<List<DownloadTask>> watchDownloadQueue() =>
      throw UnimplementedError();

  @override
  Future<void> enqueueDownload(
    Chapter chapter,
    String mangaTitle,
    ImageQuality quality,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> pauseDownload(String taskId) => throw UnimplementedError();

  @override
  Future<void> resumeDownload(String taskId) => throw UnimplementedError();

  @override
  Future<void> deleteDownload(String taskId) => throw UnimplementedError();

  @override
  Future<int> getTotalDownloadSizeBytes() => throw UnimplementedError();
}

class _StubSyncRepository implements SyncRepository {
  @override
  Future<void> pushChanges(List<SyncRecord> records) =>
      throw UnimplementedError();

  @override
  Future<List<SyncRecord>> pullChanges(DateTime since) =>
      throw UnimplementedError();

  @override
  Stream<SyncStatus> watchSyncStatus() => throw UnimplementedError();

  @override
  Future<void> fullSync() => throw UnimplementedError();

  @override
  DateTime? get lastSyncedAt => null;
}

class _StubExtensionRepository implements ExtensionRepository {
  @override
  Future<List<ExtensionInfo>> fetchMarketplaceListing() =>
      throw UnimplementedError();

  @override
  Future<void> installExtension(String extensionId) =>
      throw UnimplementedError();

  @override
  Future<void> uninstallExtension(String extensionId) =>
      throw UnimplementedError();

  @override
  Future<void> updateExtension(String extensionId) =>
      throw UnimplementedError();

  @override
  Stream<List<ExtensionInfo>> watchInstalledExtensions() =>
      throw UnimplementedError();

  @override
  Future<void> checkForUpdates() => throw UnimplementedError();
}

class _StubSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> getSettings() => throw UnimplementedError();

  @override
  Future<void> updateSettings(AppSettings settings) =>
      throw UnimplementedError();

  @override
  Stream<AppSettings> watchSettings() => throw UnimplementedError();

  @override
  Future<String> exportSettingsJson() => throw UnimplementedError();

  @override
  Future<void> importSettingsJson(String json) => throw UnimplementedError();
}
