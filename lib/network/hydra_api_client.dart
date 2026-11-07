// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/hydra_api_client.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Talks the exact contract in HYDRA-UMC-SERVER/docs/REMOTE_API.md - ported
// from HYDRA-UMC-IOS-CONTROL's own network/hydra_api_client.dart (same
// Dart/Flutter stack, direct reuse) with one deliberate change: the
// X-Hydra-Client header below identifies this client as "dsi" rather than
// "ios". See this file's own _clientHeaders doc comment for what that does
// and doesn't do server-side today.
//   - POST /api/login               - obtain a bearer token.
//   - GET  /api/hydra-info          - discovery/identity.
//   - GET  /api/settings            - full current state, needs a bearer token (either role).
//   - POST /api/stop-all            - global stop of every robot
//   - POST /api/robot/:id/command   - atomic per-robot command, either role -
//     the PRIMARY way this app writes (see state/robot_view_model.dart).
//   - GET  /api/system/metrics      - host CPU/memory/temp/uptime/network.
// =============================================================================


import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show CommandSequence, HydraApiCore, HydraApiException;

import '../app_version.dart';
import '../models/access.dart';
import '../models/contract_v2.dart';
import 'package_http_transport.dart';
import 'tls_settings.dart';

// The refused-answer type, the numbering of motion commands, the renewal of an
// expired session and the headers live in the shared package of the SDK
// (clients/dart_app_common); this class adds the choice between http and https
// (the TLS policy of the app) and the endpoints that answer with the app's own models.
export 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show HydraApiException, TokenRenewer;

class HydraApiClient extends HydraApiCore {
  // Starts as plain HTTP: getHydraInfo() below switches it to HTTPS the first time a
  // plain-HTTP probe gets no answer at all and an HTTPS one does (the server's
  // optional TLS_CERT_PATH/TLS_KEY_PATH switches it to HTTPS/WSS-only, with no
  // HTTP fallback of its own). It never goes back to http by itself.

  /// True once this server was seen answering over TLS (or was saved so).
  bool _tlsSeen;

  /// The controller id of this installation (see models/access.dart), sent in
  /// the body and in the `X-Controller-Id` header of every reserve, release,
  /// jog-arm and command. It is made once and kept (see ClientPrefs), so a
  /// reservation made from this device can still be released after a restart.
  static String controllerId = generateControllerId();

  /// The counter that numbers the motion commands of this run, shared by every client of the app.
  static final CommandSequence sharedSequence = CommandSequence();

  /// [useTls] starts the client on https:// - for a server that was already
  /// seen answering TLS. It never goes back to plain http by itself: a server
  /// that once spoke TLS and now answers over http is not trusted with a
  /// password or a token in the clear.
  HydraApiClient(String host, int port, {http.Client? client, bool useTls = false})
      : _tlsSeen = useTls,
        super(
          baseUrl: '${useTls || !TlsPolicy.isLoopback(host) ? 'https' : 'http'}://$host:$port',
          transport: PackageHttpTransport(client ?? createClient()),
          clientHeader: clientHeaderValue(kAppVersion),
          controllerIdOf: () => controllerId,
          sequence: sharedSequence,
        );

  /// `dsi/<version>`, or just `dsi` when the version is not one the server
  /// takes (1 to 24 of 0-9 A-Z a-z . _ -).
  static String clientHeaderValue(String version) => HydraApiCore.clientHeaderValue('dsi', version);

  Future<Map<String, dynamic>?> getHydraInfo() async {
    final direct = await _probeHydraInfo(baseUrl);
    if (direct != null) {
      _noteSchemeWorks();
      return direct;
    }
    // HTTPS is tried first. Plain HTTP is only a second try, and only when
    // the security settings allow it for this host (this same machine always
    // does; the local network needs the switch; anywhere else needs the remote
    // switch too). A server that once spoke TLS is never retried over plain HTTP.
    final other = _otherSchemeUrl();
    if (other != null) {
      final viaOther = await _probeHydraInfo(other);
      if (viaOther != null) {
        baseUrl = other;
        _noteSchemeWorks();
        return viaOther;
      }
    }
    return null;
  }

