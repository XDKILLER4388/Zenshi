import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/extension_info.dart';
import 'repository_providers.dart';
import 'use_case_providers.dart';

// ── Extension list notifier ────────────────────────────────────────────────────

class ExtensionListNotifier extends StreamNotifier<List<ExtensionInfo>> {
  @override
  Stream<List<ExtensionInfo>> build() {
    return ref.watch(extensionRepositoryProvider).watchInstalledExtensions();
  }

  Future<void> install(String extensionId) async {
    await ref.read(installExtensionUseCaseProvider).call(extensionId);
  }

  Future<void> uninstall(String extensionId) async {
    await ref.read(uninstallExtensionUseCaseProvider).call(extensionId);
  }

  Future<void> updateExtension(String extensionId) async {
    // Repository implementation would go here
  }

  Future<void> checkForUpdates() async {
    await ref.read(extensionRepositoryProvider).checkForUpdates();
  }
}

final extensionListProvider =
    StreamNotifierProvider<ExtensionListNotifier, List<ExtensionInfo>>(
      ExtensionListNotifier.new,
    );
