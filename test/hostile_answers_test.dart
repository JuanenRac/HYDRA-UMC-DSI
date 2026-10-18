// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/hostile_answers_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// What the app does with answers that are wrong, partial or hostile:
//   - the models read a settings tree whose fields have the wrong type
//     without throwing;
//   - the HTTP client turns every answer that is not a JSON object into a
//     HydraApiException (and keeps the status of a refusal that is not JSON);
//   - the global STOP answer is read field by field, an odd number never
//     loses it;
//   - the discovery record of a device that answers /api/hydra-info with
//     something else does not throw;
//   - the reconnect back-off stays between its floor and its ceiling for any
//     number of failed attempts (2^n overflows a 64-bit integer);
//   - frames of the wrong shape on the WebSocket are ignored, and the next
//     good frame still arrives.
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hydra_umc_dsi/models/hydra_state.dart';
import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/models/stop_all_result.dart';
import 'package:hydra_umc_dsi/network/hydra_api_client.dart';
import 'package:hydra_umc_dsi/network/hydra_websocket.dart';
import 'package:hydra_umc_dsi/state/hydra_error.dart';

HydraApiClient _client(http.Response Function(http.Request) answer) =>
    HydraApiClient('127.0.0.1', 3000, client: MockClient((request) async => answer(request)));

