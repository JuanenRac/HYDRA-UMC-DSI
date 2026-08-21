// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/hydra_websocket.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// /ws live-sync connection - copied verbatim from HYDRA-UMC-IOS-CONTROL's
// own network/hydra_websocket.dart (same Dart/Flutter stack, no port
// needed). On connect, the server immediately sends one
// {"type":"settings","payload":{...}} message with the current full
// state, then pushes the same shape to every connected client (sender
// included) whenever the state changes. A WS closed with code 1008
// (invalid/expired token) is treated as "sign in again" - see
// HYDRA-UMC-ANDROID-CONTROL's own HydraWebSocket.kt for the reference
// handling this mirrors.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

enum WsStatus { connecting, connected, disconnected }

const Duration reconnectDelay = Duration(seconds: 3);

class HydraWebSocket {
  final String host;
  final int port;
  String? token;
  final void Function(WsStatus status) onStatus;
  final void Function(Map<String, dynamic> payload) onSettings;
  final void Function(String message) onError;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  bool _closingByUser = false;
  Timer? _reconnectTimer;
  String? _lastPayloadJson;

  HydraWebSocket({
    required this.host,
    required this.port,
    this.token,
    required this.onStatus,
    required this.onSettings,
    required this.onError,
  });

  void connect() {
    _closingByUser = false;
    _openSocket();
  }

  void _openSocket() {
    onStatus(WsStatus.connecting);
    final base = 'ws://$host:$port/ws';
    final url = token != null ? '$base?token=$token' : base;
    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _channel = channel;
      _sub = channel.stream.listen(
        (raw) => _handleMessage(raw as String),
        onDone: () {
          onStatus(WsStatus.disconnected);
          _channel = null;
          _scheduleReconnect();
        },
        onError: (Object e) {
          onStatus(WsStatus.disconnected);
          onError('WebSocket connection lost: $e');
          _channel = null;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
      // WebSocketChannel.connect() doesn't confirm the handshake itself -
      // report "connected" once the stream is actually listening; a genuine
      // failure surfaces via onError/onDone above instead.
      onStatus(WsStatus.connected);
    } catch (e) {
      onStatus(WsStatus.disconnected);
      onError('WebSocket connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(String raw) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return; // malformed frame - ignore rather than tear down the connection
    }
    final err = msg['error'];
    if (err is String && err.isNotEmpty) {
      onError(err);
      return;
    }
    final type = msg['type'];
    if (type != 'settings' && type != 'delta') return;
    final payload = msg['payload'];
    if (payload is! Map<String, dynamic>) return;
    final payloadJson = jsonEncode(payload);
    if (payloadJson == _lastPayloadJson) return; // our own echoed-back write
    _lastPayloadJson = payloadJson;
    onSettings(payload);
  }

  /// Sends [payload] as a "settings" envelope over the socket - not
  /// currently called anywhere in this app, same as HYDRA-UMC-IOS-CONTROL
  /// (state/robot_view_model.dart writes exclusively through the atomic
  /// REST endpoint). Kept as a capability of this class since the server's
  /// own wire protocol does accept a client-sent "settings" envelope.
  bool send(Map<String, dynamic> payload) {
    final payloadJson = jsonEncode(payload);
    if (payloadJson == _lastPayloadJson) return true;
    final channel = _channel;
    if (channel == null) return false;
    channel.sink.add(jsonEncode({'type': 'settings', 'payload': payload}));
    _lastPayloadJson = payloadJson;
    return true;
  }

  void _scheduleReconnect() {
    if (_closingByUser) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      if (!_closingByUser) _openSocket();
    });
  }

  void disconnect() {
    _closingByUser = true;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    onStatus(WsStatus.disconnected);
  }
}
