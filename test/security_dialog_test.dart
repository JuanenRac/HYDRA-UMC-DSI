// =============================================================================
// HYDRA-UMC-DSI - test/security_dialog_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The security dialog: the plain-HTTP switches, reading the fingerprint from
// the server, trusting it only after the person confirms and saves, and the
// checks on what was typed.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/network/tls_settings.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/widgets/security_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _fingerprint = 'ab' * 32;

Future<void> _open(
  WidgetTester tester,
  RobotViewModel vm, {
  String host = '192.168.1.5',
  Future<ServerCertificate?> Function(String, int)? fetcher,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showSecurityDialog(context, vm, host: host, port: 3000, certificateFetcher: fetcher),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TlsSettingsStore.current = const TlsSettings();
  });
  tearDown(() => TlsSettingsStore.current = const TlsSettings());

  testWidgets('plain HTTP is off by default and the remote switch only shows once it is on', (tester) async {
    final vm = RobotViewModel();
    await _open(tester, vm);
    expect(find.byKey(const Key('security-allow-plain')), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('security-allow-plain'))).value, isFalse);
    expect(find.byKey(const Key('security-allow-remote')), findsNothing);
    await tester.tap(find.byKey(const Key('security-allow-plain')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('security-allow-remote')), findsOneWidget);
    await tester.tap(find.byKey(const Key('security-save')));
    await tester.pumpAndSettle();
    expect(vm.tlsSettings.allowPlainHttp, isTrue);
    expect(vm.tlsSettings.allowPlainRemote, isFalse);
    expect(TlsSettingsStore.current.allowPlainHttp, isTrue);
    expect((await TlsPrefs().load()).allowPlainHttp, isTrue);
  });

  testWidgets('the fingerprint read from the server is kept only after trusting it and saving', (tester) async {
    final vm = RobotViewModel();
    await _open(
      tester,
      vm,
      fetcher: (host, port) async => ServerCertificate(_fingerprint, 'CN=hydra', DateTime(2020), DateTime(2120)),
    );
    await tester.tap(find.byKey(const Key('security-fetch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('security-fetched')), findsOneWidget);
    expect(find.textContaining(TlsFingerprint.display(_fingerprint)), findsWidgets);
    // reading it changes nothing by itself
    expect(vm.tlsSettings.pinnedFingerprint, isEmpty);
    await tester.tap(find.byKey(const Key('security-trust')));
    await tester.pumpAndSettle();
    expect(vm.tlsSettings.pinnedFingerprint, isEmpty);
    await tester.tap(find.byKey(const Key('security-save')));
    await tester.pumpAndSettle();
    expect(vm.tlsSettings.pinnedFingerprint, _fingerprint);
    expect(TlsSettingsStore.current.pinnedFingerprint, _fingerprint);
  });

  testWidgets('a server that cannot be read says so and keeps nothing', (tester) async {
    final vm = RobotViewModel();
    await _open(tester, vm, fetcher: (host, port) async => null);
    await tester.tap(find.byKey(const Key('security-fetch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('security-message')), findsOneWidget);
    expect(find.byKey(const Key('security-trust')), findsNothing);
  });

  testWidgets('without a host there is nothing to read', (tester) async {
    final vm = RobotViewModel();
    await _open(tester, vm, host: '', fetcher: (host, port) async => fail('must not be called'));
    await tester.tap(find.byKey(const Key('security-fetch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('security-message')), findsOneWidget);
  });

  testWidgets('a fingerprint that is not 64 hexadecimal digits is refused and nothing is saved', (tester) async {
    final vm = RobotViewModel();
    await _open(tester, vm);
    await tester.enterText(find.byKey(const Key('security-fingerprint')), 'not a fingerprint');
    await tester.tap(find.byKey(const Key('security-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('security-message')), findsOneWidget);
    expect(vm.tlsSettings, const TlsSettings());
    expect((await TlsPrefs().load()), const TlsSettings());
  });

  testWidgets('a damaged CA text is refused', (tester) async {
    final vm = RobotViewModel();
    await _open(tester, vm);
    await tester.enterText(find.byKey(const Key('security-ca')), 'nonsense');
    await tester.tap(find.byKey(const Key('security-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('security-message')), findsOneWidget);
    expect(vm.tlsSettings, const TlsSettings());
  });

  testWidgets('the dialog is shown in every language', (tester) async {
    for (final locale in AppLocalizations.supportedLocales) {
      final vm = RobotViewModel();
      await _open(tester, vm, locale: locale);
      final l10n = AppLocalizations.of(tester.element(find.byKey(const Key('security-save'))))!;
      expect(l10n.securityTitle, isNotEmpty, reason: locale.languageCode);
      expect(find.text(l10n.securityTitle), findsOneWidget, reason: locale.languageCode);
      await tester.tap(find.text(l10n.securityCancel));
      await tester.pumpAndSettle();
    }
  });
}
