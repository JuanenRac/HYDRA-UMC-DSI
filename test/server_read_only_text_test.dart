// =============================================================================
// HYDRA-UMC DSI - test/server_read_only_text_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The sentence for a server in read-only mode exists in each of the 8 languages, names the command
// and is not the sentence of a single robot in safe mode.
// =============================================================================

import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';

void main() {
  test('the read-only server sentence reads in every language and carries the command', () {
    final seen = <String>{};
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      final text = l10n.errServerReadOnly('CMD-VALUE');
      expect(text.trim(), isNotEmpty, reason: locale.languageCode);
      expect(text, contains('CMD-VALUE'), reason: locale.languageCode);
      expect(text, isNot(contains('{')), reason: locale.languageCode);
      expect(text, isNot(l10n.errRobotDisabled('CMD-VALUE')), reason: locale.languageCode);
      seen.add(text);
    }
    expect(seen.length, 8, reason: 'one distinct sentence per language');
  });

  test('the Portuguese sentence is European Portuguese', () {
    final text = lookupAppLocalizations(const Locale('pt')).errServerReadOnly('x');
    expect(text, contains('desativ'));
  });
}
