// The remembered language of the panel: nothing saved means no override (the system
// language decides), a saved code of one of the eight shipped languages comes back as
// that locale, and a code the app does not ship is ignored instead of breaking the start.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/l10n/language_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('nothing saved means no override', () async {
    expect(await LanguagePrefs().loadLocale(), isNull);
  });

  test('every shipped language is saved and comes back as its own locale', () async {
    final prefs = LanguagePrefs();
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
    final prefs = LanguagePrefs();
    await prefs.saveLanguage('de');
    expect(await prefs.loadLocale(), isNotNull);
    await prefs.saveLanguage(null);
    expect(await prefs.loadLocale(), isNull);
  });

  test('a code the app does not ship is ignored', () async {
    final prefs = LanguagePrefs();
    for (final code in ['xx', '', 'EN', 'pt-PT', 'klingon']) {
      await prefs.saveLanguage(code);
      expect(await prefs.loadLocale(), isNull, reason: code);
    }
  });

  test('the last choice wins', () async {
    final prefs = LanguagePrefs();
    await prefs.saveLanguage('ja');
    await prefs.saveLanguage('zh');
    expect((await prefs.loadLocale())!.languageCode, 'zh');
  });
}
