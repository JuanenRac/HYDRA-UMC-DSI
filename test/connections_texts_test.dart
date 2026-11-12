// =============================================================================
// HYDRA-UMC-DSI - test/connections_texts_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The words of the connections dialog, in the eight languages of the app: every kind of client, every action and every
// failure has its own text, an "ago" text carries the amount it was given, and the same holds for the words of the server options dialog.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/models/connection_history.dart';
import 'package:hydra_umc_dsi/models/server_security.dart';
import 'package:hydra_umc_dsi/ui/widgets/connections_dialog.dart';
import 'package:hydra_umc_dsi/ui/widgets/server_options_dialog.dart';

void main() {
  final locales = AppLocalizations.supportedLocales;

  test('the app speaks the eight languages', () {
    expect(locales.map((l) => l.languageCode).toSet(), {'en', 'es', 'de', 'fr', 'it', 'ja', 'zh', 'pt'});
  });

  test('every kind of client has a text of its own in every language, and an unknown kind falls back to "other"', () {
    for (final locale in locales) {
      final l10n = lookupAppLocalizations(locale);
      final texts = {for (final kind in connectionKinds) kind: connectionKindName(l10n, kind)};
      for (final entry in texts.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${locale.languageCode} ${entry.key}');
      }
      expect(texts.values.toSet().length, texts.length, reason: '${locale.languageCode}: two kinds read the same');
      expect(connectionKindName(l10n, 'something-new'), l10n.connectionsKindOther);
    }
  });

  test('every action has a text of its own in every language, and an unknown one reads as an expired session', () {
    for (final locale in locales) {
      final l10n = lookupAppLocalizations(locale);
      final texts = {for (final action in connectionActions) action: connectionActionName(l10n, action)};
      for (final entry in texts.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${locale.languageCode} ${entry.key}');
      }
      expect(connectionActionName(l10n, 'login'), l10n.connectionsActionLogin);
      expect(connectionActionName(l10n, 'login_failed'), l10n.connectionsActionLoginFailed);
      expect(connectionActionName(l10n, 'logout'), l10n.connectionsActionLogout);
      expect(connectionActionName(l10n, 'never-seen'), l10n.connectionsActionSessionExpired);
    }
  });

  test('every failure has its own non-empty text in every language', () {
    for (final locale in locales) {
      final l10n = lookupAppLocalizations(locale);
      final texts = [for (final failure in ConnectionsFailure.values) connectionFailureText(l10n, failure)];
      expect(texts.every((t) => t.trim().isNotEmpty), isTrue, reason: locale.languageCode);
      expect(texts.toSet().length, texts.length, reason: '${locale.languageCode}: two failures read the same');
    }
  });

  test('the "ago" text carries the amount and changes with the unit', () {
    final now = DateTime.utc(2000, 1, 1, 12);
    final cases = {
      const Duration(seconds: 30): '30',
      const Duration(minutes: 5): '5',
      const Duration(hours: 3): '3',
      const Duration(days: 2): '2',
    };
    for (final locale in locales) {
      final l10n = lookupAppLocalizations(locale);
      final texts = <String>[];
      for (final entry in cases.entries) {
        final text = connectionAgoText(l10n, now.subtract(entry.key), now);
        expect(text, contains(entry.value), reason: '${locale.languageCode} ${entry.key}');
        texts.add(text.replaceAll(RegExp(r'\d+'), '#'));
      }
      expect(texts.toSet().length, texts.length, reason: '${locale.languageCode}: two units read the same');
    }
  });

  test('every failure, every protection that is lowered and every source of an option read differently in every language', () {
    for (final locale in locales) {
      final l10n = lookupAppLocalizations(locale);
      final failures = [for (final f in ServerOptionsFailure.values) serverOptionsFailureText(l10n, f)];
      final lowerings = [for (final l in ProtectionLowering.values) protectionLoweringText(l10n, l)];
      final sources = [for (final o in OptionSource.values) optionSourceText(l10n, o)];
      for (final group in [failures, lowerings, sources]) {
        expect(group.every((t) => t.trim().isNotEmpty), isTrue, reason: locale.languageCode);
        expect(group.toSet().length, group.length, reason: '${locale.languageCode}: two entries read the same');
      }
    }
  });
}
