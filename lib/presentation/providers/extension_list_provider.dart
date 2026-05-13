import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/extension_info.dart';

// ── Extension list notifier ────────────────────────────────────────────────────

class ExtensionListNotifier extends StreamNotifier<List<ExtensionInfo>> {
  @override
  Stream<List<ExtensionInfo>> build() {
    // Return empty list immediately — no DB access to avoid startup crashes
    return Stream.value([]);
  }

  Future<void> install(String extensionId) async {}
  Future<void> uninstall(String extensionId) async {}
  Future<void> updateExtension(String extensionId) async {}
  Future<void> checkForUpdates() async {}
}

final extensionListProvider =
    StreamNotifierProvider<ExtensionListNotifier, List<ExtensionInfo>>(
  ExtensionListNotifier.new,
);
