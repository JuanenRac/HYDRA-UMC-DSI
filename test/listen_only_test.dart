// =============================================================================
// HYDRA-UMC DSI - test/listen_only_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Listen-only mode against a real local dart:io HttpServer: with it on the panel
// sends no command but STOP and the safe-mode disable, whatever asked for it;
// with it off (the default) the same commands go out; the choice is kept.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/network/client_prefs.dart';
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
  test('listen-only is off by default and a command goes out', () async {
    final (server, vm) = await _signedIn();
    expect(vm.listenOnly, isFalse);

    vm.jog('robot', 'x', 1.0);
    vm.setSpeed(50, 50);
    await _until(() => server.commands.length >= 2, timeout: const Duration(seconds: 2));

    expect(server.commands.map((c) => c['command']), containsAll(['jog', 'speed']));
  });

  test('with listen-only on no command goes out but STOP and disable', () async {
    final (server, vm) = await _signedIn(playing: true);
    await vm.setListenOnly(true);
    expect(vm.listenOnly, isTrue);

    vm.sendCommand('play');
    vm.sendCommand('pause');
    vm.sendCommand('enable');
    vm.jog('robot', 'x', 1.0);
    vm.jogXYZ('robot', 1, 1, 1, 1.0);
    vm.toggleValve(0);
    vm.togglePump(0);
    vm.setSpeed(50, 50);
    vm.setVisionEnabled(1, true);
    vm.homeReset();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(server.commands, isEmpty, reason: 'nothing but a stop may leave');
    expect(vm.lastError, isNull, reason: 'a dropped command is not an error, the screen says why');

    vm.sendCommand('stop');
    vm.sendCommand('disable');
    await _until(() => server.commands.length == 2);
    expect(server.commands.map((c) => c['command']), unorderedEquals(['stop', 'disable']));
  });

  test('turning it off lets commands go out again', () async {
    final (server, vm) = await _signedIn();
    await vm.setListenOnly(true);
    vm.jog('robot', 'x', 1.0);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(server.commands, isEmpty);

    await vm.setListenOnly(false);
    vm.jog('robot', 'x', 1.0);
    await _until(() => server.commands.isNotEmpty);
    expect(server.commands.single['command'], 'jog');
  });

  test('the choice is kept and read back, off before any choice', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = ClientPrefs();
    expect(await prefs.loadListenOnly(), isFalse);
    await prefs.saveListenOnly(true);
    expect(await prefs.loadListenOnly(), isTrue);
  });
}
