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

  Future<void> savePairing(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPairing, value);
  }
}
