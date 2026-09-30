import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/local_profile_model.dart';

/// Device-local persistence for the profile fields the backend cannot store.
///
/// Mirrors the existing `TokenStore` seam: an interface plus a real
/// implementation and an in-memory one for tests and offline runs.
///
/// Every method is scoped by [userId]. A blank id is rejected rather than
/// falling back to a shared bucket, so a signed-out session can never read or
/// overwrite another account's values.
abstract class LocalProfileStore {
  /// Stored profile for [userId], or null when nothing is stored.
  Future<LocalProfile?> read(String userId);

  Future<void> write(String userId, LocalProfile profile);

  Future<void> clear(String userId);
}

/// Base in-memory store shared by the app's offline fallback and tests.
class MemoryLocalProfileStore implements LocalProfileStore {
  final Map<String, LocalProfile> _entries = <String, LocalProfile>{};

  @override
  Future<LocalProfile?> read(String userId) async {
    if (userId.isEmpty) return null;
    return _entries[userId];
  }

  @override
  Future<void> write(String userId, LocalProfile profile) async {
    if (userId.isEmpty) return;
    _entries[userId] = profile;
  }

  @override
  Future<void> clear(String userId) async {
    _entries.remove(userId);
  }
}

/// `SharedPreferences` implementation used on real devices.
class SharedPreferencesLocalProfileStore implements LocalProfileStore {
  const SharedPreferencesLocalProfileStore();

  /// Versioned so a future shape change cannot read older values.
  static const String _keyPrefix = 'youthx_local_profile_v1_';

  String _key(String userId) => '$_keyPrefix$userId';

  @override
  Future<LocalProfile?> read(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return LocalProfile.fromJson(decoded);
    } catch (_) {
      // A corrupt entry or an unavailable plugin channel must not break the
      // profile screen, so an unreadable record is treated as "not set".
      return null;
    }
  }

  @override
  Future<void> write(String userId, LocalProfile profile) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(userId), jsonEncode(profile.toJson()));
    } catch (_) {
      // Best effort: the value already lives in memory for this session.
      return;
    }
  }

  @override
  Future<void> clear(String userId) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (_) {
      return;
    }
  }
}

