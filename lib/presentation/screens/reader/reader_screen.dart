import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/page.dart' as manga_page;
import '../../../domain/entities/reading_progress.dart';
import '../../providers/manga_provider.dart';
import '../../providers/reader_state_provider.dart';
import '../../providers/reading_progress_provider.dart';
import '../../providers/use_case_providers.dart';

/// Full-screen manga reader with real MangaDex pages.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.mangaId,
    required this.chapterId,
    required this.sourceId,
  });

  final String mangaId;
  final String chapterId;
  final String sourceId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  double _brightness = 0.5;
  bool _showBrightnessSlider = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _enterFullScreen();
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
    _exitFullScreen();
    super.dispose();
  }

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

  void _onPageChanged(int index, int totalPages) {
    ref.read(readerStateProvider.notifier).setPage(index);
    _saveProgress(index);
  }

  void _handleTap(
    TapUpDetails details,
    BoxConstraints constraints,
    int totalPages,
  ) {
    final x = details.localPosition.dx;
    final width = constraints.maxWidth;
    final notifier = ref.read(readerStateProvider.notifier);
    final state = ref.read(readerStateProvider);

    if (x < width / 3) {
      if (state.currentPageIndex > 0) {
        notifier.previousPage();
        _pageController.previousPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    } else if (x > width * 2 / 3) {
      if (state.currentPageIndex < totalPages - 1) {
        notifier.nextPage();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    } else {
      notifier.toggleMenu();
    }
  }

  Color _themeBackground(ReaderTheme theme) => switch (theme) {
    ReaderTheme.defaultLight => Colors.white,
    ReaderTheme.dark => const Color(0xFF1A1A1A),
    ReaderTheme.amoled => Colors.black,
    ReaderTheme.sepia => const Color(0xFFF5E6C8),
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerStateProvider);
    final bgColor = _themeBackground(state.theme);
    final pageArgs = PageArgs(
      chapterId: widget.chapterId,
      sourceId: widget.sourceId,
    );
    final pagesAsync = ref.watch(chapterPagesProvider(pageArgs));

    return Scaffold(
      backgroundColor: bgColor,
      body: pagesAsync.when(
        loading: () => Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Loading chapter...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        error: (_, __) => Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white54,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Could not load chapter',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(chapterPagesProvider(widget.chapterId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (pages) {
          if (pages.isEmpty) {
            return Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No pages found for this chapter',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final totalPages = pages.length;
          final isVertical =
              state.mode == ReadingMode.verticalScroll ||
              state.mode == ReadingMode.webtoon;

          return Stack(
            children: [
              // ── Main reading area ──────────────────────────────────
              LayoutBuilder(
                builder: (ctx, constraints) {
                  return GestureDetector(
                    onTapUp: (d) => _handleTap(d, constraints, totalPages),
                    onHorizontalDragEnd: (d) {
                      if (d.primaryVelocity != null &&
                          d.primaryVelocity! > 0 &&
                          !_showBrightnessSlider) {
                        setState(() => _showBrightnessSlider = true);
                      }
                    },
                    child: isVertical
                        ? _VerticalReader(
                            pages: pages,
                            bgColor: bgColor,
                            isWebtoon: state.mode == ReadingMode.webtoon,
                          )
                        : _HorizontalReader(
                            pages: pages,
                            pageController: _pageController,
                            bgColor: bgColor,
                            isRTL: state.mode == ReadingMode.horizontalRTL,
                            onPageChanged: (i) => _onPageChanged(i, totalPages),
                          ),
                  );
                },
              ),

              // ── Brightness slider ──────────────────────────────────
              if (_showBrightnessSlider)
                _BrightnessSliderOverlay(
                  brightness: _brightness,
                  onChanged: (v) => setState(() => _brightness = v),
                  onDismiss: () =>
                      setState(() => _showBrightnessSlider = false),
                ),

              // ── Reader menu ────────────────────────────────────────
              AnimatedOpacity(
                opacity: state.menuVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !state.menuVisible,
                  child: _ReaderMenuOverlay(
                    chapterId: widget.chapterId,
                    state: state,
                    currentPage: state.currentPageIndex,
                    totalPages: totalPages,
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
                        _startAutoScroll(totalPages);
                      } else {
                        _autoScrollTimer?.cancel();
                      }
                    },
                  ),
                ),
              ),

              // ── Chapter end overlay ────────────────────────────────
              if (state.currentPageIndex >= totalPages - 1)
                _ChapterEndOverlay(
                  onNextChapter: () {},
                  onChapterList: () => context.pop(),
                ),
            ],
          );
        },
      ),
    );
  }

  void _startAutoScroll(int totalPages) {
    final speed = ref.read(readerStateProvider).autoScrollSpeed;
    final interval = Duration(milliseconds: (11 - speed) * 500);
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(interval, (_) {
      final state = ref.read(readerStateProvider);
      if (state.currentPageIndex < totalPages - 1) {
        ref.read(readerStateProvider.notifier).nextPage();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _autoScrollTimer?.cancel();
        ref.read(readerStateProvider.notifier).toggleAutoScroll();
      }
    });
  }
}

