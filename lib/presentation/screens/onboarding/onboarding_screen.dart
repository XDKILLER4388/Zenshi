import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_router.dart';

// ── Onboarding page data ───────────────────────────────────────────────────────

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
}

const _pages = [
  _OnboardingPage(
    icon: Icons.collections_bookmark_rounded,
    title: 'Your Library',
    subtitle: 'Organize manga, manhwa, and manhua in one place',
    gradient: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
  ),
  _OnboardingPage(
    icon: Icons.menu_book_rounded,
    title: 'Immersive Reader',
    subtitle:
        'Multiple reading modes, AMOLED dark, and smooth gestures',
    gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
  _OnboardingPage(
    icon: Icons.extension_rounded,
    title: 'Endless Sources',
    subtitle: 'Install extensions to access thousands of titles',
    gradient: [Color(0xFF06B6D4), Color(0xFF0891B2)],
  ),
  _OnboardingPage(
    icon: Icons.cloud_sync_rounded,
    title: 'Sync Everywhere',
    subtitle: 'Your progress syncs across all your devices',
    gradient: [Color(0xFF10B981), Color(0xFF059669)],
  ),
];

// ── Screen ─────────────────────────────────────────────────────────────────────

/// 4-page onboarding flow introducing core Zenshi features.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go(Routes.auth);
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ──────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _complete,
                  child: Text(
                    'Skip',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
            ),

            // ── Page view ────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _OnboardingPageWidget(page: _pages[i]),
              ),
            ),

            // ── Dots indicator ───────────────────────────────────────────
            _DotsIndicator(
              count: _pages.length,
              current: _currentPage,
            ),
            const SizedBox(height: 32),

            // ── Action button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLast ? 'Get Started' : 'Next',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Single onboarding page ─────────────────────────────────────────────────────

class _OnboardingPageWidget extends StatelessWidget {
  const _OnboardingPageWidget({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Icon area ────────────────────────────────────────────────
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: page.gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: page.gradient.first.withAlpha(80),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          // ── Title ────────────────────────────────────────────────────
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // ── Subtitle ─────────────────────────────────────────────────
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.onSurfaceMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dots indicator ─────────────────────────────────────────────────────────────

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
