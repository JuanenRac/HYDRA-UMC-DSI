// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/device_sign_in_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// An appliance panel with the token of its own device signs in without a person
// (POST /api/device/login) and, when its session can no longer be renewed with
// the refresh token, signs in again with the same token. A local server stands
// in for the machine's own server.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/util/panel_config.dart';

class _Secure implements SecureTokenBackend {
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
  final List<String> deviceTokensSeen = [];
  final List<WebSocket> sockets = [];
  int refreshCalls = 0;
  bool acceptDevice = true;
  bool acceptRefresh = true;

  _Server(this.http) {
    http.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        try {
          sockets.add(await WebSocketTransformer.upgrade(
            request,
            protocolSelector: (protocols) => protocols.contains('hydra.bearer') ? 'hydra.bearer' : null,
          ));
        } catch (_) {}
        return;
      }
      final body = await utf8.decoder.bind(request).join();
      final json = body.isEmpty ? <String, dynamic>{} : jsonDecode(body) as Map<String, dynamic>;
      request.response.headers.contentType = ContentType.json;
      switch ('${request.method} ${request.uri.path}') {
        case 'POST /api/device/login':
          deviceTokensSeen.add('${json['token']}');
          if (acceptDevice && json['token'] == 'hdt1.good') {
            request.response.write(jsonEncode({'success': true, 'token': 'device-access', 'refreshToken': 'device-refresh', 'role': 'operator'}));
          } else {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.write(jsonEncode({'error': 'Invalid device token'}));
          }
          break;
        case 'POST /api/refresh':
          refreshCalls++;
          if (acceptRefresh) {
            request.response.write(jsonEncode({'success': true, 'token': 'refreshed-access', 'refreshToken': 'refreshed-refresh', 'role': 'operator'}));
          } else {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.write(jsonEncode({'error': 'Invalid or expired refresh token'}));
          }
          break;
        case 'GET /api/settings':
          request.response.write(jsonEncode({'controllers': []}));
          break;
        default:
          request.response.statusCode = HttpStatus.notFound;
      }
      try {
        await request.response.close();
      } on HttpException {
        // the client went away first
      }
    });
  }

  static Future<_Server> start() async => _Server(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
  int get port => http.port;

  Future<void> close() async {
    for (final socket in sockets) {
      await socket.close();
    }
    await http.close(force: true);
  }
}

RobotViewModel _vm(_Secure secure, {bool appliance = true, String file = '/run/device.token', String? contents = 'hdt1.good\n'}) {
  return RobotViewModel(
    authPrefs: AuthPrefs(secureBackend: secure),
    config: PanelConfig(appliance: appliance, deviceTokenFile: file),
    deviceTokenReader: (path) async => path == file ? contents : null,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the key is read from the settings file and is off by default', () {
    expect(PanelConfig.defaults.deviceTokenFile, isEmpty);
    expect(PanelConfig.parse('device_token_file = /run/hydra/device.token').deviceTokenFile, '/run/hydra/device.token');
  });

  test('the token of the device gives a sign-in with no person, and the session is kept', () async {
    final server = await _Server.start();
    addTearDown(server.close);
    final secure = _Secure();
    final vm = _vm(secure);
    addTearDown(vm.logout);

    expect(await vm.deviceSignIn(host: '127.0.0.1', port: server.port), isTrue);
    expect(vm.isLoggedIn, isTrue);
    expect(server.deviceTokensSeen, ['hdt1.good'], reason: 'the file is trimmed and the token is sent once');
    expect(await AuthPrefs(secureBackend: secure).loadRefreshToken(), 'device-refresh');
  });

  test('nothing is tried outside appliance mode, without a path, or with an empty or missing file', () async {
    final server = await _Server.start();
    addTearDown(server.close);
    for (final vm in [
      _vm(_Secure(), appliance: false),
      _vm(_Secure(), file: ''),
      _vm(_Secure(), contents: '  \n'),
      _vm(_Secure(), contents: null),
    ]) {
      expect(await vm.deviceSignIn(host: '127.0.0.1', port: server.port), isFalse);
      expect(vm.isLoggedIn, isFalse);
    }
    expect(server.deviceTokensSeen, isEmpty);
  });

  test('a refused or revoked device token leaves the panel signed out', () async {
    final server = await _Server.start();
    addTearDown(server.close);
    server.acceptDevice = false;
    final vm = _vm(_Secure());
    expect(await vm.deviceSignIn(host: '127.0.0.1', port: server.port), isFalse);
    expect(vm.isLoggedIn, isFalse);
    expect(server.deviceTokensSeen, ['hdt1.good']);
  });

  test('a refused refresh token is replaced by a new sign-in with the device token, not by a logout', () async {
    final server = await _Server.start();
    addTearDown(server.close);
    final vm = _vm(_Secure());
    addTearDown(vm.logout);
    expect(await vm.deviceSignIn(host: '127.0.0.1', port: server.port), isTrue);
    server.acceptRefresh = false;

    expect(await vm.renewSessionForTest(), isTrue);
    expect(server.refreshCalls, 1, reason: 'the refresh token is tried first');
    expect(server.deviceTokensSeen.length, 2, reason: 'then the device token');
    expect(vm.isLoggedIn, isTrue);
  });
}
