import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'download_dao.g.dart';

@DriftAccessor(tables: [DownloadTasksTable])
class DownloadDao extends DatabaseAccessor<AppDatabase>
    with _$DownloadDaoMixin {
  DownloadDao(super.db);

  /// Watches the full download queue ordered by creation time.
  Stream<List<DownloadTasksTableData>> watchDownloadQueue() {
    return (select(downloadTasksTable)
          ..orderBy([(d) => OrderingTerm.asc(d.createdAt)]))
        .watch();
  }

  /// Inserts or replaces a download task row.
  Future<void> upsertDownloadTask(DownloadTasksTableCompanion task) async {
    await into(downloadTasksTable).insertOnConflictUpdate(task);
  }

  /// Updates only the status field of a download task.
  Future<void> updateDownloadStatus(String id, String status) async {
    await (update(downloadTasksTable)..where((d) => d.id.equals(id)))
        .write(DownloadTasksTableCompanion(status: Value(status)));
  }

  /// Deletes a download task by id.
  Future<void> deleteDownloadTask(String id) async {
    await (delete(downloadTasksTable)..where((d) => d.id.equals(id))).go();
  }

  /// Returns all download tasks with a given status.
  Future<List<DownloadTasksTableData>> getDownloadsByStatus(
      String status) {
    return (select(downloadTasksTable)
          ..where((d) => d.status.equals(status))
          ..orderBy([(d) => OrderingTerm.asc(d.createdAt)]))
        .get();
  }
}
