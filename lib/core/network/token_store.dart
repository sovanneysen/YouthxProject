import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal JWT persistence seam.
///
/// [SecureTokenStore] is used on real devices (Android Keystore-backed,
/// iOS Keychain-backed). [MemoryTokenStore] exists so widget tests and
/// platforms without a working plugin channel still behave correctly.
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Persists the JWT via [FlutterSecureStorage].
class SecureTokenStore implements TokenStore {
  const SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'youthx_access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    if (kIsWeb) return null;
    try {
      return await _storage.read(key: _key);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> write(String token) async {
    if (kIsWeb) return;
    try {
      await _storage.write(key: _key, value: token);
    } on MissingPluginException {
      // fall back to a session-only token
    } on PlatformException {
      // fall back to a session-only token
    }
  }

  @override
  Future<void> clear() async {
    if (kIsWeb) return;
    try {
      await _storage.delete(key: _key);
    } on MissingPluginException {
      // no-op
    } on PlatformException {
      // no-op
    }
  }
}

/// In-memory fallback used by tests and offline development.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore();

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
