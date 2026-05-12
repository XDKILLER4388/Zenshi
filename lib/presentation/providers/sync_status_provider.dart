import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/sync_repository.dart';
import 'repository_providers.dart';

// ── Sync status provider ───────────────────────────────────────────────────────

/// Streams the current [SyncStatus] from [SyncRepository].
///
/// Emits [AsyncValue<SyncStatus>] so the UI can display idle, syncing, error,
/// and offline states.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncRepositoryProvider).watchSyncStatus();
});
