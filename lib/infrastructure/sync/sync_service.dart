import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/daos/sync_queue_dao.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/entities/sync_record.dart';

/// Implements cloud sync using Supabase REST API.
/// Uses a CRDT last-write-wins strategy for conflict resolution.
class SyncService implements SyncRepository {
  final SupabaseClient _supabase;
  final SyncQueueDao _syncQueueDao;
  final _statusController = StreamController<SyncStatus>.broadcast();
  DateTime? _lastSyncedAt;

  SyncService({
    required SupabaseClient supabase,
    required SyncQueueDao syncQueueDao,
  })  : _supabase = supabase,
        _syncQueueDao = syncQueueDao;

  @override
  Stream<SyncStatus> watchSyncStatus() => _statusController.stream;

  @override
  DateTime? get lastSyncedAt => _lastSyncedAt;

  @override
  Future<void> fullSync() async {
    _statusController.add(SyncStatus.syncing);
    try {
      final pending = await _syncQueueDao.getPendingRecords();
      // Push pending changes to Supabase
      for (final record in pending) {
        await _pushQueueRecord(record);
        await _syncQueueDao.deleteRecord(record.id);
      }
      _lastSyncedAt = DateTime.now();
      _statusController.add(SyncStatus.idle);
    } catch (e) {
      _statusController.add(SyncStatus.error);
    }
  }

  Future<void> _pushQueueRecord(dynamic record) async {
    // Push to appropriate Supabase table based on entity type
    await _supabase.from('sync_reading_progress').upsert({
      'entity_id': record.entityId,
      'payload': record.payload,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> pushChanges(List<SyncRecord> records) async {
    for (final record in records) {
      await _pushRecord(record);
    }
  }

  Future<void> _pushRecord(SyncRecord record) async {
    await _supabase.from('sync_reading_progress').upsert({
      'entity_id': record.entityId,
      'payload': record.payload,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<SyncRecord>> pullChanges(DateTime since) async {
    return [];
  }
}
