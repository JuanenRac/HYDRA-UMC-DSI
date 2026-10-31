// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/connections_and_server_options_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The history of connections and the access options of the server: the reading of
// both answers, the body of a change (only what changed, never a value the server
// fixes), the changes that ask first, and the calls against a real local dart:io
// HttpServer (no mocked client).
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/models/connection_history.dart';
import 'package:hydra_umc_dsi/models/server_info.dart';
import 'package:hydra_umc_dsi/models/server_security.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';

const String _client = '{"schema_version":"1.0","id":"0123456789abcdef","kind":"dsi","user":"ana","app_version":"0.2.8","origin":"local",'
    '"two_factor":true,"first_seen_utc":"2026-01-01T00:00:00.000Z","last_seen_utc":"2026-01-02T00:00:00.000Z","active_sessions":2,"logins_ok":5,"logins_failed":1}';

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

String _tokenWithRole(String role) {
  String part(Object json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'username': 'alice', 'role': role})}.sig';
}

class _Server {
  final HttpServer http;
  final List<String> seen = [];
  final List<Map<String, dynamic>> puts = [];
  int connectionsStatus = 200;
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
      seen.add(route);
      request.response.headers.contentType = ContentType.json;
      if (route == 'POST /api/login') {
        request.response.write(jsonEncode({'success': true, 'token': _tokenWithRole('admin'), 'refreshToken': 'refresh-1'}));
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
      } else if (route == 'GET /api/connections/clients') {
        request.response.statusCode = connectionsStatus;
        request.response.write('{"clients":[$_client]}');
      } else if (route == 'GET /api/connections/events') {
        request.response.statusCode = connectionsStatus;
        request.response.write('{"events":[{"schema_version":"1.0","id":1,"at_utc":"2026-01-01T00:00:00.000Z","action":"login","client_kind":"dsi","client_id":"0123456789abcdef","user":"ana"}]}');
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

Future<(_Server, RobotViewModel)> _signedIn() async {
  SharedPreferences.setMockInitialValues({});
  final server = await _Server.start();
  addTearDown(server.close);
  final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _FakeSecureBackend()));
  addTearDown(vm.dispose);
  expect(await vm.login(ServerInfo(host: '127.0.0.1', port: server.port, username: 'alice', password: 'x')), isTrue);
  return (server, vm);
}

