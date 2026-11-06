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

import 'shared_preferences_store.dart';


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

/// The last server and the session of this app. The preferences and the session rules are the shared ones of the SDK
/// package (clients/dart_app_common); this class gives them the platform's storage.
class AuthPrefs extends AuthPrefsCore {
  AuthPrefs({SecureTokenBackend? secureBackend}) : this._(secureBackend ?? FlutterSecureStorageBackend(), SharedPreferencesPrefsStore());

  AuthPrefs._(SecureTokenBackend secure, SharedPreferencesPrefsStore plain)
      : super(store: plain, session: SessionStore(secure: secure, plain: plain, log: debugPrint));
}
