import '../repositories/extension_repository.dart';

/// Downloads and installs an extension from the marketplace.
class InstallExtensionUseCase {
  final ExtensionRepository _repository;

  const InstallExtensionUseCase(this._repository);

  Future<void> call(String extensionId) =>
      _repository.installExtension(extensionId);
}
