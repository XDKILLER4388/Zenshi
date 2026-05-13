import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/app_settings.dart';
import '../../providers/settings_provider.dart';

/// Wraps the app with MediaQuery overrides for accessibility settings.
/// Falls back to defaults if settings are not yet loaded.
class ZenshiAppWrapper extends ConsumerWidget {
  final Widget child;
  const ZenshiAppWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Safely read settings — use defaults if not loaded or errored
    AppSettings settings;
    try {
      settings = ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    } catch (_) {
      settings = AppSettings.defaults;
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(settings.textScale.clamp(0.8, 1.5)),
      ),
      child: child,
    );
  }
}
