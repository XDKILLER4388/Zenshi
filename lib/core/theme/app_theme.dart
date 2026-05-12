import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Zenshi theme factory.
///
/// Provides four named themes:
/// - [amoledDark]  — pure black AMOLED (default)
/// - [dark]        — dark grey (non-AMOLED)
/// - [light]       — light / white
/// - [sepia]       — warm beige for comfortable reading
abstract final class AppTheme {
  static const double _borderRadius = 12.0;

  // ── Shared shape ──────────────────────────────────────────────────────────

  static final _roundedShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_borderRadius),
  );

  // ── AMOLED Dark (default) ─────────────────────────────────────────────────

  static ThemeData get amoledDark => _buildDarkTheme(
        background: AppColors.background,
        surface: AppColors.surface,
        surfaceVariant: AppColors.surfaceVariant,
        onBackground: AppColors.onBackground,
        onSurface: AppColors.onSurface,
        onSurfaceMuted: AppColors.onSurfaceMuted,
        divider: AppColors.divider,
        brightness: Brightness.dark,
        systemUiOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.background,
        ),
      );

  // ── Dark (non-AMOLED) ─────────────────────────────────────────────────────

  static ThemeData get dark => _buildDarkTheme(
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        surfaceVariant: AppColors.darkSurfaceVariant,
        onBackground: AppColors.darkOnBackground,
        onSurface: AppColors.darkOnSurface,
        onSurfaceMuted: AppColors.onSurfaceMuted,
        divider: AppColors.darkDivider,
        brightness: Brightness.dark,
        systemUiOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.darkBackground,
        ),
      );

  // ── Light ─────────────────────────────────────────────────────────────────

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.lightOnSurface,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.lightOnSurface,
        displayColor: AppColors.lightOnBackground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 1,
        shape: _roundedShape,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.primary.withAlpha(30),
        labelTextStyle: WidgetStateProperty.all(AppTypography.labelSmall),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: _roundedShape,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ── Sepia ─────────────────────────────────────────────────────────────────

  static ThemeData get sepia {
    final colorScheme = ColorScheme.light(
      primary: const Color(0xFF8B5E3C),
      secondary: const Color(0xFFA0785A),
      surface: AppColors.sepiaSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.sepiaOnSurface,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.sepiaBackground,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.sepiaOnSurface,
        displayColor: AppColors.sepiaOnBackground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.sepiaSurface,
        foregroundColor: AppColors.sepiaOnBackground,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.sepiaSurface,
        elevation: 1,
        shape: _roundedShape,
        margin: EdgeInsets.zero,
      ),
    );
  }

  // ── Private builder ───────────────────────────────────────────────────────

  static ThemeData _buildDarkTheme({
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color onBackground,
    required Color onSurface,
    required Color onSurfaceMuted,
    required Color divider,
    required Brightness brightness,
    required SystemUiOverlayStyle systemUiOverlayStyle,
  }) {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: onSurface,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: onSurface,
        displayColor: onBackground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: systemUiOverlayStyle,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: _roundedShape,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primary.withAlpha(40),
        labelTextStyle: WidgetStateProperty.all(
          AppTypography.labelSmall.copyWith(color: onSurfaceMuted),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: onSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: onSurfaceMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: _roundedShape,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: _roundedShape,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: _roundedShape,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        labelStyle: AppTypography.labelMedium.copyWith(color: onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: _roundedShape,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: onBackground),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: onSurface),
        shape: _roundedShape,
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: onSurface,
        iconColor: onSurfaceMuted,
      ),
      iconTheme: IconThemeData(color: onSurface),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return onSurfaceMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withAlpha(80);
          }
          return surfaceVariant;
        }),
      ),
    );
  }
}
