import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'reading_progress_dao.g.dart';

@DriftAccessor(tables: [ReadingProgressTable])
class ReadingProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingProgressDaoMixin {
  ReadingProgressDao(super.db);

  /// Watches the reading progress for a given manga.
  ///
  /// Returns a stream that emits null when no progress record exists.
  Stream<ReadingProgressTableData?> watchProgress(String mangaId) {
    return (select(readingProgressTable)
          ..where((p) => p.mangaId.equals(mangaId))
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Returns the reading progress for a given manga, or null.
  Future<ReadingProgressTableData?> getProgress(String mangaId) {
    return (select(readingProgressTable)
          ..where((p) => p.mangaId.equals(mangaId))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Inserts or replaces a reading progress row.
  Future<void> upsertProgress(ReadingProgressTableCompanion progress) async {
    await into(readingProgressTable).insertOnConflictUpdate(progress);
  }

  /// Returns all reading progress records (used for sync).
  Future<List<ReadingProgressTableData>> getAllProgress() {
    return select(readingProgressTable).get();
  }
}
