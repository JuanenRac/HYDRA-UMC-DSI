// The sign-in screen of the panel offers the machine it is mounted on, not an address from some other network.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/login_screen.dart';
import 'package:hydra_umc_dsi/util/panel_defaults.dart';

void main() {
  test('the default address is the loopback of the machine the panel is mounted on', () {
    expect(panelDefaultHost, '127.0.0.1');
    expect(panelDefaultPort, 3000);
  });

  testWidgets('the sign-in screen is pre-filled with the default address and port', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RobotViewModel(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller!.text, panelDefaultHost);
    expect(fields[1].controller!.text, '$panelDefaultPort');
  });
}
