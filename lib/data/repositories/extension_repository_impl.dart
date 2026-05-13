import 'package:drift/drift.dart';
import '../../domain/entities/extension_info.dart';
import '../../domain/repositories/extension_repository.dart';
import '../local/daos/extension_dao.dart';
import '../local/database/app_database.dart';

class ExtensionRepositoryImpl implements ExtensionRepository {
  final ExtensionDao _extensionDao;

  ExtensionRepositoryImpl(this._extensionDao);

  @override
  Future<List<ExtensionInfo>> fetchMarketplaceListing() async {
    // In a real app, this would fetch from a remote API like Keiyoushi
    return [];
  }

  @override
  Future<void> installExtension(String extensionId) async {
    // For now, we'll just mock the installation by adding it to the DB
    // In a real app, this would download the JS/APK file
    final now = DateTime.now().millisecondsSinceEpoch;
    await _extensionDao.upsertExtension(
      ExtensionsTableCompanion.insert(
        id: extensionId,
        name: extensionId.toUpperCase(),
        version: '1.0.0',
        sourceClass: '${extensionId}Source',
        allowedDomains: '',
        sourceType: 'manga',
        language: 'EN',
        installedAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> uninstallExtension(String extensionId) async {
    await _extensionDao.deleteExtension(extensionId);
  }

  @override
  Future<void> updateExtension(String extensionId) async {
    // Mock update
  }

  @override
  Stream<List<ExtensionInfo>> watchInstalledExtensions() {
    return _extensionDao.watchExtensions().map(
      (list) => list
          .map(
            (data) => ExtensionInfo(
              id: data.id,
              name: data.name,
              version: data.version,
              sourceClass: data.sourceClass,
              allowedDomains: data.allowedDomains.split(','),
              sourceType: _parseSourceType(data.sourceType),
              language: data.language,
              isNsfw: data.isNsfw,
              healthStatus: _parseHealthStatus(data.healthStatus),
              consecutiveFailures: data.consecutiveFailures,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> checkForUpdates() async {
    // Mock check
  }

  SourceType _parseSourceType(String type) {
    return SourceType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => SourceType.manga,
    );
  }

  ExtensionHealthStatus _parseHealthStatus(String status) {
    return ExtensionHealthStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ExtensionHealthStatus.healthy,
    );
  }
}
