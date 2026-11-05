// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/hydra_websocket.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The /ws live-sync client lives in the shared package of the SDK (clients/dart_app_common). This class keeps the
// API of the app: the errors come back as [HydraError] (they are shown in the language of the person) and the
// sockets open through the TLS choices of this app (network/tls_settings.dart).
// =============================================================================

import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' as common;

import '../state/hydra_error.dart';
import 'tls_settings.dart';

export 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show WsStatus, reconnectDelay, maxReconnectDelay, reconnectBackoff, pingInterval, wsClosePolicyViolation, wsTokenSubprotocol;

class HydraWebSocket {
  final String host;
  final int port;

  /// Set from the same HydraApiClient.usesTls that already probed this server.
  final bool useTls;
  final void Function(common.WsStatus status) onStatus;
  final void Function(Map<String, dynamic> payload) onSettings;
  final void Function(HydraError error) onError;

  /// A targeted delta (only sent once this connection declares schema 2). Optional: without it every delta is folded
  /// into [onSettings] as a full-tree replace.
  final void Function(Map<String, dynamic> delta)? onDelta;

  /// The `claims` message, pushed only to a connection that asked for remoteApiVersion=2.
  final void Function(Map<String, dynamic> message)? onClaims;

  late final common.HydraWebSocket _inner;

  HydraWebSocket({
    required this.host,
    required this.port,
    this.useTls = false,
    String? token,
    required this.onStatus,
    required this.onSettings,
    required this.onError,
    this.onDelta,
    this.onClaims,
  }) {
    _inner = common.HydraWebSocket(
      host: host,
      port: port,
      useTls: useTls,
      token: token,
      onStatus: onStatus,
      onSettings: onSettings,
      onError: (e) => onError(HydraError(_kindOf(e.kind), e.params)),
      onDelta: onDelta,
      onClaims: onClaims,
      httpClientFactory: createHttpClient,
    );
  }

  static HydraErrorKind _kindOf(common.WsErrorKind kind) => switch (kind) {
        common.WsErrorKind.authRejected => HydraErrorKind.wsAuthRejected,
        common.WsErrorKind.connectionLost => HydraErrorKind.wsConnectionLost,
        common.WsErrorKind.connectFailed => HydraErrorKind.wsConnectFailed,
        common.WsErrorKind.serverMessage => HydraErrorKind.serverMessage,
      };

  String? get token => _inner.token;
  set token(String? value) => _inner.token = value;

  /// The address the socket opens (see the shared class); the token is never part of it.
  static Uri buildConnectionUri({
    required String host,
    required int port,
    String? token,
    bool useTls = false,
  }) =>
      common.HydraWebSocket.buildConnectionUri(host: host, port: port, token: token, useTls: useTls);

  void connect() => _inner.connect();

  /// Sends a "settings" envelope over the open socket. Returns false if no socket is open.
  bool send(Map<String, dynamic> payload) => _inner.send(payload);

  void disconnect() => _inner.disconnect();
}
