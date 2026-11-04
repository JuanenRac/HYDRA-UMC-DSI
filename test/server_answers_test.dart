// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/server_answers_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The answers of the server as the SDK generates them from its inventory
// (test/fixtures/server-answers.json, a vendored copy kept identical by
// tools/sync_sdk_answers.py): the minimal body (required fields only) and the
// full body (every declared field) of each route the app reads must give a
// sane model, and a refusal body must reach the app as an error.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/models/stop_all_result.dart';
import 'package:hydra_umc_dsi/models/system_status.dart';
import 'package:hydra_umc_dsi/network/hydra_api_client.dart';

Map<String, dynamic> _answers(String route, String status, String kind) {
  final file = File('test/fixtures/server-answers.json');
  final routes = (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)['routes'] as Map<String, dynamic>;
  return ((routes[route] as Map<String, dynamic>)[status] as Map<String, dynamic>)[kind] as Map<String, dynamic>;
}

void main() {
  for (final kind in ['minimal', 'full']) {
    group('the $kind answers', () {
      test('GET /api/hydra-info reads as a server', () {
        final info = ServerInfo.fromHydraInfo('h', 3000, _answers('GET /api/hydra-info', '200', kind));
        expect(info.host, 'h');
        expect(info.remoteApiVersion, greaterThanOrEqualTo(0));
      });

      test('POST /api/stop-all reads as a result whose counts are whole numbers', () {
        final result = StopAllResult.fromJson(_answers('POST /api/stop-all', '200', kind));
        expect(result.stoppedCount, greaterThanOrEqualTo(0));
        expect(result.failedCount, greaterThanOrEqualTo(0));
        expect(result.robots.length, kind == 'full' ? greaterThan(0) : equals(0));
      });

      test('GET /api/ecosystem/status reads as a list of projects without throwing', () {
        final status = EcosystemStatus.parse(_answers('GET /api/ecosystem/status', '200', kind));
        for (final project in status.projects) {
          expect(project.name, isNotEmpty);
        }
      });

      test('POST /api/login is handed back whole by the client', () async {
        final body = _answers('POST /api/login', '200', kind);
        final client = HydraApiClient('127.0.0.1', 3000,
            client: MockClient((request) async => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'})));
        final answer = await client.login('u', 'p');
        expect(answer['token'], isA<String>());
        expect(answer['refreshToken'], isA<String>());
      });
    });
  }

  test('a refusal body of the login reaches the app as an error with the status', () async {
    final body = _answers('POST /api/login', '401', 'minimal');
    final client = HydraApiClient('127.0.0.1', 3000,
        client: MockClient((request) async => http.Response(jsonEncode(body), 401, headers: {'content-type': 'application/json'})));
    await expectLater(
      client.login('u', 'p'),
      throwsA(isA<HydraApiException>().having((e) => e.statusCode, 'statusCode', 401)),
    );
  });
}