void main() {
  group('HydraState reads a tree with fields of the wrong type', () {
    test('a robot whose fields are not what they should be reads as its defaults', () {
      final robot = RobotView(<String, dynamic>{
        'id': 7,
        'name': 5,
        'online': 'yes',
        'model': ['x'],
        'role': 3,
        'tool': {'a': 1},
        'hasXYTable': 'true',
        'visionEnabled': 'yes',
        'camera': 'connected',
        'juanenPnP': 'on',
        'lumenPnP': 5,
        'heatedBed': ['enabled'],
        'combinedWith': 'x',
        'playbackState': {'isPlaying': 'true', 'isPaused': 1, 'speed': 'fast', 'acceleration': null},
        'pos': {'x': 'far'},
        'controllerBoard': 'board',
        'urtcHead': [1],
      });
      expect(robot.name, 'Robot 7');
      expect(robot.online, isFalse);
      expect(robot.model, 'Generic (6-DOF)');
      expect(robot.role, 'Idle');
      expect(robot.tool, 'None');
      expect(robot.hasXYTable, isFalse);
      expect(robot.hasCamera, isFalse);
      expect(robot.hasPnP, isFalse);
      expect(robot.hasHeatedBed, isFalse);
      expect(robot.combinedWith, isEmpty);
      expect(robot.isPlaying, isFalse);
      expect(robot.isPaused, isFalse);
      expect(robot.speed, 100.0);
      expect(robot.acceleration, 100.0);
      expect(robot.posAxis('x'), 0.0);
      expect(robot.controllerBoard, isNull);
      expect(robot.urtcHead, isNull);
    });

    test('a well-formed robot still reads its own values', () {
      final robot = RobotView(<String, dynamic>{
        'id': 1,
        'name': 'Arm',
        'online': true,
        'model': 'AR4',
        'role': 'Pick',
        'tool': 'Gripper',
        'hasXYTable': true,
        'visionEnabled': false,
        'camera': {'connected': true},
        'juanenPnP': {'enabled': true},
        'playbackState': {'isPlaying': true, 'speed': 40, 'acceleration': 12.5},
        'pos': {'x': 3},
        'controllerBoard': {'a': 1},
      });
      expect(robot.name, 'Arm');
      expect(robot.online, isTrue);
      expect(robot.manufacturer, 'Annin Robotics');
      expect(robot.role, 'Pick');
      expect(robot.tool, 'Gripper');
      expect(robot.hasXYTable, isTrue);
      expect(robot.hasCamera, isTrue);
      expect(robot.hasPnP, isTrue);
      expect(robot.isPlaying, isTrue);
      expect(robot.speed, 40.0);
      expect(robot.acceleration, 12.5);
      expect(robot.posAxis('x'), 3.0);
      expect(robot.controllerBoard, {'a': 1});
    });

    test('controllers, robots and cameras that are not objects are skipped', () {
      final state = HydraState(<String, dynamic>{
        'activeControllerId': 5,
        'controllers': [
          5,
          null,
          'x',
          {
            'id': 9,
            'name': 3,
            'ip': 4,
            'robots': [
              7,
              {'id': 1},
              'x',
              null,
            ],
            'cameras': [
              1,
              {'id': 'cam'},
            ],
          },
          {'id': '5', 'robots': 'none', 'cameras': 'none'},
        ],
      });
      final controllers = state.controllers;
      expect(controllers.length, 2);
      expect(controllers.first.id, '9');
      expect(controllers.first.name, '9');
      expect(controllers.first.ip, '');
      expect(controllers.first.robots.map((r) => r.id), [1]);
      expect(controllers.first.cameras.length, 1);
      expect(controllers.last.robots, isEmpty);
      expect(controllers.last.cameras, isEmpty);
      expect(state.activeControllerId, '5');
      expect(state.activeController?.id, '5');
    });

    test('a tree that is empty or has controllers that are not a list reads as no controllers', () {
      expect(HydraState().controllers, isEmpty);
      expect(HydraState(<String, dynamic>{'controllers': 'x'}).controllers, isEmpty);
      expect(HydraState(<String, dynamic>{'controllers': {'a': 1}}).activeController, isNull);
    });
  });

  group('ServerInfo.fromHydraInfo', () {
    test('a device that answers with the wrong types does not break the scan', () {
      final info = ServerInfo.fromHydraInfo('10.0.0.5', 3000, <String, dynamic>{
        'product': 5,
        'appVersion': ['1'],
        'hostname': {'a': 1},
        'remoteApiVersion': 'two',
        'controllerCount': null,
        'robotCount': 3.9,
        'uptimeSeconds': double.nan,
      });
      expect(info.product, '');
      expect(info.appVersion, '');
      expect(info.hostname, '');
      expect(info.remoteApiVersion, 0);
      expect(info.controllerCount, 0);
      expect(info.robotCount, 3);
      expect(info.uptimeSeconds, 0);
      expect(info.displayName, '10.0.0.5');
    });

    test('a real hydra-info record is read as it is', () {
      final info = ServerInfo.fromHydraInfo('h', 3000, <String, dynamic>{
        'product': 'HYDRA-UMC-SERVER',
        'appVersion': '0.9.1',
        'hostname': 'cm5',
        'remoteApiVersion': 2,
        'controllerCount': 1,
        'robotCount': 4,
        'uptimeSeconds': 120,
      });
      expect(info.displayName, 'cm5');
      expect(info.remoteApiVersion, 2);
      expect(info.robotCount, 4);
    });
  });

  group('HydraApiClient answers', () {
    test('a 200 whose body is not a JSON object is a HydraApiException, not a cast error', () async {
      for (final body in ['[]', 'null', '5', '"text"', '<html>', '']) {
        final client = _client((_) => http.Response(body, 200));
        client.authToken = 'tok';
        await expectLater(client.getSettings(), throwsA(isA<HydraApiException>()), reason: 'body: $body');
      }
    });

    test('a refusal that is not JSON keeps its status and has no code', () async {
      for (final body in ['<html>bad gateway</html>', '[]', 'null', '', '{"error": 5}', '{"code": 7}']) {
        final client = _client((_) => http.Response(body, 502));
        client.authToken = 'tok';
        try {
          await client.getSettings();
          fail('expected a HydraApiException');
        } on HydraApiException catch (e) {
          expect(e.statusCode, 502, reason: 'body: $body');
          expect(e.code, isNull, reason: 'body: $body');
          expect(e.serverMessage, isNull, reason: 'body: $body');
        }
      }
    });

    test('the code and the text of a JSON refusal are kept', () async {
      final client = _client((_) => http.Response('{"error":"Token expired","code":"TOKEN_EXPIRED"}', 403));
      client.authToken = 'tok';
      try {
        await client.getSettings();
        fail('expected a HydraApiException');
      } on HydraApiException catch (e) {
        expect(e.isSessionProblem, isTrue);
        expect(e.isPermissionDenied, isFalse);
        expect(e.serverMessage, 'Token expired');
      }
    });

    test('what each status means to the app', () {
      HydraApiException e(int status, [String? code]) => HydraApiException('x', statusCode: status, code: code);
      expect(e(401).isSessionProblem, isTrue);
      expect(e(403, 'TOKEN_EXPIRED').isSessionProblem, isTrue);
      expect(e(403, 'TOKEN_INVALID').isSessionProblem, isTrue);
      expect(e(403).isSessionProblem, isFalse);
      expect(e(403).isPermissionDenied, isTrue);
      expect(e(403, 'TOKEN_EXPIRED').isPermissionDenied, isFalse);
      expect(e(409).isReservedByAnother, isTrue);
      expect(e(400).isRejectedCommand, isTrue);
      expect(e(429).isRateLimited, isTrue);
      expect(e(404).isNotFound, isTrue);
      expect(HydraApiException('no answer').statusCode, isNull);
      expect(e(500).isSessionProblem || e(500).isReservedByAnother || e(500).isRejectedCommand, isFalse);
    });

    test('every call carries the client identity, the bearer token goes in a header only', () async {
      final seen = <http.Request>[];
      final client = _client((request) {
        seen.add(request);
        return http.Response('{}', 200);
      });
      client.authToken = 'tok.en';
      await client.getSettings();
      await client.postRobotCommand(3, <String, dynamic>{'command': 'stop'});
      final real = seen.where((r) => !r.url.path.endsWith('/hydra-info')).toList();
      expect(real.length, 2);
      for (final request in real) {
        expect(request.headers['Authorization'], 'Bearer tok.en');
        expect(request.headers['X-Hydra-Client'], isNotEmpty);
        expect(request.url.toString(), isNot(contains('tok.en')));
      }
      expect(real[1].url.path, '/api/robot/3/command');
    });

    test('a request without a token sends no Authorization header', () async {
      final seen = <http.Request>[];
      final client = _client((request) {
        seen.add(request);
        return http.Response('{}', 200);
      });
      await client.getSettings();
      expect(seen.where((r) => r.headers.containsKey('Authorization')), isEmpty);
    });

    test('logoutRemote never throws, whatever happens', () async {
      final failing = HydraApiClient('127.0.0.1', 3000, client: MockClient((_) async => throw const SocketException('down')));
      await failing.logoutRemote('refresh-token');
      final slow = _client((_) => http.Response('boom', 500));
      await slow.logoutRemote('refresh-token');
    });
  });

  group('StopAllResult reads the answer of the global STOP', () {
    test('numbers that are not finite do not lose the answer', () {
      final body = jsonDecode('{"success":true,"stoppedCount":1e999,"failedCount":-1e999,"robots":[{"robotId":1,"stopped":true,"valvesOff":1e999,"pumpsOff":2}]}')
          as Map<String, dynamic>;
      final result = StopAllResult.fromJson(body);
      expect(result.stoppedCount, 1, reason: 'derived from the list when the count is not a number it can use');
      expect(result.failedCount, 0);
      expect(result.robots.single.valvesOff, 0);
      expect(result.robots.single.pumpsOff, 2);
    });

    test('entries and fields of the wrong type are ignored', () {
      final result = StopAllResult.fromJson(<String, dynamic>{
        'success': 'yes',
        'persisted': 'no',
        'robots': [
          5,
          null,
          'x',
          {'robotId': [1], 'name': 7, 'controllerId': 3, 'stopped': 'true', 'reservedBy': 4, 'error': ['e']},
          {'robotId': 2, 'stopped': true},
        ],
      });
      expect(result.success, isFalse);
      expect(result.robots.length, 2);
      expect(result.robots.first.stopped, isFalse);
      expect(result.robots.first.controllerId, isNull);
      expect(result.robots.first.reservedBy, isNull);
      expect(result.robots.first.error, isNull);
      expect(result.stoppedCount, 1);
      expect(result.failedCount, 1);
      expect(result.needsAttention, isTrue);
    });

    test('robots that is not a list reads as no robots', () {
      for (final robots in [5, 'x', {'a': 1}, null]) {
        final result = StopAllResult.fromJson(<String, dynamic>{'success': true, 'robots': robots});
        expect(result.robots, isEmpty);
        expect(result.stoppedCount, 0);
      }
    });

    test('a clean answer needs no attention, a missing persisted flag counts as saved', () {
      final result = StopAllResult.fromJson(<String, dynamic>{
        'success': true,
        'stoppedCount': 2,
        'failedCount': 0,
        'robots': [
          {'robotId': 1, 'stopped': true},
          {'robotId': 2, 'stopped': true},
        ],
      });
      expect(result.persisted, isTrue);
      expect(result.needsAttention, isFalse);
      final unsaved = StopAllResult.fromJson(<String, dynamic>{'success': true, 'persisted': false, 'robots': []});
      expect(unsaved.needsAttention, isTrue);
    });

    test('built from per-robot stops it counts what stopped', () {
      final result = StopAllResult.fromRobots(const [
        StopAllRobot(robotId: 1, name: 'A', stopped: true),
        StopAllRobot(robotId: 2, name: 'B', stopped: false, error: 'no link'),
      ], viaFallback: true);
      expect(result.success, isFalse);
      expect(result.stoppedCount, 1);
      expect(result.failedCount, 1);
      expect(result.viaFallback, isTrue);
      expect(result.needsAttention, isTrue);
    });
  });

  group('reconnectBackoff', () {
    test('starts at the base delay, doubles, and never leaves its floor and ceiling', () {
      expect(reconnectBackoff(0), reconnectDelay);
      expect(reconnectBackoff(1), reconnectDelay);
      expect(reconnectBackoff(2), reconnectDelay * 2);
      expect(reconnectBackoff(3), reconnectDelay * 4);
      expect(reconnectBackoff(5), maxReconnectDelay);
      var previous = Duration.zero;
      for (var attempts = 0; attempts <= 500; attempts++) {
        final wait = reconnectBackoff(attempts);
        expect(wait >= reconnectDelay, isTrue, reason: 'attempt $attempts waited $wait');
        expect(wait <= maxReconnectDelay, isTrue, reason: 'attempt $attempts waited $wait');
        expect(wait >= previous, isTrue, reason: 'the wait must never shrink (attempt $attempts)');
        previous = wait;
      }
    });
  });

  group('WebSocket frames of the wrong shape', () {
    test('are ignored, and the next good frame still arrives', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final sockets = StreamController<WebSocket>.broadcast();
      server.listen((request) async {
        try {
          final socket = await WebSocketTransformer.upgrade(
            request,
            protocolSelector: (p) => p.contains('hydra.bearer') ? 'hydra.bearer' : null,
          );
          sockets.add(socket);
        } catch (_) {
          // a client that drops mid-handshake is not a failure of this test
        }
      });

      final settings = <Map<String, dynamic>>[];
      final deltas = <Map<String, dynamic>>[];
      final errors = <HydraError>[];
      final ws = HydraWebSocket(
        host: '127.0.0.1',
        port: server.port,
        token: 'tok.en-1',
        onStatus: (_) {},
        onSettings: settings.add,
        onError: errors.add,
        onDelta: deltas.add,
      );
      final connected = sockets.stream.first;
      ws.connect();
      final socket = await connected.timeout(const Duration(seconds: 5));

      for (final frame in [
        'not json',
        '',
        '[]',
        '5',
        'null',
        '"text"',
        '{"type":"other"}',
        '{"type":"settings"}',
        '{"type":"settings","payload":[1]}',
        '{"type":"settings","payload":"x"}',
        '{"type":"delta","payload":5}',
        '{"error":5}',
        '{"error":""}',
        '{"error":null}',
      ]) {
        socket.add(frame);
      }
      socket.add(utf8.encode('{"type":"settings","payload":{"controllers":[]}}')); // binary frame
      socket.add('{"type":"settings","payload":{"controllers":[],"marker":1}}');
      socket.add('{"type":"delta","schema":2,"robotId":4,"patch":{"x":1}}');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(settings.length, 1, reason: 'only the one good settings frame');
      expect(settings.single['marker'], 1);
      expect(deltas.length, 1);
      expect(deltas.single['robotId'], 4);
      expect(errors, isEmpty, reason: 'junk frames are not errors');
      ws.disconnect();
    });

    test('an error text from the server is passed on once, as a server message', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final sockets = StreamController<WebSocket>.broadcast();
      server.listen((request) async {
        try {
          sockets.add(await WebSocketTransformer.upgrade(
            request,
            protocolSelector: (p) => p.contains('hydra.bearer') ? 'hydra.bearer' : null,
          ));
        } catch (_) {}
      });
      final errors = <HydraError>[];
      final ws = HydraWebSocket(
        host: '127.0.0.1',
        port: server.port,
        token: 'tok.en-2',
        onStatus: (_) {},
        onSettings: (_) {},
        onError: errors.add,
      );
      final connected = sockets.stream.first;
      ws.connect();
      final socket = await connected.timeout(const Duration(seconds: 5));
      socket.add('{"error":"Access denied: admin privileges required"}');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(errors.length, 1);
      expect(errors.single.kind, HydraErrorKind.serverMessage);
      expect(errors.single.params['message'], 'Access denied: admin privileges required');
      ws.disconnect();
    });
  });
}
