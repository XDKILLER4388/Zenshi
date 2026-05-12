import 'package:flutter/foundation.dart';

enum AppThemeMode { light, dark, amoledDark, systemDefault }

enum ReadingMode { verticalScroll, horizontalLTR, horizontalRTL, webtoon }

enum ReaderTheme { defaultLight, dark, amoled, sepia }

enum AnimationSpeed { off, slow, normal, fast }

enum ImageQuality { original, high, medium, low }

/// Notification preference flags.
@immutable
class NotificationPreferences {
  final bool newChapter;
  final bool downloads;
  final bool extensionHealth;
  final bool appUpdates;

  const NotificationPreferences({
    this.newChapter = true,
    this.downloads = true,
    this.extensionHealth = true,
    this.appUpdates = true,
  });

  NotificationPreferences copyWith({
    bool? newChapter,
    bool? downloads,
    bool? extensionHealth,
    bool? appUpdates,
  }) {
    return NotificationPreferences(
      newChapter: newChapter ?? this.newChapter,
      downloads: downloads ?? this.downloads,
      extensionHealth: extensionHealth ?? this.extensionHealth,
      appUpdates: appUpdates ?? this.appUpdates,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationPreferences &&
        other.newChapter == newChapter &&
        other.downloads == downloads &&
        other.extensionHealth == extensionHealth &&
        other.appUpdates == appUpdates;
  }

  @override
  int get hashCode =>
      Object.hash(newChapter, downloads, extensionHealth, appUpdates);

  @override
  String toString() =>
      'NotificationPreferences(newChapter: $newChapter, downloads: $downloads, '
      'extensionHealth: $extensionHealth, appUpdates: $appUpdates)';
}

/// Immutable domain entity holding all user-configurable application settings.
@immutable
class AppSettings {
  final AppThemeMode theme;

  /// ARGB integer representation of the accent color (e.g. 0xFF7C3AED).
  final int accentColorValue;

  final ReadingMode defaultReadingMode;
  final ReaderTheme readerTheme;
  final String fontStyle;
  final AnimationSpeed animationSpeed;
  final bool dataSaverMode;
  final bool wifiOnlyDownload;
  final bool lowRamMode;
  final bool reducedMotion;
  final bool highContrast;

  /// Text scale factor; valid range 0.8–1.5.
  final double textScale;

  /// Maximum image cache size in megabytes; valid range 256–10240.
  final int maxCacheMb;

  final bool analyticsOptOut;
  final NotificationPreferences notifications;

  const AppSettings({
    required this.theme,
    required this.accentColorValue,
    required this.defaultReadingMode,
    required this.readerTheme,
    required this.fontStyle,
    required this.animationSpeed,
    required this.dataSaverMode,
    required this.wifiOnlyDownload,
    required this.lowRamMode,
    required this.reducedMotion,
    required this.highContrast,
    required this.textScale,
    required this.maxCacheMb,
    required this.analyticsOptOut,
    required this.notifications,
  });

  /// Factory that returns the application's default settings.
  static AppSettings get defaults => const AppSettings(
        theme: AppThemeMode.amoledDark,
        accentColorValue: 0xFF7C3AED,
        defaultReadingMode: ReadingMode.horizontalRTL,
        readerTheme: ReaderTheme.amoled,
        fontStyle: 'inter',
        animationSpeed: AnimationSpeed.normal,
        dataSaverMode: false,
        wifiOnlyDownload: false,
        lowRamMode: false,
        reducedMotion: false,
        highContrast: false,
        textScale: 1.0,
        maxCacheMb: 2048,
        analyticsOptOut: false,
        notifications: NotificationPreferences(),
      );

  AppSettings copyWith({
    AppThemeMode? theme,
    int? accentColorValue,
    ReadingMode? defaultReadingMode,
    ReaderTheme? readerTheme,
    String? fontStyle,
    AnimationSpeed? animationSpeed,
    bool? dataSaverMode,
    bool? wifiOnlyDownload,
    bool? lowRamMode,
    bool? reducedMotion,
    bool? highContrast,
    double? textScale,
    int? maxCacheMb,
    bool? analyticsOptOut,
    NotificationPreferences? notifications,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      defaultReadingMode: defaultReadingMode ?? this.defaultReadingMode,
      readerTheme: readerTheme ?? this.readerTheme,
      fontStyle: fontStyle ?? this.fontStyle,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      dataSaverMode: dataSaverMode ?? this.dataSaverMode,
      wifiOnlyDownload: wifiOnlyDownload ?? this.wifiOnlyDownload,
      lowRamMode: lowRamMode ?? this.lowRamMode,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      highContrast: highContrast ?? this.highContrast,
      textScale: textScale ?? this.textScale,
      maxCacheMb: maxCacheMb ?? this.maxCacheMb,
      analyticsOptOut: analyticsOptOut ?? this.analyticsOptOut,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.theme == theme &&
        other.accentColorValue == accentColorValue &&
        other.defaultReadingMode == defaultReadingMode &&
        other.readerTheme == readerTheme &&
        other.fontStyle == fontStyle &&
        other.animationSpeed == animationSpeed &&
        other.dataSaverMode == dataSaverMode &&
        other.wifiOnlyDownload == wifiOnlyDownload &&
        other.lowRamMode == lowRamMode &&
        other.reducedMotion == reducedMotion &&
        other.highContrast == highContrast &&
        other.textScale == textScale &&
        other.maxCacheMb == maxCacheMb &&
        other.analyticsOptOut == analyticsOptOut &&
        other.notifications == notifications;
  }

  @override
  int get hashCode => Object.hash(
        theme,
        accentColorValue,
        defaultReadingMode,
        readerTheme,
        fontStyle,
        animationSpeed,
        dataSaverMode,
        wifiOnlyDownload,
        lowRamMode,
        reducedMotion,
        highContrast,
        textScale,
        maxCacheMb,
        analyticsOptOut,
        notifications,
      );

  @override
  String toString() =>
      'AppSettings(theme: $theme, readingMode: $defaultReadingMode, '
      'dataSaverMode: $dataSaverMode, lowRamMode: $lowRamMode)';
}
