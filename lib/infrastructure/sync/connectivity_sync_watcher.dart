import 'package:connectivity_plus/connectivity_plus.dart';

/// Watches connectivity changes and triggers sync when connection is restored.
class ConnectivitySyncWatcher {
  final Connectivity _connectivity = Connectivity();

  void startWatching(Future<void> Function() onConnected) {
    _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) onConnected();
    });
  }
}
