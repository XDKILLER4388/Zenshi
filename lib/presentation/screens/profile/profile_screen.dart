import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../../core/router/app_router.dart';

/// Profile screen showing user info and account actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final authState = authAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Profile', style: AppTypography.titleMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Avatar + info
          Container(
            padding: const EdgeInsets.all(24),
            color: AppColors.surface,
            child: Column(
              children: [
                Semantics(
                  label: 'User avatar',
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withAlpha(40),
                    child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  authState?.email ?? 'Guest User',
                  style: AppTypography.titleMedium,
                ),
                if (authState?.email != null)
                  Text(
                    authState!.email!,
                    style: AppTypography.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Links
          Semantics(
            label: 'Go to Settings',
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text('Settings', style: AppTypography.labelLarge),
              trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
              onTap: () => context.push(Routes.settings),
            ),
          ),
          Semantics(
            label: 'Go to Reading History',
            child: ListTile(
              leading: const Icon(Icons.history_outlined),
              title: Text('Reading History', style: AppTypography.labelLarge),
              trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
              onTap: () => context.push(Routes.readingHistory),
            ),
          ),
          Semantics(
            label: 'Go to About',
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('About', style: AppTypography.labelLarge),
              trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
              onTap: () => context.push(Routes.about),
            ),
          ),

          const Divider(color: AppColors.divider),

          // Sign out
          Semantics(
            label: 'Sign out',
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'Sign Out',
                style: AppTypography.labelLarge.copyWith(color: AppColors.error),
              ),
              onTap: () => _confirmSignOut(context, ref),
            ),
          ),

          // Account deletion
          Semantics(
            label: 'Delete account',
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
              title: Text(
                'Delete Account',
                style: AppTypography.labelLarge.copyWith(color: AppColors.error),
              ),
              subtitle: Text(
                'Permanently deletes all your data',
                style: AppTypography.bodySmall,
              ),
              onTap: () => _showAccountDeletionDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Sign out?', style: AppTypography.titleSmall),
        content: Text(
          'You will be signed out of your account.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  Future<void> _showAccountDeletionDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete account?', style: AppTypography.titleSmall),
        content: Text(
          'This will permanently delete your account and all associated data within 30 days. This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).deleteAccount();
    }
  }
}
