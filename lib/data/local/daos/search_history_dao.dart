import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'search_history_dao.g.dart';

@DriftAccessor(tables: [SearchHistoryTable])
class SearchHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$SearchHistoryDaoMixin {
  SearchHistoryDao(super.db);

  /// Returns the [limit] most recent search entries, newest first.
  Future<List<SearchHistoryTableData>> getRecentSearches(int limit) {
    return (select(searchHistoryTable)
          ..orderBy([(s) => OrderingTerm.desc(s.searchedAt)])
          ..limit(limit))
        .get();
  }

  /// Inserts a new search history entry.
  Future<void> addSearch(SearchHistoryTableCompanion entry) async {
    await into(searchHistoryTable).insert(entry);
  }

  /// Deletes a single search history entry by id.
  Future<void> deleteSearch(String id) async {
    await (delete(searchHistoryTable)..where((s) => s.id.equals(id))).go();
  }

  /// Clears the entire search history.
  Future<void> clearHistory() async {
    await delete(searchHistoryTable).go();
  }
}
