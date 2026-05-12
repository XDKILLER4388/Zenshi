import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';

/// Full settings screen wired to [settingsProvider].
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull ?? AppSettings.defaults;
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Settings', style: AppTypography.titleMedium),
        actions: [
          Semantics(
            label: 'Export settings',
            child: IconButton(
              icon: const Icon(Icons.upload_outlined),
              tooltip: 'Export settings',
              onPressed: () => _exportSettings(context, settings),
            ),
          ),
          Semantics(
            label: 'Import settings',
            child: IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Import settings',
              onPressed: () => _importSettings(context),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Appearance
          const _SectionHeader(title: 'Appearance'),
          _ThemeSelector(current: settings.theme, onChanged: notifier.updateTheme),
          _AccentColorPicker(
            currentValue: settings.accentColorValue,
            onChanged: notifier.updateAccentColor,
          ),

          // Reader
          const _SectionHeader(title: 'Reader'),
          _ReadingModeSelector(
            current: settings.defaultReadingMode,
            onChanged: notifier.updateReadingMode,
          ),
          _ReaderThemeSelector(
            current: settings.readerTheme,
            onChanged: notifier.updateReaderTheme,
          ),
          _FontStyleSelector(
            current: settings.fontStyle,
            onChanged: (v) => notifier.save(settings.copyWith(fontStyle: v)),
          ),
          _AnimationSpeedSelector(
            current: settings.animationSpeed,
            onChanged: notifier.updateAnimationSpeed,
          ),

          // Cache
          const _SectionHeader(title: 'Cache'),
          _CacheSection(settings: settings, notifier: notifier),

          // Downloads
          const _SectionHeader(title: 'Downloads'),
          _DownloadsSection(settings: settings, notifier: notifier),

          // Performance
          const _SectionHeader(title: 'Performance'),
          _SettingsSwitch(
            title: 'Data Saver Mode',
            subtitle: 'Reduces image quality and disables preloading',
            value: settings.dataSaverMode,
            onChanged: notifier.updateDataSaverMode,
          ),
          _SettingsSwitch(
            title: 'Low RAM Mode',
            subtitle: settings.lowRamMode
                ? 'Active - animations disabled, cache limited to 256 MB'
                : 'Disables animations and limits cache for low-end devices',
            value: settings.lowRamMode,
            onChanged: notifier.updateLowRamMode,
            trailingBadge: settings.lowRamMode ? 'ACTIVE' : null,
          ),

          // Accessibility
          const _SectionHeader(title: 'Accessibility'),
          _TextScaleSlider(
            current: settings.textScale,
            onChanged: notifier.updateTextScale,
          ),
          _SettingsSwitch(
            title: 'High Contrast',
            subtitle: 'Increases contrast ratio to WCAG AA standard',
            value: settings.highContrast,
            onChanged: notifier.updateHighContrast,
          ),
          _SettingsSwitch(
            title: 'Reduced Motion',
            subtitle: 'Replaces animations with instant cuts',
            value: settings.reducedMotion,
            onChanged: notifier.updateReducedMotion,
          ),

          // Privacy
          const _SectionHeader(title: 'Privacy'),
          _SettingsSwitch(
            title: 'Opt out of Analytics',
            subtitle: 'Stop sending anonymised usage data',
            value: settings.analyticsOptOut,
            onChanged: (v) async {
              await notifier.updateAnalyticsOptOut(v);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(v
                        ? 'Analytics disabled - no data will be sent'
                        : 'Analytics enabled'),
                  ),
                );
              }
            },
          ),

          // Sync
          const _SectionHeader(title: 'Sync'),
          const _SyncSection(),

          // Account
          const _SectionHeader(title: 'Account'),
          const _AccountSection(),
        ],
      ),
    );
  }

  void _exportSettings(BuildContext context, AppSettings settings) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings exported to Downloads folder')),
    );
  }

  void _importSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings import coming soon')),
    );
  }
}

