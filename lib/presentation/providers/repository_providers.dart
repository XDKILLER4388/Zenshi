import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

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
import '../../data/repositories/extension_repository_impl.dart';

import '../../data/remote/mangadex_service.dart';
import '../../data/remote/manhwaz_service.dart';
import '../../data/remote/manhwa18_service.dart';
import '../../data/remote/bato_service.dart';
import '../../data/remote/manganato_service.dart';
import '../../data/remote/asura_service.dart';
import '../../data/remote/reaper_service.dart';
import '../../data/remote/flame_service.dart';
import '../../data/remote/mangazone_service.dart';
import '../../data/remote/mangafire_service.dart';
import '../../data/remote/comix_service.dart';
import '../../data/local/daos/manga_dao.dart';
import '../../data/local/daos/chapter_dao.dart';
import '../../data/local/database/app_database.dart';
import '../../infrastructure/download_manager/download_manager_service.dart';
import '../../data/local/daos/download_dao.dart';

// ── Auth ───────────────────────────────────────────────────────────────────────

/// Stub auth repository — Supabase not initialized in this build.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return _StubAuthRepository();
});

// ── Database ──────────────────────────────────────────────────────────────────

/// Provider for the single [AppDatabase] instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// ── Manga ──────────────────────────────────────────────────────────────────────

/// Concrete [MangaRepository] using multiple sources.
final mangaRepositoryProvider = Provider<MangaRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return _MultiSourceRepository(db.mangaDao);
});

class _MultiSourceRepository implements MangaRepository {
  final MangaDao _mangaDao;

  _MultiSourceRepository(this._mangaDao);

