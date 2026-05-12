import '../entities/app_settings.dart';

/// Abstract interface for reading and persisting application settings.
abstract class SettingsRepository {
  /// Returns the current settings snapshot.
  Future<AppSettings> getSettings();

  /// Persists [settings] to local storage (and queues for remote sync).
  Future<void> updateSettings(AppSettings settings);

  /// Emits the current settings and any subsequent changes.
  Stream<AppSettings> watchSettings();

  /// Serialises the current settings to a JSON string for export.
  Future<String> exportSettingsJson();

  /// Deserialises and applies settings from a JSON string.
  Future<void> importSettingsJson(String json);
}
