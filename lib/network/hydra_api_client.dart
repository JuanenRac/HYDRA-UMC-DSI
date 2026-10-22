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

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class HydraApiException implements Exception {
  final String message;
  /// HTTP status of the server's answer; null when there was no answer.
  final int? statusCode;
  /// The stable `code` field of the server's JSON error body
  /// (TOKEN_EXPIRED, TOKEN_INVALID, SESSION_REVOKED, ...), when it sent one.
  final String? code;
  /// The server's own `error` text, when it sent one.
  final String? serverMessage;
  HydraApiException(this.message, {this.statusCode, this.code, this.serverMessage});

  /// A 401, or a 403 that says the token expired or is invalid: a refresh or
  /// a new login can cure it. (A plain 403 is a missing role permission.)
  bool get isSessionProblem =>
      statusCode == 401 || (statusCode == 403 && (code == 'TOKEN_EXPIRED' || code == 'TOKEN_INVALID'));

  /// A 403 about the account's role, not about the session.
  bool get isPermissionDenied => statusCode == 403 && !isSessionProblem;

  /// The robot is reserved by another account (the server's 409).
  bool get isReservedByAnother => statusCode == 409;

  /// The server refused the command itself (unknown command, a value it cannot take).
  bool get isRejectedCommand => statusCode == 400;

  /// Over the server's rate limit (429).
  bool get isRateLimited => statusCode == 429;

  /// The server does not have the route (an older server).
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

class HydraApiClient {
  // Starts as plain HTTP (or HTTPS when [useTls] says the server was already
  // seen on it) - getHydraInfo()/login() switch it to HTTPS the first time a
  // plain-HTTP probe gets no answer at all and an HTTPS one does (the server's
  // optional TLS_CERT_PATH/TLS_KEY_PATH switches it to HTTPS/WSS-only, with no
  // HTTP fallback of its own). It never goes back to http by itself.
  String baseUrl;
  bool get usesTls => baseUrl.startsWith('https://');
  String? authToken;
  final http.Client _client;

  /// [useTls] starts the client on https:// - for a server that was already
  /// seen answering TLS. It never goes back to plain http by itself: a server
  /// that once spoke TLS and now answers over http is not trusted with a
  /// password or a token in the clear.
  HydraApiClient(String host, int port, {http.Client? client, bool useTls = false})
      : baseUrl = '${useTls ? 'https' : 'http'}://$host:$port',
        _client = client ?? http.Client();

  Map<String, String> get _authHeaders =>
      authToken != null ? {'Authorization': 'Bearer $authToken'} : const {};

  /// Headers for requests made outside this class (the live camera stream):
  /// the client identity and the bearer token. A server started with
  /// HYDRA_UMC_CAMERA_AUTH=required refuses the picture without a signed-in
  /// client; the token goes in a header, never in the address.
  Map<String, String> get mediaHeaders => {..._clientHeaders, ..._authHeaders};

  /// Self-identifies this client to server.ts's own per-client remote-access
  /// toggles (Config > Remote Access): HYDRA-UMC-SERVER's serverPolicy.ts
  /// recognizes "suite", "android", "ios", "watch" and "dsi", so this app's
  /// access can be switched off on its own. A request with no header, or an
  /// unrecognized value, is never gated.
  static const Map<String, String> _clientHeaders = {'X-Hydra-Client': 'dsi'};

  Future<Map<String, dynamic>> login(String username, String password) async {
    // A direct "add server, log in" flow never gets a chance to learn the
    // scheme first: resolve it here, before spending the login on a scheme a
    // TLS-only server will not answer.
    await _resolveScheme();
    final resp = await _client
        .post(
          Uri.parse('$baseUrl/api/login'),
          headers: {'Content-Type': 'application/json', ..._clientHeaders},
          body: jsonEncode({'username': username, 'password': password}),
        )
        // Longer than the other calls: login is the first request against a
        // host, so it also pays for DNS and connection set-up.
        .timeout(const Duration(seconds: 15));
    return _expectJson(resp);
  }

  /// exchanges a still-valid refresh token (returned alongside the
  /// access token by login() above, see HYDRA-UMC-SERVER's own
  /// REMOTE_API.md section 2a / refresh_tokens.ts) for a fresh access
  /// token, no password involved - this app never stores one (see
  /// auth_prefs.dart's own header comment on why only the token itself,
  /// never a password, lives in secure storage here). Throws
  /// [HydraApiException] on a 401 (session genuinely revoked, or the
  /// refresh token itself expired/unknown) - the caller's job, not this
  /// method's, to decide that means falling back to a real logout.
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final resp = await _client
        .post(
          Uri.parse('$baseUrl/api/refresh'),
          headers: {'Content-Type': 'application/json', ..._clientHeaders},
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(const Duration(seconds: 5));
    return _expectJson(resp);
  }

  /// revokes a refresh token server-side on a real, intentional
  /// logout - best-effort by design (the caller clears its own local
  /// state regardless of whether this succeeds; see robot_view_model.dart's
  /// own logout()). Never throws - a network error here must not block a
  /// local sign-out the user is actively waiting on.
  Future<void> logoutRemote(String refreshToken) async {
    try {
      await _client
          .post(
            Uri.parse('$baseUrl/api/logout'),
            headers: {'Content-Type': 'application/json', ..._clientHeaders},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best-effort - see this method's own doc comment.
    }
  }

  Future<Map<String, dynamic>?> getHydraInfo() async {
    final direct = await _probeHydraInfo(baseUrl);
    if (direct != null) return direct;
    // Only plain http that gets no answer is retried over https, and the
    // answer is remembered in baseUrl for every later call.
    if (baseUrl.startsWith('http://')) {
      final httpsUrl = baseUrl.replaceFirst('http://', 'https://');
      final viaHttps = await _probeHydraInfo(httpsUrl);
      if (viaHttps != null) {
        baseUrl = httpsUrl;
        return viaHttps;
      }
    }
    return null;
  }

  // Same scheme resolution getHydraInfo() does, for login() and getSettings():
  // a harmless GET /api/hydra-info (it needs no credentials), only to learn the
  // scheme this host answers on.
  Future<void> _resolveScheme() async {
    if (baseUrl.startsWith('https://')) return;
    if (await _probeHydraInfo(baseUrl) != null) return;
    final httpsUrl = baseUrl.replaceFirst('http://', 'https://');
    if (await _probeHydraInfo(httpsUrl) != null) baseUrl = httpsUrl;
  }

  Future<Map<String, dynamic>?> _probeHydraInfo(String base) async {
    try {
      final resp = await _client
          .get(Uri.parse('$base/api/hydra-info'), headers: _clientHeaders)
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
    await _resolveScheme(); // a restored session never ran login(), so the scheme is learned here
    final resp = await _client
        .get(Uri.parse('$baseUrl/api/settings'), headers: {..._clientHeaders, ..._authHeaders})
        .timeout(const Duration(seconds: 5));
    return _expectJson(resp);
  }

  /// [timeout] is 5 s for an ordinary command; a STOP uses a shorter one so a
  /// stuck connection is given up and retried quickly.
  Future<Map<String, dynamic>> postRobotCommand(
    dynamic robotId,
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final resp = await _client
        .post(
          Uri.parse('$baseUrl/api/robot/$robotId/command'),
          headers: {'Content-Type': 'application/json', ..._clientHeaders, ..._authHeaders},
          body: jsonEncode(payload),
        )
        .timeout(timeout);
    return _expectJson(resp);
  }

  /// POST /api/stop-all: the global stop. No body, no confirmation; any
  /// signed-in account may call it and a reservation held by another account
  /// never blocks it. Answers `{success, stoppedCount, failedCount, persisted,
  /// robots: [...]}`. A short [timeout] so a stuck connection is given up and
  /// the caller can try again at once. A server that does not have the route
  /// answers 404 and one over its rate limit answers 429 (both are
  /// [HydraApiException]s the caller turns into the per-robot stop).
  Future<Map<String, dynamic>> postStopAll({Duration timeout = const Duration(seconds: 2)}) async {
    final resp = await _client
        .post(Uri.parse('$baseUrl/api/stop-all'), headers: {..._clientHeaders, ..._authHeaders})
        .timeout(timeout);
    return _expectJson(resp);
  }

  Future<Map<String, dynamic>> getSystemMetrics() async {
    final resp = await _client
        .get(Uri.parse('$baseUrl/api/system/metrics'), headers: {..._clientHeaders, ..._authHeaders})
        .timeout(const Duration(seconds: 5));
    return _expectJson(resp);
  }

  Map<String, dynamic> _expectJson(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      // The server's error body carries a reason (`error`) and, for the auth
      // middleware, a stable `code`: keep both so the caller can tell an
      // expired session from a missing permission, an unknown command (400)
      // or a robot reserved by someone else (409).
      String? code;
      String? serverMessage;
      try {
        final body = jsonDecode(resp.body);
        if (body is Map) {
          if (body['code'] is String) code = body['code'] as String;
          if (body['error'] is String) serverMessage = body['error'] as String;
        }
      } catch (_) {
        // Not JSON (a proxy's HTML page, say): the status alone has to do.
      }
      throw HydraApiException(
        'HTTP ${resp.statusCode} from ${resp.request?.url.path}',
        statusCode: resp.statusCode,
        code: code,
        serverMessage: serverMessage,
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(resp.body);
    } on FormatException catch (e) {
      throw HydraApiException('Response is not valid JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw HydraApiException('Response is not a JSON object');
    }
    return decoded;
  }

  void close() => _client.close();
}
