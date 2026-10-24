// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/stop_long_press_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The per-robot STOP keeps its long-press protection and its Tooltip does not
// swallow the gesture: a real long press (as a finger on the touch panel gives
// it) reaches the command, a quick tap does not, and a stop that is not
// available does nothing.
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

class _FakeSecureBackend implements SecureTokenBackend {
  final Map<String, String> store = {};
  @override
  Future<void> write(String key, String value) async => store[key] = value;
  @override
  Future<String?> read(String key) async => store[key];
  @override
  Future<void> delete(String key) async => store.remove(key);
}

class _RecordingViewModel extends RobotViewModel {
  _RecordingViewModel() : super(authPrefs: AuthPrefs(secureBackend: _FakeSecureBackend()));
  final List<String> sent = [];
  @override
  void sendCommand(String command) => sent.add(command);
}

_RecordingViewModel _modelWithRobot({required bool playing}) {
  final vm = _RecordingViewModel();
  vm.state.raw['controllers'] = [
    {
      'id': 'c1',
      'robots': [
        {
          'id': 1,
          'name': 'ARM-1',
          'online': true,
          'playbackState': {'isPlaying': playing},
        },
      ],
    },
  ];
  vm.selectedRobotId = 1;
  return vm;
}

Future<void> _pump(WidgetTester tester, RobotViewModel vm) async {
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
        home: const Scaffold(body: ControlScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a long press on the stop button sends STOP', (tester) async {
    final vm = _modelWithRobot(playing: true);
    addTearDown(vm.dispose);
    await _pump(tester, vm);

    await tester.longPress(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();

    expect(vm.sent, ['stop']);
  });

  testWidgets('a quick tap on the stop button sends nothing', (tester) async {
    final vm = _modelWithRobot(playing: true);
    addTearDown(vm.dispose);
    await _pump(tester, vm);

    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();

    expect(vm.sent, isEmpty);
  });

  testWidgets('a stop that is not available (the robot is idle) does nothing, even held', (tester) async {
    final vm = _modelWithRobot(playing: false);
    addTearDown(vm.dispose);
    await _pump(tester, vm);

    await tester.longPress(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();

    expect(vm.sent, isEmpty);
  });
}
