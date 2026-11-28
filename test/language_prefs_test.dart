// The remembered language of the panel (the keeper of the shared package over the store of this app): nothing saved means no override (the system
// language decides), a saved code of one of the eight shipped languages comes back as
// that locale, and a code the app does not ship is ignored instead of breaking the start.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show LanguagePrefsCore;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/network/shared_preferences_store.dart';

class Panel {
  final LanguagePrefsCore core = LanguagePrefsCore(SharedPreferencesPrefsStore());
  Future<void> saveLanguage(String? code) => core.saveLanguage(code);
  Future<Locale?> loadLocale() async {
    final code = await core.loadLanguageCode(AppLocalizations.supportedLocales.map((l) => l.languageCode));
    return code == null ? null : Locale(code);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('nothing saved means no override', () async {
    expect(await Panel().loadLocale(), isNull);
  });

  test('every shipped language is saved and comes back as its own locale', () async {
    final prefs = Panel();
    final codes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();
    expect(codes.toSet(), {'en', 'es', 'de', 'fr', 'it', 'ja', 'zh', 'pt'});
    for (final code in codes) {
      await prefs.saveLanguage(code);
      final locale = await prefs.loadLocale();
      expect(locale, isA<Locale>(), reason: code);
      expect(locale!.languageCode, code);
    }
  });

  test('saving null removes the override', () async {
    final prefs = Panel();
    await prefs.saveLanguage('de');
    expect(await prefs.loadLocale(), isNotNull);
    await prefs.saveLanguage(null);
    expect(await prefs.loadLocale(), isNull);
  });

  test('a code the app does not ship is ignored', () async {
    final prefs = Panel();
    for (final code in ['xx', '', 'EN', 'pt-PT', 'klingon']) {
      await prefs.saveLanguage(code);
      expect(await prefs.loadLocale(), isNull, reason: code);
    }
  });

  test('the last choice wins', () async {
    final prefs = Panel();
    await prefs.saveLanguage('ja');
    await prefs.saveLanguage('zh');
    expect((await prefs.loadLocale())!.languageCode, 'zh');
  });
}
