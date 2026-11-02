// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/home_reset_and_jog_step_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// HOME/RESET (the rules, the switch kept across launches, what is sent) and
// the jog step that the server keeps for the robot, as the Android and iOS
// apps do it. The commands come from the shared contract
// (docs/robot_command_contract.json).
// =============================================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/models/hydra_state.dart';
import 'package:hydra_umc_dsi/models/robot_command_contract.dart';
import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/network/client_prefs.dart';
import 'package:hydra_umc_dsi/network/hydra_api_client.dart';
import 'package:hydra_umc_dsi/services/operator_pin.dart';
import 'package:hydra_umc_dsi/state/hydra_error.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/util/home_reset.dart';
import 'package:hydra_umc_dsi/util/panel_config.dart';

class _Backend implements SecureTokenBackend {
  final Map<String, String> store = {};
  @override
  Future<void> write(String key, String value) async => store[key] = value;
  @override
  Future<String?> read(String key) async => store[key];
  @override
  Future<void> delete(String key) async => store.remove(key);
}

String _token(String role) {
  String part(Object json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'username': 'u', 'role': role})}.sig';
}

HomeResetSituation _ready({
  bool switchedOn = true,
  bool connected = true,
  bool robotOnline = true,
  bool robotEnabled = true,
  bool robotPlaying = false,
  bool jogInFlight = false,
  bool stopInProgress = false,
  bool needsArming = false,
  String? role = 'operator',
  bool hasPose = true,
  bool serverSupports = true,
}) =>
    HomeResetSituation(
      switchedOn: switchedOn,
      connected: connected,
      robotOnline: robotOnline,
      robotEnabled: robotEnabled,
      robotPlaying: robotPlaying,
      jogInFlight: jogInFlight,
      stopInProgress: stopInProgress,
      needsArming: needsArming,
      role: role,
      hasPose: hasPose,
      serverSupports: serverSupports,
    );

class _Wire {
  final List<Map<String, dynamic>> commands = [];
  int status = 200;
  String body = '{"success":true}';
}

