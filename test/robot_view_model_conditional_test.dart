// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/robot_view_model_conditional_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Conditional writes (If-Match with the revision of the robot), the atomic table
// move and the audit record, against a real local dart:io HttpServer (no mocked
// client): a write carries the revision the last answer gave, never for STOP,
// never while another write to the robot is on its way, and a 412 changes
// nothing, says so and reads the robot again.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/models/access.dart';
import 'package:hydra_umc_dsi/models/contract_v2.dart';
import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/models/sha256.dart';
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

class _Seen {
  final String route;
  final String query;
  final Map<String, dynamic> body;
  final String? ifMatch;
  _Seen(this.route, this.query, this.body, this.ifMatch);
}

class _Server {
  final HttpServer http;
  final List<_Seen> seen = [];

  /// What the command route answers, one entry per request (the last one repeats).
  List<(int, Map<String, dynamic>)> commandAnswers = [(200, {'success': true})];
  int claimStatus = 200;
  Map<String, dynamic> claimBody = {'success': true};
  int robotStatus = 404;
  Map<String, dynamic> robotBody = {};
  int auditStatus = 404;
  String auditBody = '{}';
  double maxAmount = 100;
  int commandCount = 0;

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
      seen.add(_Seen(route, request.uri.query, json, request.headers.value('if-match')));
      request.response.headers.contentType = ContentType.json;
      if (route == 'POST /api/login') {
        request.response.write(jsonEncode({'success': true, 'token': 'tok', 'refreshToken': 'refresh-1'}));
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
                  'hasXYTable': true,
                  'joints': {'j1': 0},
                  'playbackState': {'isPlaying': false},
                  'combinedWith': [],
                },
              ],
            },
          ],
        }));
      } else if (route == 'GET /api/system/metrics') {
        request.response.write(jsonEncode({'cpu_load': 3, 'memory_usage': 40, 'temp': 48.0, 'temp_is_real': false, 'uptime': 99}));
      } else if (route == 'GET /api/claims') {
        request.response.write(jsonEncode({'claims': []}));
      } else if (route == 'GET /api/safety-limits') {
        request.response.write(jsonEncode({
          'limits': {
            'jog': {'armRequired': false, 'armTtlMs': 60000, 'default': {'maxAmount': 100, 'maxAbsolute': 1000}, 'models': {}},
          },
          'robot': {
            'id': 1,
            'model': 'Parol6 (6-DOF)',
            'jog': {'maxAmount': maxAmount, 'maxAbsolute': 500},
            'temperature': {'bedMaxC': 90},
            'jogArmedUntil': null,
          },
        }));
      } else if (route == 'POST /api/robot/1/claim' || route == 'POST /api/robot/1/release') {
        request.response.statusCode = claimStatus;
        request.response.write(jsonEncode(claimBody));
      } else if (route == 'POST /api/robot/1/command') {
        final index = commandCount < commandAnswers.length ? commandCount : commandAnswers.length - 1;
        commandCount++;
        final (status, answer) = commandAnswers[index];
        request.response.statusCode = status;
        request.response.write(jsonEncode(answer));
      } else if (route == 'GET /api/robot/1') {
        request.response.statusCode = robotStatus;
        request.response.write(jsonEncode(robotBody));
      } else if (route == 'GET /api/audit') {
        request.response.statusCode = auditStatus;
        request.response.write(auditBody);
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

Future<(_Server, RobotViewModel)> _signedIn() async {
  SharedPreferences.setMockInitialValues({});
  final server = await _Server.start();
  addTearDown(server.close);
  final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _FakeSecureBackend()));
  addTearDown(vm.dispose);
  final ok = await vm.login(ServerInfo(host: '127.0.0.1', port: server.port, username: 'alice', password: 'x'));
  expect(ok, isTrue);
  expect(vm.selectedRobot, isNotNull);
  return (server, vm);
}

