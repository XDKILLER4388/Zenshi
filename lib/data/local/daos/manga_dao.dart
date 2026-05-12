import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'manga_dao.g.dart';

@DriftAccessor(tables: [MangaTable])
class MangaDao extends DatabaseAccessor<AppDatabase> with _$MangaDaoMixin {
  MangaDao(super.db);

  /// Watches all manga that are in the user's library.
  Stream<List<MangaTableData>> watchLibrary() {
    return (select(mangaTable)
          ..where((m) => m.inLibrary.equals(true)))
        .watch();
  }

  /// Returns a single manga by its primary key, or null if not found.
  Future<MangaTableData?> getMangaById(String id) {
    return (select(mangaTable)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts or replaces a manga row.
  Future<void> upsertManga(MangaTableCompanion manga) async {
    await into(mangaTable).insertOnConflictUpdate(manga);
  }

  /// Deletes a manga by id.
  Future<void> deleteManga(String id) async {
    await (delete(mangaTable)..where((m) => m.id.equals(id))).go();
  }

  /// Full-text search across title, author, and artist columns.
  Future<List<MangaTableData>> searchManga(String query) {
    final pattern = '%$query%';
    return (select(mangaTable)
          ..where(
            (m) =>
                m.title.like(pattern) |
                m.author.like(pattern) |
                m.artist.like(pattern),
          ))
        .get();
  }

  /// Returns all manga belonging to a given source.
  Future<List<MangaTableData>> getMangaBySourceId(String sourceId) {
    return (select(mangaTable)
          ..where((m) => m.sourceId.equals(sourceId)))
        .get();
  }
}
