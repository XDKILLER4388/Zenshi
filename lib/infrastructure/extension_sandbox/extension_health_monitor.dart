import '../../core/constants/app_constants.dart';
import '../../data/local/daos/extension_dao.dart';

/// Events that can be recorded for an extension's health tracking.
enum ExtensionHealthEvent { success, failure }

/// Tracks consecutive fetch failures per extension and marks degraded status.
///
/// After [AppConstants.kExtensionDegradedThreshold] consecutive failures the
/// extension is marked as degraded in the local database. A single success
/// resets the counter to zero.
class ExtensionHealthMonitor {
  final ExtensionDao _extensionDao;

  const ExtensionHealthMonitor(this._extensionDao);

  /// Records a fetch result for [extensionId].
  ///
  /// On [ExtensionHealthEvent.success]: resets the consecutive failure counter.
  /// On [ExtensionHealthEvent.failure]: increments the counter and marks the
  /// extension as degraded once the threshold is reached.
  Future<void> recordEvent(
    String extensionId,
    ExtensionHealthEvent event,
  ) async {
    switch (event) {
      case ExtensionHealthEvent.success:
        await _extensionDao.resetFailureCount(extensionId);
      case ExtensionHealthEvent.failure:
        await _extensionDao.incrementFailureCount(extensionId);
        final ext = await _extensionDao.getExtensionById(extensionId);
        if (ext != null &&
            ext.consecutiveFailures >=
                AppConstants.kExtensionDegradedThreshold) {
          await _extensionDao.markDegraded(extensionId);
        }
    }
  }

  /// Returns `true` if [extensionId] has been marked as degraded.
  Future<bool> isDegraded(String extensionId) async {
    final ext = await _extensionDao.getExtensionById(extensionId);
    return ext?.healthStatus == 'degraded';
  }
}
