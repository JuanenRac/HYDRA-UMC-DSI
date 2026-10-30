// =============================================================================
// HYDRA-UMC DSI - test/robot_view_model_safe_mode_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The safe mode of a robot against a real local dart:io HttpServer (no mocked client):
//   - `disable` is sent for the selected robot only and marks it disabled at once;
//   - a 423 (robot-disabled) and the two refusals of `enable` (403 enable-not-allowed and
//     admin-required) each read in their own words, and the optimistic change is undone.
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
  test('disable is sent for the selected robot alone and marks it disabled at once', () async {
    final (server, vm) = await _signedIn(playing: true);
    expect(vm.selectedRobot!.isEnabled, isTrue);

    vm.sendCommand('disable');
    await _until(() => server.commands.isNotEmpty);

    expect(server.commands.single['command'], 'disable');
    expect(vm.selectedRobot!.isEnabled, isFalse);
    expect(vm.selectedRobot!.isPlaying, isFalse, reason: 'a disabled robot is stopped');
  });

  test('enable is sent and a server that does not allow it says so in its own words', () async {
    final (server, vm) = await _signedIn();
    vm.selectedRobot!.setEnabled(false);
    server.commandStatus = 403;
    server.commandBody = {'error': 'switched off', 'code': 'enable-not-allowed'};

    vm.sendCommand('enable');
    await _until(() => vm.lastError != null);

    expect(server.commands.single['command'], 'enable');
    expect(vm.lastError!.kind, HydraErrorKind.enableNotAllowed);
    expect(vm.selectedRobot!.isEnabled, isFalse, reason: 'the optimistic enable is undone');
    expect(vm.isLoggedIn, isTrue, reason: 'this 403 must not end the session');
  });

  test('only an administrator can enable: the refusal reads as such', () async {
    final (server, vm) = await _signedIn();
    vm.selectedRobot!.setEnabled(false);
    server.commandStatus = 403;
    server.commandBody = {'error': 'only an administrator', 'code': 'admin-required'};

    vm.sendCommand('enable');
    await _until(() => vm.lastError != null);

    expect(vm.lastError!.kind, HydraErrorKind.adminRequired);
  });

  test('a 423 says the robot is in safe mode and names the command', () async {
    final (server, vm) = await _signedIn();
    server.commandStatus = 423;
    server.commandBody = {'error': 'robot 1 is disabled', 'code': 'robot-disabled'};

    vm.sendCommand('play');
    await _until(() => vm.lastError != null);

    expect(vm.lastError!.kind, HydraErrorKind.robotDisabled);
    expect(vm.lastError!.params['command'], 'play');
    expect(vm.selectedRobot!.isPlaying, isFalse);
  });

  test('a robot that says nothing is enabled', () async {
    final (_, vm) = await _signedIn();
    expect(vm.selectedRobot!.raw.containsKey('enabled'), isFalse);
    expect(vm.selectedRobot!.isEnabled, isTrue);
  });
}