void main() {
  group('history of connections', () {
    test('a date is read as the server writes it', () {
      expect(ConnectionHistory.parseDate('2026-01-01T00:00:00.000Z'), DateTime.utc(2026, 1, 1));
      expect(ConnectionHistory.parseDate('2026-01-01T00:00:00.123Z'), DateTime.utc(2026, 1, 1, 0, 0, 0, 123));
      expect(ConnectionHistory.parseDate('2026-01-01T00:00:01Z'), DateTime.utc(2026, 1, 1, 0, 0, 1));
      expect(ConnectionHistory.parseDate('yesterday'), isNull);
      expect(ConnectionHistory.parseDate('2026-13-01T00:00:00.000Z'), isNull);
      expect(ConnectionHistory.parseDate(null), isNull);
    });

    test('a client is read field by field', () {
      final c = ConnectionHistory.parseClients('{"clients":[$_client]}').single;
      expect(c.kind, 'dsi');
      expect(c.user, 'ana');
      expect(c.appVersion, '0.2.8');
      expect(c.origin, 'local');
      expect(c.twoFactor, isTrue);
      expect(c.activeSessions, 2);
      expect(c.loginsOk, 5);
      expect(c.loginsFailed, 1);
      expect(c.ip, isNull);
    });

    test('an unknown kind is other and an entry with a bad identifier or date is left out', () {
      final odd = _client.replaceFirst('"dsi"', '"toaster"');
      expect(ConnectionHistory.parseClients('{"clients":[$odd]}').single.kind, 'other');
      expect(ConnectionHistory.parseClients('{"clients":[${_client.replaceFirst('0123456789abcdef', 'XYZ')}]}'), isEmpty);
      expect(ConnectionHistory.parseClients('{"clients":[${_client.replaceFirst('2026-01-02T00:00:00.000Z', 'soon')}]}'), isEmpty);
      expect(ConnectionHistory.parseClients('{"clients":"nope"}'), isEmpty);
      expect(ConnectionHistory.parseClients('{}'), isEmpty);
    });

    test('clients come most recently seen first and an address appears only when sent', () {
      final older = _client.replaceFirst('0123456789abcdef', 'fedcba9876543210').replaceFirst('2026-01-02T00:00:00.000Z', '2026-01-05T00:00:00.000Z').replaceFirst('"logins_failed":1', '"logins_failed":1,"ip":"192.168.0.9"');
      final list = ConnectionHistory.parseClients('{"clients":[$_client,$older]}');
      expect(list.map((c) => c.id), ['fedcba9876543210', '0123456789abcdef']);
      expect(list[0].ip, '192.168.0.9');
      expect(list[1].ip, isNull);
    });

    test('events come newest first and only with the actions the server writes', () {
      const events = '{"events":['
          '{"id":1,"at_utc":"2026-01-01T00:00:00.000Z","action":"login","client_kind":"studio","user":"ana"},'
          '{"id":3,"at_utc":"2026-01-03T00:00:00.000Z","action":"login_failed","client_kind":"dsi","user":"ana","app_version":"0.2.8"},'
          '{"id":2,"at_utc":"2026-01-02T00:00:00.000Z","action":"format_disk","client_kind":"studio"},'
          '{"id":0,"at_utc":"2026-01-02T00:00:00.000Z","action":"login","client_kind":"studio"}]}';
      final list = ConnectionHistory.parseEvents(events);
      expect(list.map((e) => e.id), [3, 1]);
      expect(list[0].isFailure, isTrue);
      expect(list[1].isFailure, isFalse);
      expect(list[0].appVersion, '0.2.8');
      expect(list[1].appVersion, isNull);
    });

    test('how long ago is short', () {
      final now = DateTime.utc(2026, 1, 10);
      expect(ConnectionHistory.ago(now.subtract(const Duration(seconds: 30)), now), (30, 's'));
      expect(ConnectionHistory.ago(now.subtract(const Duration(minutes: 12)), now), (12, 'min'));
      expect(ConnectionHistory.ago(now.subtract(const Duration(hours: 3)), now), (3, 'h'));
      expect(ConnectionHistory.ago(now.subtract(const Duration(days: 3)), now), (3, 'd'));
      expect(ConnectionHistory.ago(now.add(const Duration(seconds: 5)), now), (0, 's'));
    });
  });

  group('access options of the server', () {
    final options = ServerSecurityOptions.parse(_config)!;

    test('all seven options are read with where they come from', () {
      expect(options.healthOpen, const ServerOption(false, OptionSource.defaultValue));
      expect(options.publishGlobalStop, const ServerOption(false, OptionSource.config));
      expect(options.logRedaction, const ServerOption(true, OptionSource.defaultValue));
      expect(options.voiceSignature!.locked, isTrue);
      expect(options.cameraOpen!.locked, isFalse);
      expect(options.isEmpty, isFalse);
    });

    test('a server that predates the options answers without them', () {
      final old = ServerSecurityOptions.parse('{"port":18000}')!;
      expect(old.isEmpty, isTrue);
      expect(old.patch(old.toValues().copyWith(healthOpen: true)), isNull);
      expect(ServerSecurityOptions.parse('not json'), isNull);
      expect(ServerSecurityOptions.parse('[]'), isNull);
    });

    test('an option with a wrong type or an unknown source is left out and the rest still reads', () {
      final o = ServerSecurityOptions.parse('{"health":{"open":{"value":"yes","source":"default"}},'
          '"camera":{"open":{"value":true,"source":"cloud"}},"logging":{"redactSecrets":{"value":false,"source":"config"}}}')!;
      expect(o.healthOpen, isNull);
      expect(o.cameraOpen, isNull);
      expect(o.logRedaction, const ServerOption(false, OptionSource.config));
    });

    test('the body holds only what changed and each option goes under the group the server reads it from', () {
      expect(options.patch(options.toValues()), isNull);
      final one = options.patch(options.toValues().copyWith(healthOpen: true, recordAddress: true))!;
      expect(one.keys.toSet(), {'health', 'connections'});
      final all = options.patch(const ServerSecurityValues(
        healthOpen: true, publishGlobalStop: true, recordAddress: true, cameraOpen: true,
        wsQueryToken: true, logRedaction: false, voiceSignature: true))!;
      expect((all['safety'] as Map)['publishGlobalStop'], isTrue);
      expect((all['camera'] as Map)['open'], isTrue);
      expect((all['websocket'] as Map)['allowQueryToken'], isTrue);
      expect((all['logging'] as Map)['redactSecrets'], isFalse);
      // the signature is fixed by the environment of the server: it is never sent
      expect(all.containsKey('voice'), isFalse);
    });

    test('loosening a switch asks and tightening it or announcing a stop does not', () {
      final v = options.toValues();
      expect(options.lowerings(v.copyWith(healthOpen: true)), [ProtectionLowering.healthOpen]);
      expect(options.lowerings(v.copyWith(recordAddress: true)), [ProtectionLowering.recordAddress]);
      expect(options.lowerings(v.copyWith(cameraOpen: true)), [ProtectionLowering.cameraOpen]);
      expect(options.lowerings(v.copyWith(wsQueryToken: true)), [ProtectionLowering.wsQueryToken]);
      expect(options.lowerings(v.copyWith(logRedaction: false)), [ProtectionLowering.logRedactionOff]);
      expect(options.lowerings(v.copyWith(publishGlobalStop: true)), isEmpty);
      // the signature is locked: dropping it is neither sent nor asked about
      expect(options.lowerings(v.copyWith(voiceSignature: false)), isEmpty);

      final open = ServerSecurityOptions.parse('{"health":{"open":{"value":true,"source":"config"}},"camera":{"open":{"value":true,"source":"config"}}}')!;
      expect(open.lowerings(open.toValues().copyWith(healthOpen: false, cameraOpen: false)), isEmpty);
      expect(open.patch(open.toValues().copyWith(healthOpen: false)), isNotNull);
    });

    test('several loosenings are listed in a fixed order', () {
      final all = options.toValues().copyWith(healthOpen: true, recordAddress: true, cameraOpen: true, wsQueryToken: true, logRedaction: false);
      expect(options.lowerings(all), [
        ProtectionLowering.healthOpen,
        ProtectionLowering.recordAddress,
        ProtectionLowering.cameraOpen,
        ProtectionLowering.wsQueryToken,
        ProtectionLowering.logRedactionOff,
      ]);
    });
  });

  group('camera password and TLS of a new installation', () {
    const withInstall = '{"camera":{"open":{"value":false,"source":"default"},"credentialsViaEnv":{"value":true,"source":"default"}},'
        '"install":{"newInstallTls":{"value":true,"source":"default"}}}';
    final o = ServerSecurityOptions.parse(withInstall)!;

    test('both are read and kept apart from the camera pictures', () {
      expect(o.cameraCredentialsViaEnv, const ServerOption(true, OptionSource.defaultValue));
      expect(o.newInstallTls, const ServerOption(true, OptionSource.defaultValue));
      expect(o.cameraOpen, const ServerOption(false, OptionSource.defaultValue));
      final old = ServerSecurityOptions.parse('{"camera":{"open":{"value":true,"source":"config"}}}')!;
      expect(old.cameraCredentialsViaEnv, isNull);
      expect(old.newInstallTls, isNull);
      expect(old.toValues().cameraCredentialsViaEnv, isTrue);
      expect(old.toValues().newInstallTls, isTrue);
      expect(old.patch(old.toValues().copyWith(cameraCredentialsViaEnv: false, newInstallTls: false)), isNull);
    });

    test('only what changed is sent, under the group the server reads it from', () {
      expect(o.patch(o.toValues()), isNull);
      final body = o.patch(o.toValues().copyWith(cameraCredentialsViaEnv: false, newInstallTls: false))!;
      expect((body['camera'] as Map)['credentialsViaEnv'], isFalse);
      expect((body['camera'] as Map).containsKey('open'), isFalse);
      expect((body['install'] as Map)['newInstallTls'], isFalse);
      expect(body.keys.toSet(), {'camera', 'install'});
    });

    test('taking either away asks; putting it back or a value fixed by the environment does not', () {
      expect(o.lowerings(o.toValues().copyWith(cameraCredentialsViaEnv: false)), [ProtectionLowering.cameraCredentialsInArguments]);
      expect(o.lowerings(o.toValues().copyWith(newInstallTls: false)), [ProtectionLowering.newInstallTlsOff]);
      final loose = ServerSecurityOptions.parse('{"camera":{"credentialsViaEnv":{"value":false,"source":"config"}},"install":{"newInstallTls":{"value":false,"source":"config"}}}')!;
      expect(loose.lowerings(loose.toValues().copyWith(cameraCredentialsViaEnv: true, newInstallTls: true)), isEmpty);
      final fixed = ServerSecurityOptions.parse('{"camera":{"credentialsViaEnv":{"value":false,"source":"env"}},"install":{"newInstallTls":{"value":false,"source":"env"}}}')!;
      expect(fixed.cameraCredentialsViaEnv!.locked, isTrue);
      expect(fixed.lowerings(fixed.toValues().copyWith(cameraCredentialsViaEnv: true)), isEmpty);
      expect(fixed.patch(fixed.toValues().copyWith(cameraCredentialsViaEnv: true, newInstallTls: true)), isNull);
    });
  });

  group('against a local server', () {
    test('the list of clients and the latest sign-ins are read', () async {
      final (server, vm) = await _signedIn();
      await vm.refreshConnections();
      expect(vm.connectionsFailure, isNull);
      expect(vm.connectionClients!.single.user, 'ana');
      expect(vm.connectionEvents!.single.action, 'login');
      expect(server.seen, contains('GET /api/connections/clients'));
    });

    test('a server without the routes says so and keeps nothing', () async {
      final (server, vm) = await _signedIn();
      server.connectionsStatus = 404;
      await vm.refreshConnections();
      expect(vm.connectionsFailure, ConnectionsFailure.unavailable);
      expect(vm.connectionClients, isNull);
    });

    test('the options are read, only the change is sent and the answer is kept', () async {
      final (server, vm) = await _signedIn();
      await vm.refreshServerOptions();
      expect(vm.serverOptionsFailure, isNull);
      final current = vm.serverOptions!;
      await vm.saveServerOptions(current.toValues().copyWith(healthOpen: true));
      expect(server.puts, [
        {'health': {'open': true}},
      ]);
      expect(vm.serverOptions!.healthOpen, const ServerOption(true, OptionSource.config));
      expect(vm.serverOptionsSaved, isTrue);
    });

    test('nothing is sent when nothing changed', () async {
      final (server, vm) = await _signedIn();
      await vm.refreshServerOptions();
      await vm.saveServerOptions(vm.serverOptions!.toValues());
      expect(server.puts, isEmpty);
    });

    test('an account that may not read the options is told so', () async {
      final (server, vm) = await _signedIn();
      server.configStatus = 403;
      await vm.refreshServerOptions();
      expect(vm.serverOptionsFailure, ServerOptionsFailure.forbidden);
      expect(vm.serverOptions, isNull);
    });
  });
}
