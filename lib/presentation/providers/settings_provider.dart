import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import 'repository_providers.dart';

// ── Settings notifier ──────────────────────────────────────────────────────────

/// Watches the [SettingsRepository] stream and exposes typed update methods.
class SettingsNotifier extends StreamNotifier<AppSettings> {
  @override
  Stream<AppSettings> build() {
    return ref.watch(settingsRepositoryProvider).watchSettings();
  }

  /// Persists a full [AppSettings] replacement.
  Future<void> save(AppSettings settings) async {
    await ref.read(settingsRepositoryProvider).updateSettings(settings);
  }

  /// Updates only the theme field.
  Future<void> updateTheme(AppThemeMode theme) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(theme: theme));
  }

  /// Updates only the accent color field.
  Future<void> updateAccentColor(int colorValue) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(accentColorValue: colorValue));
  }

  /// Updates only the default reading mode.
  Future<void> updateReadingMode(ReadingMode mode) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(defaultReadingMode: mode));
  }

  /// Updates only the reader theme.
  Future<void> updateReaderTheme(ReaderTheme theme) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(readerTheme: theme));
  }

  /// Updates only the animation speed.
  Future<void> updateAnimationSpeed(AnimationSpeed speed) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(animationSpeed: speed));
  }

  /// Toggles Data Saver Mode.
  Future<void> updateDataSaverMode(bool enabled) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(dataSaverMode: enabled));
  }

  /// Toggles WiFi-only download mode.
  Future<void> updateWifiOnlyDownload(bool enabled) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(wifiOnlyDownload: enabled));
  }

  /// Toggles Low RAM Mode.
  Future<void> updateLowRamMode(bool enabled) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(lowRamMode: enabled));
  }

  /// Toggles reduced motion.
  Future<void> updateReducedMotion(bool enabled) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(reducedMotion: enabled));
  }

  /// Toggles high-contrast mode.
  Future<void> updateHighContrast(bool enabled) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(highContrast: enabled));
  }

  /// Updates the text scale factor (clamped to [0.8, 1.5]).
  Future<void> updateTextScale(double scale) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(textScale: scale.clamp(0.8, 1.5)));
  }

  /// Updates the maximum cache size in MB (clamped to [256, 10240]).
  Future<void> updateMaxCacheMb(int mb) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(maxCacheMb: mb.clamp(256, 10240)));
  }

  /// Toggles analytics opt-out.
  Future<void> updateAnalyticsOptOut(bool optOut) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(analyticsOptOut: optOut));
  }

  /// Updates notification preferences.
  Future<void> updateNotifications(NotificationPreferences prefs) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await save(current.copyWith(notifications: prefs));
  }
}

/// Provider for [SettingsNotifier].
final settingsProvider =
    StreamNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
