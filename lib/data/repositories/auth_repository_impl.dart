import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthState;

import '../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../infrastructure/auth/secure_storage_service.dart';

/// Maximum failed login attempts before the account is temporarily locked.
const _kMaxFailedAttempts = 10;

/// Lock duration after exceeding [_kMaxFailedAttempts].
const _kLockDuration = Duration(hours: 1);

/// Concrete implementation of [AuthRepository] backed by Supabase Auth and
/// [SecureStorageService] for local credential storage.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required SupabaseClient supabase,
    required SecureStorageService storage,
  })  : _supabase = supabase,
        _storage = storage {
    // Bridge Supabase auth state changes into our own stream.
    _supabase.auth.onAuthStateChange.listen(
      (data) {
        final session = data.session;
        if (session != null) {
          _storage.saveSessionToken(session.accessToken);
          if (session.refreshToken != null) {
            _storage.saveRefreshToken(session.refreshToken!);
          }
          _controller.add(
            AuthState(
              status: AuthStatus.authenticated,
              userId: session.user.id,
              email: session.user.email,
            ),
          );
        } else {
          _controller.add(
            const AuthState(status: AuthStatus.unauthenticated),
          );
        }
      },
      onError: (Object error) {
        _controller.addError(error);
      },
    );
  }

  final SupabaseClient _supabase;
  final SecureStorageService _storage;

  final _controller = StreamController<AuthState>.broadcast();

  // ── AuthRepository ─────────────────────────────────────────────────────────

  @override
  Stream<AuthState> watchAuthState() => _controller.stream;

  @override
  bool get isAuthenticated {
    final session = _supabase.auth.currentSession;
    return session != null && !_isGuestSync;
  }

  @override
  bool get isGuest => _isGuestSync;

  // Synchronous guest check backed by a cached flag updated on each call.
  bool _isGuestSync = false;

  // ── Sign-in methods ────────────────────────────────────────────────────────

  @override
  Future<void> signInWithEmail(String email, String password) async {
    // Rate-limiting guard.
    final lockUntil = await _storage.getLockUntil();
    if (lockUntil != null && lockUntil.isAfter(DateTime.now())) {
      final formatted = _formatTime(lockUntil);
      throw AuthFailure(
        message: 'Account locked. Try again at $formatted',
      );
    }

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      if (session == null) {
        throw const AuthFailure(message: 'Sign-in failed. Please try again.');
      }

      // Successful sign-in — reset rate-limit counters.
      await _storage.resetFailedAttempts();
      await _storage.setLockUntil(null);
      await _storage.setGuestMode(false);
      _isGuestSync = false;
    } on AuthFailure {
      rethrow;
    } catch (e) {
      await _handleSignInFailure();
      throw AuthFailure(
        message: 'Email or password incorrect.',
        cause: e,
      );
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      throw AuthFailure(
        message: 'Google sign-in failed. Please try again.',
        cause: e,
      );
    }
  }

  @override
  Future<void> signInWithDiscord() async {
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.discord);
    } catch (e) {
      throw AuthFailure(
        message: 'Discord sign-in failed. Please try again.',
        cause: e,
      );
    }
  }

  @override
  Future<void> signInAsGuest() async {
    await _storage.setGuestMode(true);
    _isGuestSync = true;
    _controller.add(const AuthState(status: AuthStatus.guest));
  }

  // ── Sign-out / account deletion ────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Best-effort sign-out; always clear local state.
    }
    await _storage.clearAll();
    _isGuestSync = false;
    _controller.add(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        // Call a Supabase RPC that handles server-side account deletion.
        await _supabase.rpc('delete_user_account');
      }
    } catch (e) {
      throw AuthFailure(
        message: 'Account deletion failed. Please try again.',
        cause: e,
      );
    }
    await signOut();
  }

  // ── Token refresh ──────────────────────────────────────────────────────────

  /// Attempts a silent token refresh. On network failure, emits
  /// [SyncStatus.offline] rather than signing the user out.
  Future<void> refreshTokenIfNeeded() async {
    try {
      await _supabase.auth.refreshSession();
    } on AuthException catch (e) {
      if (_isNetworkError(e)) {
        // Network unavailable — keep local session alive; sync will retry.
        return;
      }
      rethrow;
    } catch (e) {
      if (_isNetworkError(e)) return;
      rethrow;
    }
  }

  /// Checks whether [error] is a 401 and, if so, attempts a token refresh.
  Future<void> handleAuthError(Object error) async {
    final is401 = error is AuthException && error.statusCode == '401';
    if (is401) {
      await refreshTokenIfNeeded();
    }
  }

  // ── Guest migration ────────────────────────────────────────────────────────

  /// Migrates a guest session to a full account by signing up with
  /// [email] and [password], then clearing the guest flag.
  Future<void> migrateGuestToAccount(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final session = response.session;
      if (session == null) {
        throw const AuthFailure(
          message: 'Account creation failed. Please try again.',
        );
      }

      await _storage.setGuestMode(false);
      _isGuestSync = false;

      _controller.add(
        AuthState(
          status: AuthStatus.authenticated,
          userId: session.user.id,
          email: session.user.email,
        ),
      );
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(
        message: 'Account creation failed. Please try again.',
        cause: e,
      );
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _handleSignInFailure() async {
    await _storage.incrementFailedAttempts();
    final attempts = await _storage.getFailedAttempts();
    if (attempts >= _kMaxFailedAttempts) {
      final lockUntil = DateTime.now().add(_kLockDuration);
      await _storage.setLockUntil(lockUntil);
    }
  }

  bool _isNetworkError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('timeout');
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void dispose() {
    _controller.close();
  }
}
