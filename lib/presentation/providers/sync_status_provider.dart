import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/sync_repository.dart';

/// Streams the current [SyncStatus] — returns idle immediately.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return Stream.value(SyncStatus.idle);
});
