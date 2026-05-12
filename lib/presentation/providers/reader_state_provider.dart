import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';

// ── Reader state ───────────────────────────────────────────────────────────────

/// Immutable snapshot of the reader's current UI state.
class ReaderState {
  const ReaderState({
    this.currentPageIndex = 0,
    this.zoomLevel = 1.0,
    this.mode = ReadingMode.horizontalRTL,
    this.theme = ReaderTheme.amoled,
    this.menuVisible = false,
    this.autoScrollActive = false,
    this.autoScrollSpeed = 5,
    this.orientationLocked = false,
  });

  /// Index of the currently displayed page (0-based).
  final int currentPageIndex;

  /// Current zoom level; always in the range [1.0, 5.0].
  final double zoomLevel;

  /// Active reading mode.
  final ReadingMode mode;

  /// Active reader colour theme.
  final ReaderTheme theme;

  /// Whether the reader overlay menu is visible.
  final bool menuVisible;

  /// Whether auto-scroll is currently active.
  final bool autoScrollActive;

  /// Auto-scroll speed in the range [1, 10].
  final int autoScrollSpeed;

  /// Whether the screen orientation is locked.
  final bool orientationLocked;

  ReaderState copyWith({
    int? currentPageIndex,
    double? zoomLevel,
    ReadingMode? mode,
    ReaderTheme? theme,
    bool? menuVisible,
    bool? autoScrollActive,
    int? autoScrollSpeed,
    bool? orientationLocked,
  }) {
    return ReaderState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      mode: mode ?? this.mode,
      theme: theme ?? this.theme,
      menuVisible: menuVisible ?? this.menuVisible,
      autoScrollActive: autoScrollActive ?? this.autoScrollActive,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      orientationLocked: orientationLocked ?? this.orientationLocked,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderState &&
        other.currentPageIndex == currentPageIndex &&
        other.zoomLevel == zoomLevel &&
        other.mode == mode &&
        other.theme == theme &&
        other.menuVisible == menuVisible &&
        other.autoScrollActive == autoScrollActive &&
        other.autoScrollSpeed == autoScrollSpeed &&
        other.orientationLocked == orientationLocked;
  }

  @override
  int get hashCode => Object.hash(
        currentPageIndex,
        zoomLevel,
        mode,
        theme,
        menuVisible,
        autoScrollActive,
        autoScrollSpeed,
        orientationLocked,
      );

  @override
  String toString() =>
      'ReaderState(page: $currentPageIndex, zoom: $zoomLevel, '
      'mode: $mode, theme: $theme, menu: $menuVisible)';
}

// ── Reader state notifier ──────────────────────────────────────────────────────

/// Manages [ReaderState] and exposes page navigation, zoom, and UI actions.
class ReaderStateNotifier extends Notifier<ReaderState> {
  @override
  ReaderState build() => const ReaderState();

  // ── Page navigation ──────────────────────────────────────────────────────

  void nextPage() {
    state = state.copyWith(currentPageIndex: state.currentPageIndex + 1);
  }

  void previousPage() {
    final next = state.currentPageIndex - 1;
    if (next >= 0) {
      state = state.copyWith(currentPageIndex: next);
    }
  }

  void setPage(int index) {
    if (index >= 0) {
      state = state.copyWith(currentPageIndex: index);
    }
  }

  // ── Zoom ─────────────────────────────────────────────────────────────────

  /// Sets the zoom level, clamped to [1.0, 5.0].
  void setZoom(double zoom) {
    state = state.copyWith(zoomLevel: zoom.clamp(1.0, 5.0));
  }

  // ── Menu ─────────────────────────────────────────────────────────────────

  void toggleMenu() {
    state = state.copyWith(menuVisible: !state.menuVisible);
  }

  void hideMenu() {
    state = state.copyWith(menuVisible: false);
  }

  // ── Mode & theme ──────────────────────────────────────────────────────────

  void setMode(ReadingMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setTheme(ReaderTheme theme) {
    state = state.copyWith(theme: theme);
  }

  // ── Auto-scroll ───────────────────────────────────────────────────────────

  void toggleAutoScroll() {
    state = state.copyWith(autoScrollActive: !state.autoScrollActive);
  }

  /// Sets the auto-scroll speed, clamped to [1, 10].
  void setAutoScrollSpeed(int speed) {
    state = state.copyWith(autoScrollSpeed: speed.clamp(1, 10));
  }

  // ── Orientation ───────────────────────────────────────────────────────────

  void setOrientationLocked(bool locked) {
    state = state.copyWith(orientationLocked: locked);
  }
}

/// Provider for [ReaderStateNotifier].
final readerStateProvider =
    NotifierProvider<ReaderStateNotifier, ReaderState>(ReaderStateNotifier.new);
