import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/reading_progress.dart';
import '../../providers/reader_state_provider.dart';
import '../../providers/reading_progress_provider.dart';

// ── Page preloader service ─────────────────────────────────────────────────────

/// Maintains a sliding window of 5 pages (2 behind, current, 3 ahead).
/// Uses a Map keyed by page index to cache image bytes.
class PagePreloaderService {
  PagePreloaderService({required this.totalPages});

  final int totalPages;

  /// Cache: page index → image bytes (null = loading/not loaded)
  final Map<int, List<int>?> _cache = {};

  static const int _behind = 2;
  static const int _ahead = 3;

  /// Update the window around [currentIndex], evicting pages outside it.
  void updateWindow(int currentIndex) {
    final windowStart = (currentIndex - _behind).clamp(0, totalPages - 1);
    final windowEnd = (currentIndex + _ahead).clamp(0, totalPages - 1);

    // Evict pages outside window
    _cache.removeWhere(
      (k, _) => k < windowStart || k > windowEnd,
    );

    // Mark pages in window for loading
    for (var i = windowStart; i <= windowEnd; i++) {
      if (!_cache.containsKey(i)) {
        _cache[i] = null; // null = loading
      }
    }
  }

  bool isLoaded(int index) => _cache[index] != null;

  void dispose() {
    _cache.clear();
  }
}

// ── Mock page data ─────────────────────────────────────────────────────────────

const int _kMockPageCount = 20;

// ── Screen ─────────────────────────────────────────────────────────────────────

