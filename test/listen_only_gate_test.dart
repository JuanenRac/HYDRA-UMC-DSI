// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/listen_only_gate_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Listen-only mode at the door of the network: every write is refused with a 423 and never reaches the server, except STOP, the
// sign-in and the renewal and end of the session; reads and everything else go through when it is off.
// =============================================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show HttpRequestData;
import 'package:hydra_umc_dsi/network/listen_only_gate.dart';
import 'package:hydra_umc_dsi/network/package_http_transport.dart';

String _cmd(String command) => jsonEncode({'command': command});

void main() {
  tearDown(() => ListenOnlyGate.enabled = false);

  test('reads, STOP and the session are allowed', () {
    expect(ListenOnlyGate.allows('GET', '/api/settings', null), isTrue);
    expect(ListenOnlyGate.allows('HEAD', '/api/settings', null), isTrue);
    expect(ListenOnlyGate.allows('POST', '/api/stop-all', null), isTrue);
    for (final c in ['stop', 'disable']) {
      expect(ListenOnlyGate.allows('POST', '/api/robot/3/command', _cmd(c)), isTrue, reason: c);
    }
    for (final p in ['/api/login', '/api/refresh', '/api/logout', '/api/device/login']) {
      expect(ListenOnlyGate.allows('POST', p, '{}'), isTrue, reason: p);
    }
  });

  test('every other robot command and every write of the administration is refused', () {
    for (final c in ['jog', 'jogStart', 'play', 'pause', 'reset', 'enable', 'tool', 'valve', 'pump', 'speed', 'vision']) {
      expect(ListenOnlyGate.allows('POST', '/api/robot/3/command', _cmd(c)), isFalse, reason: c);
    }
    expect(ListenOnlyGate.allows('POST', '/api/robot/3/command', 'not json'), isFalse);
    expect(ListenOnlyGate.allows('POST', '/api/robot/3/command', null), isFalse);
    for (final w in [
      ['POST', '/api/settings'], ['PUT', '/api/settings'], ['POST', '/api/system/reboot'], ['DELETE', '/api/users/bob'],
      ['POST', '/api/push/device'], ['POST', '/api/presence'], ['POST', '/api/claims'], ['PUT', '/api/server/config'],
    ]) {
      expect(ListenOnlyGate.allows(w[0], w[1], '{}'), isFalse, reason: '${w[0]} ${w[1]}');
    }
  });

  test('the transport sends nothing refused and answers 423, and is plain when the mode is off', () async {
    var sent = 0;
    final transport = PackageHttpTransport(MockClient((http.Request r) async {
      sent++;
      return http.Response('{}', 200);
    }));
    const write = HttpRequestData('POST', 'http://127.0.0.1:3000/api/settings', body: '{}');

    expect((await transport.send(write)).statusCode, 200);
    expect(sent, 1);

    ListenOnlyGate.enabled = true;
    final refused = await transport.send(write);
    expect(refused.statusCode, 423);
    expect(jsonDecode(refused.body)['code'], 'listen-only');
    expect(sent, 1, reason: 'a refused write never reaches the server');

    await transport.send(const HttpRequestData('GET', 'http://127.0.0.1:3000/api/settings'));
    await transport.send(const HttpRequestData('POST', 'http://127.0.0.1:3000/api/stop-all'));
    expect(sent, 3);
  });
}
