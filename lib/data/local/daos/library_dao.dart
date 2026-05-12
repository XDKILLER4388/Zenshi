import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'library_dao.g.dart';

@DriftAccessor(tables: [CollectionsTable, CollectionMangaTable, TagsTable, MangaTagsTable])
class LibraryDao extends DatabaseAccessor<AppDatabase>
    with _$LibraryDaoMixin {
  LibraryDao(super.db);

  // ---------------------------------------------------------------------------
  // Collections
  // ---------------------------------------------------------------------------

  /// Watches all collections ordered by sort_order.
  Stream<List<CollectionsTableData>> watchCollections() {
    return (select(collectionsTable)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// Inserts a new collection.
  Future<void> createCollection(CollectionsTableCompanion c) async {
    await into(collectionsTable).insert(c);
  }

  /// Deletes a collection by id.
  Future<void> deleteCollection(String id) async {
    await (delete(collectionsTable)..where((c) => c.id.equals(id))).go();
  }

  /// Adds a manga to a collection (no-op if already present).
  Future<void> addMangaToCollection(
      String collectionId, String mangaId) async {
    await into(collectionMangaTable).insertOnConflictUpdate(
      CollectionMangaTableCompanion(
        collectionId: Value(collectionId),
        mangaId: Value(mangaId),
      ),
    );
  }

  /// Removes a manga from a collection.
  Future<void> removeMangaFromCollection(
      String collectionId, String mangaId) async {
    await (delete(collectionMangaTable)
          ..where(
            (cm) =>
                cm.collectionId.equals(collectionId) &
                cm.mangaId.equals(mangaId),
          ))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Tags
  // ---------------------------------------------------------------------------

  /// Watches all tags ordered by name.
  Stream<List<TagsTableData>> watchTags() {
    return (select(tagsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Inserts a new tag.
  Future<void> createTag(TagsTableCompanion tag) async {
    await into(tagsTable).insert(tag);
  }

  /// Deletes a tag by id.
  Future<void> deleteTag(String id) async {
    await (delete(tagsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Assigns a tag to a manga (no-op if already assigned).
  Future<void> addTagToManga(String mangaId, String tagId) async {
    await into(mangaTagsTable).insertOnConflictUpdate(
      MangaTagsTableCompanion(
        mangaId: Value(mangaId),
        tagId: Value(tagId),
      ),
    );
  }

  /// Removes a tag from a manga.
  Future<void> removeTagFromManga(String mangaId, String tagId) async {
    await (delete(mangaTagsTable)
          ..where(
            (mt) => mt.mangaId.equals(mangaId) & mt.tagId.equals(tagId),
          ))
        .go();
  }
}