// ── Horizontal reader ──────────────────────────────────────────────────────────

class _HorizontalReader extends StatelessWidget {
  const _HorizontalReader({
    required this.pages,
    required this.pageController,
    required this.bgColor,
    required this.isRTL,
    required this.onPageChanged,
  });

  final List<manga_page.Page> pages;
  final PageController pageController;
  final Color bgColor;
  final bool isRTL;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      reverse: isRTL,
      onPageChanged: onPageChanged,
      itemCount: pages.length,
      itemBuilder: (_, i) => _PageWidget(page: pages[i], bgColor: bgColor),
    );
  }
}

// ── Vertical reader ────────────────────────────────────────────────────────────

class _VerticalReader extends StatelessWidget {
  const _VerticalReader({
    required this.pages,
    required this.bgColor,
    required this.isWebtoon,
  });

  final List<manga_page.Page> pages;
  final Color bgColor;
  final bool isWebtoon;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: pages
            .map(
              (p) => _PageWidget(
                page: p,
                bgColor: bgColor,
                verticalGap: isWebtoon ? 0 : 4,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Single page widget ─────────────────────────────────────────────────────────

class _PageWidget extends StatelessWidget {
  const _PageWidget({
    required this.page,
    required this.bgColor,
    this.verticalGap = 0,
  });

  final manga_page.Page page;
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
        child: CachedNetworkImage(
          imageUrl: page.imageUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          placeholder: (_, __) => AspectRatio(
            aspectRatio: 0.7,
            child: Container(
              color: bgColor,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => AspectRatio(
            aspectRatio: 0.7,
            child: Container(
              color: bgColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: bgColor == Colors.white
                        ? Colors.grey
                        : AppColors.onSurfaceMuted,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Page ${page.index + 1}',
                    style: TextStyle(
                      color: bgColor == Colors.white
                          ? Colors.grey
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
    required this.chapterId,
    required this.state,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSliderChanged,
    required this.onModeChanged,
    required this.onThemeChanged,
    required this.onAutoScrollToggle,
  });

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
        // Top bar
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
                      child: Text(
                        'Chapter ${chapterId.split('-').first}',
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${currentPage + 1} / $totalPages',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom bar
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
                            divisions: totalPages > 1 ? totalPages - 1 : 1,
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
                    const SizedBox(height: 4),
                    // Mode and theme
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MenuBtn(
                          icon: Icons.swap_horiz_rounded,
                          label: _modeLabel(state.mode),
                          onTap: () => _showModeSelector(context),
                        ),
                        _MenuBtn(
                          icon: Icons.palette_outlined,
                          label: _themeLabel(state.theme),
                          onTap: () => _showThemeSelector(context),
                        ),
                        _MenuBtn(
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

  String _modeLabel(ReadingMode m) => switch (m) {
    ReadingMode.horizontalRTL => 'RTL',
    ReadingMode.horizontalLTR => 'LTR',
    ReadingMode.verticalScroll => 'Vertical',
    ReadingMode.webtoon => 'Webtoon',
  };

  String _themeLabel(ReaderTheme t) => switch (t) {
    ReaderTheme.defaultLight => 'Light',
    ReaderTheme.dark => 'Dark',
    ReaderTheme.amoled => 'AMOLED',
    ReaderTheme.sepia => 'Sepia',
  };

  void _showModeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Reading Mode', style: AppTypography.titleMedium),
            ),
            for (final m in ReadingMode.values)
              ListTile(
                title: Text(_modeLabel(m)),
                trailing: state.mode == m
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  onModeChanged(m);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Reader Theme', style: AppTypography.titleMedium),
            ),
            for (final t in ReaderTheme.values)
              ListTile(
                title: Text(_themeLabel(t)),
                trailing: state.theme == t
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  onThemeChanged(t);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MenuBtn extends StatelessWidget {
  const _MenuBtn({
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

// ── Brightness slider ──────────────────────────────────────────────────────────

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
                const Icon(
                  Icons.brightness_high,
                  color: Colors.white,
                  size: 20,
                ),
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
