// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/auth_prefs.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Persists the last server (host/port) and session token across app
// launches via shared_preferences - copied verbatim from
// HYDRA-UMC-IOS-CONTROL's own network/auth_prefs.dart. Doubly useful here:
// this app runs as a kiosk on an embedded panel that's expected to stay
// logged in across a power-cycle of the CM5 itself, not just a normal app
// relaunch.
// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';

class AuthPrefs {
  static const _keyHost = 'hydra_host';
  static const _keyPort = 'hydra_port';
  static const _keyToken = 'hydra_token';
  static const _keyUsername = 'hydra_username';

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

  Future<void> saveToken(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUsername, username);
  }

  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<String?> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }
}
