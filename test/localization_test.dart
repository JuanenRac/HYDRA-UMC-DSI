// Confirms the generated AppLocalizations pipeline actually resolves a
// non-English locale end-to-end (ARB -> flutter gen-l10n -> a real widget
// tree), not just that the English default happens to still render - the
// English-only case is already covered incidentally by widget_test.dart.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';

Widget _appWithLocale(Locale locale, Widget Function(BuildContext) builder) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: builder),
  );
}

void main() {
  testWidgets('Resolves Spanish strings for a Locale("es") override', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      _appWithLocale(const Locale('es'), (context) {
        l10n = AppLocalizations.of(context)!;
        return const SizedBox.shrink();
      }),
    );
    await tester.pump();

    expect(l10n.loginServerIp, 'IP del servidor');
    expect(l10n.controlEstopHold, 'E-STOP (mantener)');
    expect(l10n.metricsHostname, 'Nombre de host');
    expect(l10n.navMetrics, 'Métricas');
  });

  testWidgets('Resolves Japanese strings for a Locale("ja") override', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      _appWithLocale(const Locale('ja'), (context) {
        l10n = AppLocalizations.of(context)!;
        return const SizedBox.shrink();
      }),
    );
    await tester.pump();

    expect(l10n.navSettings, '設定');
  });

  testWidgets('Interpolated placeholders substitute real values', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      _appWithLocale(const Locale('en'), (context) {
        l10n = AppLocalizations.of(context)!;
        return const SizedBox.shrink();
      }),
    );
    await tester.pump();

    expect(l10n.controlValve(3), 'Valve 3');
    expect(l10n.errTxError('stop', 'timeout'), 'TX error [stop]: timeout');
    expect(l10n.cleanModeBody(12), 'Touch input is disabled - 12 s left');
    expect(l10n.threedLivePosition('ARM-1'), 'ARM-1 - live position');
  });

  testWidgets('Resolves Portuguese strings for a Locale("pt") override', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      _appWithLocale(const Locale('pt'), (context) {
        l10n = AppLocalizations.of(context)!;
        return const SizedBox.shrink();
      }),
    );
    await tester.pump();

    expect(l10n.loginServerIp, 'IP do servidor');
    expect(l10n.controlValve(3), 'Válvula 3');
    expect(l10n.errTxError('stop', 'timeout'), 'Erro de TX [stop]: timeout');
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode), contains('pt'));
  });

  test('Every language file has exactly the English keys and the same placeholders', () {
    Map<String, dynamic> load(String code) =>
        jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync()) as Map<String, dynamic>;
    final english = load('en');
    final keys = english.keys.where((k) => !k.startsWith('@')).toSet();
    final placeholder = RegExp(r'\{[a-zA-Z]+\}');
    for (final code in ['es', 'fr', 'de', 'it', 'ja', 'zh', 'pt']) {
      final table = load(code);
      final own = table.keys.where((k) => !k.startsWith('@')).toSet();
      expect(own, keys, reason: '$code differs from the English keys');
      for (final key in keys) {
        expect(
          placeholder.allMatches(table[key] as String).map((m) => m.group(0)).toList()..sort(),
          placeholder.allMatches(english[key] as String).map((m) => m.group(0)).toList()..sort(),
          reason: '$code/$key changed its placeholders',
        );
      }
    }
  });
}
