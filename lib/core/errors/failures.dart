/// Sealed hierarchy of domain-level failures.
///
/// Use these in repository return types (e.g. `Either<Failure, T>`) or as
/// error payloads in Riverpod `AsyncError` states so the UI can render
/// appropriate error messages without depending on exception types.
sealed class Failure {
  const Failure({required this.message, this.cause});

  /// Human-readable description of what went wrong.
  final String message;

  /// The underlying exception or error, if available.
  final Object? cause;

  @override
  String toString() => '$runtimeType(message: $message)';
}

// ── Network ───────────────────────────────────────────────────────────────────

/// Raised when a network request fails due to connectivity issues, timeouts,
/// or non-2xx HTTP responses.
final class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.cause,
    this.statusCode,
  });

  /// HTTP status code, if the request reached the server.
  final int? statusCode;
}

// ── Cache / Local storage ─────────────────────────────────────────────────────

/// Raised when reading from or writing to the local cache or database fails.
final class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.cause});
}

// ── Authentication ────────────────────────────────────────────────────────────

/// Raised for authentication and authorisation errors (invalid credentials,
/// expired tokens, rate-limit exceeded, etc.).
final class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.cause});
}

// ── Extension ─────────────────────────────────────────────────────────────────

/// Raised when an extension fails to load, execute, or violates sandbox rules.
final class ExtensionFailure extends Failure {
  const ExtensionFailure({
    required super.message,
    super.cause,
    this.extensionId,
  });

  /// The ID of the extension that caused the failure, if known.
  final String? extensionId;
}

// ── Storage ───────────────────────────────────────────────────────────────────

/// Raised when device storage is insufficient or a file-system operation fails.
final class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.cause});
}

// ── Sync ──────────────────────────────────────────────────────────────────────

/// Raised when cloud synchronisation fails.
final class SyncFailure extends Failure {
  const SyncFailure({required super.message, super.cause});
}

// ── Validation ────────────────────────────────────────────────────────────────

/// Raised when user-supplied input or external data fails validation rules.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.cause,
    this.field,
  });

  /// The name of the field that failed validation, if applicable.
  final String? field;
}
