import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

/// Returns a stream of application settings that emits on every change.
class GetSettingsUseCase {
  final SettingsRepository _repository;

  const GetSettingsUseCase(this._repository);

  Stream<AppSettings> call() => _repository.watchSettings();
}
