import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';

// ── Auth state notifier ────────────────────────────────────────────────────────

class AuthNotifier extends StreamNotifier<AuthState> {
  @override
  Stream<AuthState> build() {
    // Return guest state immediately — no external auth to avoid startup crashes
    return Stream.value(const AuthState(status: AuthStatus.guest));
  }

  Future<void> signInWithEmail(String email, String password) async {}
  Future<void> signInWithGoogle() async {}
  Future<void> signInWithDiscord() async {}
  Future<void> signInAsGuest() async {}
  Future<void> signOut() async {}
  Future<void> deleteAccount() async {}
}

/// Provider for [AuthNotifier].
final authProvider =
    StreamNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
