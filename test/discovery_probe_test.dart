// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/discovery_probe_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The probe the app hands to the shared discovery code: a host that answers
// with the identity of a server becomes a ServerInfo, a host that answers
// with anything else, or does not answer, becomes null, and the client given
// to the probe is left open for the next host of the sweep.
// =============================================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hydra_umc_dsi/network/discovery.dart';

class _CountingClient extends MockClient {
  _CountingClient(super.fn);
  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  test('a host that answers with the identity of a server becomes a ServerInfo', () async {
    final client = _CountingClient((request) async {
      expect(request.url.path, '/api/hydra-info');
      return http.Response(
        jsonEncode({'product': 'HYDRA-UMC-SERVER', 'appVersion': '0.9.1', 'hostname': 'cm5', 'remoteApiVersion': 2, 'robotCount': 4}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final info = await discoveryProbe(client: client)('10.0.0.5', 3000);
    expect(info, isNotNull);
    expect(info!.host, '10.0.0.5');
    expect(info.port, 3000);
    expect(info.displayName, 'cm5');
    expect(info.robotCount, 4);
    expect(client.closed, isFalse, reason: 'the client of a sweep stays open between hosts');
  });

  test('a host that answers with something else becomes null', () async {
    final client = _CountingClient((request) async => http.Response('<html>router</html>', 200));
    expect(await discoveryProbe(client: client)('10.0.0.1', 3000), isNull);
    expect(client.closed, isFalse);
  });

  test('a host that does not answer becomes null', () async {
    final client = _CountingClient((request) async => throw http.ClientException('unreachable'));
    expect(await discoveryProbe(client: client)('10.0.0.9', 3000), isNull);
  });
}
