/// Application-wide constants for Zenshi.
///
/// All values are compile-time constants so they can be used in switch
/// expressions, annotations, and const constructors.
abstract final class AppConstants {
  // ── Timing ────────────────────────────────────────────────────────────────

  /// How long the splash screen is shown before navigating away.
  static const Duration kSplashDuration = Duration(seconds: 2);

  /// Default animation duration used across the app.
  static const Duration kDefaultAnimationDuration = Duration(milliseconds: 300);

  /// Duration for page/route transition animations.
  static const Duration kPageTransitionDuration = Duration(milliseconds: 250);

  // ── Search ────────────────────────────────────────────────────────────────

  /// Maximum number of recent searches persisted locally.
  static const int kMaxSearchHistory = 20;

  // ── Reader ────────────────────────────────────────────────────────────────

  /// Number of pages to preload ahead of the current page.
  static const int kPreloadPages = 3;

  // ── Cache ─────────────────────────────────────────────────────────────────

  /// Default maximum cache size in megabytes (2 GB).
  static const int kDefaultCacheMaxMb = 2048;

  /// Pause downloads and warn the user when free storage drops below this.
  static const int kLowStorageThresholdMb = 200;

  /// Trigger LRU cache eviction when free storage drops below this.
  static const int kCacheEvictionThresholdMb = 500;

  // ── Extensions ────────────────────────────────────────────────────────────

  /// Number of consecutive fetch failures before an extension is marked
  /// as degraded.
  static const int kExtensionDegradedThreshold = 5;

  // ── Sync ──────────────────────────────────────────────────────────────────

  /// Debounce window (seconds) before a local change is pushed to the sync
  /// queue to avoid excessive writes on rapid edits.
  static const int kSyncDebounceSeconds = 30;
}
