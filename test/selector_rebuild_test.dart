// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/selector_rebuild_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The screens listen to the fields they draw, not to the whole view model: a
// metrics tick must not redraw the settings, the 3D view or the STOP banner,
// and a robot that moves must not redraw the metrics. The count is Flutter's
// own list of widgets rebuilt (debugPrintRebuildDirtyWidgets), so a screen
// that goes back to watching everything fails here.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/services/operator_pin.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/metrics_screen.dart';
import 'package:hydra_umc_dsi/ui/settings_screen.dart';
import 'package:hydra_umc_dsi/ui/three_d_screen.dart';
import 'package:hydra_umc_dsi/ui/widgets/stop_all.dart';
import 'package:hydra_umc_dsi/util/panel_config.dart';

class _Backend implements SecureTokenBackend {
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
}

class _Vm extends RobotViewModel {
  _Vm() : super(authPrefs: AuthPrefs(secureBackend: _Backend()), config: PanelConfig.defaults, operatorPin: OperatorPin(backend: _Backend()));
  void poke() => notifyListeners();
}

Future<_Vm> _pump(WidgetTester tester, Widget screen) async {
  final vm = _Vm();
  vm.state.raw['controllers'] = [
    {
      'id': 'c1',
      'robots': [
        {'id': 1, 'name': 'ARM-1', 'online': true, 'pos': {'x': 10, 'y': 20, 'z': 30}},
      ],
    },
  ];
  vm.selectedRobotId = 1;
  vm.metrics = SystemMetrics(cpuLoad: 10, memoryUsage: 20, temp: 40, uptime: 100);
  await tester.pumpWidget(
    ChangeNotifierProvider<RobotViewModel>.value(
      value: vm,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Column(children: [Expanded(child: screen)])),
      ),
    ),
  );
  await tester.pump();
  return vm;
}

/// The names of the widgets rebuilt while [action] runs.
Future<String> _rebuilt(WidgetTester tester, Future<void> Function() action) async {
  final lines = <String>[];
  final oldPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) => lines.add(message ?? '');
  debugPrintRebuildDirtyWidgets = true;
  try {
    await action();
    await tester.pump();
  } finally {
    debugPrintRebuildDirtyWidgets = false;
    debugPrint = oldPrint;
  }
  return lines.join('\n');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the metrics screen follows the readings and nothing else', (tester) async {
    final vm = await _pump(tester, const MetricsScreen());
    addTearDown(vm.dispose);
    final unrelated = await _rebuilt(tester, () async {
      vm.selectedRobot!.raw['pos']['x'] = 99;
      vm.confirmPlay = false;
      vm.poke();
    });
    expect(unrelated, isNot(contains('MetricsScreen')));
    final related = await _rebuilt(tester, () async {
      vm.metrics = SystemMetrics(cpuLoad: 55, memoryUsage: 20, temp: 40, uptime: 101);
      vm.poke();
    });
    expect(related, contains('MetricsScreen'));
  });

  testWidgets('the settings follow what they show and not the readings or the robots', (tester) async {
    final vm = await _pump(tester, const SettingsScreen());
    addTearDown(vm.dispose);
    final unrelated = await _rebuilt(tester, () async {
      vm.metrics = SystemMetrics(cpuLoad: 55, memoryUsage: 20, temp: 40, uptime: 101);
      vm.selectedRobot!.raw['pos']['x'] = 99;
      vm.poke();
    });
    expect(unrelated, isNot(contains('SettingsScreen')));
    final related = await _rebuilt(tester, () async {
      await vm.setConfirmPlay(false);
    });
    expect(related, contains('SettingsScreen'));
  });

  testWidgets('the 3D view follows the selected robot and not the readings', (tester) async {
    final vm = await _pump(tester, const ThreeDScreen());
    addTearDown(vm.dispose);
    final unrelated = await _rebuilt(tester, () async {
      vm.metrics = SystemMetrics(cpuLoad: 55, memoryUsage: 20, temp: 40, uptime: 101);
      vm.poke();
    });
    expect(unrelated, isNot(contains('ThreeDScreen')));
    final related = await _rebuilt(tester, () async {
      vm.selectedRobot!.raw['pos']['x'] = 99;
      vm.poke();
    });
    expect(related, contains('ThreeDScreen'));
  });

  testWidgets('the STOP banner, which sits on every tab, follows only the state of the STOP', (tester) async {
    final vm = await _pump(tester, const StopAllBanner());
    addTearDown(vm.dispose);
    final unrelated = await _rebuilt(tester, () async {
      vm.metrics = SystemMetrics(cpuLoad: 55, memoryUsage: 20, temp: 40, uptime: 101);
      vm.selectedRobot!.raw['pos']['x'] = 99;
      vm.poke();
    });
    expect(unrelated, isNot(contains('StopAllBanner')));
    final related = await _rebuilt(tester, () async {
      vm.stopAllUnconfirmed = true;
      vm.poke();
    });
    expect(related, contains('StopAllBanner'));
  });
}
