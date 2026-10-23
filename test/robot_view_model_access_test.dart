// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/robot_view_model_access_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Reservations, controller id, safety limits and jog arming, against a real
// local dart:io HttpServer (no mocked client): the controller id goes with
// every claim, release, jog-arm and command; the refusals of the server read
// differently; a jog above the limit of the model, or one the server requires
// to be armed and is not, is never sent.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/models/access.dart';
import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/network/hydra_api_client.dart';
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

class _Seen {
  final String route;
  final Map<String, dynamic> body;
  final String? controllerHeader;
  _Seen(this.route, this.body, this.controllerHeader);
}

String _tokenWithRole(String role) {
  String part(Object json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'username': 'alice', 'role': role})}.sig';
}

class _Server {
  final HttpServer http;
  final List<_Seen> seen = [];
  int commandStatus = 200;
  Map<String, dynamic> commandBody = {'success': true};
  int claimStatus = 200;
  Map<String, dynamic> claimBody = {'success': true};
  bool armRequired = false;
  double maxAmount = 100;
  List<Map<String, dynamic>> claims = [];
  int? jogArmedUntil;
  String role = 'admin';

  _Server(this.http) {
    http.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        try {
          final socket = await WebSocketTransformer.upgrade(
            request,
            protocolSelector: (p) => p.contains('hydra.bearer') ? 'hydra.bearer' : null,
          );
          socket.listen((_) {});
        } catch (_) {}
        return;
      }
      final body = await utf8.decoder.bind(request).join();
      final json = body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic> : <String, dynamic>{};
      final route = '${request.method} ${request.uri.path}';
      seen.add(_Seen(route, json, request.headers.value('x-controller-id')));
      request.response.headers.contentType = ContentType.json;
      if (route == 'POST /api/login') {
        request.response.write(jsonEncode({'success': true, 'token': _tokenWithRole(role), 'refreshToken': 'refresh-1'}));
      } else if (route == 'GET /api/settings') {
        request.response.write(jsonEncode({
          'activeControllerId': 'c1',
          'controllers': [
            {
              'id': 'c1',
              'robots': [
                {'id': 1, 'online': true, 'joints': {'j1': 0}, 'playbackState': {'isPlaying': false}, 'combinedWith': []},
              ],
            },
          ],
        }));
      } else if (route == 'GET /api/system/metrics') {
        request.response.write(jsonEncode({'cpu_load': 3, 'memory_usage': 40, 'temp': 48.0, 'temp_is_real': false, 'uptime': 99}));
      } else if (route == 'GET /api/claims') {
        request.response.write(jsonEncode({'claims': claims}));
      } else if (route == 'GET /api/safety-limits') {
        request.response.write(jsonEncode({
          'limits': {
            'jog': {'armRequired': armRequired, 'armTtlMs': 60000, 'default': {'maxAmount': 100, 'maxAbsolute': 1000}, 'models': {}},
          },
          'robot': {
            'id': 1,
            'model': 'Parol6 (6-DOF)',
            'jog': {'maxAmount': maxAmount, 'maxAbsolute': 500},
            'temperature': {'bedMaxC': 90},
            'jogArmedUntil': jogArmedUntil,
          },
        }));
      } else if (route == 'POST /api/robot/1/claim' || route == 'POST /api/robot/1/release') {
        request.response.statusCode = claimStatus;
        request.response.write(jsonEncode(claimBody));
      } else if (route == 'POST /api/robot/1/jog-arm') {
        jogArmedUntil = json['armed'] == true ? DateTime.now().millisecondsSinceEpoch + 60000 : null;
        request.response.write(jsonEncode({'success': true, 'armed': json['armed'], 'ttlMs': 60000}));
      } else if (route == 'POST /api/robot/1/command') {
        request.response.statusCode = commandStatus;
        request.response.write(jsonEncode(commandBody));
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });
  }

  static Future<_Server> start() async => _Server(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
  int get port => http.port;
  Future<void> close() => http.close(force: true);
  Iterable<_Seen> to(String route) => seen.where((s) => s.route == route);
}

