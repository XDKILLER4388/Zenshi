import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/extension_info.dart';
import 'repository_providers.dart';

// ── Extension list notifier ────────────────────────────────────────────────────

/// Watches the installed extensions stream and exposes install/uninstall/update
/// actions.
class ExtensionListNotifier extends StreamNotifier<List<ExtensionInfo>> {
  @override
  Stream<List<ExtensionInfo>> build() {
    return ref.watch(extensionRepositoryProvider).watchInstalledExtensions();
  }

  Future<void> install(String extensionId) async {
    await ref.read(extensionRepositoryProvider).installExtension(extensionId);
  }

  Future<void> uninstall(String extensionId) async {
    await ref.read(extensionRepositoryProvider).uninstallExtension(extensionId);
  }

  Future<void> updateExtension(String extensionId) async {
    await ref.read(extensionRepositoryProvider).updateExtension(extensionId);
  }

  Future<void> checkForUpdates() async {
    await ref.read(extensionRepositoryProvider).checkForUpdates();
  }
}

/// Provider for [ExtensionListNotifier].
final extensionListProvider =
    StreamNotifierProvider<ExtensionListNotifier, List<ExtensionInfo>>(
  ExtensionListNotifier.new,
);
