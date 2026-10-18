// =============================================================================
// HYDRA-UMC DSI (Flutter) - models/server_info.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// One entry in the discovery/connection list - see HYDRA-UMC-STUDIO's own
// docs/REMOTE_API.md section 1 (GET /api/hydra-info) for the wire shape
// this is built from. Copied verbatim from HYDRA-UMC-IOS-CONTROL's own
// models/server_info.dart (same Dart/Flutter stack, no port needed) so
// this client agrees field-for-field with the other 4 clients
// (SUITE/Android/iOS/the browser UI itself) on what a "server" is.
// =============================================================================

class ServerInfo {
  final String host;
  final int port;
  final String product;
  final int remoteApiVersion;
  final String appVersion;
  final String hostname;
  final int controllerCount;
  final int robotCount;
  final int uptimeSeconds;
  final String nickname; // user-assigned label, not from the server

  // Credentials are always supplied by the operator. Production servers never
  // create a source-known administrator account, so discovery must not turn
  // into an implicit admin/admin login attempt.
  final String username;
  final String password;

  /// True once the server was seen answering only over HTTPS (it was started
  /// with TLS_CERT_PATH/TLS_KEY_PATH): every address built from this is
  /// https/wss.
  final bool useTls;

  const ServerInfo({
    required this.host,
    this.port = 3000,
    this.product = '',
    this.remoteApiVersion = 0,
    this.appVersion = '',
    this.hostname = '',
    this.controllerCount = 0,
    this.robotCount = 0,
    this.uptimeSeconds = 0,
    this.nickname = '',
    this.username = '',
    this.password = '',
    this.useTls = false,
  });

  String get baseUrl => '${useTls ? 'https' : 'http'}://$host:$port';

  String wsUrl(String? token) {
    final base = '${useTls ? 'wss' : 'ws'}://$host:$port/ws';
    return token != null ? '$base?token=$token' : base;
  }

  String get displayName => nickname.isNotEmpty ? nickname : (hostname.isNotEmpty ? hostname : host);

  factory ServerInfo.fromHydraInfo(String host, int port, Map<String, dynamic> payload, {bool useTls = false}) {
    return ServerInfo(
      host: host,
      port: port,
      product: _asString(payload['product']),
      remoteApiVersion: _asInt(payload['remoteApiVersion']),
      appVersion: _asString(payload['appVersion']),
      hostname: _asString(payload['hostname']),
      controllerCount: _asInt(payload['controllerCount']),
      robotCount: _asInt(payload['robotCount']),
      uptimeSeconds: _asInt(payload['uptimeSeconds']),
      useTls: useTls,
    );
  }

  // A device that answers on this port with something else must not break the
  // scan with a cast: a number reads as itself, anything else as 0.
  static int _asInt(dynamic v) => v is num && v.isFinite ? v.toInt() : 0;

  static String _asString(dynamic v) => v is String ? v : '';

  ServerInfo copyWith({String? nickname, String? username, String? password, bool? useTls}) {
    return ServerInfo(
      host: host,
      port: port,
      product: product,
      remoteApiVersion: remoteApiVersion,
      appVersion: appVersion,
      hostname: hostname,
      controllerCount: controllerCount,
      robotCount: robotCount,
      uptimeSeconds: uptimeSeconds,
      nickname: nickname ?? this.nickname,
      username: username ?? this.username,
      password: password ?? this.password,
      useTls: useTls ?? this.useTls,
    );
  }

  String get connectionId => '$host:$port';
}
