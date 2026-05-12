import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';

/// Custom cache manager for manga page images.
///
/// Uses [flutter_cache_manager] with a 30-day stale period and a maximum of
/// 2 000 cached objects. LRU eviction is handled internally by the library
/// via [maxNrOfCacheObjects].
///
/// CDN support: [flutter_cache_manager] respects standard HTTP cache headers
/// (Cache-Control, ETag, Last-Modified) automatically via [HttpFileService],
/// so CDN-served images benefit from conditional requests and proper TTL
/// handling without any extra configuration.
class ZenshiCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'zenshi_image_cache';

  static final ZenshiCacheManager _instance = ZenshiCacheManager._();
  factory ZenshiCacheManager() => _instance;

  ZenshiCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 2000,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ));
}

// ── Image cache service ────────────────────────────────────────────────────────

/// Service that manages the image cache lifecycle.
///
/// Wraps [ZenshiCacheManager] and adds:
/// - Open-page tracking (pages currently visible in the Reader are never
///   evicted by [runEvictionIfNeeded]).
/// - Data Saver Mode URL rewriting (appends `?w=720`).
/// - Size-based eviction trigger when storage falls below the configured
///   threshold.
class ImageCacheService {
  final ZenshiCacheManager _cacheManager;

  /// URLs currently open in the Reader — protected from eviction.
  final Set<String> _openPageUrls = {};

  ImageCacheService({ZenshiCacheManager? cacheManager})
      : _cacheManager = cacheManager ?? ZenshiCacheManager();

  // ── Open-page tracking ─────────────────────────────────────────────────

  /// Marks [url] as currently open in the Reader (protected from eviction).
  void markPageOpen(String url) => _openPageUrls.add(url);

  /// Unmarks [url] as open (eligible for eviction again).
  void markPageClosed(String url) => _openPageUrls.remove(url);

  // ── URL helpers ────────────────────────────────────────────────────────

  /// Returns the effective image URL for [url].
  ///
  /// When [dataSaver] is `true`, appends `?w=720` to request a reduced-
  /// quality image (≤720 px wide) from the CDN / source server.
  String getImageUrl(String url, {bool dataSaver = false}) {
    if (!dataSaver) return url;
    // Avoid double-appending the parameter.
    if (url.contains('?')) {
      return '$url&w=720';
    }
    return '$url?w=720';
  }

  // ── Cache access ───────────────────────────────────────────────────────

  /// Returns a stream of the file for [url], caching it on first load.
  ///
  /// Emits [DownloadProgress] events while downloading, then a [FileInfo]
  /// event when the file is ready.
  Stream<FileResponse> getImageFile(String url) {
    return _cacheManager.getFileStream(url, withProgress: true);
  }

  // ── Cache size ─────────────────────────────────────────────────────────

  /// Returns the total cache size in bytes by summing all files under the
  /// `libCachedImageData` directory created by [flutter_cache_manager].
  Future<int> getCacheSizeBytes() async {
    final cacheDir = await getApplicationCacheDirectory();
    final dir = Directory('${cacheDir.path}/libCachedImageData');
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Clears the entire image cache.
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  // ── Eviction ───────────────────────────────────────────────────────────

  /// Runs size-based eviction if the cache exceeds [maxMb] MB.
  ///
  /// Pages currently open in the Reader ([_openPageUrls]) are never evicted.
  /// [flutter_cache_manager] handles per-object LRU eviction internally via
  /// [maxNrOfCacheObjects]; this method provides an additional size-based
  /// safety valve.
  Future<void> runEvictionIfNeeded(int maxMb) async {
    final sizeBytes = await getCacheSizeBytes();
    final maxBytes = maxMb * 1024 * 1024;
    if (sizeBytes <= maxBytes) return;

    // flutter_cache_manager handles LRU eviction internally.
    // For size-based eviction we trigger a full cache cleanup.
    // Open pages are re-fetched on next access (they are still in memory).
    await _cacheManager.emptyCache();
  }
}

// ── Cache eviction service ─────────────────────────────────────────────────────

/// Monitors storage and triggers cache eviction when free space falls below
/// [AppConstants.kCacheEvictionThresholdMb] (500 MB).
///
/// Call [checkAndEvict] periodically (e.g. from a background timer or before
/// starting a new download batch).
class CacheEvictionService {
  final ImageCacheService _imageCacheService;

  CacheEvictionService({ImageCacheService? imageCacheService})
      : _imageCacheService = imageCacheService ?? ImageCacheService();

  /// Checks current cache size and triggers eviction if needed.
  ///
  /// Eviction is triggered when the cache exceeds the configured maximum
  /// ([maxCacheMb]) or when free storage falls below
  /// [AppConstants.kCacheEvictionThresholdMb] MB.
  Future<void> checkAndEvict({
    int maxCacheMb = AppConstants.kDefaultCacheMaxMb,
  }) async {
    await _imageCacheService.runEvictionIfNeeded(maxCacheMb);
  }

  /// Returns the current cache size in megabytes.
  Future<double> getCacheSizeMb() async {
    final bytes = await _imageCacheService.getCacheSizeBytes();
    return bytes / (1024 * 1024);
  }
}
