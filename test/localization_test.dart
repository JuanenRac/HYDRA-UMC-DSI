// Confirms the generated AppLocalizations pipeline actually resolves a
// non-English locale end-to-end (ARB -> flutter gen-l10n -> a real widget
// tree), not just that the English default happens to still render - the
// English-only case is already covered incidentally by widget_test.dart.

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
}
