// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/auth_prefs.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Persists the last server (host/port) across app launches via
// shared_preferences - host/port are not secrets, so a plain preferences
// file is a real, appropriate store for them. This app runs as a kiosk on
// an embedded panel that's expected to stay logged in across a power-cycle
// of the CM5 itself, not just a normal app relaunch, so the session token
// itself is handled separately below.
//
// DSI-01 (found in an ecosystem-wide software-improvements audit, P1): the
// session token used to live in the exact same SharedPreferences file as
// host/port - a plain, unencrypted store, not a secrets vault. Token
// reads/writes now go through `SecureTokenBackend`, backed by
// `flutter_secure_storage` (libsecret's real Secret Service on Linux -
// this app's actual deployment target - Keychain on iOS/macOS, Keystore-
// backed encrypted storage on Android/Windows).
//
// REV-011 (found in an independent revalidation audit, P1): DSI-01 above
// wrapped every secure call so a failure fell back to writing the token in
// PLAIN SharedPreferences - the exact failure of the protection mechanism
// itself silently removing the guarantee it was meant to provide. A bare
// kiosk image with no Secret Service provider now keeps the session in
// memory ONLY, for the current app run - never persisted to disk, and
// never written in plaintext automatically. A real restart/power-cycle on
// that specific (secure-storage-broken) device requires logging in again;
// this never regresses a device where secure storage genuinely works,
// this app's real, intended deployment target. A token already saved
// under the pre-DSI-01 plain key is still migrated into secure storage
// (and the old copy removed) the first time it is successfully read back
// - that is reading pre-existing legacy data, not a new plaintext write.
//
// V07-015 (found in an independent revalidation audit, P1): two real
// gaps found by static inspection of the two functions below. First,
// `clearToken()` caught a failed secure-storage `delete()` and just
// logged it - a real logout could return successfully while the old
// token was still sitting in secure storage, letting a later
// `loadToken()` (a real restart, say) resurrect the "cleared" session.
// Second, `saveToken()` wrote the token and username as two SEPARATE
// secure-storage calls - if the token write succeeded but the username
// write then failed, the catch block reported the whole session as
// in-memory-only, while secure storage was actually left holding a real,
// orphaned token with no matching username. Fixed with a plain,
// non-secret `_keyLoggedOut` marker in ordinary SharedPreferences: it is
// the real source of truth `loadToken()`/`loadUsername()` check FIRST,
// set BEFORE `clearToken()` ever attempts the real secure delete (so a
// failed delete can never un-invalidate a real logout), and cleared only
// by a fresh, successful `saveToken()`. `saveToken()` itself now reverts
// (best-effort) whatever it did manage to write if a later step in the
// same call fails, so secure storage never holds half of a session.
// =============================================================================

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The real seam this file is tested through - `FlutterSecureStorageBackend`
/// is the genuine platform-backed implementation used in production;
/// tests inject a fake instead of exercising a real platform channel.
abstract class SecureTokenBackend {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class FlutterSecureStorageBackend implements SecureTokenBackend {
  FlutterSecureStorageBackend([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class AuthPrefs {
  AuthPrefs({SecureTokenBackend? secureBackend}) : _secure = secureBackend ?? FlutterSecureStorageBackend();

  static const _keyHost = 'hydra_host';
  static const _keyPort = 'hydra_port';
  // Legacy, plaintext SharedPreferences keys - only ever written now as a
  // real fallback when secure storage is genuinely unavailable, and read
  // once as a migration source.
  static const _keyToken = 'hydra_token';
  static const _keyUsername = 'hydra_username';
  // C08: the opaque refresh token HYDRA-UMC-SERVER's own POST /api/login
  // now also returns (refresh_tokens.ts) - same secure-storage treatment
  // as the access token itself (never a legacy plaintext fallback; an
  // in-memory-only session if secure storage is genuinely unavailable).
  // No migration path needed the way _keyToken has one: this key simply
  // didn't exist before this feature, so an absent value here just means
  // "this session predates refresh-token support" - loadRefreshToken()
  // returning null is a normal, expected state, not a broken one.
  static const _keyRefreshToken = 'hydra_refresh_token';
  // V07-015: a plain, non-secret marker - the real, persistent source of
  // truth for "is there still an active session", checked BEFORE ever
  // consulting secure storage. Never holds a token/username itself, so
  // storing it in ordinary SharedPreferences carries none of the risk a
  // real secret would.
  static const _keyLoggedOut = 'hydra_logged_out';

  final SecureTokenBackend _secure;

  // REV-011: the real, honest fallback for a secure-storage write/read
  // failure - kept only for this AuthPrefs instance's own lifetime
  // (effectively, this app run), never written to any disk-backed store.
  String? _inMemoryToken;
  String? _inMemoryUsername;
  String? _inMemoryRefreshToken;

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

  // C08: `refreshToken` is optional and named for backward source
  // compatibility with every existing call site - omitting it (a server
  // predating refresh-token support) leaves the previously-stored refresh
  // token, if any, untouched rather than deleting it, since a missing
  // argument here says nothing about whether one should still exist.
  Future<void> saveToken(String token, String username, {String? refreshToken}) async {
    var tokenWritten = false;
    var usernameWritten = false;
    try {
      await _secure.write(_keyToken, token);
      tokenWritten = true;
      await _secure.write(_keyUsername, username);
      usernameWritten = true;
      if (refreshToken != null) {
        await _secure.write(_keyRefreshToken, refreshToken);
      }
      // Secure storage is now the source of truth - clear any stale
      // plaintext copy left by a pre-DSI-01 session, and any in-memory-
      // only fallback REV-011 left behind from an earlier failure this
      // same run.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUsername);
      // V07-015: a real, new login supersedes whatever the logged-out
      // marker said before it.
      await prefs.remove(_keyLoggedOut);
      _inMemoryToken = null;
      _inMemoryUsername = null;
      _inMemoryRefreshToken = null;
    } catch (e) {
      // V07-015: the token write above may already have succeeded before
      // THIS step failed - reverting it (best-effort) keeps secure
      // storage from silently holding half of a session while this
      // catch block reports the whole thing as in-memory-only below.
      if (usernameWritten) {
        try {
          await _secure.delete(_keyUsername);
        } catch (_) {}
      }
      if (tokenWritten) {
        try {
          await _secure.delete(_keyToken);
        } catch (_) {
          // Cannot even revert it - the in-memory session below still
          // takes over for this run either way, and a real logout
          // (clearToken()) no longer trusts a stale secure copy anyway.
        }
      }
      // REV-011: never fall back to a plaintext SharedPreferences write
      // here - that would silently defeat the whole point of secure
      // storage. This session stays usable for the rest of this app run
      // only; a real restart on this (secure-storage-broken) device
      // requires logging in again.
      debugPrint(
        'AuthPrefs: secure storage write failed ($e) - this session will NOT be '
        'persisted to disk (never falling back to plaintext); it stays usable only '
        'until this app instance restarts.',
      );
      _inMemoryToken = token;
      _inMemoryUsername = username;
      _inMemoryRefreshToken = refreshToken;
    }
  }

  Future<String?> loadToken() async {
    if (_inMemoryToken != null) return _inMemoryToken;
    final prefs = await SharedPreferences.getInstance();
    // V07-015: a real logout does not trust a secure-storage delete to
    // have actually succeeded before honouring it - this marker is
    // checked before secure storage (or the legacy plaintext fallback
    // below) is ever consulted, so a delete that silently failed can
    // never resurrect the "cleared" session.
    if (prefs.getBool(_keyLoggedOut) ?? false) return null;
    String? secureToken;
    try {
      secureToken = await _secure.read(_keyToken);
    } catch (e) {
      debugPrint('AuthPrefs: secure storage read failed ($e) - using in-memory session only.');
    }
    if (secureToken != null) return secureToken;

    // No secure-stored token yet - either a fresh device, or secure
    // storage is genuinely unavailable on this real deployment target. A
    // pre-DSI-01 install may still have one in plain SharedPreferences;
    // migrate it in and remove the old copy so it doesn't linger once
    // secure storage IS available.
    final legacyToken = prefs.getString(_keyToken);
    if (legacyToken == null) return null;
    final legacyUsername = prefs.getString(_keyUsername);
    try {
      await _secure.write(_keyToken, legacyToken);
      if (legacyUsername != null) await _secure.write(_keyUsername, legacyUsername);
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUsername);
    } catch (e) {
      // Secure storage genuinely unavailable - keep serving the legacy
      // value rather than losing a real, already-logged-in session; the
      // plaintext copy stays in place since there is nowhere safer to move
      // it to yet.
      debugPrint('AuthPrefs: could not migrate legacy token to secure storage ($e).');
    }
    return legacyToken;
  }

  Future<String?> loadUsername() async {
    if (_inMemoryUsername != null) return _inMemoryUsername;
    final prefs = await SharedPreferences.getInstance();
    // V07-015: same real logged-out marker loadToken() checks above -
    // never report a stale username for a session that was logged out.
    if (prefs.getBool(_keyLoggedOut) ?? false) return null;
    try {
      final secureUsername = await _secure.read(_keyUsername);
      if (secureUsername != null) return secureUsername;
    } catch (e) {
      debugPrint('AuthPrefs: secure storage read failed ($e) - using in-memory session only.');
    }
    return prefs.getString(_keyUsername);
  }

  /// C08: no legacy plaintext fallback here (unlike loadToken()/
  /// loadUsername() above) - this key never existed before refresh-token
  /// support did, so there is nothing to migrate. `null` is a normal,
  /// expected result for a session established before this feature, or
  /// after logging out, not a broken one.
  Future<String?> loadRefreshToken() async {
    if (_inMemoryRefreshToken != null) return _inMemoryRefreshToken;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyLoggedOut) ?? false) return null;
    try {
      return await _secure.read(_keyRefreshToken);
    } catch (e) {
      debugPrint('AuthPrefs: secure storage read failed ($e) - using in-memory session only.');
      return null;
    }
  }

  Future<void> clearToken() async {
    _inMemoryToken = null;
    _inMemoryUsername = null;
    _inMemoryRefreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    // V07-015: set BEFORE attempting the real secure delete below - a
    // real logout must be honoured even if that delete itself fails
    // (caught and only logged next), never left contingent on it.
    await prefs.setBool(_keyLoggedOut, true);
    try {
      await _secure.delete(_keyToken);
      await _secure.delete(_keyUsername);
      await _secure.delete(_keyRefreshToken);
    } catch (e) {
      debugPrint(
        'AuthPrefs: secure storage delete failed ($e) - session already '
        'invalidated via the logged-out marker regardless.',
      );
    }
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUsername);
  }
}
