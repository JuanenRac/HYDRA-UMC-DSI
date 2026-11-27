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
  final sent = <(String?, String?, String)>[]; // If-Match, X-Controller-Id, body
  var status = 200;
  var answer = '{}';

  setUp(() async {
    seen.clear();
    auth.clear();
    sent.clear();
    http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    http.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      sent.add((request.headers.value('if-match'), request.headers.value('x-controller-id'), body));
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

  test('a claim goes out with the token, the controller and the revision, and gives the new revision', () async {
    answer = '{"success":true,"reservation":{"ownerUsername":"ana"},"reservationHistory":[],"revision":"r2"}';
    final claimed = await client.postClaim(2, ifMatch: '"r1"');
    expect(claimed['revision'], 'r2');
    expect((claimed['reservation'] as Map)['ownerUsername'], 'ana');
    expect(seen.single, 'POST /api/robot/2/claim');
    expect(auth.single, 'Bearer tok');
    expect(sent.single.$1, '"r1"');
    expect(sent.single.$2, HydraApiClient.controllerId);
    expect(jsonDecode(sent.single.$3), {'controllerId': HydraApiClient.controllerId});
  });

  test('a take over sends force and the life of the claim', () async {
    answer = '{"success":true,"reservation":{},"reservationHistory":[],"revision":"r3"}';
    await client.postClaim(2, ttlMs: 60000, force: true);
    expect(sent.single.$1, isNull);
    expect(jsonDecode(sent.single.$3), {'ttlMs': 60000, 'force': true, 'controllerId': HydraApiClient.controllerId});
  });

  test('an older server with no revision and a release with no history are accepted', () async {
    answer = '{"success":true,"reservation":{},"reservationHistory":[]}';
    expect((await client.postClaim(2))['revision'], '');
    answer = '{"success":true}';
    expect((await client.postRelease(2))['success'], isTrue);
    expect(seen, ['POST /api/robot/2/claim', 'POST /api/robot/2/release']);
  });

  test('a claim answer without a reservation is an API error', () async {
    answer = '{"success":true}';
    await expectLater(client.postClaim(2), throwsA(isA<HydraApiException>()));
  });

  test('a refused claim keeps the code of the server', () async {
    status = 409;
    answer = '{"error":"x","code":"other-account"}';
    await expectLater(client.postClaim(2), throwsA(isA<HydraApiException>().having((e) => e.code, 'code', 'other-account')));
  });
}