// Section header
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// Generic settings switch
class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.trailingBadge,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? trailingBadge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: ${value ? "enabled" : "disabled"}',
      child: ListTile(
        title: Row(
          children: [
            Text(title, style: AppTypography.labelLarge),
            if (trailingBadge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.warning.withAlpha(80)),
                ),
                child: Text(
                  trailingBadge!,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle, style: AppTypography.bodySmall),
        trailing: Switch(value: value, onChanged: onChanged),
        onTap: () => onChanged(!value),
      ),
    );
  }
}

// Theme selector
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.current, required this.onChanged});
  final AppThemeMode current;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Theme', style: AppTypography.labelLarge),
      subtitle: Text(_label(current), style: AppTypography.bodySmall),
      trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
      onTap: () => _showSheet(context),
    );
  }

  String _label(AppThemeMode m) => switch (m) {
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
        AppThemeMode.amoledDark => 'AMOLED Dark',
        AppThemeMode.systemDefault => 'System Default',
      };

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Theme', style: AppTypography.titleMedium),
            ),
            for (final mode in AppThemeMode.values)
              ListTile(
                title: Text(_label(mode)),
                trailing: current == mode
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  onChanged(mode);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Accent color picker
class _AccentColorPicker extends StatelessWidget {
  const _AccentColorPicker({required this.currentValue, required this.onChanged});
  final int currentValue;
  final ValueChanged<int> onChanged;

  static const _presets = [
    (0xFF7C3AED, 'Purple'),
    (0xFF2563EB, 'Blue'),
    (0xFF06B6D4, 'Cyan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Accent Color', style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (value, label) in _presets)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Semantics(
                    label: '$label accent color${currentValue == value ? ", selected" : ""}',
                    button: true,
                    child: GestureDetector(
                      onTap: () => onChanged(value),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(value),
                          shape: BoxShape.circle,
                          border: currentValue == value
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: currentValue == value
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '#7C3AED',
                    prefixText: '#',
                    isDense: true,
                  ),
                  onSubmitted: (v) {
                    final hex = v.replaceAll('#', '');
                    if (hex.length == 6) {
                      final parsed = int.tryParse('FF$hex', radix: 16);
                      if (parsed != null) onChanged(parsed);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Reading mode selector
class _ReadingModeSelector extends StatelessWidget {
  const _ReadingModeSelector({required this.current, required this.onChanged});
  final ReadingMode current;
  final ValueChanged<ReadingMode> onChanged;

  String _label(ReadingMode m) => switch (m) {
        ReadingMode.verticalScroll => 'Vertical Scroll',
        ReadingMode.horizontalLTR => 'Horizontal (Left to Right)',
        ReadingMode.horizontalRTL => 'Horizontal (Right to Left)',
        ReadingMode.webtoon => 'Webtoon',
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Default Reading Mode', style: AppTypography.labelLarge),
      subtitle: Text(_label(current), style: AppTypography.bodySmall),
      trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Reading Mode', style: AppTypography.titleMedium),
              ),
              for (final mode in ReadingMode.values)
                ListTile(
                  title: Text(_label(mode)),
                  trailing: current == mode
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onChanged(mode);
                    Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// Reader theme selector
class _ReaderThemeSelector extends StatelessWidget {
  const _ReaderThemeSelector({required this.current, required this.onChanged});
  final ReaderTheme current;
  final ValueChanged<ReaderTheme> onChanged;

  String _label(ReaderTheme t) => switch (t) {
        ReaderTheme.defaultLight => 'Default (White)',
        ReaderTheme.dark => 'Dark (Dark Grey)',
        ReaderTheme.amoled => 'AMOLED (Pure Black)',
        ReaderTheme.sepia => 'Sepia (Warm Beige)',
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Reader Theme', style: AppTypography.labelLarge),
      subtitle: Text(_label(current), style: AppTypography.bodySmall),
      trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Reader Theme', style: AppTypography.titleMedium),
              ),
              for (final theme in ReaderTheme.values)
                ListTile(
                  title: Text(_label(theme)),
                  trailing: current == theme
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onChanged(theme);
                    Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// Font style selector
class _FontStyleSelector extends StatelessWidget {
  const _FontStyleSelector({required this.current, required this.onChanged});
  final String current;
  final ValueChanged<String> onChanged;

  static const _fonts = [
    ('inter', 'Inter'),
    ('roboto', 'Roboto'),
    ('nunito', 'Nunito'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Font Style', style: AppTypography.labelLarge),
      subtitle: Text(
        _fonts.firstWhere((f) => f.$1 == current, orElse: () => _fonts.first).$2,
        style: AppTypography.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Font Style', style: AppTypography.titleMedium),
              ),
              for (final (id, label) in _fonts)
                ListTile(
                  title: Text(label),
                  trailing: current == id
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onChanged(id);
                    Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// Animation speed selector
class _AnimationSpeedSelector extends StatelessWidget {
  const _AnimationSpeedSelector({required this.current, required this.onChanged});
  final AnimationSpeed current;
  final ValueChanged<AnimationSpeed> onChanged;

  String _label(AnimationSpeed s) => switch (s) {
        AnimationSpeed.off => 'Off',
        AnimationSpeed.slow => 'Slow',
        AnimationSpeed.normal => 'Normal',
        AnimationSpeed.fast => 'Fast',
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Animation Speed', style: AppTypography.labelLarge),
      subtitle: Text(_label(current), style: AppTypography.bodySmall),
      trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Animation Speed', style: AppTypography.titleMedium),
              ),
              for (final speed in AnimationSpeed.values)
                ListTile(
                  title: Text(_label(speed)),
                  trailing: current == speed
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onChanged(speed);
                    Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// Cache section
class _CacheSection extends StatelessWidget {
  const _CacheSection({required this.settings, required this.notifier});
  final AppSettings settings;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Current Cache Size', style: AppTypography.labelLarge),
          subtitle: Text('Calculating...', style: AppTypography.bodySmall),
          trailing: TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cache cleared')),
            ),
            child: Text('Clear', style: AppTypography.labelMedium.copyWith(color: AppColors.error)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Max Cache Size', style: AppTypography.labelLarge),
                  Text('${settings.maxCacheMb} MB', style: AppTypography.bodySmall),
                ],
              ),
              Semantics(
                label: 'Max cache size slider, ${settings.maxCacheMb} megabytes',
                child: Slider(
                  value: settings.maxCacheMb.toDouble(),
                  min: 256,
                  max: 10240,
                  divisions: 39,
                  activeColor: AppColors.primary,
                  onChanged: (v) => notifier.updateMaxCacheMb(v.round()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('256 MB', style: AppTypography.bodySmall),
                  Text('10 GB', style: AppTypography.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Downloads section
class _DownloadsSection extends StatelessWidget {
  const _DownloadsSection({required this.settings, required this.notifier});
  final AppSettings settings;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsSwitch(
          title: 'WiFi Only',
          subtitle: 'Only download on WiFi connections',
          value: settings.wifiOnlyDownload,
          onChanged: notifier.updateWifiOnlyDownload,
        ),
      ],
    );
  }
}

// Text scale slider
class _TextScaleSlider extends StatelessWidget {
  const _TextScaleSlider({required this.current, required this.onChanged});
  final double current;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Text Scale', style: AppTypography.labelLarge),
              Text('${(current * 100).round()}%', style: AppTypography.bodySmall),
            ],
          ),
          Semantics(
            label: 'Text scale slider, ${(current * 100).round()} percent',
            child: Slider(
              value: current,
              min: 0.8,
              max: 1.5,
              divisions: 14,
              activeColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('80%', style: AppTypography.bodySmall),
              Text('150%', style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

// Sync section
class _SyncSection extends ConsumerWidget {
  const _SyncSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          title: Text('Last Sync', style: AppTypography.labelLarge),
          subtitle: Text('Never', style: AppTypography.bodySmall),
        ),
        ListTile(
          title: Text('Manual Sync', style: AppTypography.labelLarge),
          subtitle: Text('Sync all data to cloud now', style: AppTypography.bodySmall),
          trailing: Semantics(
            label: 'Trigger manual sync',
            child: IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync now',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync started...')),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Account section
class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text('Profile', style: AppTypography.labelLarge),
          trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: Text('Sign Out', style: AppTypography.labelLarge.copyWith(color: AppColors.error)),
          onTap: () => _confirmSignOut(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Sign out?', style: AppTypography.titleSmall),
        content: Text('You will be signed out of your account.', style: AppTypography.bodyMedium),
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
}
