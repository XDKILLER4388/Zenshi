import '../repositories/extension_repository.dart';

/// Uninstalls an installed extension.
class UninstallExtensionUseCase {
  final ExtensionRepository _repository;

  const UninstallExtensionUseCase(this._repository);

  Future<void> call(String extensionId) =>
      _repository.uninstallExtension(extensionId);
}
