// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/hydra_api_client.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Talks the exact contract in HYDRA-UMC-STUDIO/docs/REMOTE_API.md - ported
// from HYDRA-UMC-IOS-CONTROL's own network/hydra_api_client.dart (same
// Dart/Flutter stack, direct reuse) with one deliberate change: the
// X-Hydra-Client header below identifies this client as "dsi" rather than
// "ios". See this file's own _clientHeaders doc comment for what that does
// and doesn't do server-side today.
//   - POST /api/login               - obtain a bearer token.
//   - GET  /api/hydra-info          - discovery/identity.
//   - GET  /api/settings            - full current state, no auth needed.
//   - POST /api/settings            - overwrite the whole state, ADMIN only.
//   - POST /api/robot/:id/command   - atomic per-robot command, either role -
//     the PRIMARY way this app writes (see state/robot_view_model.dart).
//   - GET  /api/system/metrics      - host CPU/memory/temp/uptime/network.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class HydraApiException implements Exception {
  final String message;
  HydraApiException(this.message);
  @override
  String toString() => message;
}

class HydraApiClient {
  final String baseUrl;
  String? authToken;
  final http.Client _client;

  HydraApiClient(String host, int port, {http.Client? client})
      : baseUrl = 'http://$host:$port',
        _client = client ?? http.Client();

  Map<String, String> get _authHeaders =>
      authToken != null ? {'Authorization': 'Bearer $authToken'} : const {};

  /// Self-identifies this client to server.ts's own per-client remote-access
  /// toggles (Config > Remote Access). REMOTE_API.md section 1 documents
  /// only "suite", "android", "ios" as recognized values as of this writing -
  /// "dsi" is a genuinely new client the server doesn't know how to gate yet.
  /// Per that same section: "A request with no X-Hydra-Client header, or an
  /// unrecognized value, is never gated here" - so this app's discovery
  /// requests simply pass through ungated (same as today's behavior with no
  /// header at all) until HYDRA-UMC-STUDIO's own SystemSettings.remoteAccess
  /// type and Config > Remote Access UI grow a 4th "dsi" toggle. Tracked in
  /// SONNET/HYDRA-UMC-DSI/mejoras_futuras.txt - out of scope for this app's
  /// own repo since it requires a change on the server side.
  static const Map<String, String> _clientHeaders = {'X-Hydra-Client': 'dsi'};

  Future<Map<String, dynamic>> login(String username, String password) async {
    final resp = await _client
        .post(
          Uri.parse('$baseUrl/api/login'),
          headers: {'Content-Type': 'application/json', ..._clientHeaders},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 5));
    return _expectJson(resp);
  }

  Future<Map<String, dynamic>?> getHydraInfo() async {
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/api/hydra-info'), headers: _clientHeaders)
          .timeout(const Duration(seconds: 3));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (!json.containsKey('remoteApiVersion')) return null;
      return json;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getSettings() async {
    final resp = await _client
        .get(Uri.parse('$baseUrl/api/settings'), headers: {..._clientHeaders, ..._authHeaders})
        .timeout(const Duration(seconds: 5));
    return _expectJson(resp);
  }

  Future<void> postSettings(Map<String, dynamic> payload) async {
    final resp = await _client
        .post(
          Uri.parse('$baseUrl/api/settings'),
          headers: {'Content-Type': 'application/json', ..._clientHeaders, ..._authHeaders},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 5));
    _expectJson(resp);
  }

  Future<Map<String, dynamic>> postRobotCommand(dynamic robotId, Map<String, dynamic> payload) async {
    final resp = await _client
        .post(
          Uri.parse('$baseUrl/api/robot/$robotId/command'),
          headers: {'Content-Type': 'application/json', ..._clientHeaders, ..._authHeaders},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 5));
    return _expectJson(resp);
  }

  Future<Map<String, dynamic>> getSystemMetrics() async {
    final resp = await _client
        .get(Uri.parse('$baseUrl/api/system/metrics'), headers: _clientHeaders)
        .timeout(const Duration(seconds: 5));
    return _expectJson(resp);
  }

  Map<String, dynamic> _expectJson(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HydraApiException('HTTP ${resp.statusCode} from ${resp.request?.url.path}');
    }
    try {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw HydraApiException('Response is not valid JSON: ${e.message}');
    }
  }

  void close() => _client.close();
}