RobotViewModel _vmWithRobot(_Wire wire, {String role = 'operator', Map<String, dynamic> robot = const {}}) {
  final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: PanelConfig.defaults, operatorPin: OperatorPin(backend: _Backend()));
  final mock = MockClient((r) async {
    if (r.method == 'POST' && r.url.path == '/api/robot/1/command') {
      wire.commands.add(jsonDecode(r.body) as Map<String, dynamic>);
      return http.Response(wire.body, wire.status);
    }
    return http.Response('{}', 404);
  });
  vm.apiClient = HydraApiClient('127.0.0.1', 3000, client: mock)..authToken = _token(role);
  vm.activeServer = ServerInfo(host: '127.0.0.1', port: 3000);
  vm.isLoggedIn = true;
  vm.state.raw['controllers'] = [
    {
      'id': 'c1',
      'robots': [
        {
          'id': 1,
          'name': 'ARM-1',
          'online': true,
          'pos': {'x': 10.0, 'y': 20.0, 'z': 30.0},
          'playbackState': {'isPlaying': false},
          ...robot,
        },
      ],
    },
  ];
  vm.selectedRobotId = 1;
  return vm;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the shared contract', () {
    test('the generated constants say what the shared file says', () {
      expect(RobotCommandContract.reset, 'reset');
      expect(RobotCommandContract.jogStep, 'jogStep');
      expect(RobotCommandContract.homeResetEnabledByDefault, isFalse);
      expect(RobotCommandContract.homeResetConfirmSteps, 2);
      expect(RobotCommandContract.homeResetConfirmWindowMs, greaterThan(0));
      expect(RobotCommandContract.continuous, contains('jogStep'));
      expect(RobotCommandContract.all, containsAll(['stop', 'jog', 'reset', 'jogStep', 'speed']));
    });
  });

  group('HOME/RESET rules', () {
    test('a ready situation has no block, and a role that cannot be read is left to the server', () {
      expect(homeResetBlockOf(_ready()), HomeResetBlock.none);
      expect(homeResetBlockOf(_ready(role: 'admin')), HomeResetBlock.none);
      expect(homeResetBlockOf(_ready(role: null)), HomeResetBlock.none);
    });

    test('each reason blocks, and the switch wins over everything else', () {
      expect(homeResetBlockOf(_ready(switchedOn: false)), HomeResetBlock.off);
      expect(homeResetBlockOf(_ready(connected: false)), HomeResetBlock.notConnected);
      expect(homeResetBlockOf(_ready(serverSupports: false)), HomeResetBlock.notSupported);
      expect(homeResetBlockOf(_ready(role: 'viewer')), HomeResetBlock.role);
      expect(homeResetBlockOf(_ready(robotOnline: false)), HomeResetBlock.offline);
      expect(homeResetBlockOf(_ready(robotEnabled: false)), HomeResetBlock.safeMode);
      expect(homeResetBlockOf(_ready(stopInProgress: true)), HomeResetBlock.stopPending);
      expect(homeResetBlockOf(_ready(robotPlaying: true)), HomeResetBlock.moving);
      expect(homeResetBlockOf(_ready(jogInFlight: true)), HomeResetBlock.jogBusy);
      expect(homeResetBlockOf(_ready(needsArming: true)), HomeResetBlock.notArmed);
      expect(homeResetBlockOf(_ready(hasPose: false)), HomeResetBlock.noPose);
      expect(homeResetBlockOf(_ready(switchedOn: false, connected: false, robotPlaying: true)), HomeResetBlock.off);
    });

    test('only the last step finishes, a late step starts over, cancel starts over', () {
      var now = DateTime(2000, 1, 1);
      final confirmation = HomeResetConfirmation(steps: 2, window: const Duration(seconds: 20), clock: () => now);
      expect(confirmation.advance(), const HomeResetProgress.waiting(2));
      now = now.add(const Duration(seconds: 5));
      expect(confirmation.advance().isDone, isTrue);
      expect(confirmation.advance(), const HomeResetProgress.waiting(2), reason: 'done does not stay armed');
      now = now.add(const Duration(seconds: 21));
      expect(confirmation.current, 1);
      confirmation.cancel();
      expect(confirmation.advance(), const HomeResetProgress.waiting(2));
    });
  });

  group('HOME/RESET in the view model', () {
    test('it is off before any choice and a choice is kept across launches', () async {
      expect(await ClientPrefs().loadHomeReset(false), isFalse);
      final vm = _vmWithRobot(_Wire());
      addTearDown(vm.dispose);
      expect(vm.homeResetEnabled, isFalse);
      await vm.setHomeResetEnabled(true);
      expect(await ClientPrefs().loadHomeReset(false), isTrue);
      final next = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: PanelConfig.defaults, operatorPin: OperatorPin(backend: _Backend()));
      addTearDown(next.dispose);
      await next.init();
      expect(next.homeResetEnabled, isTrue);
    });

    test('switched off, nothing is sent; switched on, the reset goes once with the target and zeroes the pose', () async {
      final wire = _Wire();
      final vm = _vmWithRobot(wire);
      addTearDown(vm.dispose);
      vm.homeReset();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(wire.commands, isEmpty);
      expect(vm.lastError!.kind, HydraErrorKind.homeResetBlocked);
      expect(vm.lastError!.params['block'], HomeResetBlock.off.name);

      await vm.setHomeResetEnabled(true);
      vm.lastError = null;
      vm.homeReset();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(wire.commands.single['command'], 'reset');
      expect(wire.commands.single['params'], {'target': 'robot'});
      expect(vm.selectedRobot!.posAxis('x'), 0.0);
      expect(vm.selectedRobot!.posAxis('z'), 0.0);
    });

    test('a robot that is playing, or a viewer, is not reset', () async {
      final wire = _Wire();
      final playing = _vmWithRobot(wire, robot: {'playbackState': {'isPlaying': true}});
      addTearDown(playing.dispose);
      await playing.setHomeResetEnabled(true);
      expect(playing.homeResetBlock(), HomeResetBlock.moving);
      playing.homeReset();
      expect(wire.commands, isEmpty);

      final viewer = _vmWithRobot(wire, role: 'viewer');
      addTearDown(viewer.dispose);
      await viewer.setHomeResetEnabled(true);
      expect(viewer.homeResetBlock(), HomeResetBlock.role);
    });

    test('a server that does not know the command is remembered, and the reason is the phrase of the button', () async {
      final wire = _Wire()
        ..status = 400
        ..body = '{"error":"Unknown command: reset"}';
      final vm = _vmWithRobot(wire);
      addTearDown(vm.dispose);
      await vm.setHomeResetEnabled(true);
      vm.homeReset();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(vm.homeResetServerSupports, isFalse);
      expect(vm.lastError!.kind, HydraErrorKind.homeResetBlocked);
      expect(vm.lastError!.params['block'], HomeResetBlock.notSupported.name);
      expect(vm.homeResetBlock(), HomeResetBlock.notSupported);
    });
  });

  group('jog step kept by the server', () {
    const steps = [0.1, 1.0, 5.0, 10.0, 25.0, 50.0, 90.0, 100.0];

    test('the step of the robot is the one the server keeps, snapped to a step the screen offers', () {
      expect(RobotView({'id': 1, 'jogStep': 25}).jogStepOr(10, steps), 25.0);
      expect(RobotView({'id': 1, 'jogStep': 30}).jogStepOr(10, steps), 25.0);
      expect(RobotView({'id': 1, 'jogStep': 0.3}).jogStepOr(10, steps), 0.1);
      expect(RobotView({'id': 1, 'jogStep': 400}).jogStepOr(10, steps), 100.0);
    });

    test('a robot with no usable step falls back', () {
      for (final raw in [<String, dynamic>{'id': 1}, {'id': 1, 'jogStep': 0}, {'id': 1, 'jogStep': -5}, {'id': 1, 'jogStep': 'x'}, {'id': 1, 'jogStep': double.nan}]) {
        expect(RobotView(raw).jogStep, isNull);
        expect(RobotView(raw).jogStepOr(10, steps), 10.0);
      }
    });

    test('choosing a step shows it at once and sends the jogStep command once the choice settles', () async {
      final wire = _Wire();
      final vm = _vmWithRobot(wire);
      addTearDown(vm.dispose);
      vm.setJogStep(25);
      expect(vm.selectedRobot!.jogStep, 25.0);
      vm.setJogStep(50);
      expect(wire.commands, isEmpty, reason: 'debounced');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(wire.commands.length, 1, reason: 'a flick through the list is one request');
      expect(wire.commands.single['command'], 'jogStep');
      expect(wire.commands.single['params'], {'value': 50.0});
    });

    test('a step the server could not take goes back to the one it had', () async {
      final wire = _Wire()
        ..status = 400
        ..body = '{"error":"bad value"}';
      final vm = _vmWithRobot(wire, robot: {'jogStep': 10});
      addTearDown(vm.dispose);
      vm.setJogStep(25);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(vm.selectedRobot!.jogStep, 10.0);
      expect(vm.lastError, isNotNull);
    });

    test('a step that makes no sense is never sent', () async {
      final wire = _Wire();
      final vm = _vmWithRobot(wire);
      addTearDown(vm.dispose);
      for (final bad in [0.0, -1.0, double.nan, double.infinity, RobotCommandContract.jogStepMax + 1]) {
        vm.setJogStep(bad);
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(wire.commands, isEmpty);
    });
  });
}