  @override
  Stream<List<Manga>> watchLibrary() {
    return _mangaDao.watchLibrary().map(
      (list) => list
          .map(
            (data) => Manga(
              id: data.id,
              sourceId: data.sourceId,
              title: data.title,
              coverUrl: data.coverUrl,
              author: data.author,
              artist: data.artist,
              description: data.description,
              status: _parseMangaStatus(data.status),
              genres: data.genres?.split(',') ?? [],
              averageRating: data.averageRating,
              isNsfw: data.isNsfw,
              inLibrary: data.inLibrary,
              lastUpdated: data.lastUpdated != null
                  ? DateTime.fromMillisecondsSinceEpoch(data.lastUpdated!)
                  : null,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<Manga?> getMangaById(String id, String sourceId) async {
    // Check local database first
    final local = await _mangaDao.getMangaById(id);
    if (local != null) {
      return Manga(
        id: local.id,
        sourceId: local.sourceId,
        title: local.title,
        coverUrl: local.coverUrl,
        author: local.author,
        artist: local.artist,
        description: local.description,
        status: _parseMangaStatus(local.status),
        genres: local.genres?.split(',') ?? [],
        averageRating: local.averageRating,
        isNsfw: local.isNsfw,
        inLibrary: local.inLibrary,
        lastUpdated: local.lastUpdated != null
            ? DateTime.fromMillisecondsSinceEpoch(local.lastUpdated!)
            : null,
      );
    }

    return switch (sourceId) {
      'bato' => BatoService.fetchMangaById(id),
      'manganato' => ManganatoService.fetchMangaById(id),
      'asura' => AsuraService.fetchMangaById(id),
      'mangazone' => MangaZoneService.fetchMangaById(id),
      'reaper' => ReaperService.fetchMangaById(id),
      'flame' => FlameService.fetchMangaById(id),
      'manhwaz' => ManhwazService.fetchMangaById(id),
      'manhwa18' => Manhwa18Service.fetchMangaById(id),
      'mangafire' => MangaFireService.fetchDetails(id),
      'comix' => ComixService.fetchMangaById(id),
      _ => MangaDexService.fetchMangaById(id),
    };
  }

  @override
  Future<List<Manga>> searchManga(SearchQuery query) async {
    final title = query.query;
    if (title.isEmpty) return [];

    // Search all sources in parallel for maximum coverage
    final results = await Future.wait([
      MangaDexService.search(title),
      ManhwazService.search(title),
      Manhwa18Service.search(title),
      BatoService.search(title),
      ManganatoService.search(title),
      MangaZoneService.search(title),
      AsuraService.search(title),
      ReaperService.search(title),
      FlameService.search(title),
      MangaFireService.search(title),
      ComixService.search(title),
    ]);

    return results.expand((x) => x).toList();
  }

  @override
  Future<void> addToLibrary(Manga manga) async {
    await _mangaDao.upsertManga(
      MangaTableCompanion.insert(
        id: manga.id,
        sourceId: manga.sourceId,
        title: manga.title,
        coverUrl: Value(manga.coverUrl),
        author: Value(manga.author),
        artist: Value(manga.artist),
        description: Value(manga.description),
        status: Value(manga.status.name),
        genres: Value(manga.genres.join(',')),
        averageRating: Value(manga.averageRating),
        isNsfw: Value(manga.isNsfw),
        inLibrary: const Value(true),
        lastUpdated: Value(manga.lastUpdated?.millisecondsSinceEpoch),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> removeFromLibrary(String mangaId) async {
    final manga = await _mangaDao.getMangaById(mangaId);
    if (manga != null) {
      await _mangaDao.upsertManga(
        MangaTableCompanion(id: Value(manga.id), inLibrary: const Value(false)),
      );
    }
  }

  @override
  Future<List<Chapter>> getChapterList(String mangaId, String sourceId) async {
    final chapters = await switch (sourceId) {
      'manhwaz' => ManhwazService.fetchChapterList(mangaId),
      'manhwa18' => Manhwa18Service.fetchChapterList(mangaId),
      'bato' => BatoService.fetchChapterList(mangaId),
      'manganato' => ManganatoService.fetchChapterList(mangaId),
      'mangazone' => MangaZoneService.fetchChapterList(mangaId),
      'asura' => AsuraService.fetchChapterList(mangaId),
      'reaper' => ReaperService.fetchChapterList(mangaId),
      'flame' => FlameService.fetchChapterList(mangaId),
      'mangafire' => MangaFireService.fetchChapters(mangaId),
      'comix' => ComixService.fetchChapterList(mangaId),
      _ => MangaDexService.fetchChapterList(mangaId),
    };

    // If no chapters found and it's not MangaDex, try MangaDex as a fallback
    if (chapters.isEmpty && sourceId != 'mangadex') {
      // We'd need to search for the title on MangaDex first, but for now let's just return empty
      return [];
    }

    return chapters;
  }

  @override
  Future<List<Page>> getPages(Chapter chapter) async {
    return switch (chapter.sourceId) {
      'manhwaz' => ManhwazService.fetchPages(chapter.id),
      'manhwa18' => Manhwa18Service.fetchPages(chapter.id),
      'bato' => BatoService.fetchPages(chapter.id),
      'manganato' => ManganatoService.fetchPages(chapter.id),
      'mangazone' => MangaZoneService.fetchPages(chapter.id),
      'asura' => AsuraService.fetchPages(chapter.id),
      'reaper' => ReaperService.fetchPages(chapter.id),
      'flame' => FlameService.fetchPages(chapter.id),
      'mangafire' => MangaFireService.fetchPages(chapter.id),
      'comix' => ComixService.fetchPages(chapter.id),
      _ => MangaDexService.fetchPages(chapter.id),
    };
  }

  MangaStatus _parseMangaStatus(String? status) {
    return MangaStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => MangaStatus.unknown,
    );
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
    return switch (chapter.sourceId) {
      'manhwaz' => ManhwazService.fetchPages(chapter.id),
      'manhwa18' => Manhwa18Service.fetchPages(chapter.id),
      'bato' => BatoService.fetchPages(chapter.id),
      'manganato' => ManganatoService.fetchPages(chapter.id),
      'asura' => AsuraService.fetchPages(chapter.id),
      'reaper' => ReaperService.fetchPages(chapter.id),
      'flame' => FlameService.fetchPages(chapter.id),
      'mangafire' => MangaFireService.fetchPages(chapter.id),
      'comix' => ComixService.fetchPages(chapter.id),
      _ => MangaDexService.fetchPages(chapter.id),
    };
  }

  @override
  Future<void> saveReadingProgress(ReadingProgress progress) async {}

  @override
  Stream<ReadingProgress?> watchProgress(String mangaId) => Stream.value(null);

  @override
  Future<ReadingProgress?> getProgress(String mangaId) async => null;
}

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

/// Concrete [ExtensionRepository] using local database.
final extensionRepositoryProvider = Provider<ExtensionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExtensionRepositoryImpl(db.extensionDao);
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
  Stream<AuthState> watchAuthState() =>
      Stream.value(const AuthState(status: AuthStatus.guest));
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
  Future<void> removeFromLibrary(String mangaId) => throw UnimplementedError();

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
  Stream<List<DownloadTask>> watchDownloadQueue() => throw UnimplementedError();

  @override
  Future<void> enqueueDownload(
    Chapter chapter,
    String mangaTitle,
    ImageQuality quality,
  ) => throw UnimplementedError();

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
