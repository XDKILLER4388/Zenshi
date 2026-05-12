import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

// ── Notification category ──────────────────────────────────────────────────────

enum _NotificationCategory {
  newChapter,
  downloads,
  extensions,
  appUpdates,
}

// ── Mock notification model ────────────────────────────────────────────────────

class _AppNotification {
  final String id;
  final _NotificationCategory category;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? routeTarget;

  const _AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.routeTarget,
  });

  _AppNotification copyWith({bool? isRead}) => _AppNotification(
        id: id,
        category: category,
        title: title,
        body: body,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
        routeTarget: routeTarget,
      );
}

// ── Mock data ──────────────────────────────────────────────────────────────────

final _mockNotifications = [
  _AppNotification(
    id: '1',
    category: _NotificationCategory.newChapter,
    title: 'New Chapter Available',
    body: 'One Piece — Chapter 1110 is now available.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    routeTarget: '/manga/one-piece',
  ),
  _AppNotification(
    id: '2',
    category: _NotificationCategory.newChapter,
    title: 'New Chapter Available',
    body: 'Jujutsu Kaisen — Chapter 256 is now available.',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    isRead: true,
    routeTarget: '/manga/jjk',
  ),
  _AppNotification(
    id: '3',
    category: _NotificationCategory.downloads,
    title: 'Download Complete',
    body: 'Chainsaw Man — Chapter 150 downloaded successfully.',
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    isRead: true,
  ),
  _AppNotification(
    id: '4',
    category: _NotificationCategory.extensions,
    title: 'Extension Degraded',
    body: 'Manganato is experiencing issues. Consider switching to an alternative source.',
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    routeTarget: '/extensions',
  ),
  _AppNotification(
    id: '5',
    category: _NotificationCategory.appUpdates,
    title: 'App Update Available',
    body: 'Zenshi v1.1.0 is available with new features and bug fixes.',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
  ),
  _AppNotification(
    id: '6',
    category: _NotificationCategory.downloads,
    title: 'Download Failed',
    body: 'Demon Slayer — Chapter 205 failed to download. Tap to retry.',
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    isRead: true,
    routeTarget: '/downloads',
  ),
];

// ── Notifications provider ─────────────────────────────────────────────────────

class _NotificationsNotifier
    extends StateNotifier<List<_AppNotification>> {
  _NotificationsNotifier() : super(_mockNotifications);

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void markAsRead(String id) {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
  }
}

final _notificationsProvider =
    StateNotifierProvider<_NotificationsNotifier, List<_AppNotification>>(
  (_) => _NotificationsNotifier(),
);

// ── Notifications screen ───────────────────────────────────────────────────────

/// Notifications screen showing recent app notifications.
///
/// Features:
/// - Categories: New Chapters, Downloads, Extensions, App Updates
/// - Each notification: icon, title, body, time ago, read/unread indicator
/// - Tap to navigate to relevant screen
/// - Mark all as read button
/// - Empty state
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(_notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Notifications', style: AppTypography.titleMedium),
        actions: [
          if (unreadCount > 0)
            Semantics(
              label: 'Mark all notifications as read',
              child: TextButton(
                onPressed: () =>
                    ref.read(_notificationsProvider.notifier).markAllAsRead(),
                child: Text(
                  'Mark all read',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const _EmptyState()
          : _NotificationList(notifications: notifications),
    );
  }
}

// ── Notification list ──────────────────────────────────────────────────────────

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.notifications});

  final List<_AppNotification> notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group by category
    final grouped = <_NotificationCategory, List<_AppNotification>>{};
    for (final n in notifications) {
      grouped.putIfAbsent(n.category, () => []).add(n);
    }

    final categoryOrder = [
      _NotificationCategory.newChapter,
      _NotificationCategory.downloads,
      _NotificationCategory.extensions,
      _NotificationCategory.appUpdates,
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final category in categoryOrder)
          if (grouped.containsKey(category)) ...[
            _CategoryHeader(category: category),
            ...grouped[category]!.map(
              (n) => _NotificationItem(
                notification: n,
                onTap: () {
                  ref.read(_notificationsProvider.notifier).markAsRead(n.id);
                  if (n.routeTarget != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Navigate to ${n.routeTarget}'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
      ],
    );
  }
}

// ── Category header ────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});

  final _NotificationCategory category;

  @override
  Widget build(BuildContext context) {
    final label = switch (category) {
      _NotificationCategory.newChapter => 'New Chapters',
      _NotificationCategory.downloads => 'Downloads',
      _NotificationCategory.extensions => 'Extensions',
      _NotificationCategory.appUpdates => 'App Updates',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: AppTypography.titleSmall.copyWith(color: AppColors.onSurfaceMuted),
      ),
    );
  }
}

// ── Notification item ──────────────────────────────────────────────────────────

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  final _AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (notification.category) {
      _NotificationCategory.newChapter => Icons.auto_stories_outlined,
      _NotificationCategory.downloads => Icons.download_outlined,
      _NotificationCategory.extensions => Icons.extension_outlined,
      _NotificationCategory.appUpdates => Icons.system_update_outlined,
    };

    final iconColor = switch (notification.category) {
      _NotificationCategory.newChapter => AppColors.primary,
      _NotificationCategory.downloads => AppColors.success,
      _NotificationCategory.extensions => AppColors.warning,
      _NotificationCategory.appUpdates => AppColors.secondary,
    };

    return Semantics(
      label: '${notification.title}. ${notification.body}. '
          '${notification.isRead ? 'Read' : 'Unread'}. '
          '${_timeAgo(notification.timestamp)}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : AppColors.primary.withAlpha(10),
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.labelLarge.copyWith(
                              color: notification.isRead
                                  ? AppColors.onSurfaceMuted
                                  : AppColors.onBackground,
                            ),
                          ),
                        ),
                        // Unread dot
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppTypography.bodySmall.copyWith(
                        color: notification.isRead
                            ? AppColors.onSurfaceMuted
                            : AppColors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notification.timestamp),
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),

              // Navigate arrow (if tappable)
              if (notification.routeTarget != null)
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.onSurfaceMuted),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_none_outlined,
              size: 72,
              color: AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: 16),
            Text('No notifications', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up! Notifications about new chapters, downloads, and extensions will appear here.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
