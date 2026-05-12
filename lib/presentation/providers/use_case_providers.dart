import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/add_to_library_use_case.dart';
import '../../domain/usecases/enqueue_download_use_case.dart';
import '../../domain/usecases/get_chapter_list_use_case.dart';
import '../../domain/usecases/get_download_queue_use_case.dart';
import '../../domain/usecases/get_library_use_case.dart';
import '../../domain/usecases/get_pages_use_case.dart';
import '../../domain/usecases/get_reading_progress_use_case.dart';
import '../../domain/usecases/get_settings_use_case.dart';
import '../../domain/usecases/install_extension_use_case.dart';
import '../../domain/usecases/remove_from_library_use_case.dart';
import '../../domain/usecases/save_reading_progress_use_case.dart';
import '../../domain/usecases/search_manga_use_case.dart';
import '../../domain/usecases/sync_use_case.dart';
import '../../domain/usecases/uninstall_extension_use_case.dart';
import '../../domain/usecases/update_settings_use_case.dart';
import 'repository_providers.dart';

// ── Library ────────────────────────────────────────────────────────────────────

final getLibraryUseCaseProvider = Provider<GetLibraryUseCase>((ref) {
  return GetLibraryUseCase(ref.watch(mangaRepositoryProvider));
});

final addToLibraryUseCaseProvider = Provider<AddToLibraryUseCase>((ref) {
  return AddToLibraryUseCase(ref.watch(mangaRepositoryProvider));
});

final removeFromLibraryUseCaseProvider =
    Provider<RemoveFromLibraryUseCase>((ref) {
  return RemoveFromLibraryUseCase(ref.watch(mangaRepositoryProvider));
});

// ── Search ─────────────────────────────────────────────────────────────────────

final searchMangaUseCaseProvider = Provider<SearchMangaUseCase>((ref) {
  return SearchMangaUseCase(ref.watch(mangaRepositoryProvider));
});

// ── Chapters & pages ───────────────────────────────────────────────────────────

final getChapterListUseCaseProvider = Provider<GetChapterListUseCase>((ref) {
  return GetChapterListUseCase(ref.watch(mangaRepositoryProvider));
});

final getPagesUseCaseProvider = Provider<GetPagesUseCase>((ref) {
  return GetPagesUseCase(ref.watch(readerRepositoryProvider));
});

// ── Reading progress ───────────────────────────────────────────────────────────

final saveReadingProgressUseCaseProvider =
    Provider<SaveReadingProgressUseCase>((ref) {
  return SaveReadingProgressUseCase(ref.watch(readerRepositoryProvider));
});

final getReadingProgressUseCaseProvider =
    Provider<GetReadingProgressUseCase>((ref) {
  return GetReadingProgressUseCase(ref.watch(readerRepositoryProvider));
});

// ── Downloads ──────────────────────────────────────────────────────────────────

final enqueueDownloadUseCaseProvider = Provider<EnqueueDownloadUseCase>((ref) {
  return EnqueueDownloadUseCase(ref.watch(downloadRepositoryProvider));
});

final getDownloadQueueUseCaseProvider =
    Provider<GetDownloadQueueUseCase>((ref) {
  return GetDownloadQueueUseCase(ref.watch(downloadRepositoryProvider));
});

// ── Settings ───────────────────────────────────────────────────────────────────

final getSettingsUseCaseProvider = Provider<GetSettingsUseCase>((ref) {
  return GetSettingsUseCase(ref.watch(settingsRepositoryProvider));
});

final updateSettingsUseCaseProvider = Provider<UpdateSettingsUseCase>((ref) {
  return UpdateSettingsUseCase(ref.watch(settingsRepositoryProvider));
});

// ── Extensions ─────────────────────────────────────────────────────────────────

final installExtensionUseCaseProvider =
    Provider<InstallExtensionUseCase>((ref) {
  return InstallExtensionUseCase(ref.watch(extensionRepositoryProvider));
});

final uninstallExtensionUseCaseProvider =
    Provider<UninstallExtensionUseCase>((ref) {
  return UninstallExtensionUseCase(ref.watch(extensionRepositoryProvider));
});

// ── Sync ───────────────────────────────────────────────────────────────────────

final syncUseCaseProvider = Provider<SyncUseCase>((ref) {
  return SyncUseCase(ref.watch(syncRepositoryProvider));
});
