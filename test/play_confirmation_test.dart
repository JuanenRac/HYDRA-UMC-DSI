// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/play_confirmation_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// PLAY asks first: the rules, the option (on until the person turns it off,
// kept across launches) and the screen (what the dialog says, that cancelling
// sends nothing, that a robot already playing is not asked about again).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/network/client_prefs.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/control_screen.dart';
import 'package:hydra_umc_dsi/util/play_confirmation.dart';

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

_RecordingViewModel _modelWithRobot({bool playing = false, double speed = 250, int points = 7}) {
  final vm = _RecordingViewModel();
  vm.state.raw['controllers'] = [
    {
      'id': 'c1',
      'robots': [
        {
          'id': 1,
          'name': 'ARM-1',
          'online': true,
          'recordedPoints': List.generate(points, (i) => {'x': i}),
          'playbackState': {'isPlaying': playing, 'speed': speed},
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

  test('PLAY asks when the option is on and the robot is not playing, and only then', () {
    expect(playNeedsConfirmation(askBeforePlay: true, robotIsPlaying: false), isTrue);
    expect(playNeedsConfirmation(askBeforePlay: false, robotIsPlaying: false), isFalse);
    expect(playNeedsConfirmation(askBeforePlay: true, robotIsPlaying: true), isFalse);
    expect(playNeedsConfirmation(askBeforePlay: false, robotIsPlaying: true), isFalse);
  });

  test('the speed is a whole percent and a damaged value is 0; the points are counted from a list only', () {
    expect(playSpeedPercent(250), 250);
    expect(playSpeedPercent(12.5), 13);
    expect(playSpeedPercent(double.nan), 0);
    expect(playSpeedPercent(double.infinity), 0);
    expect(playSpeedPercent(-5), 0);
    expect(recordedPointsCount({'recordedPoints': [1, 2, 3]}), 3);
    expect(recordedPointsCount({'recordedPoints': 'many'}), 0);
    expect(recordedPointsCount({}), 0);
  });

  test('the option is on before any choice, and a choice is kept across launches', () async {
    expect(await ClientPrefs().loadConfirmPlay(), isTrue);
    final vm = _RecordingViewModel();
    addTearDown(vm.dispose);
    expect(vm.confirmPlay, isTrue);
    await vm.setConfirmPlay(false);
    expect(vm.confirmPlay, isFalse);
    expect(await ClientPrefs().loadConfirmPlay(), isFalse);
    final next = _RecordingViewModel();
    addTearDown(next.dispose);
    await next.init();
    expect(next.confirmPlay, isFalse);
  });

  testWidgets('PLAY shows the robot, its points, the speed and the reservation, and sends nothing until it is confirmed', (tester) async {
    final vm = _modelWithRobot();
    addTearDown(vm.dispose);
    await _pump(tester, vm);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    expect(find.text('Start playback?'), findsOneWidget);
    expect(find.textContaining('ARM-1 will run the trajectory it has: 7 recorded points at 250% speed.'), findsOneWidget);
    expect(find.textContaining('The robot is not reserved.'), findsOneWidget);
    expect(vm.sent, isEmpty);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(vm.sent, ['play']);
    expect(find.text('Start playback?'), findsNothing);
  });

  testWidgets('cancelling the question sends nothing', (tester) async {
    final vm = _modelWithRobot();
    addTearDown(vm.dispose);
    await _pump(tester, vm);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(vm.sent, isEmpty);
    expect(find.text('Start playback?'), findsNothing);
  });

  testWidgets('with the option off PLAY goes straight through', (tester) async {
    final vm = _modelWithRobot();
    addTearDown(vm.dispose);
    await vm.setConfirmPlay(false);
    await _pump(tester, vm);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    expect(find.text('Start playback?'), findsNothing);
    expect(vm.sent, ['play']);
  });

  testWidgets('a robot that is already playing is not asked about again', (tester) async {
    final vm = _modelWithRobot(playing: true);
    addTearDown(vm.dispose);
    await _pump(tester, vm);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    expect(find.text('Start playback?'), findsNothing);
    expect(vm.sent, ['play']);
  });
}
