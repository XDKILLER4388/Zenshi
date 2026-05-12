import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/widgets/common/zenshi_app_wrapper.dart';

/// Root application widget.
///
/// Reads the [appRouterProvider] and [AppTheme.amoledDark] from the Riverpod
/// container. Theme selection will be driven by [settingsProvider] in Task 5.
class ZenshiApp extends ConsumerWidget {
  const ZenshiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return ZenshiAppWrapper(
      child: MaterialApp.router(
        title: 'Zenshi',
        debugShowCheckedModeBanner: false,

        // Themes — active theme will be driven by settingsProvider in Task 5.
        theme: AppTheme.light,
        darkTheme: AppTheme.amoledDark,
        themeMode: ThemeMode.dark,

        // Navigation
        routerConfig: router,
      ),
    );
  }
}