/// Full-screen manga reader.
///
/// Supports horizontal paging (LTR/RTL), vertical scroll, and webtoon modes.
/// Tap zones: left 1/3 = previous, right 1/3 = next, center = toggle menu.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.mangaId,
    required this.chapterId,
  });

  final String mangaId;
  final String chapterId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final PageController _pageController;
  late final PagePreloaderService _preloader;
  Timer? _autoScrollTimer;
  double _brightness = 0.5;
  bool _showBrightnessSlider = false;

  @override
  void initState() {
    super.initState();
    _preloader = PagePreloaderService(totalPages: _kMockPageCount);
    _pageController = PageController();
    _enterFullScreen();
    _preloader.updateWindow(0);
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _preloader.dispose();
    _exitFullScreen();
    super.dispose();
  }

  // ── Auto-scroll ──────────────────────────────────────────────────────────

  void _startAutoScroll() {
    final speed = ref.read(readerStateProvider).autoScrollSpeed;
    final interval = Duration(milliseconds: (11 - speed) * 500);
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(interval, (_) {
      final state = ref.read(readerStateProvider);
      if (state.currentPageIndex < _kMockPageCount - 1) {
        ref.read(readerStateProvider.notifier).nextPage();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _stopAutoScroll();
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    ref.read(readerStateProvider.notifier).toggleAutoScroll();
  }

  // ── Progress save ────────────────────────────────────────────────────────

  void _saveProgress(int pageIndex) {
    final progress = ReadingProgress(
      id: '${widget.mangaId}_${widget.chapterId}',
      mangaId: widget.mangaId,
      chapterId: widget.chapterId,
      pageIndex: pageIndex,
      updatedAt: DateTime.now(),
    );
    ref.read(readingProgressProvider(widget.mangaId).notifier).save(progress);
  }

  // ── Page change ──────────────────────────────────────────────────────────

  void _onPageChanged(int index) {
    ref.read(readerStateProvider.notifier).setPage(index);
    _preloader.updateWindow(index);
    _saveProgress(index);
  }

  // ── Tap zone handler ─────────────────────────────────────────────────────

  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    final x = details.localPosition.dx;
    final width = constraints.maxWidth;
    final notifier = ref.read(readerStateProvider.notifier);
    final state = ref.read(readerStateProvider);

    if (x < width / 3) {
      // Left zone → previous page
      if (state.currentPageIndex > 0) {
        notifier.previousPage();
        _pageController.previousPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    } else if (x > width * 2 / 3) {
      // Right zone → next page
      if (state.currentPageIndex < _kMockPageCount - 1) {
        notifier.nextPage();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // Center zone → toggle menu
      notifier.toggleMenu();
    }
  }

  // ── Background color ─────────────────────────────────────────────────────

  Color _themeBackground(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.defaultLight:
        return Colors.white;
      case ReaderTheme.dark:
        return const Color(0xFF1A1A1A);
      case ReaderTheme.amoled:
        return Colors.black;
      case ReaderTheme.sepia:
        return const Color(0xFFF5E6C8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerStateProvider);
    final bgColor = _themeBackground(state.theme);
    final isVertical = state.mode == ReadingMode.verticalScroll ||
        state.mode == ReadingMode.webtoon;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Main reading area ──────────────────────────────────────────
          LayoutBuilder(
            builder: (ctx, constraints) {
              return GestureDetector(
                onTapUp: (d) => _handleTap(d, constraints),
                onHorizontalDragEnd: (d) {
                  // Left-edge swipe → brightness slider
                  if (d.primaryVelocity != null &&
                      d.primaryVelocity! > 0 &&
                      !_showBrightnessSlider) {
                    setState(() => _showBrightnessSlider = true);
                  }
                },
                child: isVertical
                    ? _VerticalReader(
                        pageCount: _kMockPageCount,
                        bgColor: bgColor,
                        isWebtoon: state.mode == ReadingMode.webtoon,
                      )
                    : _HorizontalReader(
                        pageController: _pageController,
                        pageCount: _kMockPageCount,
                        bgColor: bgColor,
                        isRTL: state.mode == ReadingMode.horizontalRTL,
                        onPageChanged: _onPageChanged,
                      ),
              );
            },
          ),

          // ── Brightness slider overlay ──────────────────────────────────
          if (_showBrightnessSlider)
            _BrightnessSliderOverlay(
              brightness: _brightness,
              onChanged: (v) => setState(() => _brightness = v),
              onDismiss: () => setState(() => _showBrightnessSlider = false),
            ),

          // ── Reader menu overlay ────────────────────────────────────────
          AnimatedOpacity(
            opacity: state.menuVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !state.menuVisible,
              child: _ReaderMenuOverlay(
                mangaId: widget.mangaId,
                chapterId: widget.chapterId,
                state: state,
                currentPage: state.currentPageIndex,
                totalPages: _kMockPageCount,
                onPageSliderChanged: (v) {
                  final index = v.round();
                  ref.read(readerStateProvider.notifier).setPage(index);
                  _pageController.jumpToPage(index);
                },
                onModeChanged: (m) =>
                    ref.read(readerStateProvider.notifier).setMode(m),
                onThemeChanged: (t) =>
                    ref.read(readerStateProvider.notifier).setTheme(t),
                onAutoScrollToggle: () {
                  final notifier = ref.read(readerStateProvider.notifier);
                  notifier.toggleAutoScroll();
                  if (!state.autoScrollActive) {
                    _startAutoScroll();
                  } else {
                    _autoScrollTimer?.cancel();
                  }
                },
              ),
            ),
          ),

          // ── Chapter end overlay ────────────────────────────────────────
          if (state.currentPageIndex >= _kMockPageCount - 1)
            _ChapterEndOverlay(
              onNextChapter: () {},
              onChapterList: () => context.pop(),
            ),

          // ── Chapter start overlay (first page, swipe back) ─────────────
          if (state.currentPageIndex == 0 && state.menuVisible)
            _ChapterStartOverlay(
              onPreviousChapter: () {},
            ),
        ],
      ),
    );
  }
}

// ── Horizontal reader ──────────────────────────────────────────────────────────

class _HorizontalReader extends StatelessWidget {
  const _HorizontalReader({
    required this.pageController,
    required this.pageCount,
    required this.bgColor,
    required this.isRTL,
    required this.onPageChanged,
  });

