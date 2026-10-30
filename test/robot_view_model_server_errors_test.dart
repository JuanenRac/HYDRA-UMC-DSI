// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/robot_view_model_server_errors_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// How a command the server refuses (or only half accepts) reaches the
// operator, and the guards around jogging, stopping and renewing the
// session, against a real local dart:io HttpServer (no mocked client):
//   - 409 (a robot reserved by another account), 400 (a command the server
//     does not have), a role 403 and a 200 that carries `warnings` each read
//     differently, and the optimistic change is rolled back;
//   - a 403 TOKEN_EXPIRED is renewed once with the refresh token and the
//     request repeated, without the user noticing;
//   - while one jog is on the wire the next tick is dropped, and nothing jogs
//     while a trajectory is running;
//   - a pause is sent as an explicit desired state;
//   - a robot whose joints arrive as JSON integers (home pose) reads fine.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/models/hydra_state.dart';
import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/state/hydra_error.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';

class _FakeSecureBackend implements SecureTokenBackend {
  final Map<String, String> store = {};
  @override
  Future<void> write(String key, String value) async => store[key] = value;
  @override
  Future<String?> read(String key) async => store[key];
  @override
  Future<void> delete(String key) async => store.remove(key);
}

class _Server {
  final HttpServer http;
  int commandStatus = 200;
  Map<String, dynamic> commandBody = {'success': true};
  Duration commandDelay = Duration.zero;
  final List<Map<String, dynamic>> commands = [];
  final List<String?> commandAuth = [];
  String validToken = 'token-1';
  int refreshCalls = 0;
  bool playing = false;

  _Server(this.http) {
    http.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final WebSocket socket;
        try {
          socket = await WebSocketTransformer.upgrade(
            request,
            protocolSelector: (p) => p.contains('hydra.bearer') ? 'hydra.bearer' : null,
          );
        } catch (_) {
          // The client may drop mid-handshake (dart:io then throws inside the upgrade).
          return;
        }
        socket.listen((_) {});
        return;
      }
      final body = await utf8.decoder.bind(request).join();
      final json = body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic> : <String, dynamic>{};
      request.response.headers.contentType = ContentType.json;
      final route = '${request.method} ${request.uri.path}';
      if (route == 'POST /api/login') {
        request.response.write(jsonEncode({'success': true, 'token': 'token-1', 'refreshToken': 'refresh-1'}));
      } else if (route == 'GET /api/settings') {
        request.response.write(jsonEncode({
          'activeControllerId': 'c1',
          'controllers': [
            {
              'id': 'c1',
              'robots': [
                {
                  'id': 1,
                  'online': true,
                  'joints': {'j1': 0, 'j2': 12.5},
                  'playbackState': {'isPlaying': playing},
                  'combinedWith': [],
                },
              ],
            },
          ],
        }));
      } else if (route == 'POST /api/refresh') {
        refreshCalls++;
        validToken = 'token-2';
        request.response.write(jsonEncode({'success': true, 'token': 'token-2', 'refreshToken': 'refresh-2'}));
      } else if (route == 'POST /api/logout') {
        request.response.write(jsonEncode({'success': true}));
      } else if (route == 'GET /api/system/metrics') {
        request.response.write(jsonEncode({'cpu_load': 3, 'memory_usage': 40, 'temp': 48.0, 'temp_is_real': false, 'uptime': 99}));
      } else if (route == 'POST /api/robot/1/command') {
        commands.add(json);
        final auth = request.headers.value('authorization');
        commandAuth.add(auth);
        if (commandDelay > Duration.zero) await Future<void>.delayed(commandDelay);
        if (auth != 'Bearer $validToken') {
          request.response.statusCode = HttpStatus.forbidden;
          request.response.write(jsonEncode({'error': 'Access denied: token expired', 'code': 'TOKEN_EXPIRED'}));
        } else {
          request.response.statusCode = commandStatus;
          request.response.write(jsonEncode(commandBody));
        }
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });
  }

  static Future<_Server> start() async => _Server(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
  int get port => http.port;
  Future<void> close() => http.close(force: true);
}

Future<void> _until(bool Function() condition, {Duration timeout = const Duration(seconds: 5)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<(_Server, RobotViewModel)> _signedIn({bool playing = false}) async {
  SharedPreferences.setMockInitialValues({});
  final server = await _Server.start();
  server.playing = playing;
  addTearDown(server.close);
  final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _FakeSecureBackend()));
  addTearDown(vm.dispose);
  final ok = await vm.login(ServerInfo(host: '127.0.0.1', port: server.port, username: 'alice', password: 'x'));
  expect(ok, isTrue);
  expect(vm.selectedRobot, isNotNull);
  return (server, vm);
}