  // Same scheme resolution getHydraInfo() does, for login() and getSettings():
  // a harmless GET /api/hydra-info (it needs no credentials), only to learn the
  // scheme this host answers on.
  @override
  Future<void> resolveScheme() async {
    if (usesTls && _tlsSeen) return;
    _httpsProbeError = null;
    if (await _probeHydraInfo(baseUrl) != null) {
      _noteSchemeWorks();
      return;
    }
    final other = _otherSchemeUrl();
    if (other == null) return;
    if (await _probeHydraInfo(other) != null) {
      baseUrl = other;
      _noteSchemeWorks();
    } else if (usesTls && _httpsProbeError != null && isTlsFailure(_httpsProbeError!) && !isCertificateRejection(_httpsProbeError!)) {
      // The server does not speak TLS at all (it ended the handshake, it did not refuse a certificate) and plain HTTP
      // is allowed for this host: the server just does not answer GET /api/hydra-info, so go by the failed handshake.
      baseUrl = other;
    }
  }

  Object? _httpsProbeError;

  /// A server that answered over HTTPS is not trusted over plain HTTP later.
  void _noteSchemeWorks() {
    if (usesTls) _tlsSeen = true;
  }

  /// The other scheme to try for this host, or null when it must not be tried.
  String? _otherSchemeUrl() {
    if (baseUrl.startsWith('http://')) return baseUrl.replaceFirst('http://', 'https://');
    if (_tlsSeen) return null;
    final host = Uri.parse(baseUrl).host;
    if (!TlsSettingsStore.current.plainAllowedFor(host)) return null;
    return baseUrl.replaceFirst('https://', 'http://');
  }

  Future<Map<String, dynamic>?> _probeHydraInfo(String base) async {
    try {
      final resp = await call('GET', '$base/api/hydra-info', headers: clientHeaders, timeout: const Duration(seconds: 3));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (!json.containsKey('remoteApiVersion')) return null;
      return json;
    } catch (e) {
      if (base.startsWith('https://')) _httpsProbeError = e;
      return null;
    }
  }

  Future<List<ClaimInfo>> getClaims() async =>
      ClaimInfo.listFromJson(await getJson('/api/claims', const Duration(seconds: 5)));

  Future<RobotRead?> getRobot(dynamic robotId) async {
    try {
      final answer = await getJson('/api/robot/$robotId', const Duration(seconds: 5));
      final robot = answer['robot'];
      if (robot is! Map<String, dynamic>) return null;
      return RobotRead(robot, revisionOf(answer));
    } on HydraApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  /// The audit lines of the server ([query] is the part after `/api/audit`).
  Future<String> getAuditBody(String query) => getText('/api/audit$query', const Duration(seconds: 10));

  Future<String> getConnectionClientsBody() => getText('/api/connections/clients', const Duration(seconds: 10));

  Future<String> getConnectionEventsBody(int limit) =>
      getText('/api/connections/events?limit=${limit.clamp(1, 500)}', const Duration(seconds: 10));

  Future<String> getServerConfigBody() => getText('/api/admin/server-config', const Duration(seconds: 10));

  Future<String> putServerConfigBody(Map<String, dynamic> body) async {
    final resp = await call('PUT', '$baseUrl/api/admin/server-config',
        headers: {'Content-Type': 'application/json', ...clientHeaders, ...authHeaders},
        body: jsonEncode(body),
        timeout: const Duration(seconds: 10));
    throwForStatus(resp);
    return resp.body;
  }

  Future<RobotSafety?> getRobotSafety(dynamic robotId) async {
    try {
      return RobotSafety.fromJson(await getJson('/api/safety-limits?robotId=$robotId', const Duration(seconds: 5)));
    } on HydraApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  /// The arm state of the URTC tools as the server relays it (read only).
  Future<Map<String, dynamic>> getToolArms() => getJson('/api/tool-arms', const Duration(seconds: 8));

  Future<Map<String, dynamic>> getEcosystemStatus() => getJson('/api/ecosystem/status', const Duration(seconds: 8));

  Future<Map<String, dynamic>> postEcosystemService(String unit, String action) => postJson(
      '/api/ecosystem/service/${Uri.encodeComponent(unit)}/${Uri.encodeComponent(action)}', const Duration(seconds: 20));

  Future<Map<String, dynamic>> postAdminRestart() => postJson('/api/admin/restart', const Duration(seconds: 8));

  Future<Map<String, dynamic>> postSystemReboot() => postJson('/api/system/reboot', const Duration(seconds: 8));
}
