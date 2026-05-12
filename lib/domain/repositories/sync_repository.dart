import '../entities/sync_record.dart';

enum SyncStatus { idle, syncing, error, offline }

/// Abstract interface for cloud synchronisation operations.
abstract class SyncRepository {
  /// Pushes [records] to the remote backend.
  Future<void> pushChanges(List<SyncRecord> records);

  /// Pulls all remote changes that occurred after [since].
  Future<List<SyncRecord>> pullChanges(DateTime since);

  /// Emits the current sync status and any subsequent changes.
  Stream<SyncStatus> watchSyncStatus();

  /// Performs a full bidirectional sync.
  Future<void> fullSync();

  /// The timestamp of the last successful sync, or null if never synced.
  DateTime? get lastSyncedAt;
}
