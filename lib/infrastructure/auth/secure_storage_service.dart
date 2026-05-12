import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps [FlutterSecureStorage] to provide typed access to auth-related
/// secrets stored in the Android Keystore (via EncryptedSharedPreferences).
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keySessionToken = 'session_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyIsGuest = 'is_guest';
  static const _keyFailedAttempts = 'failed_attempts';
  static const _keyLockUntil = 'lock_until';

  // ── Session token ──────────────────────────────────────────────────────────

  Future<void> saveSessionToken(String token) async {
    await _storage.write(key: _keySessionToken, value: token);
  }

  Future<String?> getSessionToken() async {
    return _storage.read(key: _keySessionToken);
  }

  // ── Refresh token ──────────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  // ── Guest mode ─────────────────────────────────────────────────────────────

  Future<void> setGuestMode(bool isGuest) async {
    await _storage.write(key: _keyIsGuest, value: isGuest.toString());
  }

  Future<bool> isGuestMode() async {
    final value = await _storage.read(key: _keyIsGuest);
    return value == 'true';
  }

  // ── Rate-limiting ──────────────────────────────────────────────────────────

  Future<int> getFailedAttempts() async {
    final value = await _storage.read(key: _keyFailedAttempts);
    return int.tryParse(value ?? '0') ?? 0;
  }

  Future<void> incrementFailedAttempts() async {
    final current = await getFailedAttempts();
    await _storage.write(
      key: _keyFailedAttempts,
      value: (current + 1).toString(),
    );
  }

  Future<void> resetFailedAttempts() async {
    await _storage.write(key: _keyFailedAttempts, value: '0');
  }

  Future<DateTime?> getLockUntil() async {
    final value = await _storage.read(key: _keyLockUntil);
    if (value == null) return null;
    final ms = int.tryParse(value);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLockUntil(DateTime? lockUntil) async {
    if (lockUntil == null) {
      await _storage.delete(key: _keyLockUntil);
    } else {
      await _storage.write(
        key: _keyLockUntil,
        value: lockUntil.millisecondsSinceEpoch.toString(),
      );
    }
  }

  // ── Bulk clear ─────────────────────────────────────────────────────────────

  /// Deletes all stored secrets (called on sign-out).
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
