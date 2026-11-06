// =============================================================================
// HYDRA-UMC DSI - test/pairing_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Pairing by link on the panel, through the view model: the switch starts off, nothing is read while it is off, nothing is
// kept before the person confirms, a link without a fingerprint is never accepted, and the limits of the shared package are
// the ones this app shows. The sign-in screen shows the switch and the box, and the question of the pairing opens over it.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/network/tls_settings.dart';
import 'package:hydra_umc_dsi/state/hydra_error.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/login_screen.dart';
import 'package:hydra_umc_dsi/ui/widgets/pairing_widgets.dart';
import 'package:hydra_umc_dsi/util/pairing_link.dart';

void main() {
  final fp = 'cd' * 32;

  test('pairing starts off, and the choice is kept for the next start', () async {
    SharedPreferences.setMockInitialValues({});
    final first = RobotViewModel();
    addTearDown(first.dispose);
    expect(first.pairingEnabled, isFalse);
    await first.setPairingEnabled(true);

    final second = RobotViewModel();
    addTearDown(second.dispose);
    await second.init();
    expect(second.pairingEnabled, isTrue);
  });

  test('while it is off nothing is read, and the person is told', () async {
    SharedPreferences.setMockInitialValues({});
    final vm = RobotViewModel();
    addTearDown(vm.dispose);
    expect(await vm.receivePairing('hydra-umc://pair?host=a.local&port=3000'), isTrue);
    expect(vm.pairingOffer, isNull);
    expect(vm.lastError!.kind, HydraErrorKind.pairingOff);
    expect(await vm.receivePairing('https://example.com'), isFalse, reason: 'not a pairing link at all');
  });

  test('an offer is only shown: nothing is kept before the person confirms', () async {
    SharedPreferences.setMockInitialValues({});
    final vm = RobotViewModel();
    addTearDown(vm.dispose);
    await vm.setPairingEnabled(true);
    await vm.receivePairing('hydra-umc://pair?host=hydra.local&port=3443&fp=$fp&name=Cell');
    expect(vm.pairingOffer!.host, 'hydra.local');
    expect(vm.pairingOffer!.name, 'Cell');
    expect(vm.tlsSettings.pinnedFingerprint, isEmpty);
    expect(vm.pairedHost, isNull);
    vm.dismissPairing();
    expect(vm.pairingOffer, isNull);
    expect(vm.tlsSettings.pinnedFingerprint, isEmpty);
  });

  test('confirming requires TLS, pins the certificate and hands the address to the sign-in', () async {
    SharedPreferences.setMockInitialValues({});
    final vm = RobotViewModel();
    addTearDown(vm.dispose);
    await vm.setTlsSettings(TlsSettings(allowPlainHttp: true, pinnedFingerprint: 'ab' * 32));
    await vm.setPairingEnabled(true);
    await vm.receivePairing('hydra-umc://pair?host=hydra.local&port=3443&fp=$fp');
    await vm.confirmPairing();
    expect(vm.tlsSettings.allowPlainHttp, isFalse);
    expect(vm.tlsSettings.allowPlainRemote, isFalse);
    expect(vm.tlsSettings.pinnedFingerprint, fp);
    expect(vm.pairedHost, 'hydra.local');
    expect(vm.pairedPort, 3443);
    expect(vm.pairingOffer, isNull);
  });

  test('a link without a fingerprint is refused: no offer, no TLS change, nothing paired', () async {
    SharedPreferences.setMockInitialValues({});
    final vm = RobotViewModel();
    addTearDown(vm.dispose);
    await vm.setPairingEnabled(true);
    await vm.receivePairing('hydra-umc://pair?host=hydra.local&port=3000');
    expect(vm.pairingOffer, isNull);
    expect(vm.lastError!.kind, HydraErrorKind.pairingProblem);
    expect(vm.lastError!.params['problem'], 'missingFingerprint');
    await vm.confirmPairing();
    expect(vm.tlsSettings, const TlsSettings());
    expect(vm.pairedHost, isNull);
  });

  test('a bad link says why and offers nothing', () async {
    SharedPreferences.setMockInitialValues({});
    final vm = RobotViewModel();
    addTearDown(vm.dispose);
    await vm.setPairingEnabled(true);
    await vm.receivePairing('hydra-umc://pair?host=a.local&port=99999');
    expect(vm.pairingOffer, isNull);
    expect(vm.lastError!.kind, HydraErrorKind.pairingProblem);
    expect(await vm.readPastedPairing('just some text'), isFalse);
    expect(vm.lastError!.params['problem'], 'notAPairingLink');
  });

  test('every refusal has its own words in the language of the panel', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    for (final problem in PairingProblem.values) {
      expect(pairingProblemText(l10n, problem), isNotEmpty);
    }
    expect(pairingProblemText(l10n, PairingProblem.missingFingerprint), l10n.pairingProblemNoFingerprint);
  });

  testWidgets('the sign-in screen shows the switch, reads a typed link and asks before it keeps anything', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final vm = RobotViewModel();
    addTearDown(vm.dispose);
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ChangeNotifierProvider<RobotViewModel>.value(
        value: vm,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => PairingDialogHost(vm: vm, navigatorKey: navigatorKey, child: child!),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('pairing-link-field')), findsNothing, reason: 'the box is drawn only while the switch is on');
    await vm.setPairingEnabled(true);
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pairing-link-field')), 'hydra-umc://pair?host=hydra.local&port=3443&fp=$fp&name=Cell');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('pairing-read-button')));
    await tester.tap(find.byKey(const Key('pairing-read-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pairing-dialog')), findsOneWidget);
    expect(vm.tlsSettings.pinnedFingerprint, isEmpty, reason: 'nothing is kept before the person confirms');
    await tester.tap(find.byKey(const Key('pairing-confirm')));
    await tester.pumpAndSettle();
    expect(vm.tlsSettings.pinnedFingerprint, fp);
    expect(vm.pairedHost, 'hydra.local');
  });
}
