import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'extension_dao.g.dart';

@DriftAccessor(tables: [ExtensionsTable])
class ExtensionDao extends DatabaseAccessor<AppDatabase>
    with _$ExtensionDaoMixin {
  ExtensionDao(super.db);

  /// Watches all installed extensions ordered by name.
  Stream<List<ExtensionsTableData>> watchExtensions() {
    return (select(extensionsTable)
          ..orderBy([(e) => OrderingTerm.asc(e.name)]))
        .watch();
  }

  /// Returns a single extension by its primary key, or null.
  Future<ExtensionsTableData?> getExtensionById(String id) {
    return (select(extensionsTable)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts or replaces an extension row.
  Future<void> upsertExtension(ExtensionsTableCompanion ext) async {
    await into(extensionsTable).insertOnConflictUpdate(ext);
  }

  /// Deletes an extension by id.
  Future<void> deleteExtension(String id) async {
    await (delete(extensionsTable)..where((e) => e.id.equals(id))).go();
  }

  /// Increments the consecutive_failures counter by 1.
  Future<void> incrementFailureCount(String id) async {
    await customUpdate(
      'UPDATE extensions SET consecutive_failures = consecutive_failures + 1 WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {extensionsTable},
    );
  }

  /// Resets the consecutive_failures counter to 0.
  Future<void> resetFailureCount(String id) async {
    await (update(extensionsTable)..where((e) => e.id.equals(id))).write(
      const ExtensionsTableCompanion(
        consecutiveFailures: Value(0),
      ),
    );
  }

  /// Sets health_status to 'degraded'.
  Future<void> markDegraded(String id) async {
    await (update(extensionsTable)..where((e) => e.id.equals(id))).write(
      const ExtensionsTableCompanion(
        healthStatus: Value('degraded'),
      ),
    );
  }
}
