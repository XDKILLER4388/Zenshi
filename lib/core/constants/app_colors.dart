import 'package:flutter/material.dart';

/// Zenshi AMOLED-optimised colour palette.
///
/// All colours are defined as static constants so they can be referenced
/// without a BuildContext and used in both ThemeData and custom widgets.
abstract final class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  /// Pure AMOLED black — saves power on OLED panels.
  static const Color background = Color(0xFF000000);

  /// Slightly lifted surface for cards and sheets.
  static const Color surface = Color(0xFF0D0D0D);

  /// Secondary surface variant for nested containers.
  static const Color surfaceVariant = Color(0xFF1A1A1A);

  /// Card background — sits between surface and surfaceVariant.
  static const Color cardBackground = Color(0xFF111111);

  // ── Brand / Accent ────────────────────────────────────────────────────────
  /// Neon purple — primary brand colour.
  static const Color primary = Color(0xFF7C3AED);

  /// Neon blue — secondary accent.
  static const Color secondary = Color(0xFF2563EB);

  /// Neon cyan — tertiary accent.
  static const Color tertiary = Color(0xFF06B6D4);

  // ── On-colours ────────────────────────────────────────────────────────────
  /// Text / icons on [background].
  static const Color onBackground = Color(0xFFFFFFFF);

  /// Text / icons on [surface].
  static const Color onSurface = Color(0xFFE5E5E5);

  /// Muted / secondary text on surfaces.
  static const Color onSurfaceMuted = Color(0xFF9CA3AF);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  // ── Structural ────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFF2A2A2A);

  // ── Light theme equivalents ───────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F4F6);
  static const Color lightOnBackground = Color(0xFF111827);
  static const Color lightOnSurface = Color(0xFF374151);
  static const Color lightOnSurfaceMuted = Color(0xFF6B7280);
  static const Color lightDivider = Color(0xFFE5E7EB);

  // ── Dark (non-AMOLED) theme ───────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkOnBackground = Color(0xFFE5E5E5);
  static const Color darkOnSurface = Color(0xFFD1D5DB);
  static const Color darkDivider = Color(0xFF3A3A3A);

  // ── Sepia theme ───────────────────────────────────────────────────────────
  static const Color sepiaBackground = Color(0xFFF5E6C8);
  static const Color sepiaSurface = Color(0xFFEDD9A3);
  static const Color sepiaOnBackground = Color(0xFF3B2F1E);
  static const Color sepiaOnSurface = Color(0xFF5C4A2A);
}
