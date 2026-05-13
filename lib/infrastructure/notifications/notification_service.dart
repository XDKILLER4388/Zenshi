import 'package:flutter/foundation.dart';

/// Stub notification service — Firebase removed for v1.0 build.
/// Push notifications will be added in a future release.
class NotificationService {
  Future<void> initialize() async {
    debugPrint('NotificationService: stub — Firebase not configured');
  }

  Future<String?> getToken() async => null;
}
