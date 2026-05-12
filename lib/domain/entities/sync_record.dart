import 'package:flutter/foundation.dart';

enum SyncEntityType { readingProgress, library, settings, collection, tag }

enum SyncOperation { upsert, delete }

/// Immutable domain entity representing a pending or completed sync operation.
@immutable
class SyncRecord {
  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const SyncRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncRecord &&
        other.id == id &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        other.operation == operation &&
        mapEquals(other.payload, payload) &&
        other.createdAt == createdAt &&
        other.retryCount == retryCount;
  }

  @override
  int get hashCode => Object.hash(
        id,
        entityType,
        entityId,
        operation,
        Object.hashAll(payload.entries.map((e) => Object.hash(e.key, e.value))),
        createdAt,
        retryCount,
      );

  @override
  String toString() =>
      'SyncRecord(id: $id, entityType: $entityType, entityId: $entityId, '
      'operation: $operation, retryCount: $retryCount)';
}
