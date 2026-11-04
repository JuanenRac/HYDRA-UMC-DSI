// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/system_status_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// What the System tab reads: the verdict of the safety service and the status
// of the ecosystem. Both are parsed defensively, and anything that is not
// clearly a current READY is never shown as one.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hydra_umc_dsi/models/system_status.dart';
import 'package:hydra_umc_dsi/network/safety_zones_client.dart';

void main() {
  final read = DateTime.utc(2000, 1, 1, 12, 0, 10);

  Map<String, dynamic> verdict(String state, {String? at, String reason = '', bool signed = false}) => {
        'sdkSafetyState': {'schema_version': '1.0', 'state': state, 'source': 'hydra-umc-safety-zones', 'timestamp_utc': ?at},
        'reason': reason,
        if (signed) 'sdkSafetyStateSignature': {'sig': 'x'},
      };

  group('SafetyStatus', () {
    test('the states of the contract are read, in any case', () {
      expect(SafetyStatus.parse(verdict('READY'), read).level, SafetyLevel.ready);
      expect(SafetyStatus.parse(verdict('warning'), read).level, SafetyLevel.warning);
      expect(SafetyStatus.parse(verdict('DANGER'), read).level, SafetyLevel.danger);
      expect(SafetyStatus.parse(verdict('INHIBITED'), read).level, SafetyLevel.inhibited);
      expect(SafetyStatus.parse(verdict('FAULT'), read).level, SafetyLevel.fault);
    });

    test('anything else, or nothing at all, is unknown and never ready', () {
      expect(SafetyStatus.parse(verdict('SAFE-ISH'), read).level, SafetyLevel.unknown);
      expect(SafetyStatus.parse(const {}, read).level, SafetyLevel.unknown);
      expect(SafetyStatus.parse({'sdkSafetyState': 'READY'}, read).level, SafetyLevel.unknown);
      expect(SafetyStatus.parse({'sdkSafetyState': {'state': 7}}, read).level, SafetyLevel.unknown);
    });

    test('the reason, the time and the signature', () {
      final s = SafetyStatus.parse(verdict('DANGER', at: '2000-01-01T12:00:05+00:00', reason: 'zone 2 breached', signed: true), read);
      expect(s.reason, 'zone 2 breached');
      expect(s.reachedAt, DateTime.utc(2000, 1, 1, 12, 0, 5));
      expect(s.signed, isTrue);
      expect(SafetyStatus.parse(verdict('READY', at: 'garbage'), read).reachedAt, isNull);
    });

    test('only a CURRENT ready is confirmed', () {
      final s = SafetyStatus.parse(verdict('READY', at: '2000-01-01T12:00:05+00:00'), read);
      const limit = Duration(seconds: 10);
      expect(s.isConfirmedReady(DateTime.utc(2000, 1, 1, 12, 0, 12), limit), isTrue);
      expect(s.isConfirmedReady(DateTime.utc(2000, 1, 1, 12, 0, 20), limit), isFalse, reason: 'a stale READY is not a READY');
      expect(SafetyStatus.parse(verdict('DANGER', at: '2000-01-01T12:00:09+00:00'), read).isConfirmedReady(read, limit), isFalse);
    });

    test('with no time of its own the time it was read counts', () {
      final s = SafetyStatus.parse(verdict('READY'), read);
      expect(s.isStale(read.add(const Duration(seconds: 5)), const Duration(seconds: 10)), isFalse);
      expect(s.isStale(read.add(const Duration(seconds: 15)), const Duration(seconds: 10)), isTrue);
    });
  });

  group('SafetyZonesClient', () {
    SafetyZonesClient client(MockClient mock, {String token = ''}) => SafetyZonesClient(host: '127.0.0.1', port: 8108, token: token, client: mock, clock: () => read);

    test('reads /state and sends the token only when there is one', () async {
      http.Request? seen;
      final ok = client(MockClient((r) async {
        seen = r;
        return http.Response('{"sdkSafetyState":{"state":"READY"},"reason":""}', 200);
      }), token: 'secret');
      final s = await ok.read();
      expect(s.level, SafetyLevel.ready);
      expect(seen!.url.toString(), 'http://127.0.0.1:8108/state');
      expect(seen!.headers['Authorization'], 'Bearer secret');

      http.Request? plain;
      await client(MockClient((r) async {
        plain = r;
        return http.Response('{"sdkSafetyState":{"state":"READY"}}', 200);
      })).read();
      expect(plain!.headers.containsKey('Authorization'), isFalse);
    });

    test('a 404 is "no verdict yet", not safe', () async {
      final s = await client(MockClient((r) async => http.Response('{"error":"no safety verdict has been reached yet"}', 404))).read();
      expect(s.noVerdictYet, isTrue);
      expect(s.level, SafetyLevel.unknown);
    });

    test('a refused token, a broken answer and a silent service are failures, never a made-up state', () async {
      Future<SafetyFailure> failure(MockClient mock) async {
        try {
          await client(mock).read();
        } on SafetyZonesException catch (e) {
          return e.failure;
        }
        fail('expected an exception');
      }

      expect(await failure(MockClient((r) async => http.Response('{}', 401))), SafetyFailure.unauthorized);
      expect(await failure(MockClient((r) async => http.Response('boom', 500))), SafetyFailure.other);
      expect(await failure(MockClient((r) async => http.Response('not json', 200))), SafetyFailure.other);
      expect(await failure(MockClient((r) async => http.Response('[1]', 200))), SafetyFailure.other);
      expect(await failure(MockClient((r) async => throw http.ClientException('refused'))), SafetyFailure.unreachable);
    });
  });

  group('EcosystemStatus', () {
    final raw = {
      'available': true,
      'scannedAt': '2000-01-01T12:00:00.000Z',
      'projects': [
        {'name': 'HYDRA-UMC-DATALAKE', 'version': '0.1.8', 'systemdUnit': 'hydra-umc-datalake.service', 'activeState': 'active', 'subState': 'running', 'pid': 12, 'live': true},
        {'name': 'HYDRA-UMC-ORCHESTRATOR', 'version': '0.1.8', 'systemdUnit': 'hydra-umc-orchestrator.service', 'activeState': 'inactive', 'live': false},
        {'name': 'HYDRA-UMC-SDK', 'version': '0.3.7'},
        {'name': 'HYDRA-UMC-GATEWAY', 'live': null, 'systemdUnit': 'hydra-umc-gateway.service', 'activeState': 'active'},
        'garbage',
      ],
    };

    test('only services are listed, in order, and a library is not "down"', () {
      final eco = EcosystemStatus.parse(raw);
      expect(eco.available, isTrue);
      expect(eco.projects.length, 4);
      expect(eco.services.map((p) => p.name), ['HYDRA-UMC-DATALAKE', 'HYDRA-UMC-GATEWAY', 'HYDRA-UMC-ORCHESTRATOR']);
      expect(eco.runningCount, 2);
      final sdk = eco.projects.firstWhere((p) => p.name == 'HYDRA-UMC-SDK');
      expect(sdk.isService, isFalse);
      expect(sdk.isDown, isFalse);
      expect(eco.projects.firstWhere((p) => p.name == 'HYDRA-UMC-ORCHESTRATOR').isDown, isTrue);
    });

    test('a unit that is active counts as running even when nothing was probed', () {
      expect(EcosystemProject.parse({'name': 'x', 'systemdUnit': 'x.service', 'activeState': 'active'}).isRunning, isTrue);
      expect(EcosystemProject.parse({'name': 'x', 'systemdUnit': 'x.service', 'activeState': 'failed'}).isRunning, isFalse);
    });

    test('junk becomes an empty, unavailable status', () {
      final eco = EcosystemStatus.parse({'projects': 'no'});
      expect(eco.available, isFalse);
      expect(eco.projects, isEmpty);
      expect(EcosystemStatus.parse(const {}).scannedAt, isNull);
    });
  });

  group('SafetyStatus breaches', () {
    test('the listed zones, their total and the stop requests are read; junk entries are skipped', () {
      final st = SafetyStatus.parse({
        'sdkSafetyState': {'state': 'DANGER'},
        'breaches': [
          {'zone_id': 'a', 'level': 'danger', 'object_id': 'o1'},
          'junk',
          {'zone_id': 'b', 'level': 'whatever', 'object_id': 'o2'},
        ],
        'breachCount': 7,
        'estopRequestCount': 2,
      }, DateTime(2000));
      expect(st.breaches.length, 2);
      expect(st.breaches[0].danger, isTrue);
      expect(st.breaches[1].danger, isFalse, reason: 'an unknown level is shown as a warning');
      expect(st.breachCount, 7);
      expect(st.estopRequestCount, 2);
    });

    test('a total below what is listed, or no lists at all, never hides what the service sent', () {
      final low = SafetyStatus.parse({'sdkSafetyState': {'state': 'DANGER'}, 'breaches': [{'zone_id': 'a', 'level': 'danger', 'object_id': 'o'}], 'breachCount': 0}, DateTime(2000));
      expect(low.breachCount, 1);
      final none = SafetyStatus.parse({'sdkSafetyState': {'state': 'READY'}}, DateTime(2000));
      expect(none.breaches, isEmpty);
      expect(none.estopRequestCount, isNull);
    });
  });
}
