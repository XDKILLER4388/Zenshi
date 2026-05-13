import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/auth_screen.dart';
import '../../presentation/screens/downloads/downloads_screen.dart';
import '../../presentation/screens/extensions/extension_marketplace_screen.dart';
import '../../presentation/screens/home/discover_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/library/library_screen.dart';
import '../../presentation/screens/manga_details/chapter_list_screen.dart';
import '../../presentation/screens/manga_details/manga_details_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/reader/reader_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/library/reading_history_screen.dart';
import '../../presentation/screens/settings/about_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

// ── Route name constants ──────────────────────────────────────────────────────

abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const home = '/home';
  static const discover = '/home/discover';
  static const library = '/home/library';
  static const downloads = '/home/downloads';
  static const mangaDetails = '/manga/:id';
  static const chapterList = '/manga/:id/chapters';
  static const reader = '/reader/:mangaId/:chapterId';
  static const search = '/search';
  static const extensions = '/extensions';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const profile = '/profile';
  static const about = '/about';
  static const readingHistory = '/library/history';
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Riverpod provider that exposes the [GoRouter] instance.
///
/// Auth redirect logic lives here: unauthenticated users are sent to
/// [Routes.auth]. Replace the stub flags with real auth state in Task 5.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    // No redirects — splash screen handles navigation logic
    routes: [
      // ── Splash ──────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Onboarding ───────────────────────────────────────────────────────
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.auth,
        name: 'auth',
        builder: (_, __) => const AuthScreen(),
      ),

      // ── Home shell (bottom nav) ───────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: Routes.discover,
            name: 'discover',
            builder: (_, __) => const DiscoverScreen(),
          ),
          GoRoute(
            path: Routes.library,
            name: 'library',
            builder: (_, __) => const LibraryScreen(),
          ),
          GoRoute(
            path: Routes.downloads,
            name: 'downloads',
            builder: (_, __) => const DownloadsScreen(),
          ),
        ],
      ),

      // ── Manga details ─────────────────────────────────────────────────────
      GoRoute(
        path: '/manga/:id',
        name: 'mangaDetails',
        builder: (_, state) => MangaDetailsScreen(
          mangaId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'chapters',
            name: 'chapterList',
            builder: (_, state) => ChapterListScreen(
              mangaId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ── Reader ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/reader/:mangaId/:chapterId',
        name: 'reader',
        builder: (_, state) => ReaderScreen(
          mangaId: state.pathParameters['mangaId']!,
          chapterId: state.pathParameters['chapterId']!,
        ),
      ),

      // ── Search ────────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.search,
        name: 'search',
        builder: (_, __) => const SearchScreen(),
      ),

      // ── Extensions ────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.extensions,
        name: 'extensions',
        builder: (_, __) => const ExtensionMarketplaceScreen(),
      ),

      // ── Notifications ─────────────────────────────────────────────────────
      GoRoute(
        path: Routes.notifications,
        name: 'notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),

      // ── Settings ──────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),

      // ── Profile ───────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),

      // ── About ─────────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.about,
        name: 'about',
        builder: (_, __) => const AboutScreen(),
      ),

      // ── Reading History ───────────────────────────────────────────────────
      GoRoute(
        path: Routes.readingHistory,
        name: 'readingHistory',
        builder: (_, __) => const ReadingHistoryScreen(),
      ),
    ],
  );
});
