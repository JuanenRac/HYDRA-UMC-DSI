// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/system_screen_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The System tab on the screen: the safety card never shows a green light it
// was not given, the restart buttons follow the role and the settings file,
// every restart asks first (the whole Compute Module twice), and the services
// of the ecosystem can only be controlled by an administrator.
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/network/hydra_api_client.dart';
import 'package:hydra_umc_dsi/network/safety_zones_client.dart';
import 'package:hydra_umc_dsi/services/operator_pin.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/state/system_model.dart';
import 'package:hydra_umc_dsi/ui/system_screen.dart';
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

class _Rig {
  final RobotViewModel vm;
  final SystemModel model;
  final List<String> posts;
  final List<String> closed;
  _Rig(this.vm, this.model, this.posts, this.closed);

  void dispose() {
    model.dispose();
    vm.dispose();
  }
}

/// A System tab with a fake safety service ([safetyBody], [safetyStatus]) and a fake server.
_Rig _rig(PanelConfig config, {String role = 'admin', String safetyBody = '', int safetyStatus = 200, bool supervised = true}) {
  final posts = <String>[];
  final closed = <String>[];
  final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: config, operatorPin: OperatorPin(backend: _Backend()));
  vm.apiClient = HydraApiClient(
    '127.0.0.1',
    3000,
    client: MockClient((r) async {
      if (r.url.path == '/api/ecosystem/status') {
        return http.Response(
            jsonEncode({
              'available': true,
              'projects': [
                {'name': 'HYDRA-UMC-DATALAKE', 'version': '0.1.8', 'systemdUnit': 'hydra-umc-datalake.service', 'activeState': 'active', 'live': true},
                {'name': 'HYDRA-UMC-ORCHESTRATOR', 'version': '0.1.8', 'systemdUnit': 'hydra-umc-orchestrator.service', 'activeState': 'inactive', 'live': false},
              ],
            }),
            200);
      }
      if (r.method == 'POST') {
        posts.add(r.url.path);
        return http.Response('{"success":true}', 200);
      }
      return http.Response('{}', 404);
    }),
  )..authToken = _token(role);
  vm.activeServer = ServerInfo(host: '127.0.0.1', port: 3000);
  vm.isLoggedIn = true;
  final model = SystemModel(
    vm: vm,
    supervised: supervised,
    screenRestarter: () => closed.add('closed'),
    safetyClientFactory: (c) => SafetyZonesClient(
      host: c.safetyHost,
      port: c.safetyPort,
      client: MockClient((r) async {
        if (safetyStatus == 0) throw http.ClientException('refused');
        return http.Response(safetyBody, safetyStatus);
      }),
    ),
  );
  return _Rig(vm, model, posts, closed);
}

Future<void> _show(WidgetTester tester, _Rig rig) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RobotViewModel>.value(value: rig.vm),
        ChangeNotifierProvider<SystemModel>.value(value: rig.model),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SystemScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

