// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/tool_arms_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The tool arms card of the System tab: read only, off by default, a report
// that is old is never shown as safe, and an answer that is missing, refused
// or malformed is "not available" and never an empty list.
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
import 'package:hydra_umc_dsi/models/tool_arms.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/network/hydra_api_client.dart';
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

String _token() {
  String part(Object json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'username': 'u', 'role': 'viewer'})}.sig';
}

Map<String, Object?> _arm(String robot, int tool, {bool armed = true, bool stale = false, double age = 1, String by = 'urtc', int seq = 1}) =>
    {'robot': robot, 'toolId': tool, 'armed': armed, 'by': by, 'seq': seq, 'ageSeconds': age, 'stale': stale};

Map<String, Object?> _report(List<Map<String, Object?>> arms, {double ttl = 30}) => {
      'schema_version': '1.0',
      'ttlSeconds': ttl,
      'arms': arms,
      'armedCount': arms.where((a) => a['armed'] == true).length,
      'staleCount': arms.where((a) => a['stale'] == true).length,
    };

final _t0 = DateTime.utc(2000, 1, 1, 12);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the contract is read strictly', () {
    test('a good report is read', () {
      final r = ToolArmsReport.parse(_report([_arm('arm-1', 2)]), _t0)!;
      expect(r.arms.single.robot, 'arm-1');
      expect(r.arms.single.toolId, 2);
      expect(r.armedCount, 1);
    });

    test('anything outside the closed shape refuses the whole answer', () {
      final good = _report([_arm('arm-1', 2)]);
      Map<String, Object?> with_(String key, Object? value) => {...good, key: value};
      Map<String, Object?> row(String key, Object? value) => with_('arms', [
            {..._arm('arm-1', 2), key: value},
          ]);
      final bad = <Object?>[
        null,
        'text',
        <Object?>[],
        with_('schema_version', '2.0'),
        with_('schema_version', null),
        with_('ttlSeconds', 0),
        with_('ttlSeconds', -1),
        with_('ttlSeconds', 'x'),
        with_('arms', 'x'),
        with_('arms', List.generate(maxToolArms + 1, (i) => _arm('r$i', 1))),
        with_('armedCount', -1),
        with_('armedCount', 1.5),
        with_('staleCount', '0'),
        row('robot', ''),
        row('robot', '-bad'),
        row('robot', 'a b'),
        row('robot', 7),
        row('toolId', -1),
        row('toolId', maxToolId + 1),
        row('toolId', 1.5),
        row('armed', 1),
        row('stale', 'no'),
        row('by', 7),
        row('by', 'x' * 65),
        row('seq', 0),
        row('seq', null),
        row('ageSeconds', -1),
        row('ageSeconds', 'x'),
      ];
      for (var i = 0; i < bad.length; i++) {
        expect(ToolArmsReport.parse(bad[i], _t0), isNull, reason: 'case $i');
      }
    });

    test('one bad row among good ones refuses the list, it is never half read', () {
      final data = _report([_arm('arm-1', 1), {..._arm('arm-2', 1), 'seq': 0}]);
      expect(ToolArmsReport.parse(data, _t0), isNull);
    });

    test('the limits themselves are accepted', () {
      final data = _report(List.generate(maxToolArms, (i) => _arm('r$i', i % (maxToolId + 1))));
      expect(ToolArmsReport.parse(data, _t0)!.arms.length, maxToolArms);
      expect(ToolArmsReport.parse(_report([_arm('A', maxToolId, by: 'x' * 64)]), _t0), isNotNull);
    });
  });

  group('an old report is never safe', () {
    final r = ToolArmsReport.parse(_report([_arm('a', 1, armed: true), _arm('a', 2, armed: false)], ttl: 30), _t0)!;

    test('a fresh row is what it says', () {
      expect(r.levelOf(r.arms[0], _t0), ToolArmLevel.armed);
      expect(r.levelOf(r.arms[1], _t0), ToolArmLevel.disarmed);
    });

    test('stale and armed is a warning; stale and disarmed is unknown', () {
      final s = ToolArmsReport.parse(_report([_arm('a', 1, armed: true, stale: true), _arm('a', 2, armed: false, stale: true)]), _t0)!;
      expect(s.levelOf(s.arms[0], _t0), ToolArmLevel.warning);
      expect(s.levelOf(s.arms[1], _t0), ToolArmLevel.unknown);
    });

    test('a row grows old on this panel even if the server called it fresh', () {
      final later = _t0.add(const Duration(seconds: 31));
      expect(r.levelOf(r.arms[0], later), ToolArmLevel.warning);
      expect(r.levelOf(r.arms[1], later), ToolArmLevel.unknown);
      expect(r.levelOf(r.arms[1], _t0.add(const Duration(seconds: 29))), ToolArmLevel.disarmed);
    });

    test('a clock that went back does not make a row younger', () {
      expect(r.ageNow(r.arms[0], _t0.subtract(const Duration(hours: 1))), 1);
    });

    test('dangerous rows come first, then by robot and tool', () {
      final s = ToolArmsReport.parse(
          _report([
            _arm('b', 1, armed: false),
            _arm('a', 2, armed: false, stale: true),
            _arm('b', 0, armed: true),
            _arm('a', 1, armed: true, stale: true),
            _arm('a', 0, armed: true),
          ]),
          _t0)!;
      final order = s.sorted(_t0).map((a) => '${a.robot}${a.toolId}').toList();
      expect(order, ['a1', 'a0', 'b0', 'a2', 'b1']);
    });
  });

  test('the age is short text', () {
    expect(formatToolArmAge(0).unit, 's');
    expect(formatToolArmAge(59.9).value, 59);
    expect(formatToolArmAge(60), (unit: 'min', value: 1));
    expect(formatToolArmAge(3599).value, 59);
    expect(formatToolArmAge(3600), (unit: 'h', value: 1));
    expect(formatToolArmAge(90000).value, 25);
  });

  group('the settings', () {
    test('off by default, and it opens the System tab only when on', () {
      expect(PanelConfig.defaults.toolArmsPanel, isFalse);
      expect(PanelConfig.defaults.systemTab, isFalse);
      final on = PanelConfig.parse('tool_arms_panel = on\ntool_arms_poll_seconds = 7\n');
      expect(on.toolArmsPanel, isTrue);
      expect(on.toolArmsPollSeconds, 7);
      expect(on.systemTab, isTrue);
    });

    test('a poll time that makes no sense keeps the default', () {
      expect(PanelConfig.parse('tool_arms_poll_seconds = 0').toolArmsPollSeconds, PanelConfig.defaults.toolArmsPollSeconds);
      expect(PanelConfig.parse('tool_arms_poll_seconds = x').toolArmsPollSeconds, PanelConfig.defaults.toolArmsPollSeconds);
    });
  });

  group('on the screen', () {
    const on = PanelConfig(toolArmsPanel: true);

    test('with the switch off nothing is asked of the server', () async {
      final calls = <String>[];
      final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: PanelConfig.defaults, operatorPin: OperatorPin(backend: _Backend()));
      vm.apiClient = HydraApiClient('127.0.0.1', 3000, client: MockClient((r) async {
        calls.add(r.url.path);
        return http.Response('{}', 404);
      }));
      vm.activeServer = ServerInfo(host: '127.0.0.1', port: 3000);
      vm.isLoggedIn = true;
      final model = SystemModel(vm: vm, supervised: true)..setVisible(true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls.where((c) => c.contains('tool-arms')), isEmpty);
      expect(model.toolArms, isNull);
      model.dispose();
      vm.dispose();
    });

    test('with the switch on and the tab shown the route is read, and only read', () async {
      final calls = <String>[];
      final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: on, operatorPin: OperatorPin(backend: _Backend()));
      vm.apiClient = HydraApiClient('127.0.0.1', 3000, client: MockClient((r) async {
        calls.add('${r.method} ${r.url.path}');
        return http.Response(jsonEncode(_report([_arm('a', 1)])), 200);
      }))
        ..authToken = _token();
      vm.activeServer = ServerInfo(host: '127.0.0.1', port: 3000);
      vm.isLoggedIn = true;
      final model = SystemModel(vm: vm, supervised: true)..setVisible(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, contains('GET /api/tool-arms'));
      expect(calls.every((c) => c.startsWith('GET')), isTrue, reason: 'read only');
      expect(model.toolArms!.arms.single.robot, 'a');
      model.setVisible(false);
      expect(vm.panelConfig.toolArmsPanel, isTrue);
      model.dispose();
      vm.dispose();
    });

    for (final c in <(int, ToolArmsFailure)>[
      (404, ToolArmsFailure.unsupported),
      (502, ToolArmsFailure.unavailable),
      (503, ToolArmsFailure.unavailable),
      (504, ToolArmsFailure.unavailable),
      (403, ToolArmsFailure.forbidden),
      (500, ToolArmsFailure.other),
    ]) {
      test('status ${c.$1} is "${c.$2.name}" and keeps no list', () async {
        final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: on, operatorPin: OperatorPin(backend: _Backend()));
        vm.apiClient = HydraApiClient('127.0.0.1', 3000, client: MockClient((r) async => http.Response('{"error":"x"}', c.$1)))..authToken = _token();
        vm.activeServer = ServerInfo(host: '127.0.0.1', port: 3000);
        vm.isLoggedIn = true;
        final model = SystemModel(vm: vm, supervised: true);
        await model.readToolArms();
        expect(model.toolArms, isNull);
        expect(model.toolArmsFailure, c.$2);
        model.dispose();
        vm.dispose();
      });
    }

    test('a malformed answer is "shape", a dead server is "network"', () async {
      Future<SystemModel> model(Future<http.Response> Function(http.Request) f) async {
        final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: on, operatorPin: OperatorPin(backend: _Backend()));
        vm.apiClient = HydraApiClient('127.0.0.1', 3000, client: MockClient(f))..authToken = _token();
        vm.activeServer = ServerInfo(host: '127.0.0.1', port: 3000);
        vm.isLoggedIn = true;
        final m = SystemModel(vm: vm, supervised: true);
        addTearDown(() {
          m.dispose();
          vm.dispose();
        });
        await m.readToolArms();
        return m;
      }

      expect((await model((r) async => http.Response('{"schema_version":"9"}', 200))).toolArmsFailure, ToolArmsFailure.shape);
      expect((await model((r) async => http.Response('not json', 200))).toolArmsFailure, ToolArmsFailure.shape);
      expect((await model((r) async => throw http.ClientException('refused'))).toolArmsFailure, ToolArmsFailure.network);
    });

    test('a good reading followed by a failed one drops the list', () async {
      var good = true;
      final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: on, operatorPin: OperatorPin(backend: _Backend()));
      vm.apiClient = HydraApiClient('127.0.0.1', 3000,
          client: MockClient((r) async => good ? http.Response(jsonEncode(_report([_arm('a', 1, armed: false)])), 200) : http.Response('{}', 503)))
        ..authToken = _token();
      vm.activeServer = ServerInfo(host: '127.0.0.1', port: 3000);
      vm.isLoggedIn = true;
      final model = SystemModel(vm: vm, supervised: true);
      await model.readToolArms();
      expect(model.toolArms, isNotNull);
      expect(model.toolArmsFailure, isNull);
      good = false;
      await model.readToolArms();
      expect(model.toolArms, isNull, reason: 'a list that could not be refreshed is not kept as current');
      expect(model.toolArmsFailure, ToolArmsFailure.unavailable);
      model.dispose();
      vm.dispose();
    });
  });

  group('the texts', () {
    testWidgets('every language has every text and the placeholders are filled', (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        final texts = <String>[
          l.systemToolArmsTitle,
          l.toolArmsLoading,
          l.toolArmsNone,
          l.toolArmsSummary(2, 5),
          l.toolArmsStaleNote(3),
          l.toolArmsRow('arm-1', 4),
          l.toolArmsBy('urtc'),
          l.toolArmsAgeSeconds(7),
          l.toolArmsAgeMinutes(7),
          l.toolArmsAgeHours(7),
          l.toolArmsArmed,
          l.toolArmsDisarmed,
          l.toolArmsWarning,
          l.toolArmsUnknown,
          l.toolArmsUnavailable,
          l.toolArmsUnsupported,
          l.toolArmsForbidden,
          l.toolArmsNetwork,
          l.toolArmsOther,
          l.toolArmsShape,
          l.toolArmsReadOnlyNote,
        ];
        for (final t in texts) {
          expect(t.trim(), isNotEmpty, reason: locale.languageCode);
          expect(t, isNot(contains('{')), reason: '${locale.languageCode}: $t');
        }
        expect(l.toolArmsRow('arm-1', 4), allOf(contains('arm-1'), contains('4')), reason: locale.languageCode);
        expect(texts.toSet().length, greaterThan(15), reason: '${locale.languageCode} must not repeat one text for several states');
      }
      expect(AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(), {'en', 'es', 'de', 'fr', 'it', 'ja', 'zh', 'pt'});
    });

    testWidgets('the card shows rows, the old ones as not confirmed', (tester) async {
      final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: const PanelConfig(toolArmsPanel: true), operatorPin: OperatorPin(backend: _Backend()));
      final model = SystemModel(vm: vm, supervised: true);
      model.toolArms = ToolArmsReport.parse(
          _report([_arm('arm-1', 1, armed: false), _arm('arm-1', 2, armed: true), _arm('arm-2', 1, armed: true, stale: true, age: 200)]), DateTime.now());
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RobotViewModel>.value(value: vm),
            ChangeNotifierProvider<SystemModel>.value(value: model),
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
      expect(find.byKey(const Key('tool-arms-summary')), findsOneWidget);
      expect(find.text('2 of 3 tools armed'), findsOneWidget);
      expect(find.byKey(const Key('tool-arms-stale')), findsOneWidget);
      // the old armed row first, then the fresh armed one, then the disarmed one
      expect((tester.widget<Text>(find.byKey(const Key('tool-arm-level-0')))).data, 'ARMED, REPORT OLD');
      expect((tester.widget<Text>(find.byKey(const Key('tool-arm-level-1')))).data, 'ARMED');
      expect((tester.widget<Text>(find.byKey(const Key('tool-arm-level-2')))).data, 'DISARMED');
      expect(find.byKey(const Key('tool-arms-problem')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      model.dispose();
      vm.dispose();
    });

    testWidgets('a failure is a message, never an empty list', (tester) async {
      final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: const PanelConfig(toolArmsPanel: true), operatorPin: OperatorPin(backend: _Backend()));
      final model = SystemModel(vm: vm, supervised: true)..toolArmsFailure = ToolArmsFailure.unavailable;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RobotViewModel>.value(value: vm),
            ChangeNotifierProvider<SystemModel>.value(value: model),
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
      expect(find.byKey(const Key('tool-arms-problem')), findsOneWidget);
      expect(find.byKey(const Key('tool-arms-none')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      model.dispose();
      vm.dispose();
    });
  });
}
