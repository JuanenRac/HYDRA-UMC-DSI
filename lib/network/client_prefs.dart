// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/client_prefs.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Small client-side preferences that are not secrets: today the controller id
// of this installation (see models/access.dart).
// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';

class ClientPrefs {
  static const _keyControllerId = 'hydra_controller_id';
  static const _keyConditionalMode = 'hydra_conditional_mode';

  /// The conditional-writes mode chosen in this app (`off`, `standard`, `strict`); null before any choice.
  Future<String?> loadConditionalMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyConditionalMode);
  }

  Future<void> saveConditionalMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConditionalMode, mode);
  }

  /// The controller id kept for this installation, or null before the first one was saved.
  Future<String?> loadControllerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyControllerId);
  }

  /// Keeps the controller id, so a reservation made from this device can still
  /// be released after the app restarts.
  Future<void> saveControllerId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyControllerId, id);
  }
}
