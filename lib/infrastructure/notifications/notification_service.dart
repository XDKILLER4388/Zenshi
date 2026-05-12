import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Handles FCM push notification setup and routing.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Requests notification permissions and sets up message handlers.
  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Get FCM token for this device
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show in-app notification banner
    debugPrint('Foreground message: ${message.notification?.title}');
  }

  void _handleMessageTap(RemoteMessage message) {
    // Route to appropriate screen based on message data
    final type = message.data['type'];
    debugPrint('Message tapped: type=$type');
  }

  /// Returns the FCM token for registering with Supabase.
  Future<String?> getToken() => _messaging.getToken();
}
