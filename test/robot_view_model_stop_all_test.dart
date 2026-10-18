// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/robot_view_model_stop_all_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The global STOP (POST /api/stop-all) against a real local dart:io
// HttpServer: the request itself (bearer, client header, no body), the
// per-robot answer, a failure / unsaved stop / reserved robot, the fall back
// to the per-robot stop on 429 and 404, the retry of a dropped connection and
// the persistent "not confirmed" state until a later STOP is answered.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // 'ok' | '429' | '404' | 'drop' (the connection is cut without an answer)
  String stopAllMode = 'ok';
  Map<String, dynamic> stopAllBody = {};
  int stopAllCalls = 0;
  int settingsCalls = 0;
  final List<String?> stopAllAuth = [];
  final List<String?> stopAllClientHeader = [];
  final List<int> stopAllBodyLength = [];
  final List<String> robotCommands = [];
  String validToken = 'token-1';
  int refreshCalls = 0;

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
      request.response.headers.contentType = ContentType.json;
      final route = '${request.method} ${request.uri.path}';
      if (route == 'POST /api/login') {
        request.response.write(jsonEncode({'success': true, 'token': 'token-1', 'refreshToken': 'refresh-1'}));
      } else if (route == 'GET /api/settings') {
        settingsCalls++;
        request.response.write(jsonEncode({
          'activeControllerId': 'c1',
          'controllers': [
            {
              'id': 'c1',
              'robots': [
                {'id': 1, 'name': 'A1', 'online': true, 'playbackState': {'isPlaying': true}, 'combinedWith': []},
                {'id': 2, 'name': 'A2', 'online': true, 'playbackState': {'isPlaying': true}, 'combinedWith': []},
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
      } else if (route == 'POST /api/stop-all') {
        stopAllCalls++;
        stopAllAuth.add(request.headers.value('authorization'));
        stopAllClientHeader.add(request.headers.value('x-hydra-client'));
        stopAllBodyLength.add(body.length);
        if (stopAllMode == 'drop') {
          final socket = await request.response.detachSocket();
          socket.destroy();
          return;
        }
        if (request.headers.value('authorization') != 'Bearer $validToken') {
          request.response.statusCode = HttpStatus.forbidden;
          request.response.write(jsonEncode({'error': 'Access denied: token expired', 'code': 'TOKEN_EXPIRED'}));
        } else if (stopAllMode == '429') {
          request.response.statusCode = 429;
          request.response.write(jsonEncode({'error': 'Too many requests'}));
        } else if (stopAllMode == '404') {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write(jsonEncode({'error': 'Not found'}));
        } else {
          request.response.write(jsonEncode(stopAllBody));
        }
      } else if (route.startsWith('POST /api/robot/') && route.endsWith('/command')) {
        robotCommands.add('${request.uri.path}:${jsonDecode(body)['command']}');
        request.response.write(jsonEncode({'success': true}));
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

Future<(_Server, RobotViewModel)> _signedIn() async {
  SharedPreferences.setMockInitialValues({});
  final server = await _Server.start();
  addTearDown(server.close);
  final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _FakeSecureBackend()));
  addTearDown(vm.dispose);
  final ok = await vm.login(ServerInfo(host: '127.0.0.1', port: server.port, username: 'alice', password: 'x'));
  expect(ok, isTrue);
  return (server, vm);
}

Map<String, dynamic> _answer({List<Map<String, dynamic>>? robots, bool persisted = true}) {
  final list = robots ??
      [
        {'robotId': 1, 'controllerId': 'c1', 'name': 'A1', 'stopped': true, 'valvesOff': 1, 'pumpsOff': 0},
        {'robotId': 2, 'controllerId': 'c1', 'name': 'A2', 'stopped': true, 'valvesOff': 0, 'pumpsOff': 1},
      ];
  final stopped = list.where((r) => r['stopped'] == true).length;
  return {
    'success': stopped == list.length,
    'stoppedCount': stopped,
    'failedCount': list.length - stopped,
    'persisted': persisted,
    'robots': list,
  };
}

void main() {
  test('the client posts /api/stop-all with the bearer token, the client header and no body', () async {
    final (server, vm) = await _signedIn();
    server.stopAllBody = _answer();

    final answer = await vm.apiClient!.postStopAll();

    expect(answer['stoppedCount'], 2);
    expect(server.stopAllAuth.single, 'Bearer token-1');
    expect(server.stopAllClientHeader.single, isNotNull);
    expect(server.stopAllBodyLength.single, 0);
  });

  test('one call stops every robot, reads the answer robot by robot and refreshes the state', () async {
    final (server, vm) = await _signedIn();
    server.stopAllBody = _answer();
    final before = server.settingsCalls;

    await vm.stopAll();

    expect(server.stopAllCalls, 1, reason: 'one tap is one call, with no roster refresh before it');
    expect(vm.stopAllUnconfirmed, isFalse);
    final result = vm.stopAllResult!;
    expect(result.stoppedCount, 2);
    expect(result.failedCount, 0);
    expect(result.needsAttention, isFalse);
    expect(result.robots.map((r) => r.name), ['A1', 'A2']);
    expect(result.robots.first.valvesOff, 1);
    await _until(() => server.settingsCalls > before);
    expect(server.settingsCalls, greaterThan(before));
    expect(vm.stopAllInFlight, isFalse);
  });

  test('a failed robot, an unsaved stop and a reservation of another account are reported', () async {
    final (server, vm) = await _signedIn();
    server.stopAllBody = _answer(persisted: false, robots: [
      {'robotId': 1, 'controllerId': 'c1', 'name': 'A1', 'stopped': true, 'reservedBy': 'bob'},
      {'robotId': 2, 'controllerId': 'c1', 'name': 'A2', 'stopped': false, 'error': 'controller offline'},
    ]);

    await vm.stopAll();

    final result = vm.stopAllResult!;
    expect(result.failedCount, 1);
    expect(result.persisted, isFalse);
    expect(result.needsAttention, isTrue);
    expect(result.robots.first.reservedBy, 'bob');
    expect(result.robots.last.error, 'controller offline');
    expect(vm.stopAllUnconfirmed, isFalse, reason: 'the server answered');
  });

  test('a 429 falls back to the per-robot stop of every robot', () async {
    final (server, vm) = await _signedIn();
    server.stopAllMode = '429';

    await vm.stopAll();

    expect(server.robotCommands, unorderedEquals(['/api/robot/1/command:stop', '/api/robot/2/command:stop']));
    final result = vm.stopAllResult!;
    expect(result.viaFallback, isTrue);
    expect(result.stoppedCount, 2);
    expect(vm.stopAllUnconfirmed, isFalse);
  });

  test('a 404 (an older server) falls back to the per-robot stop too', () async {
    final (server, vm) = await _signedIn();
    server.stopAllMode = '404';

    await vm.stopAll();

    expect(server.robotCommands.length, 2);
    expect(vm.stopAllResult!.viaFallback, isTrue);
  });

  test('a dropped connection is retried once, then STOP stays not confirmed until a later one is answered', () async {
    final (server, vm) = await _signedIn();
    server.stopAllMode = 'drop';

    await vm.stopAll();

    expect(server.stopAllCalls, 2, reason: 'one retry after a network error');
    expect(vm.stopAllUnconfirmed, isTrue);
    expect(vm.lastError!.kind, HydraErrorKind.stopNotConfirmed);
    expect(vm.stopAllResult, isNull);

    server.stopAllMode = 'ok';
    server.stopAllBody = _answer();
    await vm.stopAll();

    expect(vm.stopAllUnconfirmed, isFalse);
    expect(vm.stopAllResult!.stoppedCount, 2);
  });

  test('an expired token is renewed once and the STOP repeated', () async {
    final (server, vm) = await _signedIn();
    server.validToken = 'something-else';
    server.stopAllBody = _answer();

    await vm.stopAll();

    expect(server.refreshCalls, 1);
    expect(server.stopAllCalls, 2);
    expect(vm.stopAllResult!.stoppedCount, 2);
  });

  test('dismissing the result clears it, and signing out forgets a pending not-confirmed state', () async {
    final (server, vm) = await _signedIn();
    server.stopAllBody = _answer();
    await vm.stopAll();
    vm.dismissStopAllResult();
    expect(vm.stopAllResult, isNull);

    server.stopAllMode = 'drop';
    await vm.stopAll();
    expect(vm.stopAllUnconfirmed, isTrue);
    vm.logout();
    expect(vm.stopAllUnconfirmed, isFalse);
  });
}