void main() {
  test('a 409 says the robot is reserved by another account and rolls the change back', () async {
    final (server, vm) = await _signedIn();
    server.commandStatus = 409;
    server.commandBody = {'error': 'robot 1 is reserved by alice'};

    vm.sendCommand('play');
    await _until(() => vm.lastError != null);

    expect(vm.lastError!.kind, HydraErrorKind.robotReserved);
    expect(vm.lastError!.params['owner'], contains('alice'));
    expect(vm.selectedRobot!.isPlaying, isFalse, reason: 'the optimistic play is undone');
  });

  test('a 400 shows the server\'s reason', () async {
    final (server, vm) = await _signedIn();
    server.commandStatus = 400;
    server.commandBody = {'error': 'unknown command'};

    vm.sendCommand('play');
    await _until(() => vm.lastError != null);

    expect(vm.lastError!.kind, HydraErrorKind.commandRejected);
    expect(vm.lastError!.params['reason'], 'unknown command');
  });

  test('a role 403 reads as a missing permission, not an expired session', () async {
    final (server, vm) = await _signedIn();
    server.commandStatus = 403;
    server.commandBody = {'error': 'Access denied: admin privileges required'};

    vm.sendCommand('play');
    await _until(() => vm.lastError != null);

    expect(vm.lastError!.kind, HydraErrorKind.permissionDenied);
    expect(vm.isLoggedIn, isTrue, reason: 'a role 403 must not end the session');
  });

  test('a 200 answer with warnings counts as not applied and is rolled back', () async {
    final (server, vm) = await _signedIn();
    server.commandBody = {
      'success': true,
      'warnings': [
        {'message': 'speed out of range - not applied'},
      ],
    };

    vm.sendCommand('play');
    await _until(() => vm.lastError != null);

    expect(vm.lastError!.kind, HydraErrorKind.commandNotApplied);
    expect(vm.lastError!.params['reason'], contains('speed out of range'));
    expect(vm.selectedRobot!.isPlaying, isFalse);
  });

  test('an expired token is renewed once and the command repeated, silently', () async {
    final (server, vm) = await _signedIn();
    server.validToken = 'something-else'; // the server no longer accepts token-1

    vm.sendCommand('play');
    await _until(() => server.commands.length >= 2);
    await _until(() => vm.lastError == null && server.refreshCalls == 1);

    expect(server.refreshCalls, 1);
    expect(server.commandAuth.last, 'Bearer token-2', reason: 'the repeat carries the renewed token');
    expect(vm.lastError, isNull);
    expect(vm.isLoggedIn, isTrue);
    expect(vm.selectedRobot!.isPlaying, isTrue, reason: 'the command went through, so it stays applied');
  });

  test('a command the app does not know is not sent', () async {
    final (server, vm) = await _signedIn();

    vm.sendCommand('shutdown');
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(server.commands, isEmpty);
    expect(vm.lastError!.kind, HydraErrorKind.unknownCommand);
  });

  test('pause is sent as an explicit desired state', () async {
    final (server, vm) = await _signedIn(playing: true);

    vm.sendCommand('pause');
    await _until(() => server.commands.isNotEmpty);

    final params = server.commands.single['params'] as Map<String, dynamic>;
    expect(params['paused'], isTrue);
    expect(vm.selectedRobot!.isPaused, isTrue);
  });

  test('while one jog is on the wire the next tick is dropped', () async {
    final (server, vm) = await _signedIn();
    server.commandDelay = const Duration(milliseconds: 400);

    vm.jogXYZ('robot', 1, 0, 0, 10);
    vm.jogXYZ('robot', 1, 0, 0, 10); // still in flight: dropped
    vm.jogXYZ('robot', 1, 0, 0, 10);
    await _until(() => server.commands.isNotEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(server.commands.length, 1);

    vm.jogXYZ('robot', 1, 0, 0, 10); // answered by now: goes through
    await _until(() => server.commands.length == 2);
    expect(server.commands.length, 2);
    await Future<void>.delayed(const Duration(milliseconds: 600)); // let it finish before the test ends
  });

  test('nothing jogs while a trajectory is running', () async {
    final (server, vm) = await _signedIn(playing: true);

    vm.jogXYZ('robot', 1, 0, 0, 10);
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(server.commands, isEmpty);
    expect(vm.jogBlocked(), isTrue);
  });

  test('the temperature of a host without a sensor is flagged as not real', () async {
    final (_, vm) = await _signedIn();
    await _until(() => vm.metrics != null, timeout: const Duration(seconds: 8));

    expect(vm.metrics, isNotNull);
    expect(vm.metrics!.tempIsReal, isFalse);
  });

  test('a robot whose joints arrive as JSON integers reads as numbers', () {
    final robot = RobotView({'id': 1, 'joints': {'j1': 0, 'j2': 12.5, 'j3': 'bad'}});

    expect(robot.joint('j1'), 0.0);
    expect(robot.joint('j2'), 12.5);
    expect(robot.joint('j3'), 0.0);
    expect(robot.joint('j9'), 0.0);
  });

  test('a relative XY-table jog leaves pos.tx and pos.ty alone', () {
    final robot = RobotView({'id': 1, 'pos': {'tx': 5.0, 'ty': 6.0}});

    robot.setXyTableAxis('x', 99);

    expect(robot.xyTablePos['x'], 99);
    expect(robot.pos['tx'], 5.0);
    expect(robot.pos['ty'], 6.0);
  });
}
