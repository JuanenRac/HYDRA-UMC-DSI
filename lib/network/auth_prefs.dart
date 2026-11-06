// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/auth_prefs.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Persists the last server (host/port) across app launches via
// shared_preferences - not secrets, so a plain preferences file is the right
// store for them - and the session (token, user name, refresh token).
//
// The session rules (secure storage only, a failed save reverts what it wrote,
// a renewal keeps the refresh token and a sign-in replaces it, the logged-out
// marker is set before the secure delete, a legacy plain token is moved in)
// are the ones every mobile app shares: they live in `SessionStore` of the
// shared Dart package (see the SDK's docs/SESSION_STORE.md) and are checked
// against its conformance vectors. This file only supplies the platform's
// storage: `flutter_secure_storage` (libsecret's Secret Service on Linux, the kiosk's target; Keychain on iOS/macOS; Keystore-backed storage on Android/Windows) and
// shared_preferences for the plain markers.
// =============================================================================

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hydra_umc_app_common/hydra_umc_app_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tests inject a fake of this seam instead of a real platform channel.
export 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show SecureTokenBackend;

class FlutterSecureStorageBackend implements SecureTokenBackend {
  FlutterSecureStorageBackend([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// The plain markers of the session, kept in ordinary shared preferences.
class _SharedPreferencesPlain implements SessionPlainStore {
  @override
  Future<bool?> getBool(String key) async => (await SharedPreferences.getInstance()).getBool(key);

  @override
  Future<String?> getString(String key) async => (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> setBool(String key, bool value) async {
    await (await SharedPreferences.getInstance()).setBool(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await (await SharedPreferences.getInstance()).remove(key);
  }
}

class AuthPrefs {
  AuthPrefs({SecureTokenBackend? secureBackend})
    : _session = SessionStore(
        secure: secureBackend ?? FlutterSecureStorageBackend(),
        plain: _SharedPreferencesPlain(),
        log: debugPrint,
      );

  static const _keyHost = 'hydra_host';
  static const _keyPort = 'hydra_port';
  static const _keyUseTls = 'hydra_use_tls';

  final SessionStore _session;

  Future<void> saveConnection(String host, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHost, host);
    await prefs.setInt(_keyPort, port);
  }

  Future<(String, int)?> loadConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString(_keyHost);
    final port = prefs.getInt(_keyPort);
    if (host == null || port == null) return null;
    return (host, port);
  }

  // `refreshToken` is optional and named so an older caller (or a server
  // predating refresh-token support) leaves whatever refresh token was
  // already stored untouched rather than wiping it. `replaceRefreshToken` is
  // for a real login: an absent refreshToken then DELETES the stored one, so
  // a refresh token left behind by a previous account can never become valid
  // again for the account that signs in next.
  Future<void> saveToken(
    String token,
    String username, {
    String? refreshToken,
    bool replaceRefreshToken = false,
  }) => _session.saveSession(
    token,
    username,
    refreshToken: refreshToken,
    replaceRefreshToken: replaceRefreshToken,
  );

  /// The scheme the saved server was last seen answering. Once it spoke TLS
  /// the app starts on https and never probes it over plain http again.
  Future<void> saveUseTls(bool useTls) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseTls, useTls);
  }

  Future<bool> loadUseTls() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseTls) ?? false;
  }

  Future<String?> loadToken() => _session.loadToken();

  Future<String?> loadUsername() => _session.loadUsername();

  /// The opaque refresh token, or null: no refresh token on file is a real,
  /// expected state, not an error.
  Future<String?> loadRefreshToken() => _session.loadRefreshToken();

  Future<void> clearToken() => _session.clearSession();
}
