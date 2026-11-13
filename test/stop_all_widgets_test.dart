// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/stop_all_widgets_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The global STOP as the person sees it: one tap on either button sends the stop and nothing waits or asks, the
// "not confirmed" state offers a retry that sends it again, and the result banner says robot by robot what happened,
// warns when something failed or was not saved, and closes.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/models/stop_all_result.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/state/hydra_error.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/widgets/stop_all.dart';

class _Backend implements SecureTokenBackend {
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
}

class _Vm extends RobotViewModel {
  _Vm() : super(authPrefs: AuthPrefs(secureBackend: _Backend()));
  int stops = 0;

  @override
  Future<void> stopAll() async {
    stops++;
  }

  void show({bool unconfirmed = false, StopAllResult? result}) {
    stopAllUnconfirmed = unconfirmed;
    stopAllResult = result;
    notifyListeners();
  }
}

Future<_Vm> _pump(WidgetTester tester) async {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  final vm = _Vm();
  await tester.pumpWidget(
    ChangeNotifierProvider<RobotViewModel>.value(
      value: vm,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Column(children: [StopAllBanner(), StopAllButton(), StopAllButton(large: true)]),
        ),
      ),
    ),
  );
  await tester.pump();
  return vm;
}

Future<AppLocalizations> _en() => AppLocalizations.delegate.load(const Locale('en'));

void main() {
  testWidgets('one tap on the compact button sends the stop, with no confirmation', (tester) async {
    final vm = await _pump(tester);
    await tester.tap(find.byKey(const Key('stop-all')));
    await tester.pump();
    expect(vm.stops, 1);
  });

  testWidgets('one tap on the large button sends the stop too', (tester) async {
    final vm = await _pump(tester);
    await tester.tap(find.byKey(const Key('stop-all-large')));
    await tester.pump();
    expect(vm.stops, 1);
  });

  testWidgets('both buttons say STOP and carry the tooltip of the global stop', (tester) async {
    await _pump(tester);
    final l10n = await _en();
    expect(find.text(l10n.stopAllLabel), findsNWidgets(2));
    expect(find.byTooltip(l10n.stopAllTooltip), findsNWidgets(2));
  });

  testWidgets('with nothing to say the banner takes no room', (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('stop-all-unconfirmed')), findsNothing);
    expect(find.byKey(const Key('stop-all-result')), findsNothing);
  });

  testWidgets('a stop that is not confirmed is shown on every screen and can be retried', (tester) async {
    final vm = await _pump(tester);
    final l10n = await _en();
    vm.show(unconfirmed: true);
    await tester.pump();
    expect(find.byKey(const Key('stop-all-unconfirmed')), findsOneWidget);
    expect(find.text(const HydraError(HydraErrorKind.stopNotConfirmed).localize(l10n)), findsOneWidget);
    await tester.tap(find.text(l10n.stopAllRetry));
    await tester.pump();
    expect(vm.stops, 1);
  });

  testWidgets('the unconfirmed state wins over an older result', (tester) async {
    final vm = await _pump(tester);
    vm.show(
      unconfirmed: true,
      result: StopAllResult.fromRobots(const [StopAllRobot(robotId: 1, name: 'Arm', stopped: true)]),
    );
    await tester.pump();
    expect(find.byKey(const Key('stop-all-unconfirmed')), findsOneWidget);
    expect(find.byKey(const Key('stop-all-result')), findsNothing);
  });

  testWidgets('the result lists every robot, who held it and why it failed', (tester) async {
    final vm = await _pump(tester);
    final l10n = await _en();
    vm.show(
      result: StopAllResult.fromRobots(const [
        StopAllRobot(robotId: 1, name: 'Arm', stopped: true),
        StopAllRobot(robotId: 2, name: 'Table', stopped: false, reservedBy: 'operator', error: 'no link'),
      ]),
    );
    await tester.pump();
    expect(find.byKey(const Key('stop-all-result')), findsOneWidget);
    expect(find.text(l10n.stopAllSummary(1, 1)), findsOneWidget);
    expect(find.text('✓ Arm: ${l10n.stopAllRobotStopped}'), findsOneWidget);
    expect(
      find.text('✗ Table: ${l10n.stopAllRobotFailed} - ${l10n.stopAllReservedBy('operator')} - no link'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('a clean result is green with a check, and says nothing about saving', (tester) async {
    final vm = await _pump(tester);
    final l10n = await _en();
    vm.show(result: StopAllResult.fromRobots(const [StopAllRobot(robotId: 1, name: 'Arm', stopped: true)]));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text(l10n.stopAllNotSaved), findsNothing);
    expect(find.text(l10n.stopAllRobotByRobot), findsNothing);
  });

  testWidgets('a stop the server could not save, and one made robot by robot, say so', (tester) async {
    final vm = await _pump(tester);
    final l10n = await _en();
    vm.show(
      result: const StopAllResult(
        success: true,
        stoppedCount: 1,
        failedCount: 0,
        persisted: false,
        viaFallback: true,
        robots: [StopAllRobot(robotId: 1, name: 'Arm', stopped: true)],
      ),
    );
    await tester.pump();
    expect(find.text(l10n.stopAllNotSaved), findsOneWidget);
    expect(find.text(l10n.stopAllRobotByRobot), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('closing the result takes the banner away', (tester) async {
    final vm = await _pump(tester);
    final l10n = await _en();
    vm.show(result: StopAllResult.fromRobots(const [StopAllRobot(robotId: 1, name: 'Arm', stopped: true)]));
    await tester.pump();
    await tester.tap(find.byTooltip(l10n.stopAllClose));
    await tester.pump();
    expect(vm.stopAllResult, isNull);
    expect(find.byKey(const Key('stop-all-result')), findsNothing);
  });
}
