import '../entities/extension_info.dart';

/// Abstract interface for extension marketplace and lifecycle management.
abstract class ExtensionRepository {
  /// Fetches the full list of available extensions from the marketplace.
  Future<List<ExtensionInfo>> fetchMarketplaceListing();

  /// Downloads and installs the extension identified by [extensionId].
  Future<void> installExtension(String extensionId);

  /// Uninstalls the extension identified by [extensionId].
  Future<void> uninstallExtension(String extensionId);

  /// Updates the extension identified by [extensionId] to the latest version.
  Future<void> updateExtension(String extensionId);

  /// Emits the list of installed extensions and any subsequent changes.
  Stream<List<ExtensionInfo>> watchInstalledExtensions();

  /// Checks the marketplace for available updates to installed extensions.
  Future<void> checkForUpdates();
}
