import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_router.dart';

/// Shell route wrapper providing the bottom navigation bar and app bar.
///
/// The [child] widget is injected by go_router's [ShellRoute] and represents
/// the currently active tab content.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.child});

  final Widget child;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    _NavDestination(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Discover',
      route: Routes.discover,
    ),
    _NavDestination(
      icon: Icons.collections_bookmark_outlined,
      selectedIcon: Icons.collections_bookmark,
      label: 'Library',
      route: Routes.library,
    ),
    _NavDestination(
      icon: Icons.download_outlined,
      selectedIcon: Icons.download,
      label: 'Downloads',
      route: Routes.downloads,
    ),
  ];

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    context.go(_destinations[index].route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Zenshi',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        actions: [
          // Search icon
          IconButton(
            icon: const Icon(Icons.search_rounded),
            color: AppColors.onSurface,
            tooltip: 'Search',
            onPressed: () => context.push(Routes.search),
          ),
          // Notifications bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.onSurface,
            tooltip: 'Notifications',
            onPressed: () => context.push(Routes.notifications),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withAlpha(40),
        destinations: _destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon, color: AppColors.onSurfaceMuted),
                selectedIcon: Icon(d.selectedIcon, color: AppColors.primary),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
}
