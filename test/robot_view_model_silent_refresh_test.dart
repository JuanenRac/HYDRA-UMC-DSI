// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/robot_view_model_silent_refresh_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// C08: real end-to-end coverage for RobotViewModel's own
// _attemptTokenRefresh() - a real local dart:io HttpServer serves both the
// plain HTTP routes (POST /api/login, GET /api/settings, POST /api/refresh)
// AND the real WebSocket upgrade at /ws (same real-socket approach
// hydra_websocket_test.dart's own _FakeHydraServer already uses, extended
// here to also answer the REST calls RobotViewModel.connect()/login() make -
// no mocked HydraApiClient/HydraWebSocket anywhere in this file). The
// server side deliberately closes the FIRST /ws connection with 1008 to
// reproduce the real trigger, then accepts a SECOND one to prove the app
// reconnected with the freshly, silently refreshed token - exercised
// through RobotViewModel's own public login(), never by calling the
// private _attemptTokenRefresh() directly.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
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

/// Real local HTTP + WebSocket server. `wsShouldReject` decides what the
/// NEXT real `/ws` connection gets: true closes it with 1008 immediately
/// after a real handshake, false leaves it open.
class _FakeServer {
  final HttpServer server;
  final List<bool> _wsBehaviors;
  int _wsConnectionCount = 0;
  final List<String?> wsTokensSeen = [];
  String currentLoginToken = 'initial-token';
  String currentRefreshToken = 'initial-refresh-token';
  String refreshedToken = 'renewed-token';
  String refreshedRefreshToken = 'renewed-refresh-token';

  _FakeServer(this.server, this._wsBehaviors) {
    server.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final query = request.uri.queryParameters;
        wsTokensSeen.add(query['token']);
        final rejectThisOne = _wsConnectionCount < _wsBehaviors.length ? _wsBehaviors[_wsConnectionCount] : false;
        _wsConnectionCount++;
        final socket = await WebSocketTransformer.upgrade(request);
        if (rejectThisOne) {
          await socket.close(1008, 'Access denied: Invalid token');
        }
        return;
      }
      final body = await utf8.decoder.bind(request).join();
      Map<String, dynamic> json = {};
      try {
        json = body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic> : {};
      } catch (_) {}
      request.response.headers.contentType = ContentType.json;
      switch ('${request.method} ${request.uri.path}') {
        case 'POST /api/login':
          request.response.write(jsonEncode({
            'success': true,
            'token': currentLoginToken,
            'refreshToken': currentRefreshToken,
            'role': 'admin',
          }));
          break;
        case 'GET /api/settings':
          request.response.write(jsonEncode({'controllers': []}));
          break;
        case 'POST /api/refresh':
          if (json['refreshToken'] != currentRefreshToken) {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.write(jsonEncode({'error': 'Invalid or expired refresh token'}));
          } else {
            request.response.write(jsonEncode({
              'success': true,
              'token': refreshedToken,
              'refreshToken': refreshedRefreshToken,
              'role': 'admin',
            }));
          }
          break;
        case 'POST /api/logout':
          request.response.write(jsonEncode({'success': true}));
          break;
        default:
          request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });
  }

  static Future<_FakeServer> start(List<bool> wsBehaviors) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _FakeServer(server, wsBehaviors);
  }

  int get port => server.port;

  Future<void> close() async {
    await server.close(force: true);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a WS 1008 close is recovered silently via the stored refresh token, without a visible logout', () async {
    final fakeServer = await _FakeServer.start([true, false]);
    addTearDown(fakeServer.close);

    final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _FakeSecureBackend()));
    final server = ServerInfo(host: '127.0.0.1', port: fakeServer.port, username: 'alice', password: 'irrelevant-for-this-test');

    final ok = await vm.login(server);
    expect(ok, isTrue);

    // The real 1008 close (from the FIRST WS connection) must recover on
    // its own - poll for the real, observable side effect (a second real
    // WS connection) rather than a fixed sleep.
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (fakeServer.wsTokensSeen.length < 2 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    expect(fakeServer.wsTokensSeen.length, 2, reason: 'exactly one real reconnect after the silent refresh');
    expect(fakeServer.wsTokensSeen[0], 'initial-token');
    expect(fakeServer.wsTokensSeen[1], 'renewed-token', reason: 'the second real WS connection must carry the freshly refreshed token');
    expect(vm.isLoggedIn, isTrue, reason: 'a recoverable 1008 must never surface as a visible logout');
  });

  test('a WS 1008 close with an unrecognized refresh token still forces a real logout', () async {
    final fakeServer = await _FakeServer.start([true]);
    addTearDown(fakeServer.close);
    // The server will reject any refresh attempt against this token -
    // simulates a genuinely revoked session (see refresh_tokens.ts's own
    // consumeRefreshToken() contract this mirrors).
    fakeServer.currentRefreshToken = 'a-token-the-refresh-endpoint-will-reject';

    final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _FakeSecureBackend()));
    final server = ServerInfo(host: '127.0.0.1', port: fakeServer.port, username: 'alice', password: 'irrelevant-for-this-test');

    // login() itself succeeds and stores currentRefreshToken - but
    // _FakeServer's own POST /api/refresh handler always compares against
    // currentRefreshToken, so overwriting it above (before login()) means
    // the token login() actually receives and stores no longer matches
    // what the server will accept - reproducing a real revoked refresh
    // token without needing a second server instance.
    fakeServer.currentRefreshToken = 'initial-refresh-token';
    final ok = await vm.login(server);
    expect(ok, isTrue);
    fakeServer.currentRefreshToken = 'a-different-token-now';

    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (vm.isLoggedIn && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    expect(vm.isLoggedIn, isFalse, reason: 'an unrecoverable session must still force a real, visible logout');
  });
}
