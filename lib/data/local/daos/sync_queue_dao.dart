import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Returns all pending sync records ordered by creation time (oldest first).
  Future<List<SyncQueueTableData>> getPendingRecords() {
    return (select(syncQueueTable)
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .get();
  }

  /// Adds a new record to the sync queue.
  Future<void> enqueue(SyncQueueTableCompanion record) async {
    await into(syncQueueTable).insert(record);
  }

  /// Removes a record from the sync queue after successful sync.
  Future<void> deleteRecord(String id) async {
    await (delete(syncQueueTable)..where((s) => s.id.equals(id))).go();
  }

  /// Increments the retry_count for a record (used for exponential backoff).
  Future<void> incrementRetryCount(String id) async {
    await customUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {syncQueueTable},
    );
  }

  /// Removes all records from the sync queue.
  Future<void> clearAll() async {
    await delete(syncQueueTable).go();
  }
}
