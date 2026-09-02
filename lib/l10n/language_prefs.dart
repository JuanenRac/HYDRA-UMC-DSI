// =============================================================================
// HYDRA-UMC DSI (Flutter) - l10n/language_prefs.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Ported from HYDRA-UMC-IOS-CONTROL's own l10n/language_prefs.dart.
// Persists an explicit language override across launches via
// shared_preferences (same "remember me" mechanism as
// network/auth_prefs.dart) - the same precedence order this ecosystem
// already uses in HYDRA-UMC-UPDATER's own i18n.py resolveInitialLang():
// a previously saved choice on this device, then the OS's own configured
// locale (when it's one of the 7 this app ships), then English.
// =============================================================================

import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

class LanguagePrefs {
  static const _keyLanguage = 'hydra_language';

  Future<void> saveLanguage(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null) {
      await prefs.remove(_keyLanguage);
    } else {
      await prefs.setString(_keyLanguage, languageCode);
    }
  }

  /// Null means "no explicit override" - MaterialApp's own `locale` stays
  /// null too in that case, so Flutter resolves the OS locale itself
  /// against `supportedLocales` (falling back to English when the device
  /// locale isn't one of the 7 this app ships).
  Future<Locale?> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_keyLanguage);
    if (code == null) return null;
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == code) return locale;
    }
    return null;
  }
}
