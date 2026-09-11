// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/robot_view_model_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Unit coverage for state/robot_view_model.dart's own _sendAtomicCommand():
// the optimistic-mutate-then-rollback-on-failure flow and combinedWith
// propagation, neither of which the pre-existing widget_test.dart smoke
// test touches. Not a port from HYDRA-UMC-IOS-CONTROL - that sibling app
// has the exact same gap, so there is no reference implementation to
// reuse here.
//
// Exercised via sendCommand('play') - a real, server-supported command
// control_screen.dart actually wires to a button - rather than the former
// 'enable'/'disable' stand-ins, which HYDRA-UMC-SERVER's own
// /api/robot/:id/command switch never implemented (found while
// auditing the code; see robot_view_model.dart's sendCommand() header for
// the removal). This suite only cares about the generic optimistic-mutate/
// rollback/combinedWith machinery, so any real command exercises it equally
// well.
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
import 'package:hydra_umc_dsi/state/hydra_error.dart';
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
Map<String, dynamic> _rawStateWith({required bool robot1Playing, required bool robot2Playing, List<int> combinedWith = const [2]}) {
  return <String, dynamic>{
    'activeControllerId': 'c1',
    'controllers': <dynamic>[
      <String, dynamic>{
        'id': 'c1',
        'robots': <dynamic>[
          <String, dynamic>{
            'id': 1,
            'playbackState': <String, dynamic>{'isPlaying': robot1Playing},
            'combinedWith': <dynamic>[...combinedWith],
          },
          <String, dynamic>{'id': 2, 'playbackState': <String, dynamic>{'isPlaying': robot2Playing}},
        ],
      },
    ],
  };
}

void main() {
  group('RobotViewModel._sendAtomicCommand (via sendCommand)', () {
    test('optimistic mutation applies immediately, before the server responds', () async {
      final vm = RobotViewModel();
      vm.state = HydraState(_rawStateWith(robot1Playing: false, robot2Playing: false));
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

      vm.sendCommand('play');

      // Synchronous part of _sendAtomicCommand (snapshot + localMutate)
      // runs before the first await, so this is true immediately, with no
      // pump/delay needed.
      expect(vm.robots.firstWhere((r) => r.id == 1).isPlaying, isTrue);
    });

    test('propagates to combinedWith siblings optimistically', () async {
      final vm = RobotViewModel();
      vm.state = HydraState(_rawStateWith(robot1Playing: false, robot2Playing: false, combinedWith: [2]));
      vm.selectedRobotId = 1;
      vm.apiClient = HydraApiClient(
        'testhost',
        3000,
        client: MockClient((request) async => http.Response('{"success": true}', 200)),
      );

      vm.sendCommand('play');

      expect(vm.robots.firstWhere((r) => r.id == 1).isPlaying, isTrue);
      expect(vm.robots.firstWhere((r) => r.id == 2).isPlaying, isTrue, reason: 'robot 2 is in robot 1\'s combinedWith list');
    });

    test('rolls back the optimistic mutation (and its combinedWith siblings) when the server rejects the command', () async {
      final vm = RobotViewModel();
      vm.state = HydraState(_rawStateWith(robot1Playing: false, robot2Playing: false, combinedWith: [2]));
      vm.selectedRobotId = 1;
      vm.apiClient = HydraApiClient(
        'testhost',
        3000,
        client: MockClient((request) async => http.Response('server exploded', 500)),
      );

      vm.sendCommand('play');
      // Mutation applied optimistically first...
      expect(vm.robots.firstWhere((r) => r.id == 1).isPlaying, isTrue);

      // ...then the (mocked) network round-trip completes and rolls it back.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(vm.robots.firstWhere((r) => r.id == 1).isPlaying, isFalse, reason: 'robot 1 should roll back to its pre-mutation snapshot');
      expect(vm.robots.firstWhere((r) => r.id == 2).isPlaying, isFalse, reason: 'combinedWith sibling should roll back too');
      expect(vm.lastError?.kind, HydraErrorKind.txError);
      expect(vm.lastError?.params['command'], 'play');
    });

    test('a successful command keeps the mutation and clears lastError', () async {
      final vm = RobotViewModel();
      vm.state = HydraState(_rawStateWith(robot1Playing: false, robot2Playing: false, combinedWith: const []));
      vm.selectedRobotId = 1;
      vm.lastError = const HydraError(HydraErrorKind.loginFailed);
      vm.apiClient = HydraApiClient(
        'testhost',
        3000,
        client: MockClient((request) async => http.Response('{"success": true}', 200)),
      );

      vm.sendCommand('play');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(vm.robots.firstWhere((r) => r.id == 1).isPlaying, isTrue);
      expect(vm.lastError, isNull);
    });

    // C08 (item #14 de la lista de pendientes de software/hardware):
    // "cancelar una orden de robot en curso sin testear en ningun cliente
    // salvo el relay de voz interno" - every test above starts from an
    // idle robot (robot1Playing: false); none of them exercised the real
    // "an order is actually in flight, then gets cancelled" case the
    // audit named. Same real gap closed today in HYDRA-UMC-ANDROID-CONTROL's
    // own RobotViewModelSendAtomicCommandTest.kt.
    test('stop cancels an in-flight order optimistically on both the target robot and its combinedWith sibling', () async {
      final vm = RobotViewModel();
      vm.state = HydraState(_rawStateWith(robot1Playing: true, robot2Playing: true, combinedWith: const [2]));
      vm.selectedRobotId = 1;
      vm.apiClient = HydraApiClient(
        'testhost',
        3000,
        client: MockClient((request) async => http.Response('{"success": true}', 200)),
      );

      vm.sendCommand('stop');

      expect(vm.robots.firstWhere((r) => r.id == 1).isPlaying, isFalse, reason: 'robot 1\'s in-flight order must be cancelled immediately');
      expect(vm.robots.firstWhere((r) => r.id == 2).isPlaying, isFalse, reason: 'the combinedWith sibling\'s order must be cancelled too');
    });

    test('a failed cancel rolls the in-flight order back to still-playing on both robots', () async {
      final vm = RobotViewModel();
      vm.state = HydraState(_rawStateWith(robot1Playing: true, robot2Playing: true, combinedWith: const [2]));
      vm.selectedRobotId = 1;
      vm.apiClient = HydraApiClient(
        'testhost',
        3000,
        client: MockClient((request) async => http.Response('server exploded', 500)),
      );

      vm.sendCommand('stop');
      expect(vm.robots.firstWhere((r) => r.id == 1).isPlaying, isFalse, reason: 'optimistic cancel applies immediately');

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(vm.robots.firstWhere((r) => r.id == 1).isPlaying, isTrue, reason: 'the cancel never actually reached the robot - it must roll back to still-playing');
      expect(vm.robots.firstWhere((r) => r.id == 2).isPlaying, isTrue, reason: 'the combinedWith sibling must be rolled back too');
    });

    test('jog() rolls back position on failure without touching an uncombined sibling', () async {
      final vm = RobotViewModel();
      final raw = _rawStateWith(robot1Playing: true, robot2Playing: true, combinedWith: const []);
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
