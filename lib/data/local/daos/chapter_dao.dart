import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'chapter_dao.g.dart';

@DriftAccessor(tables: [ChaptersTable])
class ChapterDao extends DatabaseAccessor<AppDatabase>
    with _$ChapterDaoMixin {
  ChapterDao(super.db);

  /// Watches all chapters for a given manga, ordered by chapter number descending.
  Stream<List<ChaptersTableData>> watchChaptersByManga(String mangaId) {
    return (select(chaptersTable)
          ..where((c) => c.mangaId.equals(mangaId))
          ..orderBy([(c) => OrderingTerm.desc(c.chapterNumber)]))
        .watch();
  }

  /// Returns a single chapter by its primary key, or null if not found.
  Future<ChaptersTableData?> getChapterById(String id) {
    return (select(chaptersTable)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts or replaces a chapter row.
  Future<void> upsertChapter(ChaptersTableCompanion chapter) async {
    await into(chaptersTable).insertOnConflictUpdate(chapter);
  }

  /// Sets the isRead flag for a chapter.
  Future<void> markChapterRead(String id, bool isRead) async {
    await (update(chaptersTable)..where((c) => c.id.equals(id)))
        .write(ChaptersTableCompanion(isRead: Value(isRead)));
  }

  /// Returns all unread chapters for a given manga.
  Future<List<ChaptersTableData>> getUnreadChapters(String mangaId) {
    return (select(chaptersTable)
          ..where(
            (c) => c.mangaId.equals(mangaId) & c.isRead.equals(false),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.chapterNumber)]))
        .get();
  }
}
