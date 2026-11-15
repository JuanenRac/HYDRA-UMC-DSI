// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/client_prefs.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Small client-side preferences that are not secrets: today the controller id
// of this installation (see models/access.dart).
// =============================================================================

import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show ClientPrefsCore;
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_store.dart';

class ClientPrefs extends ClientPrefsCore {
  ClientPrefs() : super(SharedPreferencesPrefsStore());

  static const _keyPairing = 'hydra_pairing_enabled';

  /// Whether pairing by link is switched on; [defaultValue] (off) before any choice.
  Future<bool> loadPairing(bool defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPairing) ?? defaultValue;
  }

  static const _keyListenOnly = 'hydra_listen_only';

  /// Whether the app is in listen-only mode (it sends no command but STOP); off before any choice.
  Future<bool> loadListenOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyListenOnly) ?? false;
  }

  Future<void> saveListenOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyListenOnly, value);
  }

  Future<void> savePairing(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPairing, value);
  }

  static const _keyRequireReleaseSignature = 'hydra_require_release_signature';

  /// Whether a downloaded release must also carry a valid signature of the releases; off before any choice, which is how the
  /// app behaved before the check existed (the digest is checked either way).
  Future<bool> loadRequireReleaseSignature() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRequireReleaseSignature) ?? false;
  }

  Future<void> saveRequireReleaseSignature(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRequireReleaseSignature, value);
  }

  static const _keyUpdateNotice = 'hydra_update_notice';

  /// Whether the person asked to be told about new versions; off before any choice, and then nothing is read from the network.
  Future<bool> loadUpdateNotice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUpdateNotice) ?? false;
  }

  Future<void> saveUpdateNotice(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUpdateNotice, value);
  }
}
