import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import 'repository_providers.dart';

// ── Auth state notifier ────────────────────────────────────────────────────────

/// Watches the [AuthRepository] stream and exposes sign-in / sign-out actions.
///
/// The provider emits [AsyncValue<AuthState>] so the UI can handle loading,
/// error, and data states uniformly.
class AuthNotifier extends StreamNotifier<AuthState> {
  @override
  Stream<AuthState> build() {
    return ref.watch(authRepositoryProvider).watchAuthState();
  }

  Future<void> signInWithEmail(String email, String password) async {
    await ref.read(authRepositoryProvider).signInWithEmail(email, password);
  }

  Future<void> signInWithGoogle() async {
    await ref.read(authRepositoryProvider).signInWithGoogle();
  }

  Future<void> signInWithDiscord() async {
    await ref.read(authRepositoryProvider).signInWithDiscord();
  }

  Future<void> signInAsGuest() async {
    await ref.read(authRepositoryProvider).signInAsGuest();
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
  }
}

/// Provider for [AuthNotifier].
final authProvider =
    StreamNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
