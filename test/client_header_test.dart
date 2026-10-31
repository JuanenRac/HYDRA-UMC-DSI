// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/client_header_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The X-Hydra-Client header of this app: its type and, after a slash, its
// version ("dsi/<version>"):
//   - the type is always "dsi" (the server compares the type only; the
//     version goes to its history of connections);
//   - the version is the one of the build and it is a version the server
//     accepts (1 to 24 of 0-9 A-Z a-z . _ -);
//   - a version the server would not accept is left out and the value is just
//     "dsi";
//   - every call, and the headers for the camera stream, carry it.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hydra_umc_dsi/app_version.dart';
import 'package:hydra_umc_dsi/network/hydra_api_client.dart';

// The pattern of the server (src/connections.ts, CLIENT_HEADER), for the whole value.
final RegExp _serverPattern = RegExp(r'^(studio|suite|android|ios|dsi|watch|voice)(?:/([0-9A-Za-z._-]{1,24}))?$');

void main() {
  group('the client identity header', () {
    test('is the type and the version of the build, and the server reads both', () {
      final value = HydraApiClient.clientHeaderValue(kAppVersion);
      expect(value, 'dsi/$kAppVersion');
      final match = _serverPattern.firstMatch(value);
      expect(match, isNotNull);
      expect(match!.group(1), 'dsi');
      expect(match.group(2), kAppVersion);
    });

    test('takes the longest version the server takes and none that it would not', () {
      expect(HydraApiClient.clientHeaderValue('0.8.1.6'), 'dsi/0.8.1.6');
      expect(HydraApiClient.clientHeaderValue('a' * 24), 'dsi/${'a' * 24}');
      for (final bad in <String>['', 'a' * 25, '0.7 5', '0.7/5', '0.7\r\nX-Evil: 1', 'v1,2', 'versi\u00f3n', ' 0.7.5', '0.7.5\n']) {
        expect(HydraApiClient.clientHeaderValue(bad), 'dsi', reason: bad);
      }
    });

    test('every request carries it, and so do the headers of the camera stream', () async {
      final seen = <http.Request>[];
      final client = HydraApiClient('127.0.0.1', 3000, client: MockClient((request) async {
        seen.add(request);
        return http.Response('{}', 200);
      }));
      client.authToken = 'tok.en';
      await client.getSettings();
      await client.postRobotCommand(3, <String, dynamic>{'command': 'stop'});
      expect(seen, isNotEmpty);
      for (final request in seen) {
        expect(request.headers['X-Hydra-Client'], 'dsi/$kAppVersion');
      }
      expect(client.mediaHeaders['X-Hydra-Client'], 'dsi/$kAppVersion');
    });
  });
}
