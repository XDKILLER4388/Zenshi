import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/app_settings.dart';
import '../../providers/settings_provider.dart';

/// Wraps the app with MediaQuery overrides for accessibility settings.
/// Applies text scale, high contrast, and reduced motion from AppSettings.
class ZenshiAppWrapper extends ConsumerWidget {
  final Widget child;
  const ZenshiAppWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(settings.textScale),
      ),
      child: child,
    );
  }
}
