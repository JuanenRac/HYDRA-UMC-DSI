// =============================================================================
// HYDRA-UMC DSI (Flutter) - models/server_info.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
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
  });

  String get baseUrl => 'http://$host:$port';

  String wsUrl(String? token) {
    final base = 'ws://$host:$port/ws';
    return token != null ? '$base?token=$token' : base;
  }

  String get displayName => nickname.isNotEmpty ? nickname : (hostname.isNotEmpty ? hostname : host);

  factory ServerInfo.fromHydraInfo(String host, int port, Map<String, dynamic> payload) {
    return ServerInfo(
      host: host,
      port: port,
      product: (payload['product'] ?? '') as String,
      remoteApiVersion: (payload['remoteApiVersion'] ?? 0) as int,
      appVersion: (payload['appVersion'] ?? '') as String,
      hostname: (payload['hostname'] ?? '') as String,
      controllerCount: (payload['controllerCount'] ?? 0) as int,
      robotCount: (payload['robotCount'] ?? 0) as int,
      uptimeSeconds: (payload['uptimeSeconds'] ?? 0) as int,
    );
  }

  ServerInfo copyWith({String? nickname, String? username, String? password}) {
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
    );
  }

  String get connectionId => '$host:$port';
}
