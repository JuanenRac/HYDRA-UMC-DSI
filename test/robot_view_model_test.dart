// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/robot_view_model_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Unit coverage for state/robot_view_model.dart's own _sendAtomicCommand():
// the optimistic-mutate-then-rollback-on-failure flow and combinedWith
// propagation, neither of which the pre-existing widget_test.dart smoke
// test touches. Not a port from HYDRA-UMC-IOS-CONTROL - that sibling app
// has the exact same gap (see mejoras_futuras.txt item 6), so there is no
// reference implementation to reuse here.
//
// HydraApiClient takes an optional injected http.Client, so these tests
// swap in package:http's own MockClient (already available transitively
// via the http dependency, no new package needed) instead of hitting a
// real HYDRA-UMC STUDIO server - RobotViewModel's apiClient/state/
// selectedRobotId fields are all public, so a client+state pair can be
// wired in directly without going through the real login()/connect() flow
// (which would need a live server).
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hydra_umc_dsi/models/hydra_state.dart';
import 'package:hydra_umc_dsi/network/hydra_api_client.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';

// Every nested map/list below is explicitly typed <String, dynamic> /
// dynamic - real settings.json state always arrives via jsonDecode(), which
// always reifies as Map<String, dynamic>, never the narrower Map<String,
// Object> a plain untyped literal like `{'id': 1, ...}` infers. Getting
// this wrong doesn't break reads (RobotView's own accessors don't care),
// but it does break the rollback path's `raw..clear()..addAll(snapshot)`
// (snapshot is always Map<String, dynamic>, since it round-trips through
// jsonDecode/jsonEncode too) with a runtime type error that has nothing to
// do with the production code being tested - matching the real shape here
// avoids a false failure.
Map<String, dynamic> _rawStateWith({required bool robot1Online, required bool robot2Online, List<int> combinedWith = const [2]}) {
  return <String, dynamic>{
    'activeControllerId': 'c1',
    'controllers': <dynamic>[
      <String, dynamic>{
        'id': 'c1',
        'robots': <dynamic>[
          <String, dynamic>{'id': 1, 'online': robot1Online, 'combinedWith': <dynamic>[...combinedWith]},
          <String, dynamic>{'id': 2, 'online': robot2Online},
        ],
      },
    ],
  };
}

void main() {
  group('RobotViewModel._sendAtomicCommand (via sendCommand)', () {
    test('optimistic mutation applies immediately, before the server responds', () async {
      final vm = RobotViewModel();
      vm.state = HydraState(_rawStateWith(robot1Online: false, robot2Online: false));
      vm.selectedRobotId = 1;
      vm.apiClient = HydraApiClient(
        'testhost',
        3000,
        client: MockClient((request) async {
          // Never actually completes within this test - just proves the
          // local mutation already happened before this handler is even
          // reached, since sendCommand() doesn't await.
          return http.Response('{"success": true}', 200);
        }),
      );

      vm.sendCommand('enable');

      // Synchronous part of _sendAtomicCommand (snapshot + localMutate)
      // runs before the first await, so this is true immediately, with no
      // pump/delay needed.
      expect(vm.robots.firstWhere((r) => r.id == 1).online, isTrue);
    });

    test('propagates to combinedWith siblings optimistically', () async {
      final vm = RobotViewModel();
      vm.state = HydraState(_rawStateWith(robot1Online: false, robot2Online: false, combinedWith: [2]));
      vm.selectedRobotId = 1;
      vm.apiClient = HydraApiClient(
        'testhost',
        3000,
        client: MockClient((request) async => http.Response('{"success": true}', 200)),
      );

      vm.sendCommand('enable');

      expect(vm.robots.firstWhere((r) => r.id == 1).online, isTrue);
      expect(vm.robots.firstWhere((r) => r.id == 2).online, isTrue, reason: 'robot 2 is in robot 1\'s combinedWith list');
    });

    test('rolls back the optimistic mutation (and its combinedWith siblings) when the server rejects the command', () async {
      final vm = RobotViewModel();
      vm.state = HydraState(_rawStateWith(robot1Online: false, robot2Online: false, combinedWith: [2]));
      vm.selectedRobotId = 1;
      vm.apiClient = HydraApiClient(
        'testhost',
        3000,
        client: MockClient((request) async => http.Response('server exploded', 500)),
      );

      vm.sendCommand('enable');
      // Mutation applied optimistically first...
      expect(vm.robots.firstWhere((r) => r.id == 1).online, isTrue);

      // ...then the (mocked) network round-trip completes and rolls it back.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(vm.robots.firstWhere((r) => r.id == 1).online, isFalse, reason: 'robot 1 should roll back to its pre-mutation snapshot');
      expect(vm.robots.firstWhere((r) => r.id == 2).online, isFalse, reason: 'combinedWith sibling should roll back too');
      expect(vm.lastError, contains('enable'));
    });

    test('a successful command keeps the mutation and clears lastError', () async {
      final vm = RobotViewModel();
      vm.state = HydraState(_rawStateWith(robot1Online: false, robot2Online: false, combinedWith: const []));
      vm.selectedRobotId = 1;
      vm.lastError = 'stale error from a previous attempt';
      vm.apiClient = HydraApiClient(
        'testhost',
        3000,
        client: MockClient((request) async => http.Response('{"success": true}', 200)),
      );

      vm.sendCommand('enable');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(vm.robots.firstWhere((r) => r.id == 1).online, isTrue);
      expect(vm.lastError, isEmpty);
    });

    test('jog() rolls back position on failure without touching an uncombined sibling', () async {
      final vm = RobotViewModel();
      final raw = _rawStateWith(robot1Online: true, robot2Online: true, combinedWith: const []);
      (raw['controllers'] as List).cast<Map<String, dynamic>>().first['robots'][0]['pos'] = {'x': 10.0};
      vm.state = HydraState(raw);
      vm.selectedRobotId = 1;
      vm.apiClient = HydraApiClient(
        'testhost',
        3000,
        client: MockClient((request) async => http.Response('bad request', 400)),
      );

      vm.jog('robot', 'x', 5.0);
      expect(vm.robots.firstWhere((r) => r.id == 1).posAxis('x'), 15.0);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(vm.robots.firstWhere((r) => r.id == 1).posAxis('x'), 10.0, reason: 'position should roll back to its pre-jog snapshot');
    });
  });
}
