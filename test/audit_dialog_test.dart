// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/audit_dialog_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The audit dialog, drawn and used against a real local dart:io HttpServer: a recorded line with its type, outcome and
// person, the check of the chain when asked (the server's and this app's own), the filters that ask the server again,
// an empty record, a record the server keeps switched off, and a refusal shown as a sentence.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/l10n/app_localizations_en.dart';
import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/models/sha256.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/widgets/audit_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _en = AppLocalizationsEn();

const String _prev = '0000000000000000000000000000000000000000000000000000000000000000';
const String _line = '{"seq":1,"ts":"2030-01-01T00:00:00.000Z","type":"claim","outcome":"ok","username":"ana","prev":"$_prev"}';

String _stored() => '${_line.substring(0, _line.length - 1)},"hash":"${sha256Hex(utf8.encode(_line))}"}';

String _record({bool enabled = true, bool lockedOff = false, List<String>? entries}) {
  final list = entries ?? [_stored()];
  return '{"enabled":$enabled,"lockedOff":$lockedOff,"entries":[${list.join(',')}],"verification":{"ok":true,"entries":${list.length}}}';
}

class _FakeSecureBackend implements SecureTokenBackend {
  final Map<String, String> store = {};
  @override
  Future<void> write(String key, String value) async => store[key] = value;
  @override
  Future<String?> read(String key) async => store[key];
  @override
  Future<void> delete(String key) async => store.remove(key);
}

String _admin() {
  String part(Object json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'username': 'alice', 'role': 'admin'})}.sig';
}

class _Server {
  final HttpServer http;
  final List<String> auditQueries = [];
  int auditStatus = 200;
  String auditBody = _record();

  _Server(this.http) {
    http.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        try {
          final socket = await WebSocketTransformer.upgrade(request, protocolSelector: (p) => p.contains('hydra.bearer') ? 'hydra.bearer' : null);
          socket.listen((_) {});
        } catch (_) {}
        return;
      }
      await utf8.decoder.bind(request).join();
      final route = '${request.method} ${request.uri.path}';
      request.response.headers.contentType = ContentType.json;
      if (route == 'POST /api/login') {
        request.response.write(jsonEncode({'success': true, 'token': _admin(), 'refreshToken': 'refresh-1'}));
      } else if (route == 'GET /api/settings') {
        request.response.write(jsonEncode({
          'activeControllerId': 'c1',
          'controllers': [
            {
              'id': 'c1',
              'robots': [
                {'id': 1, 'name': 'Arm A', 'online': true, 'joints': {'j1': 0}, 'playbackState': {'isPlaying': false}, 'combinedWith': []},
              ],
            },
          ],
        }));
      } else if (route == 'GET /api/system/metrics') {
        request.response.write(jsonEncode({'cpu_load': 3, 'memory_usage': 40, 'temp': 48.0, 'temp_is_real': false, 'uptime': 99}));
      } else if (route == 'GET /api/claims') {
        request.response.write(jsonEncode({'claims': []}));
      } else if (route == 'GET /api/audit') {
        auditQueries.add(request.uri.query);
        request.response.statusCode = auditStatus;
        request.response.write(auditBody);
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });
  }

  static Future<_Server> start() async => _Server(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
  int get port => http.port;
  Future<void> close() => http.close(force: true);
}

Future<void> _until(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }
  expect(done(), isTrue, reason: 'the server never answered');
}

Future<void> _done(WidgetTester tester, RobotViewModel vm) async {
  await tester.pumpWidget(const SizedBox());
  vm.dispose();
  await tester.pump();
}

Future<(_Server, RobotViewModel)> _open(WidgetTester tester, {int status = 200, String? body}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  final server = (await tester.runAsync(_Server.start))!;
  server.auditStatus = status;
  if (body != null) server.auditBody = body;
  addTearDown(() => server.close());
  final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _FakeSecureBackend()));
  final ok = await tester.runAsync(() => vm.login(ServerInfo(host: '127.0.0.1', port: server.port, username: 'alice', password: 'x')));
  expect(ok, isTrue);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: AuditDialog(vm: vm)),
  ));
  await tester.pump();
  await _until(tester, () => server.auditQueries.isNotEmpty && !vm.auditBusy);
  await tester.pump();
  return (server, vm);
}

void main() {
  // the widget test binding answers every HTTP request with a 400 unless this is lifted; these tests talk to a real local server
  setUp(() => HttpOverrides.global = null);

  testWidgets('a recorded line shows its number, its type, its outcome and the person', (tester) async {
    final (_, vm) = await _open(tester);
    expect(find.text(_en.auditTitle), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text(_en.auditTypeClaim), findsOneWidget);
    expect(find.text(_en.auditOutcomeOk), findsOneWidget);
    expect(find.text('ana'), findsOneWidget);
    expect(find.byKey(const ValueKey('audit-failure')), findsNothing);
    await _done(tester, vm);
  });

  testWidgets('the first read asks for no check of the chain and verify asks for it and shows both results', (tester) async {
    final (server, vm) = await _open(tester);
    expect(server.auditQueries.first, isNot(contains('verify')));
    expect(find.byKey(const ValueKey('audit-server-chain')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('audit-verify')));
    await tester.pump();
    await _until(tester, () => server.auditQueries.length == 2 && !vm.auditBusy);
    await tester.pump();
    expect(server.auditQueries.last, contains('verify=1'));
    expect(find.byKey(const ValueKey('audit-server-chain')), findsOneWidget);
    expect(find.byKey(const ValueKey('audit-local-chain')), findsOneWidget);
    await _done(tester, vm);
  });

  testWidgets('each filter button asks the server again with its choice', (tester) async {
    final (server, vm) = await _open(tester);
    await tester.tap(find.byKey(const ValueKey('audit-type')));
    await tester.pump();
    await _until(tester, () => server.auditQueries.length == 2 && !vm.auditBusy);
    expect(server.auditQueries.last, contains('type='));
    await tester.tap(find.byKey(const ValueKey('audit-robot')));
    await tester.pump();
    await _until(tester, () => server.auditQueries.length == 3 && !vm.auditBusy);
    expect(server.auditQueries.last, contains('robotId=1'));
    expect(find.text('Arm A'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('audit-limit')));
    await tester.pump();
    await _until(tester, () => server.auditQueries.length == 4 && !vm.auditBusy);
    expect(server.auditQueries.last, contains('limit='));
    await _done(tester, vm);
  });

  testWidgets('an empty record says so', (tester) async {
    final (_, vm) = await _open(tester, body: _record(entries: []));
    expect(find.text(_en.auditEmpty), findsOneWidget);
    expect(find.text('#1'), findsNothing);
    await _done(tester, vm);
  });

  testWidgets('a record that the server keeps off says why', (tester) async {
    final (_, vm) = await _open(tester, body: _record(enabled: false, lockedOff: true, entries: []));
    expect(find.text(_en.auditLockedOff), findsOneWidget);
    await _done(tester, vm);
  });

  testWidgets('an account that is not an administrator is told so in a sentence', (tester) async {
    final (_, vm) = await _open(tester, status: 403, body: '{"error":"admin only"}');
    expect(find.byKey(const ValueKey('audit-failure')), findsOneWidget);
    expect(find.text(_en.auditFailureForbidden), findsOneWidget);
    expect(find.text('#1'), findsNothing);
    await _done(tester, vm);
  });
}
