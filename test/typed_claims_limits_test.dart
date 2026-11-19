// =============================================================================
// HYDRA-UMC-DSI - test/typed_claims_limits_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The reservations and the safety limits go through the generated client: the request, the token and the errors, against a local dart:io HttpServer.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydra_umc_dsi/network/hydra_api_client.dart';

void main() {
  late HttpServer http;
  late HydraApiClient client;
  final seen = <String>[];
  final auth = <String>[];
  var status = 200;
  var answer = '{}';

  setUp(() async {
    seen.clear();
    auth.clear();
    http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    http.listen((request) async {
      seen.add('${request.method} ${request.uri}');
      auth.add(request.headers.value('authorization') ?? '');
      request.response.headers.contentType = ContentType.json;
      request.response.statusCode = status;
      request.response.write(answer);
      await request.response.close();
    });
    status = 200;
    client = HydraApiClient('127.0.0.1', http.port);
    client.authToken = 'tok';
  });

  tearDown(() async {
    client.close();
    await http.close(force: true);
  });

  test('the claims are read through the generated client with the token', () async {
    answer = jsonEncode({
      'claims': [
        {'robotId': 2, 'ownerUsername': 'ana', 'claimedAt': 1000, 'expiresAt': 2000},
      ],
    });
    final claims = await client.getClaims();
    expect(claims, hasLength(1));
    expect(seen.single, 'GET /api/claims');
    expect(auth.single, 'Bearer tok');
  });

  test('a claim list that misses a required field is an API error', () async {
    answer = '{"claims":[{"robotId":2}]}';
    await expectLater(client.getClaims(), throwsA(isA<HydraApiException>()));
  });

  test('the safety limits of an older server without the route are null', () async {
    status = 404;
    answer = '{"error":"not found"}';
    expect(await client.getRobotSafety(3), isNull);
    expect(seen.single, 'GET /api/safety-limits?robotId=3');
  });

  test('another error of the safety limits is thrown', () async {
    status = 500;
    answer = '{"error":"boom"}';
    await expectLater(client.getRobotSafety(3), throwsA(isA<HydraApiException>()));
  });
}
