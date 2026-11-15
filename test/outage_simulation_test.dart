// =============================================================================
// HYDRA-UMC-DSI - test/outage_simulation_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Simulation of a server that goes wrong and comes back, with a stand-in for the
// network (no hardware, no panel): the connection is cut, the server answers 503
// or 504, a page that is not JSON, an expired session. The order of the faults is
// drawn from a fixed seed. What must hold on the panel: every fault reaches the
// caller as an error and never as a silent success (the global STOP above all),
// and the call after the server is back works as if nothing had happened.
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hydra_umc_dsi/network/hydra_api_client.dart';

enum _Fault { cut, unavailable, gatewayTimeout, notJson, sessionExpired }

const _seed = 20260101;

/// The faults in an order drawn from the seed, [rounds] times each.
List<_Fault> _drawn(int rounds, int seed) {
  final all = <_Fault>[for (var i = 0; i < rounds; i++) ..._Fault.values];
  all.shuffle(Random(seed));
  return all;
}

const _stopAnswer = <String, dynamic>{
  'success': true,
  'stoppedCount': 2,
  'failedCount': 0,
  'persisted': true,
  'robots': [
    {'robotId': 1, 'controllerId': 'c1', 'name': 'A1', 'stopped': true, 'valvesOff': 1, 'pumpsOff': 0},
    {'robotId': 2, 'controllerId': 'c1', 'name': 'A2', 'stopped': true, 'valvesOff': 0, 'pumpsOff': 1},
  ],
};

class _Network {
  _Fault? fault;
  int calls = 0;

  http.Response answer(http.Request request) {
    calls++;
    switch (fault) {
      case null:
        if (request.url.path.endsWith('/api/stop-all')) {
          return http.Response(jsonEncode(_stopAnswer), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{"controllers":[]}', 200, headers: {'content-type': 'application/json'});
      case _Fault.cut:
        throw const SocketException('connection reset by peer');
      case _Fault.unavailable:
        return http.Response('{"error":"service unavailable"}', 503);
      case _Fault.gatewayTimeout:
        return http.Response('<html>gateway timeout</html>', 504);
      case _Fault.notJson:
        return http.Response('<html>captive portal</html>', 200);
      case _Fault.sessionExpired:
        return http.Response('{"error":"Token expired","code":"TOKEN_EXPIRED"}', 403);
    }
  }
}

HydraApiClient _clientOn(_Network network) {
  final client = HydraApiClient('127.0.0.1', 3000, client: MockClient((request) async => network.answer(request)));
  client.authToken = 'tok';
  return client;
}

void main() {
  test('each fault of the server is an error for the settings and the next call after it works, in any order', () async {
    final network = _Network();
    final client = _clientOn(network);
    for (final fault in _drawn(4, _seed)) {
      network.fault = fault;
      Object? error;
      try {
        await client.getSettings();
      } catch (e) {
        error = e;
      }
      expect(error, isNotNull, reason: 'the fault $fault must not look like a success');
      if (fault == _Fault.unavailable || fault == _Fault.gatewayTimeout) {
        expect(error, isA<HydraApiException>(), reason: '$fault');
        expect((error! as HydraApiException).statusCode, fault == _Fault.unavailable ? 503 : 504);
      }
      if (fault == _Fault.sessionExpired) {
        expect(error, isA<HydraApiException>());
        expect((error! as HydraApiException).isSessionProblem, isTrue);
      }
      network.fault = null;
      final settings = await client.getSettings();
      expect(settings['controllers'], isA<List<dynamic>>(), reason: 'the call after $fault');
    }
  });

  test('the global STOP is never reported as done while the server is wrong, and is answered once it is back', () async {
    final network = _Network();
    final client = _clientOn(network);
    for (final fault in _drawn(3, _seed + 1)) {
      network.fault = fault;
      Object? error;
      Map<String, dynamic>? answer;
      try {
        answer = await client.postStopAll();
      } catch (e) {
        error = e;
      }
      expect(answer, isNull, reason: 'a STOP under $fault must not come back as an answer');
      expect(error, isNotNull, reason: '$fault');
      network.fault = null;
      final stop = await client.postStopAll();
      expect(stop['stoppedCount'], 2);
      expect(stop['failedCount'], 0);
    }
  });

  test('the order of the faults is the same for the same seed and another for another seed', () {
    expect(_drawn(4, _seed), _drawn(4, _seed));
    expect(_drawn(4, _seed), isNot(_drawn(4, _seed + 7)));
  });

  test('a long outage leaves no memory in the client: after fifty failed calls the first good one is answered', () async {
    final network = _Network();
    final client = _clientOn(network);
    final random = Random(_seed + 2);
    var failures = 0;
    for (var i = 0; i < 50; i++) {
      network.fault = _Fault.values[random.nextInt(_Fault.values.length)];
      try {
        await client.getSettings();
      } catch (_) {
        failures++;
      }
    }
    expect(failures, 50);
    network.fault = null;
    expect((await client.getSettings())['controllers'], isA<List<dynamic>>());
  });
}
