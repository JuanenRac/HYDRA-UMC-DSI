// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/stop_presence_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The global STOP is on screen wherever a robot can be driven: the Control tab carries the large one and the main screen carries the one of its bar, so
// leaving the Control tab never means looking for it.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/control_screen.dart';
import 'package:hydra_umc_dsi/ui/main_screen.dart';
import 'package:hydra_umc_dsi/ui/widgets/stop_all.dart';

class _Backend implements SecureTokenBackend {
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
}

Future<RobotViewModel> _pump(WidgetTester tester, Widget screen, {bool withRobot = true}) async {
  final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()));
  if (withRobot) {
    vm.state.raw['controllers'] = [
      {
        'id': 'c1',
        'robots': [
          {'id': 1, 'name': 'ARM-1', 'online': true},
        ],
      },
    ];
    vm.selectedRobotId = 1;
  }
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
        home: screen,
      ),
    ),
  );
  await tester.pump();
  return vm;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the Control tab carries the large global STOP once a robot is selected', (tester) async {
    final vm = await _pump(tester, const Scaffold(body: ControlScreen()));
    addTearDown(vm.dispose);
    final stop = tester.widgetList<StopAllButton>(find.byType(StopAllButton)).toList();
    expect(stop, hasLength(1));
    expect(stop.single.large, isTrue);
  });

  testWidgets('the main screen carries the global STOP in its bar, with or without a robot', (tester) async {
    for (final withRobot in [true, false]) {
      final vm = await _pump(tester, const MainScreen(), withRobot: withRobot);
      addTearDown(vm.dispose);
      expect(find.byType(StopAllButton), findsWidgets, reason: 'withRobot=$withRobot');
      await tester.pumpWidget(const SizedBox());
    }
  });
}
