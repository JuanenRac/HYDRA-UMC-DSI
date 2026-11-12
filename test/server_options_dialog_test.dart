// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/server_options_dialog_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The access options dialog, drawn and used against a real local dart:io HttpServer: the rows it draws, a value the
// server fixes that cannot be changed, a change that lowers a protection asking first (and sending nothing when it
// is refused), and a refusal of the server shown as a sentence.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/l10n/app_localizations_en.dart';
import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/widgets/server_options_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _en = AppLocalizationsEn();

const String _config = '{"port":18000,"aiAccess":{"value":"open","source":"default"},'
    '"health":{"open":{"value":false,"source":"default"}},'
    '"safety":{"publishGlobalStop":{"value":false,"source":"config"}},'
    '"connections":{"recordAddress":{"value":false,"source":"default"}},'
    '"camera":{"open":{"value":false,"source":"default"}},'
    '"websocket":{"allowQueryToken":{"value":false,"source":"default"}},'
    '"logging":{"redactSecrets":{"value":true,"source":"default"}},'
    '"voice":{"includeHeardText":{"value":false,"source":"default"},"requireSignature":{"value":false,"source":"env"}}}';

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
  final List<Map<String, dynamic>> puts = [];
  int configStatus = 200;

  _Server(this.http) {
    http.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        try {
          final socket = await WebSocketTransformer.upgrade(request, protocolSelector: (p) => p.contains('hydra.bearer') ? 'hydra.bearer' : null);
          socket.listen((_) {});
        } catch (_) {}
        return;
      }
      final body = await utf8.decoder.bind(request).join();
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
                {'id': 1, 'online': true, 'joints': {'j1': 0}, 'playbackState': {'isPlaying': false}, 'combinedWith': []},
              ],
            },
          ],
        }));
      } else if (route == 'GET /api/system/metrics') {
        request.response.write(jsonEncode({'cpu_load': 3, 'memory_usage': 40, 'temp': 48.0, 'temp_is_real': false, 'uptime': 99}));
      } else if (route == 'GET /api/claims') {
        request.response.write(jsonEncode({'claims': []}));
      } else if (route == 'GET /api/admin/server-config') {
        request.response.statusCode = configStatus;
        request.response.write(_config);
      } else if (route == 'PUT /api/admin/server-config') {
        puts.add(jsonDecode(body) as Map<String, dynamic>);
        request.response.write(_config.replaceFirst('"health":{"open":{"value":false,"source":"default"}}', '"health":{"open":{"value":true,"source":"config"}}'));
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

/// Waits, on the real clock, until the dialog has an answer from the server (the options or the reason it has none).
Future<void> _settle(WidgetTester tester, RobotViewModel vm) async {
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    if (!vm.serverOptionsBusy && (vm.serverOptions != null || vm.serverOptionsFailure != null)) return;
  }
  fail('the server options never arrived: busy=${vm.serverOptionsBusy} options=${vm.serverOptions} failure=${vm.serverOptionsFailure}');
}

/// Takes the dialog down and stops the timers of the view model, which a test may not leave running.
Future<void> _done(WidgetTester tester, RobotViewModel vm) async {
  await tester.pumpWidget(const SizedBox());
  vm.dispose();
  await tester.pump();
}

/// Signs in and opens the dialog; the real sockets only move outside the fake clock of the test, so each wait goes through runAsync.
Future<(_Server, RobotViewModel)> _open(WidgetTester tester, {int configStatus = 200}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  final server = (await tester.runAsync(_Server.start))!;
  server.configStatus = configStatus;
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
    home: Scaffold(body: ServerOptionsDialog(vm: vm)),
  ));
  await tester.pump();
  await _settle(tester, vm);
  return (server, vm);
}

void main() {
  // the widget test binding answers every HTTP request with a 400 unless this is lifted; these tests talk to a real local server
  setUp(() => HttpOverrides.global = null);

  testWidgets('the dialog draws a row for every option the server sends and the one it fixes cannot be switched', (tester) async {
    final (_, vm) = await _open(tester);
    expect(find.text(_en.serverOptionsTitle), findsOneWidget);
    for (final id in ['health', 'stop', 'address', 'camera', 'ws', 'log', 'voice']) {
      expect(find.byKey(ValueKey('server-option-$id')), findsOneWidget, reason: id);
    }
    // an option that the server does not send is not drawn
    expect(find.byKey(const ValueKey('server-option-install-tls')), findsNothing);
    expect(tester.widget<Switch>(find.byKey(const ValueKey('server-option-log'))).value, isTrue);
    expect(tester.widget<Switch>(find.byKey(const ValueKey('server-option-health'))).value, isFalse);
    // the voice signature comes from the environment: the server fixes it, so the switch is dead
    expect(tester.widget<Switch>(find.byKey(const ValueKey('server-option-voice'))).onChanged, isNull);
    expect(tester.widget<Switch>(find.byKey(const ValueKey('server-option-health'))).onChanged, isNotNull);
    expect(find.byKey(const ValueKey('server-options-failure')), findsNothing);
    await _done(tester, vm);
  });

  testWidgets('save is off until something changes', (tester) async {
    final (_, vm) = await _open(tester);
    final save = find.byKey(const ValueKey('server-options-save'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('server-option-log')));
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('server-option-log')));
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await _done(tester, vm);
  });

  testWidgets('lowering a protection asks first and sends nothing when the answer is no', (tester) async {
    final (server, vm) = await _open(tester);
    await tester.tap(find.byKey(const ValueKey('server-option-health')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('server-options-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('server-options-confirm')), findsOneWidget);
    expect(find.textContaining(_en.serverOptionsHealthConfirm), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('server-options-confirm-no')));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    expect(server.puts, isEmpty);
    await _done(tester, vm);
  });

  testWidgets('after yes the change goes out alone and the dialog says it was saved', (tester) async {
    final (server, vm) = await _open(tester);
    await tester.tap(find.byKey(const ValueKey('server-option-health')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('server-options-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-options-confirm-yes')));
    await tester.pump();
    for (var i = 0; i < 100 && server.puts.isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    expect(server.puts, hasLength(1));
    expect(jsonEncode(server.puts.single), contains('"open":true'));
    expect(jsonEncode(server.puts.single), isNot(contains('redactSecrets')));
    expect(find.byKey(const ValueKey('server-options-saved')), findsOneWidget);
    await _done(tester, vm);
  });

  testWidgets('a refusal of the server is shown as a sentence and no row is drawn', (tester) async {
    final (_, vm) = await _open(tester, configStatus: 403);
    expect(find.byKey(const ValueKey('server-options-failure')), findsOneWidget);
    expect(find.byKey(const ValueKey('server-option-health')), findsNothing);
    await _done(tester, vm);
  });
}
