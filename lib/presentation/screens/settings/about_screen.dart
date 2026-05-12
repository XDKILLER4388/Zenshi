import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

/// About screen showing app info, links, and licenses.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('About', style: AppTypography.titleMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // App header
          Container(
            padding: const EdgeInsets.all(32),
            color: AppColors.surface,
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.auto_stories, size: 44, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text('Zenshi', style: AppTypography.headlineSmall),
                const SizedBox(height: 4),
                Text('Version 1.0.0', style: AppTypography.bodySmall),
                const SizedBox(height: 12),
                Text(
                  'A premium, offline-first manga, manhua, and manhwa reader with a modular extension system.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Links
          Semantics(
            label: 'Open GitHub repository',
            child: ListTile(
              leading: const Icon(Icons.code_outlined),
              title: Text('GitHub', style: AppTypography.labelLarge),
              subtitle: Text('View source code', style: AppTypography.bodySmall),
              trailing: const Icon(Icons.open_in_new, size: 16, color: AppColors.onSurfaceMuted),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('GitHub link coming soon')),
              ),
            ),
          ),
          Semantics(
            label: 'Open Privacy Policy',
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text('Privacy Policy', style: AppTypography.labelLarge),
              trailing: const Icon(Icons.open_in_new, size: 16, color: AppColors.onSurfaceMuted),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy coming soon')),
              ),
            ),
          ),
          Semantics(
            label: 'Open Terms of Service',
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text('Terms of Service', style: AppTypography.labelLarge),
              trailing: const Icon(Icons.open_in_new, size: 16, color: AppColors.onSurfaceMuted),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms of Service coming soon')),
              ),
            ),
          ),
          Semantics(
            label: 'View open source licenses',
            child: ListTile(
              leading: const Icon(Icons.balance_outlined),
              title: Text('Open Source Licenses', style: AppTypography.labelLarge),
              trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Zenshi',
                applicationVersion: '1.0.0',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
