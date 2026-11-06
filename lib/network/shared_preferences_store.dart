// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/shared_preferences_store.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The adapter that gives the shared preferences of the SDK package
// (clients/dart_app_common) their storage: the plugin shared_preferences.
// =============================================================================

import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show PrefsStore;
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesPrefsStore implements PrefsStore {
  @override
  Future<bool?> getBool(String key) async => (await SharedPreferences.getInstance()).getBool(key);

  @override
  Future<int?> getInt(String key) async => (await SharedPreferences.getInstance()).getInt(key);

  @override
  Future<String?> getString(String key) async => (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> setBool(String key, bool value) async {
    await (await SharedPreferences.getInstance()).setBool(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await (await SharedPreferences.getInstance()).setInt(key, value);
  }

  @override
  Future<void> setString(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await (await SharedPreferences.getInstance()).remove(key);
  }
}
