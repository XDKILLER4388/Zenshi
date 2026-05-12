import 'extension_manifest.dart';
import 'extension_sandbox.dart';
import 'extension_health_monitor.dart';

/// Manages the lifecycle of all active extension sandboxes.
///
/// Maintains a registry of running [ExtensionSandbox] instances keyed by
/// extension ID. Sandboxes are created on first use and reused for subsequent
/// requests to the same extension.
class ExtensionSandboxManager {
  final Map<String, ExtensionSandbox> _sandboxes = {};
  final ExtensionHealthMonitor _healthMonitor;

  ExtensionSandboxManager(this._healthMonitor);

  /// Returns the running sandbox for [manifest.id], creating and starting one
  /// if it does not already exist.
  ///
  /// Throws [ExtensionFailure] if the isolate cannot be spawned.
  Future<ExtensionSandbox> getOrCreateSandbox(
    ExtensionManifest manifest,
  ) async {
    if (_sandboxes.containsKey(manifest.id)) {
      return _sandboxes[manifest.id]!;
    }
    final sandbox = ExtensionSandbox(manifest);
    await sandbox.start();
    _sandboxes[manifest.id] = sandbox;
    return sandbox;
  }

  /// Stops and removes the sandbox for [extensionId].
  ///
  /// Does nothing if no sandbox exists for that ID.
  void removeSandbox(String extensionId) {
    _sandboxes[extensionId]?.stop();
    _sandboxes.remove(extensionId);
  }

  /// Stops all running sandboxes and clears the registry.
  void stopAll() {
    for (final sandbox in _sandboxes.values) {
      sandbox.stop();
    }
    _sandboxes.clear();
  }

  /// Returns `true` if a sandbox is currently running for [extensionId].
  bool isRunning(String extensionId) {
    return _sandboxes[extensionId]?.isRunning ?? false;
  }

  /// Sends a request to the sandbox for [manifest] and records the health
  /// event based on whether the request succeeds or fails.
  ///
  /// Creates the sandbox if it does not already exist.
  Future<SandboxResponse> sendRequest(
    ExtensionManifest manifest,
    SandboxRequest request,
  ) async {
    final sandbox = await getOrCreateSandbox(manifest);
    try {
      final response = await sandbox.sendRequest(request);
      if (response.success) {
        await _healthMonitor.recordEvent(
          manifest.id,
          ExtensionHealthEvent.success,
        );
      } else {
        await _healthMonitor.recordEvent(
          manifest.id,
          ExtensionHealthEvent.failure,
        );
      }
      return response;
    } catch (e) {
      await _healthMonitor.recordEvent(
        manifest.id,
        ExtensionHealthEvent.failure,
      );
      rethrow;
    }
  }
}