String _verdict(String state, DateTime at, {String reason = ''}) =>
    jsonEncode({'sdkSafetyState': {'state': state, 'timestamp_utc': at.toUtc().toIso8601String()}, 'reason': reason});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('with nothing switched on the tab says so', (tester) async {
    final rig = _rig(PanelConfig.defaults);
    await _show(tester, rig);
    expect(find.byKey(const Key('safety-state')), findsNothing);
    expect(find.byKey(const Key('reboot-screen')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    rig.dispose();
  });

  testWidgets('a current READY is green and says nothing is wrong', (tester) async {
    final rig = _rig(const PanelConfig(safetyPanel: true), safetyBody: _verdict('READY', DateTime.now()));
    await _show(tester, rig);
    expect(find.text('READY'), findsOneWidget);
    expect(find.byKey(const Key('safety-problem')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    rig.dispose();
  });

  testWidgets('a breach shows the state and the reason, and is not a green light', (tester) async {
    final rig = _rig(const PanelConfig(safetyPanel: true), safetyBody: _verdict('DANGER', DateTime.now(), reason: 'zone 2 breached'));
    await _show(tester, rig);
    expect(find.text('DANGER'), findsOneWidget);
    expect(find.textContaining('zone 2 breached'), findsOneWidget);
    expect(find.text('READY'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    rig.dispose();
  });

  testWidgets('the breached zones and the stop requests of the service are listed, a danger first as danger', (tester) async {
    final body = jsonEncode({
      'sdkSafetyState': {'state': 'DANGER', 'timestamp_utc': DateTime.now().toUtc().toIso8601String()},
      'reason': 'danger zone breached',
      'breaches': [
        {'zone_id': 'cell-1', 'level': 'danger', 'object_id': 'person-3'},
        {'zone_id': 'aisle', 'level': 'warning', 'object_id': 'cart'},
      ],
      'breachCount': 5,
      'estopRequestCount': 1,
    });
    final rig = _rig(const PanelConfig(safetyPanel: true), safetyBody: body);
    await _show(tester, rig);
    expect(find.byKey(const Key('safety-breach-0')), findsOneWidget);
    expect(find.byKey(const Key('safety-breach-1')), findsOneWidget);
    expect(find.byKey(const Key('safety-breach-2')), findsNothing);
    expect(find.textContaining('cell-1'), findsOneWidget);
    expect(find.textContaining('person-3'), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets, reason: 'three more are not listed');
    expect(find.byKey(const Key('safety-stops')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    rig.dispose();
  });

  testWidgets('a verdict without the lists shows none and is read as before', (tester) async {
    final rig = _rig(const PanelConfig(safetyPanel: true), safetyBody: _verdict('DANGER', DateTime.now(), reason: 'x'));
    await _show(tester, rig);
    expect(find.byKey(const Key('safety-breach-0')), findsNothing);
    expect(find.byKey(const Key('safety-stops')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    rig.dispose();
  });

  testWidgets('an old READY, a silent service and a service with no verdict are all "unknown"', (tester) async {
    for (final (body, status) in [
      (_verdict('READY', DateTime.now().subtract(const Duration(minutes: 5))), 200),
      ('', 0),
      ('{}', 404),
    ]) {
      final rig = _rig(const PanelConfig(safetyPanel: true), safetyBody: body, safetyStatus: status);
      await _show(tester, rig);
      expect(find.text('READY'), findsNothing);
      expect(find.text('UNKNOWN'), findsOneWidget);
      expect(find.byKey(const Key('safety-problem')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      rig.dispose();
    }
  });

  testWidgets('an operator can restart the screen after confirming; a viewer cannot', (tester) async {
    var rig = _rig(const PanelConfig(rebootButton: true), role: 'operator');
    await _show(tester, rig);
    expect(find.byKey(const Key('reboot-host')), findsNothing, reason: 'not offered by default');
    await tester.tap(find.byKey(const Key('reboot-screen')));
    await tester.pumpAndSettle();
    expect(rig.closed, isEmpty, reason: 'it asks first');
    await tester.tap(find.byKey(const Key('reboot-confirm-screen')));
    await tester.pumpAndSettle();
    expect(rig.closed, ['closed']);
    expect(find.byKey(const Key('reboot-services')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('reboot-services'))).onPressed, isNull, reason: 'the server restart is for administrators');
    await tester.pumpWidget(const SizedBox());
    rig.dispose();

    rig = _rig(const PanelConfig(rebootButton: true), role: 'viewer');
    await _show(tester, rig);
    expect(tester.widget<FilledButton>(find.byKey(const Key('reboot-screen'))).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
    rig.dispose();
  });

  testWidgets('the server restart asks first and uses its own route', (tester) async {
    final rig = _rig(const PanelConfig(rebootButton: true));
    await _show(tester, rig);
    await tester.tap(find.byKey(const Key('reboot-services')));
    await tester.pumpAndSettle();
    expect(rig.posts, isEmpty);
    await tester.tap(find.byKey(const Key('reboot-confirm-services')));
    await tester.pumpAndSettle();
    expect(rig.posts, ['/api/admin/restart']);
    await tester.pumpWidget(const SizedBox());
    rig.dispose();
  });

  testWidgets('the whole Compute Module is offered only when chosen, and asks twice', (tester) async {
    final rig = _rig(const PanelConfig(rebootButton: true, rebootAction: RebootAction.host, rebootHostAllowed: true));
    await _show(tester, rig);
    await tester.tap(find.byKey(const Key('reboot-host')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reboot-confirm-host-1')));
    await tester.pumpAndSettle();
    expect(rig.posts, isEmpty, reason: 'the second question has not been answered');
    // Saying no to the second question stops it.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(rig.posts, isEmpty);

    await tester.tap(find.byKey(const Key('reboot-host')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reboot-confirm-host-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reboot-confirm-host-2')));
    await tester.pumpAndSettle();
    expect(rig.posts, ['/api/system/reboot']);
    await tester.pumpWidget(const SizedBox());
    rig.dispose();
  });

  testWidgets('the ecosystem lists the services; an administrator restarts one after confirming, an operator cannot', (tester) async {
    var rig = _rig(const PanelConfig(ecosystemView: true));
    rig.model.setVisible(true);
    await _show(tester, rig);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('HYDRA-UMC-DATALAKE'), findsOneWidget);
    expect(find.byKey(const Key('eco-summary')), findsOneWidget);
    expect(find.textContaining('1 of 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('eco-restart-HYDRA-UMC-DATALAKE')));
    await tester.pumpAndSettle();
    expect(rig.posts, isEmpty);
    await tester.tap(find.byKey(const Key('eco-confirm')));
    await tester.pumpAndSettle();
    expect(rig.posts, ['/api/ecosystem/service/hydra-umc-datalake.service/restart']);
    await tester.pumpWidget(const SizedBox());
    rig.dispose();

    rig = _rig(const PanelConfig(ecosystemView: true), role: 'operator');
    rig.model.setVisible(true);
    await _show(tester, rig);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<IconButton>(find.byKey(const Key('eco-restart-HYDRA-UMC-DATALAKE'))).onPressed, isNull);
    expect(tester.widget<IconButton>(find.byKey(const Key('eco-start-HYDRA-UMC-ORCHESTRATOR'))).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
    rig.dispose();
  });
}
