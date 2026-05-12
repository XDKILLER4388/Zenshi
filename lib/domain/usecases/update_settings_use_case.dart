import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

/// Persists updated application settings.
class UpdateSettingsUseCase {
  final SettingsRepository _repository;

  const UpdateSettingsUseCase(this._repository);

  Future<void> call(AppSettings settings) =>
      _repository.updateSettings(settings);
}