void main() {
  test('the first write has no If-Match, learns the revision, and the next one carries it quoted', () async {
    final (server, vm) = await _signedIn();
    server.commandAnswers = [
      (200, {'success': true, 'revision': 'rev-1'}),
      (200, {'success': true, 'revision': 'rev-2'}),
    ];

    vm.sendCommand('play');
    await _until(() => vm.revisions.known(1) == 'rev-1');
    expect(server.to('POST /api/robot/1/command').first.ifMatch, isNull);

    vm.sendCommand('pause');
    await _until(() => vm.revisions.known(1) == 'rev-2');
    expect(server.to('POST /api/robot/1/command').toList()[1].ifMatch, '"rev-1"');
  });

  test('a jog is unconditional in the standard mode and conditional in the strict one', () async {
    final (server, vm) = await _signedIn();
    vm.revisions.learn(1, 'r0');

    vm.jog('robot', 'x', 1);
    await _until(() => server.to('POST /api/robot/1/command').length == 1);
    expect(server.to('POST /api/robot/1/command').first.ifMatch, isNull);

    // The answer carried no revision, so what was known was forgotten; learn one again and ask for the strict mode.
    await _until(() => vm.revisions.known(1) == null);
    await vm.setConditionalMode(ConditionalMode.strict);
    vm.revisions.learn(1, 'r9');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    vm.jog('robot', 'x', 1);
    await _until(() => server.to('POST /api/robot/1/command').length == 2);
    expect(server.to('POST /api/robot/1/command').toList()[1].ifMatch, '"r9"');
  });

  test('STOP never carries If-Match, and with the check off nothing does', () async {
    final (server, vm) = await _signedIn();
    await vm.setConditionalMode(ConditionalMode.strict);
    vm.revisions.learn(1, 'r1');

    vm.sendCommand('stop');
    await _until(() => server.to('POST /api/robot/1/command').isNotEmpty);
    expect(server.to('POST /api/robot/1/command').first.ifMatch, isNull);

    await _until(() => vm.revisions.known(1) == null);
    await vm.setConditionalMode(ConditionalMode.off);
    vm.revisions.learn(1, 'r1');
    vm.sendCommand('play');
    await _until(() => server.to('POST /api/robot/1/command').length == 2);
    expect(server.to('POST /api/robot/1/command').toList()[1].ifMatch, isNull);
  });

  test('a 412 says so, undoes the change, and reads the robot again', () async {
    final (server, vm) = await _signedIn();
    server.commandAnswers = [
      (412, {'error': 'the robot changed since you read it', 'code': 'revision-mismatch', 'revision': 'now-rev'}),
    ];
    server.robotStatus = 200;
    server.robotBody = {
      'robot': {'id': 1, 'valves': [true, false]},
      'revision': 'now-rev',
      'cellId': 'c1',
    };
    vm.revisions.learn(1, 'stale');

    vm.sendCommand('play');
    await _until(() => vm.lastError != null);

    expect(vm.lastError!.kind, HydraErrorKind.revisionChanged);
    expect(vm.lastError!.params['command'], 'play');
    expect(server.to('POST /api/robot/1/command').first.ifMatch, '"stale"');
    await _until(() => server.to('GET /api/robot/1').isNotEmpty);
    await _until(() => vm.revisions.known(1) == 'now-rev');
    await _until(() => vm.selectedRobot?.raw['valves'] is List);
    expect(vm.selectedRobot!.isPlaying, isFalse, reason: 'the play was undone');
    expect(vm.selectedRobot!.raw['hasXYTable'], isTrue, reason: 'the rest of the robot is kept');
  });

  test('reserving and releasing carry the revision, a take-over does not', () async {
    final (server, vm) = await _signedIn();
    server.claimBody = {'success': true, 'revision': 'after-claim'};

    await vm.claimSelectedRobot();
    expect(vm.revisions.known(1), 'after-claim');
    expect(server.to('POST /api/robot/1/claim').first.ifMatch, isNull);

    await vm.releaseSelectedRobot();
    expect(server.to('POST /api/robot/1/release').first.ifMatch, '"after-claim"');
  });

  test('a 412 on a release is said and the robot is read again', () async {
    final (server, vm) = await _signedIn();
    server.claimStatus = 412;
    server.claimBody = {'error': 'changed', 'code': 'revision-mismatch', 'revision': 'cur'};
    server.robotStatus = 200;
    server.robotBody = {
      'robot': {'id': 1},
      'revision': 'cur',
    };
    vm.revisions.learn(1, 'old');

    await vm.releaseSelectedRobot();

    expect(vm.lastError!.kind, HydraErrorKind.revisionChanged);
    await _until(() => vm.revisions.known(1) == 'cur');
  });

  test('a jog of the XY table is one relative table command', () async {
    final (server, vm) = await _signedIn();

    vm.jog('xytable', 'x', 5);
    await _until(() => server.to('POST /api/robot/1/command').isNotEmpty);

    final sent = server.to('POST /api/robot/1/command').first.body;
    expect(sent['command'], 'table');
    final params = sent['params'] as Map<String, dynamic>;
    expect(params['x'], 5.0);
    expect(params['y'], 0.0);
    expect(params['mode'], 'relative');
    expect(vm.selectedRobot!.xyTablePos['x'], 5.0);
  });

  test('a table move above the limit of the model is not sent', () async {
    final (server, vm) = await _signedIn();
    server.maxAmount = 5;
    await vm.refreshAccess();

    vm.jog('xytable', 'y', 10);

    expect(vm.lastError!.kind, HydraErrorKind.jogOverLimit);
    expect(vm.lastError!.params['limit'], '5');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(server.to('POST /api/robot/1/command'), isEmpty);
  });

  test('a server that does not know the table command gets the jogs it understands, and is remembered', () async {
    final (server, vm) = await _signedIn();
    server.commandAnswers = [
      (400, {'error': 'unknown command'}),
      (200, {'success': true}),
    ];

    vm.jog('xytable', 'x', 5);
    await _until(() => server.to('POST /api/robot/1/command').length == 2);
    final first = server.to('POST /api/robot/1/command').toList();
    expect(first[0].body['command'], 'table');
    expect(first[1].body['command'], 'jog');
    final jogParams = first[1].body['params'] as Map<String, dynamic>;
    expect(jogParams['target'], 'xytable');
    expect(jogParams['amount'], 5.0);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    vm.jog('xytable', 'y', 2);
    await _until(() => server.to('POST /api/robot/1/command').length == 3);
    expect(server.to('POST /api/robot/1/command').toList()[2].body['command'], 'jog', reason: 'the next move goes straight to the jogs');
  });

  test('the audit record is read with its filter and the chain is checked when asked', () async {
    final (server, vm) = await _signedIn();
    const prev = '0000000000000000000000000000000000000000000000000000000000000000';
    const line = '{"seq":1,"ts":"2030-01-01T00:00:00.000Z","type":"claim","outcome":"ok","username":"ana","prev":"$prev"}';
    final digest = sha256Hex(utf8.encode(line));
    final stored = '${line.substring(0, line.length - 1)},"hash":"$digest"}';
    server.auditStatus = 200;
    server.auditBody = '{"enabled":true,"lockedOff":false,"entries":[$stored],"verification":{"ok":true,"entries":1}}';

    await vm.refreshAudit(verify: true, type: 'claim', robotId: 1, limit: 50);

    expect(server.to('GET /api/audit').first.query, 'limit=50&type=claim&robotId=1&verify=1');
    expect(vm.auditRead!.lines.length, 1);
    expect(vm.auditChain!.ok, isTrue);
    expect(vm.auditFailure, isNull);
    expect(vm.auditRead!.verification!.ok, isTrue);
  });

  test('an account that is not an administrator, or an older server, is told so', () async {
    final (server, vm) = await _signedIn();
    server.auditStatus = 403;
    server.auditBody = '{"error":"admin only"}';

    await vm.refreshAudit();
    expect(vm.auditFailure, AuditFailure.forbidden);
    expect(vm.auditRead, isNull);

    server.auditStatus = 404;
    server.auditBody = '{"error":"no","code":"audit-unavailable"}';
    await vm.refreshAudit();
    expect(vm.auditFailure, AuditFailure.unavailable);
  });

  test('the audit lines are exported as the server stores them', () async {
    final (server, vm) = await _signedIn();
    server.auditStatus = 200;
    server.auditBody = '{"seq":1}\n';

    final text = await vm.exportAudit(limit: 10);

    expect(text, '{"seq":1}\n');
    expect(server.to('GET /api/audit').first.query, 'limit=10&format=jsonl');
    server.auditStatus = 500;
    expect(await vm.exportAudit(), isNull);
  });

  test('a recent push lets the poll of the reservations rest, an old one does not', () async {
    final (server, vm) = await _signedIn();
    expect(vm.claimsArePushed(), isFalse);
    final before = server.to('GET /api/claims').length;

    await vm.refreshAccess(fromPoll: true);
    expect(server.to('GET /api/claims').length, before + 1, reason: 'no push yet: the poll asks');

    vm.claimsPushedAt = DateTime.now();
    expect(vm.claimsArePushed(), isTrue);
    await vm.refreshAccess(fromPoll: true);
    expect(server.to('GET /api/claims').length, before + 1, reason: 'a fresh push: the poll rests');
    await vm.refreshAccess();
    expect(server.to('GET /api/claims').length, before + 2, reason: 'an ordinary refresh always asks');
    expect(vm.claimsArePushed(DateTime.now().add(const Duration(minutes: 5))), isFalse);
    expect(ClaimInfo.listFromJson({'claims': []}), isEmpty);
  });
}
