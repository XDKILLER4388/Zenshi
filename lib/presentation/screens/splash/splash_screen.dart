import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../providers/auth_provider.dart';

/// Splash screen shown on every app launch.
///
/// Displays the Zenshi logo with a fade-in animation, then after
/// [AppConstants.kSplashDuration] navigates to the appropriate screen:
/// - /onboarding  if first launch
/// - /auth        if onboarding complete but not authenticated
/// - /home        if authenticated
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future.delayed(AppConstants.kSplashDuration);
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete =
        prefs.getBool('onboarding_complete') ?? false;

    if (!mounted) return;

    if (!onboardingComplete) {
      context.go(Routes.onboarding);
      return;
    }

    // Check auth state
    final authState = ref.read(authProvider).valueOrNull;
    if (authState == null ||
        authState.status == AuthStatus.unauthenticated) {
      context.go(Routes.auth);
    } else {
      context.go(Routes.discover);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo ──────────────────────────────────────────────────
              _ZenshiLogo(),
              const SizedBox(height: 24),
              // ── App name ──────────────────────────────────────────────
              Text(
                'Zenshi',
                style: AppTypography.headlineLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your manga universe',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Zenshi logo widget ─────────────────────────────────────────────────────────

class _ZenshiLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9F5FFF),
            AppColors.primary,
            Color(0xFF5B21B6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(100),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'Z',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 56,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