Future<void> _until(bool Function() condition, {Duration timeout = const Duration(seconds: 5)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<(_Server, RobotViewModel)> _signedIn({String role = 'admin'}) async {
  SharedPreferences.setMockInitialValues({});
  final server = await _Server.start();
  server.role = role;
  addTearDown(server.close);
  final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _FakeSecureBackend()));
  addTearDown(vm.dispose);
  final ok = await vm.login(ServerInfo(host: '127.0.0.1', port: server.port, username: 'alice', password: 'x'));
  expect(ok, isTrue);
  expect(vm.selectedRobot, isNotNull);
  return (server, vm);
}

void main() {
  test('a jog sends the controller id in the body and in the header', () async {
    final (server, vm) = await _signedIn();

    vm.jog('robot', 'x', 5);
    await _until(() => server.to('POST /api/robot/1/command').isNotEmpty);

    final sent = server.to('POST /api/robot/1/command').first;
    expect(sent.controllerHeader, HydraApiClient.controllerId);
    expect(sent.body['controllerId'], HydraApiClient.controllerId);
  });

  test('reserving and releasing send the controller id and refresh the list', () async {
    final (server, vm) = await _signedIn();

    await vm.claimSelectedRobot();
    await vm.releaseSelectedRobot();

    for (final route in ['POST /api/robot/1/claim', 'POST /api/robot/1/release']) {
      final sent = server.to(route).single;
      expect(sent.controllerHeader, HydraApiClient.controllerId, reason: route);
      expect(sent.body['controllerId'], HydraApiClient.controllerId, reason: route);
    }
    expect(server.to('GET /api/claims'), isNotEmpty, reason: 'the list is read again after each request');
    expect(vm.lastError, isNull);
  });

  test('a refused reservation says why, one reason per code', () async {
    final (server, vm) = await _signedIn();
    server.claimStatus = 409;

    server.claimBody = {'error': 'robot is already claimed by bob', 'code': 'other-account'};
    await vm.claimSelectedRobot();
    expect(vm.lastError!.kind, HydraErrorKind.robotReserved);
    expect(vm.lastError!.params['owner'], contains('bob'));

    server.claimBody = {'error': 'x', 'code': 'other-controller'};
    await vm.claimSelectedRobot();
    expect(vm.lastError!.kind, HydraErrorKind.claimOtherController);

    server.claimBody = {'error': 'x', 'code': 'controller-id-required'};
    await vm.claimSelectedRobot();
    expect(vm.lastError!.kind, HydraErrorKind.claimControllerRequired);
  });

  test('a command refused for the controller reads differently from another account', () async {
    final (server, vm) = await _signedIn();
    server.commandStatus = 409;
    server.commandBody = {'error': 'x', 'code': 'other-controller'};

    vm.sendCommand('play');
    await _until(() => vm.lastError != null);

    expect(vm.lastError!.kind, HydraErrorKind.claimOtherController);
    expect(vm.selectedRobot!.isPlaying, isFalse, reason: 'the optimistic play is undone');
  });

  test('a jog above the limit of the model is not sent', () async {
    final (server, vm) = await _signedIn();
    server.maxAmount = 5;
    await vm.refreshAccess();
    expect(vm.safetyByRobot[1]!.jog.maxAmount, 5);

    vm.jog('robot', 'x', 10);

    expect(vm.lastError!.kind, HydraErrorKind.jogOverLimit);
    expect(vm.lastError!.params['limit'], '5');
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(server.to('POST /api/robot/1/command'), isEmpty);

    vm.jog('robot', 'x', 4); // within the limit
    await _until(() => server.to('POST /api/robot/1/command').isNotEmpty);
    expect(server.to('POST /api/robot/1/command'), hasLength(1));
  });

  test('a jog the server requires to be armed is not sent until it is armed', () async {
    final (server, vm) = await _signedIn();
    server.armRequired = true;
    await vm.refreshAccess();
    expect(vm.jogNeedsArming(1), isTrue);

    vm.jog('robot', 'x', 1);
    expect(vm.lastError!.kind, HydraErrorKind.jogNotArmed);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(server.to('POST /api/robot/1/command'), isEmpty);

    await vm.setJogArmed(true);
    expect(vm.jogNeedsArming(1), isFalse);
    final arm = server.to('POST /api/robot/1/jog-arm').single;
    expect(arm.body['armed'], isTrue);
    expect(arm.body['controllerId'], HydraApiClient.controllerId);

    await vm.setJogArmed(false);
    expect(vm.jogNeedsArming(1), isTrue);
  });

  test('a 403 jog-not-armed from the server ends the arming and is not read as a missing permission', () async {
    final (server, vm) = await _signedIn();
    server.commandStatus = 403;
    server.commandBody = {'error': 'not armed', 'code': 'jog-not-armed'};
    vm.jogArmedUntil[1] = DateTime.now().add(const Duration(minutes: 1));

    vm.jog('robot', 'x', 1);
    await _until(() => vm.lastError != null);

    expect(vm.lastError!.kind, HydraErrorKind.jogNotArmed);
    expect(vm.jogArmedUntil.containsKey(1), isFalse);
    expect(vm.isLoggedIn, isTrue);
  });

  test('the list of reservations tells where the robot stands', () async {
    final (server, vm) = await _signedIn();
    expect(vm.claimStandingOf(1), ClaimStanding.free);

    server.claims = [
      {'robotId': 1, 'robotName': 'A1', 'ownerUsername': 'alice', 'controllerId': HydraApiClient.controllerId, 'expiresAt': 1},
    ];
    await vm.refreshAccess();
    expect(vm.claimStandingOf(1), ClaimStanding.mineHere);

    server.claims = [
      {'robotId': 1, 'robotName': 'A1', 'ownerUsername': 'alice', 'controllerId': 'dsi-elsewhere', 'expiresAt': 1},
    ];
    await vm.refreshAccess();
    expect(vm.claimStandingOf(1), ClaimStanding.mineElsewhere);

    server.claims = [
      {'robotId': 1, 'robotName': 'A1', 'ownerUsername': 'bob', 'controllerId': 'x', 'expiresAt': 1},
    ];
    await vm.refreshAccess();
    expect(vm.claimStandingOf(1), ClaimStanding.other);
  });

  test('an administrator can take over a robot someone else holds, and the request carries force', () async {
    final (server, vm) = await _signedIn();
    server.claims = [
      {'robotId': 1, 'robotName': 'A1', 'ownerUsername': 'bob', 'controllerId': 'x', 'expiresAt': 1},
    ];
    await vm.refreshAccess();
    expect(vm.isAdmin, isTrue);
    expect(vm.canTakeOver(1), isTrue);

    await vm.takeOverSelectedRobot();

    final sent = server.to('POST /api/robot/1/claim').single;
    expect(sent.body['force'], isTrue);
    expect(sent.body['controllerId'], HydraApiClient.controllerId);
  });

  test('an operator never gets the take-over and nothing is sent if it is asked for anyway', () async {
    final (server, vm) = await _signedIn(role: 'operator');
    server.claims = [
      {'robotId': 1, 'robotName': 'A1', 'ownerUsername': 'bob', 'controllerId': 'x', 'expiresAt': 1},
    ];
    await vm.refreshAccess();
    expect(vm.isAdmin, isFalse);
    expect(vm.canTakeOver(1), isFalse);

    await vm.takeOverSelectedRobot();

    expect(server.to('POST /api/robot/1/claim'), isEmpty);
  });

  test('an administrator has no take-over on a free robot or on one reserved here', () async {
    final (server, vm) = await _signedIn();
    expect(vm.canTakeOver(1), isFalse);
    server.claims = [
      {'robotId': 1, 'robotName': 'A1', 'ownerUsername': 'alice', 'controllerId': HydraApiClient.controllerId, 'expiresAt': 1},
    ];
    await vm.refreshAccess();
    expect(vm.canTakeOver(1), isFalse);
  });
}
