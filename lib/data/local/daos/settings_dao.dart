import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Returns the single settings row, or null if not yet initialised.
  Future<AppSettingsTableData?> getSettings() {
    return (select(appSettingsTable)..where((s) => s.id.equals(1)))
        .getSingleOrNull();
  }

  /// Inserts or replaces the settings row (id is always 1).
  Future<void> upsertSettings(AppSettingsTableCompanion settings) async {
    await into(appSettingsTable).insertOnConflictUpdate(settings);
  }

  /// Watches the single settings row for reactive UI updates.
  Stream<AppSettingsTableData?> watchSettings() {
    return (select(appSettingsTable)..where((s) => s.id.equals(1)))
        .watchSingleOrNull();
  }
}
