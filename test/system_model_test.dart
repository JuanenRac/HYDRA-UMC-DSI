// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/system_model_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The state and the restart actions of the System tab, against fake HTTP
// clients: the role is checked before anything is asked, the screen restart
// needs a supervisor, the server restart needs an administrator, the whole
// Compute Module needs the settings file AND the local panel, every action
// leaves a line in the audit trail, and the safety verdict that is stale or
// unreadable never reads as ready.
// =============================================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/models/system_status.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/network/hydra_api_client.dart';
import 'package:hydra_umc_dsi/network/safety_zones_client.dart';
import 'package:hydra_umc_dsi/services/operator_pin.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/state/system_model.dart';
import 'package:hydra_umc_dsi/util/panel_config.dart';

class _Backend implements SecureTokenBackend {
  final Map<String, String> store = {};
  @override
  Future<void> write(String key, String value) async => store[key] = value;
  @override
  Future<String?> read(String key) async => store[key];
  @override
  Future<void> delete(String key) async => store.remove(key);
}

String _token(String role) {
  String part(Object json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'username': 'u', 'role': role})}.sig';
}

class _Calls {
  final List<String> requests = [];
  bool failPosts = false;
}

RobotViewModel _signedIn(String role, PanelConfig config, _Calls calls, {String host = '127.0.0.1'}) {
  final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: config, operatorPin: OperatorPin(backend: _Backend()));
  final mock = MockClient((r) async {
    calls.requests.add('${r.method} ${r.url.path}');
    if (r.url.path == '/api/ecosystem/status') {
      return http.Response(
          jsonEncode({
            'available': true,
            'projects': [
              {'name': 'HYDRA-UMC-DATALAKE', 'version': '1', 'systemdUnit': 'hydra-umc-datalake.service', 'activeState': 'active', 'live': true},
            ],
          }),
          200);
    }
    if (r.method == 'POST') {
      return calls.failPosts ? http.Response('{"error":"nope"}', 503) : http.Response('{"success":true}', 200);
    }
    return http.Response('{}', 404);
  });
  vm.apiClient = HydraApiClient(host, 3000, client: mock)..authToken = _token(role);
  vm.activeServer = ServerInfo(host: host, port: 3000);
  vm.isLoggedIn = true;
  return vm;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('restart actions', () {
    const all = PanelConfig(rebootButton: true);

    test('a viewer, or a role that cannot be read, may not restart anything', () async {
      for (final role in ['viewer', '']) {
        final calls = _Calls();
        final vm = _signedIn(role, all, calls);
        var closed = 0;
        final model = SystemModel(vm: vm, supervised: true, screenRestarter: () => closed++);
        addTearDown(() {
          model.dispose();
          vm.dispose();
        });
        expect(model.roleMayRestart, isFalse);
        expect(model.restartScreen(), SystemActionResult.roleDenied);
        expect(await model.restartServices(), SystemActionResult.roleDenied);
        expect(await model.restartHost(), SystemActionResult.roleDenied);
        expect(closed, 0);
        expect(calls.requests.where((r) => r.startsWith('POST')), isEmpty);
      }
    });

    test('an operator restarts the screen (when a supervisor will start it again) but not the server', () async {
      final calls = _Calls();
      final vm = _signedIn('operator', all, calls);
      var closed = 0;
      final model = SystemModel(vm: vm, supervised: true, screenRestarter: () => closed++);
      addTearDown(() {
        model.dispose();
        vm.dispose();
      });
      expect(model.restartScreen(), SystemActionResult.ok);
      expect(closed, 1);
      expect(await model.restartServices(), SystemActionResult.adminOnly);
      expect(calls.requests, isEmpty, reason: 'the server was not even asked');
      expect(model.auditTrail.length, 2);
      expect(model.auditTrail.first, contains('role=operator'));
      expect(model.auditTrail.first, contains('restart-screen'));
      expect(model.auditTrail.last, contains('adminOnly'));
    });

    test('without a supervisor the screen is not closed: it would not come back', () {
      final vm = _signedIn('admin', all, _Calls());
      var closed = 0;
      final model = SystemModel(vm: vm, supervised: false, screenRestarter: () => closed++);
      addTearDown(() {
        model.dispose();
        vm.dispose();
      });
      expect(model.restartScreen(), SystemActionResult.notSupervised);
      expect(closed, 0);
    });

    test('an administrator restarts the server through its own route', () async {
      final calls = _Calls();
      final vm = _signedIn('admin', all, calls);
      final model = SystemModel(vm: vm, supervised: true);
      addTearDown(() {
        model.dispose();
        vm.dispose();
      });
      expect(await model.restartServices(), SystemActionResult.ok);
      expect(calls.requests, ['POST /api/admin/restart']);
      calls.failPosts = true;
      expect(await model.restartServices(), SystemActionResult.failed);
    });

    test('the whole Compute Module: never by default, never from another address, only when chosen', () async {
      // 1. The button exists but the file does not allow the host.
      var calls = _Calls();
      var vm = _signedIn('admin', const PanelConfig(rebootButton: true), calls);
      var model = SystemModel(vm: vm, supervised: true);
      expect(await model.restartHost(), SystemActionResult.notAllowed);
      expect(calls.requests, isEmpty);
      model.dispose();
      vm.dispose();

      // 2. Allowed by the file, but the panel talks to another machine.
      const chosen = PanelConfig(rebootButton: true, rebootAction: RebootAction.host, rebootHostAllowed: true);
      calls = _Calls();
      vm = _signedIn('admin', chosen, calls, host: '192.168.0.50');
      model = SystemModel(vm: vm, supervised: true);
      expect(await model.restartHost(), SystemActionResult.notLocal);
      expect(calls.requests, isEmpty);
      model.dispose();
      vm.dispose();

      // 3. Chosen on purpose and local: it goes through.
      calls = _Calls();
      vm = _signedIn('operator', chosen, calls);
      model = SystemModel(vm: vm, supervised: true);
      expect(await model.restartHost(), SystemActionResult.ok);
      expect(calls.requests, ['POST /api/system/reboot']);
      expect(model.auditTrail.single, contains('restart-host'));
      model.dispose();
      vm.dispose();
    });

    test('only an administrator controls a service of the ecosystem', () async {
      var calls = _Calls();
      var vm = _signedIn('operator', const PanelConfig(ecosystemView: true), calls);
      var model = SystemModel(vm: vm, supervised: true);
      expect(await model.serviceAction('hydra-umc-datalake.service', 'restart'), SystemActionResult.adminOnly);
      expect(calls.requests, isEmpty);
      model.dispose();
      vm.dispose();

      calls = _Calls();
      vm = _signedIn('admin', const PanelConfig(ecosystemView: true), calls);
      model = SystemModel(vm: vm, supervised: true);
      expect(await model.serviceAction('hydra-umc-datalake.service', 'restart'), SystemActionResult.ok);
      expect(calls.requests, contains('POST /api/ecosystem/service/hydra-umc-datalake.service/restart'));
      expect(model.busyUnit, isNull);
      model.dispose();
      vm.dispose();
    });
  });

  group('readings', () {
    test('the ecosystem is read only while the tab is shown and it is switched on', () async {
      final calls = _Calls();
      final vm = _signedIn('admin', const PanelConfig(ecosystemView: true, ecosystemPollSeconds: 5), calls);
      final model = SystemModel(vm: vm, supervised: true);
      addTearDown(() {
        model.dispose();
        vm.dispose();
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls.requests, isEmpty, reason: 'the tab is not shown');
      model.setVisible(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls.requests, contains('GET /api/ecosystem/status'));
      expect(model.ecosystem!.services.single.name, 'HYDRA-UMC-DATALAKE');
      expect(model.ecosystemFailed, isFalse);
    });

    test('nothing is read when the file does not switch it on', () async {
      final calls = _Calls();
      final vm = _signedIn('admin', PanelConfig.defaults, calls);
      var factoryCalls = 0;
      final model = SystemModel(vm: vm, supervised: true, safetyClientFactory: (c) {
        factoryCalls++;
        return SafetyZonesClient(host: c.safetyHost, port: c.safetyPort);
      });
      addTearDown(() {
        model.dispose();
        vm.dispose();
      });
      model.setVisible(true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls.requests, isEmpty);
      expect(factoryCalls, 0);
    });

    test('a safety verdict that is current READY reads ready; stale, missing or unreachable reads unknown', () async {
      var now = DateTime.utc(2000, 1, 1, 12, 0, 10);
      var body = '{"sdkSafetyState":{"state":"READY","timestamp_utc":"2000-01-01T12:00:09+00:00"},"reason":""}';
      var status = 200;
      final vm = _signedIn('operator', const PanelConfig(safetyPanel: true, safetyStaleSeconds: 10), _Calls());
      final model = SystemModel(
        vm: vm,
        supervised: true,
        clock: () => now,
        safetyClientFactory: (c) => SafetyZonesClient(
          host: c.safetyHost,
          port: c.safetyPort,
          clock: () => now,
          client: MockClient((r) async {
            if (status == 0) throw http.ClientException('refused');
            return http.Response(body, status);
          }),
        ),
      );
      addTearDown(() {
        model.dispose();
        vm.dispose();
      });
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(model.safetyLevel, SafetyLevel.ready);

      now = now.add(const Duration(seconds: 30));
      expect(model.safetyLevel, SafetyLevel.unknown, reason: 'the verdict is 31 s old');

      now = DateTime.utc(2000, 1, 1, 12, 0, 10);
      body = '{"sdkSafetyState":{"state":"DANGER","timestamp_utc":"2000-01-01T12:00:09+00:00"},"reason":"zone"}';
      await model.readSafety();
      expect(model.safetyLevel, SafetyLevel.danger);

      status = 0;
      await model.readSafety();
      expect(model.safetyFailure, SafetyFailure.unreachable);
      expect(model.safetyLevel, SafetyLevel.unknown, reason: 'an unreachable service is not "still danger" or "still ready"');

      status = 404;
      await model.readSafety();
      expect(model.safetyLevel, SafetyLevel.unknown);
      expect(model.safety!.noVerdictYet, isTrue);
    });
  });
}
