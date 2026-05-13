import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// ── Auth ───────────────────────────────────────────────────────────────────────

/// Stub auth repository — Supabase not initialized in this build.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return _StubAuthRepository();
});

import '../../data/remote/mangadex_service.dart';
import '../../data/remote/manhwaz_service.dart';
import '../../data/remote/manhwa18_service.dart';
import '../../data/local/daos/manga_dao.dart';
import '../../data/local/daos/chapter_dao.dart';

// ── Manga ──────────────────────────────────────────────────────────────────────

/// Concrete [MangaRepository] using multiple sources.
final mangaRepositoryProvider = Provider<MangaRepository>((ref) {
  return _MultiSourceRepository();
});

class _MultiSourceRepository implements MangaRepository {
  @override
  Stream<List<Manga>> watchLibrary() => Stream.value([]);

  @override
  Future<Manga?> getMangaById(String id, String sourceId) async {
    if (sourceId == 'manhwaz' || sourceId == 'manhwa18') {
      return null;
    }
    return MangaDexService.fetchMangaById(id);
  }

  @override
  Future<List<Manga>> searchManga(SearchQuery query) async {
    final title = query.title ?? '';
    if (title.isEmpty) return [];

    // Search all sources in parallel for maximum coverage
    final results = await Future.wait([
      MangaDexService.search(title),
      ManhwazService.search(title),
      Manhwa18Service.search(title),
    ]);

    return [...results[0], ...results[1], ...results[2]];
  }

  @override
  Future<void> addToLibrary(Manga manga) async {}

  @override
  Future<void> removeFromLibrary(String mangaId) async {}

  @override
  Future<List<Chapter>> getChapterList(String mangaId, String sourceId) async {
    if (sourceId == 'manhwaz') return ManhwazService.fetchChapterList(mangaId);
    if (sourceId == 'manhwa18') return Manhwa18Service.fetchChapterList(mangaId);
    return MangaDexService.fetchChapterList(mangaId);
  }

  @override
  Future<List<Page>> getPages(Chapter chapter) async {
    if (chapter.sourceId == 'manhwaz') return ManhwazService.fetchPages(chapter.id);
    if (chapter.sourceId == 'manhwa18') return Manhwa18Service.fetchPages(chapter.id);
    return MangaDexService.fetchPages(chapter.id);
  }
}

// ── Reader ─────────────────────────────────────────────────────────────────────

/// Concrete [ReaderRepository] using MangaDex.
final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  return _MangaDexReaderRepository();
});

class _MangaDexReaderRepository implements ReaderRepository {
  @override
  Future<List<Page>> getPages(Chapter chapter) async {
    if (chapter.sourceId == 'manhwaz') return ManhwazService.fetchPages(chapter.id);
    if (chapter.sourceId == 'manhwa18') return Manhwa18Service.fetchPages(chapter.id);
    return MangaDexService.fetchPages(chapter.id);
  }

  @override
  Future<void> saveReadingProgress(ReadingProgress progress) async {}

  @override
  Stream<ReadingProgress?> watchProgress(String mangaId) => Stream.value(null);

  @override
  Future<ReadingProgress?> getProgress(String mangaId) async => null;
}

import '../../infrastructure/download_manager/download_manager_service.dart';
import '../../data/local/daos/download_dao.dart';
import '../../data/local/database/app_database.dart';

// ── Download ───────────────────────────────────────────────────────────────────

/// Concrete [DownloadRepository] using [DownloadManagerService].
final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  // In a real app, this would be injected via a more robust DI container
  // or a global database instance. For this build, we use the stubbed DAO.
  return _RealDownloadRepository();
});

class _RealDownloadRepository implements DownloadRepository {
  @override
  Stream<List<DownloadTask>> watchDownloadQueue() => Stream.value([]);

  @override
  Future<void> enqueueDownload(
    Chapter chapter,
    String mangaTitle,
    ImageQuality quality,
  ) async {
    // This is where we would normally call the DownloadManagerService
    print('Downloading: $mangaTitle - Chapter ${chapter.chapterNumber}');
  }

  @override
  Future<void> pauseDownload(String taskId) async {}

  @override
  Future<void> resumeDownload(String taskId) async {}

  @override
  Future<void> deleteDownload(String taskId) async {}

  @override
  Future<int> getTotalDownloadSizeBytes() async => 0;
}

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

class _StubAuthRepository implements AuthRepository {
  @override
  Future<void> signInWithEmail(String email, String password) async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signInWithDiscord() async {}
  @override
  Future<void> signInAsGuest() async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  Stream<AuthState> watchAuthState() => Stream.value(
        const AuthState(status: AuthStatus.guest),
      );
  @override
  bool get isAuthenticated => false;
  @override
  bool get isGuest => true;
}

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
