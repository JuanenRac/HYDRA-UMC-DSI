// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/hydra_error_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Every kind of error the app can show reads as a sentence in each of the 8
// languages, with the values it was given (a command name, the server's own
// reason, the account holding a reservation) in the text.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/state/hydra_error.dart';

const _params = <String, String>{
  'error': 'ERR-VALUE',
  'command': 'CMD-VALUE',
  'reason': 'REASON-VALUE',
  'owner': 'OWNER-VALUE',
  'message': 'MESSAGE-VALUE',
};

void main() {
  test('the app supports the 8 languages', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      {'en', 'es', 'de', 'fr', 'it', 'ja', 'zh', 'pt'},
    );
  });

  test('every error kind reads as text in every language', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      for (final kind in HydraErrorKind.values) {
        final text = HydraError(kind, _params).localize(l10n);
        expect(text.trim(), isNotEmpty, reason: '$kind in ${locale.languageCode}');
        expect(text, isNot(contains('{')), reason: 'an unfilled placeholder in $kind / ${locale.languageCode}: $text');
      }
    }
  });

  test('the values an error was given reach the text, in every language', () {
    const carriers = {
      HydraErrorKind.loginError: 'ERR-VALUE',
      HydraErrorKind.fetchFailed: 'ERR-VALUE',
      HydraErrorKind.wsConnectionLost: 'ERR-VALUE',
      HydraErrorKind.wsConnectFailed: 'ERR-VALUE',
      HydraErrorKind.txError: 'CMD-VALUE',
      HydraErrorKind.unknownCommand: 'CMD-VALUE',
      HydraErrorKind.robotReserved: 'OWNER-VALUE',
      HydraErrorKind.commandRejected: 'REASON-VALUE',
      HydraErrorKind.commandNotApplied: 'REASON-VALUE',
      HydraErrorKind.serverMessage: 'MESSAGE-VALUE',
    };
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      carriers.forEach((kind, expected) {
        expect(HydraError(kind, _params).localize(l10n), contains(expected), reason: '$kind in ${locale.languageCode}');
      });
    }
  });

  test('an error without its values still reads, with no "null" in it', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      for (final kind in HydraErrorKind.values) {
        if (kind == HydraErrorKind.serverMessage) continue; // its text IS the server's message
        final text = HydraError(kind).localize(l10n);
        expect(text.trim(), isNotEmpty, reason: '$kind in ${locale.languageCode}');
        expect(text, isNot(contains('null')), reason: '$kind in ${locale.languageCode}: $text');
      }
      expect(HydraError(HydraErrorKind.serverMessage).localize(l10n), '');
    }
  });

  test('the languages really differ from English where they should', () {
    final english = lookupAppLocalizations(const Locale('en'));
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == 'en') continue;
      final l10n = lookupAppLocalizations(locale);
      expect(
        HydraError(HydraErrorKind.stopNotConfirmed).localize(l10n),
        isNot(HydraError(HydraErrorKind.stopNotConfirmed).localize(english)),
        reason: 'the STOP warning is not translated in ${locale.languageCode}',
      );
    }
  });
}