  final PageController pageController;
  final int pageCount;
  final Color bgColor;
  final bool isRTL;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      reverse: isRTL,
      onPageChanged: onPageChanged,
      itemCount: pageCount,
      itemBuilder: (_, i) => _PageView(
        pageIndex: i,
        bgColor: bgColor,
      ),
    );
  }
}

// ── Vertical reader ────────────────────────────────────────────────────────────

class _VerticalReader extends StatelessWidget {
  const _VerticalReader({
    required this.pageCount,
    required this.bgColor,
    required this.isWebtoon,
  });

  final int pageCount;
  final Color bgColor;
  final bool isWebtoon;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(
          pageCount,
          (i) => _PageView(
            pageIndex: i,
            bgColor: bgColor,
            verticalGap: isWebtoon ? 0 : 8,
          ),
        ),
      ),
    );
  }
}

// ── Single page view ───────────────────────────────────────────────────────────

class _PageView extends StatelessWidget {
  const _PageView({
    required this.pageIndex,
    required this.bgColor,
    this.verticalGap = 0,
  });

  final int pageIndex;
  final Color bgColor;
  final double verticalGap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: verticalGap),
      color: bgColor,
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 5.0,
        child: AspectRatio(
          aspectRatio: 0.7,
          child: Container(
            color: bgColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: bgColor == Colors.white
                        ? Colors.grey.shade300
                        : AppColors.surfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Page ${pageIndex + 1}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: bgColor == Colors.white
                          ? Colors.grey.shade400
                          : AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reader menu overlay ────────────────────────────────────────────────────────

class _ReaderMenuOverlay extends StatelessWidget {
  const _ReaderMenuOverlay({
    required this.mangaId,
    required this.chapterId,
    required this.state,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSliderChanged,
    required this.onModeChanged,
    required this.onThemeChanged,
    required this.onAutoScrollToggle,
  });

  final String mangaId;
  final String chapterId;
  final ReaderState state;
  final int currentPage;
  final int totalPages;
  final ValueChanged<double> onPageSliderChanged;
  final ValueChanged<ReadingMode> onModeChanged;
  final ValueChanged<ReaderTheme> onThemeChanged;
  final VoidCallback onAutoScrollToggle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Top bar ──────────────────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Manga Title',
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Chapter ${chapterId.split('_').last}',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Bottom bar ───────────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page slider
                    Row(
                      children: [
                        Text(
                          '${currentPage + 1}',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: currentPage.toDouble(),
                            min: 0,
                            max: (totalPages - 1).toDouble(),
                            divisions: totalPages - 1,
                            activeColor: AppColors.primary,
                            inactiveColor: Colors.white30,
                            onChanged: onPageSliderChanged,
                          ),
                        ),
                        Text(
                          '$totalPages',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Mode and theme selectors
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Reading mode
                        _MenuIconButton(
                          icon: Icons.swap_horiz_rounded,
                          label: _modeLabel(state.mode),
                          onTap: () => _showModeSelector(context),
                        ),
                        // Theme
                        _MenuIconButton(
                          icon: Icons.palette_outlined,
                          label: _themeLabel(state.theme),
                          onTap: () => _showThemeSelector(context),
                        ),
                        // Auto-scroll
                        _MenuIconButton(
                          icon: state.autoScrollActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          label: 'Auto',
                          onTap: onAutoScrollToggle,
                          active: state.autoScrollActive,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _modeLabel(ReadingMode mode) {
    switch (mode) {
      case ReadingMode.horizontalRTL:
        return 'RTL';
      case ReadingMode.horizontalLTR:
        return 'LTR';
      case ReadingMode.verticalScroll:
        return 'Vertical';
      case ReadingMode.webtoon:
        return 'Webtoon';
    }
  }

  String _themeLabel(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.defaultLight:
        return 'Light';
      case ReaderTheme.dark:
        return 'Dark';
      case ReaderTheme.amoled:
        return 'AMOLED';
      case ReaderTheme.sepia:
        return 'Sepia';
    }
  }

  void _showModeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ModeSelector(
        current: state.mode,
        onSelect: (m) {
          onModeChanged(m);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ThemeSelector(
        current: state.theme,
        onSelect: (t) {
          onThemeChanged(t);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ── Menu icon button ───────────────────────────────────────────────────────────

class _MenuIconButton extends StatelessWidget {
  const _MenuIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? AppColors.primary : Colors.white,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: active ? AppColors.primary : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode selector ──────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.current, required this.onSelect});

  final ReadingMode current;
  final ValueChanged<ReadingMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final modes = [
      (ReadingMode.horizontalRTL, 'Right to Left', Icons.arrow_back),
      (ReadingMode.horizontalLTR, 'Left to Right', Icons.arrow_forward),
      (ReadingMode.verticalScroll, 'Vertical Scroll', Icons.swap_vert),
      (ReadingMode.webtoon, 'Webtoon', Icons.view_day_outlined),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Reading Mode', style: AppTypography.titleMedium),
          ),
          ...modes.map(
            (m) => ListTile(
              leading: Icon(m.$3,
                  color: current == m.$1
                      ? AppColors.primary
                      : AppColors.onSurfaceMuted),
              title: Text(m.$2),
              trailing: current == m.$1
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => onSelect(m.$1),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Theme selector ─────────────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.current, required this.onSelect});

  final ReaderTheme current;
  final ValueChanged<ReaderTheme> onSelect;

  @override
  Widget build(BuildContext context) {
    final themes = [
      (ReaderTheme.defaultLight, 'Light', Colors.white),
      (ReaderTheme.dark, 'Dark', const Color(0xFF1A1A1A)),
      (ReaderTheme.amoled, 'AMOLED', Colors.black),
      (ReaderTheme.sepia, 'Sepia', const Color(0xFFF5E6C8)),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Reader Theme', style: AppTypography.titleMedium),
          ),
          ...themes.map(
            (t) => ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: t.$3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
              ),
              title: Text(t.$2),
              trailing: current == t.$1
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => onSelect(t.$1),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Brightness slider overlay ──────────────────────────────────────────────────

class _BrightnessSliderOverlay extends StatelessWidget {
  const _BrightnessSliderOverlay({
    required this.brightness,
    required this.onChanged,
    required this.onDismiss,
  });

  final double brightness;
  final ValueChanged<double> onChanged;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.brightness_high, color: Colors.white, size: 20),
                const SizedBox(height: 8),
                RotatedBox(
                  quarterTurns: 3,
                  child: SizedBox(
                    width: 150,
                    child: Slider(
                      value: brightness,
                      min: 0.1,
                      max: 1.0,
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.white30,
                      onChanged: onChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.brightness_low, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chapter end overlay ────────────────────────────────────────────────────────

class _ChapterEndOverlay extends StatelessWidget {
  const _ChapterEndOverlay({
    required this.onNextChapter,
    required this.onChapterList,
  });

  final VoidCallback onNextChapter;
  final VoidCallback onChapterList;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(230),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'End of Chapter',
                style: AppTypography.titleSmall.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: onChapterList,
                    icon: const Icon(Icons.list, size: 16),
                    label: const Text('Chapter List'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onNextChapter,
                    icon: const Icon(Icons.skip_next, size: 16),
                    label: const Text('Next Chapter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chapter start overlay ──────────────────────────────────────────────────────

class _ChapterStartOverlay extends StatelessWidget {
  const _ChapterStartOverlay({required this.onPreviousChapter});

  final VoidCallback onPreviousChapter;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(230),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onPreviousChapter,
                icon: const Icon(Icons.skip_previous, size: 16),
                label: const Text('Previous Chapter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
