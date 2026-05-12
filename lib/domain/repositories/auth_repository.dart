/// Authentication status values.
enum AuthStatus { authenticated, guest, unauthenticated }

/// Immutable snapshot of the current authentication state.
class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? email;

  const AuthState({
    required this.status,
    this.userId,
    this.email,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.status == status &&
        other.userId == userId &&
        other.email == email;
  }

  @override
  int get hashCode => Object.hash(status, userId, email);

  @override
  String toString() =>
      'AuthState(status: $status, userId: $userId, email: $email)';
}

/// Abstract interface for authentication operations.
abstract class AuthRepository {
  /// Signs in with [email] and [password].
  Future<void> signInWithEmail(String email, String password);

  /// Signs in via Google OAuth.
  Future<void> signInWithGoogle();

  /// Signs in via Discord OAuth.
  Future<void> signInWithDiscord();

  /// Creates a local-only guest session.
  Future<void> signInAsGuest();

  /// Signs out the current user and clears the local session.
  Future<void> signOut();

  /// Permanently deletes the current user's account and all associated data.
  Future<void> deleteAccount();

  /// Emits the current auth state and any subsequent changes.
  Stream<AuthState> watchAuthState();

  /// Whether a non-guest user is currently authenticated.
  bool get isAuthenticated;

  /// Whether the current session is a guest session.
  bool get isGuest;
}
