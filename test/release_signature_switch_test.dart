// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/release_signature_switch_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The settings switch "Require a release signature": off at first, kept when
// turned on, and written in all eight languages.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/network/client_prefs.dart';
import 'package:hydra_umc_dsi/ui/widgets/release_signature_switch.dart';

Widget host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('off at first, and turning it on is kept', (tester) async {
    await tester.pumpWidget(host(ReleaseSignatureSwitch(prefs: ClientPrefs())));
    await tester.pumpAndSettle();
    final finder = find.byKey(const Key('settings-require-release-signature'));
    expect(tester.widget<SwitchListTile>(finder).value, isFalse);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(finder).value, isTrue);
    expect(await ClientPrefs().loadRequireReleaseSignature(), isTrue);
  });

  testWidgets('shows what a saved choice says', (tester) async {
    SharedPreferences.setMockInitialValues({'hydra_require_release_signature': true});
    await tester.pumpWidget(host(ReleaseSignatureSwitch(prefs: ClientPrefs())));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('settings-require-release-signature'))).value, isTrue);
  });

  test('the two texts exist in the eight languages and differ from the English one', () {
    final english = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    for (final lang in ['de', 'es', 'fr', 'it', 'ja', 'pt', 'zh']) {
      final arb = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;
      for (final key in ['settingsRequireReleaseSignature', 'settingsRequireReleaseSignatureSubtitle']) {
        expect(arb[key], isA<String>(), reason: '$lang $key');
        expect(arb[key], isNot(english[key]), reason: '$lang $key');
      }
    }
  });
}
