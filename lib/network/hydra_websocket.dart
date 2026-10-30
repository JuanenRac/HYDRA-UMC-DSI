// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/hydra_websocket.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// /ws live-sync connection. On connect, the server immediately sends one
// {"type":"settings","payload":{...}} message with the current full
// state, then pushes the same shape to every connected client (sender
// included) whenever the state changes, from either a POST /api/settings,
// a POST /api/robot/:id/command (broadcast as "delta" - SAME payload
// shape, only the label differs), or a client sending the "settings"
// envelope back over its own socket.
//
// The server's /ws upgrade requires a token, which travels as the
// "hydra.bearer" subprotocol (Sec-WebSocket-Protocol: hydra.bearer, <token>)
// so that it stays out of the address that proxies and logs record. The
// server refuses /ws?token= by default, so there is no second form: a server
// that does not answer the subprotocol is a failed connection, reported as
// such, and the token never goes into the address.
//
// When the token is bad the server first sends one {"error":"Access denied
// ..."} frame and, about 100 ms later, closes with code 1008. Both reach the
// caller as errors, but they describe ONE event: wsAuthRejected is reported
// only for the close, and the frame is passed on as a plain serverMessage so
// the caller can treat the pair as a single authentication failure.
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../state/hydra_error.dart';
import 'tls_settings.dart';

enum WsStatus { connecting, connected, disconnected }

/// First wait before a reconnect attempt; it doubles after every attempt that
/// fails to open (up to [maxReconnectDelay]) and starts again from here as
/// soon as one opens.
const Duration reconnectDelay = Duration(seconds: 3);
const Duration maxReconnectDelay = Duration(seconds: 30);

/// How long to wait before reconnect attempt number [failedAttempts] + 1: the
/// base delay, doubled after every attempt that failed to open, up to
/// [maxReconnectDelay].
Duration reconnectBackoff(int failedAttempts) {
  // 2^n overflows a 64-bit integer for n >= 62 and the wait collapsed to zero
  // after about half an hour of failed attempts, so the doubling stops well
  // before the ceiling would be hit anyway.
  final doublings = min(max(0, failedAttempts - 1), 10);
  final backoff = reconnectDelay * (1 << doublings);
  return backoff > maxReconnectDelay ? maxReconnectDelay : backoff;
}

/// The client pings this often, so a link that died without a close (Wi-Fi
/// dropped, no FIN) is noticed instead of waiting for the OS to give up.
const Duration pingInterval = Duration(seconds: 20);

/// RFC 6455 close code the server sends for a missing/invalid/expired
/// auth token (server.ts's own /ws upgrade check) - same constant name
/// as HYDRA-UMC-ANDROID-CONTROL's own HydraWebSocket.kt.
const int wsClosePolicyViolation = 1008;

/// The subprotocol name the server reads a token from.
const String wsTokenSubprotocol = 'hydra.bearer';

final RegExp _subprotocolToken = RegExp(r"^[A-Za-z0-9!#$%&'*+\-.^_`|~]+$");

class HydraWebSocket {
  final String host;
  final int port;
  /// See buildConnectionUri's own doc comment - set from the same
  /// HydraApiClient.usesTls that already probed this server.
  final bool useTls;
  String? token;
  final void Function(WsStatus status) onStatus;
  final void Function(Map<String, dynamic> payload) onSettings;
  final void Function(HydraError error) onError;
  /// A real targeted delta (server.ts's own broadcastRobotDelta(), sent
  /// only once this connection declares schema 2 via ?remoteApiVersion=2
  /// below). Optional: a caller that doesn't pass this still gets every
  /// delta folded into onSettings as a full-tree replace.
  final void Function(Map<String, dynamic> delta)? onDelta;

  /// The `claims` message (who reserves which robot, pushed when a reservation, an arming or a stop changes, only to
  /// a connection that asked for remoteApiVersion=2): the same list as GET /api/claims, so the app need not poll it.
  final void Function(Map<String, dynamic> message)? onClaims;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  bool _closingByUser = false;
  Timer? _reconnectTimer;
  String? _lastPayloadJson;
  // Identifies the connection attempt in progress: callbacks of an older
  // attempt (superseded by a reconnect or a disconnect) are ignored.
  int _generation = 0;
  // Consecutive attempts that never opened - drives the reconnect back-off.
  int _failedAttempts = 0;
  final Random _random = Random();

  HydraWebSocket({
    required this.host,
    required this.port,
    this.useTls = false,
    this.token,
    required this.onStatus,
    required this.onSettings,
    required this.onError,
    this.onDelta,
    this.onClaims,
  });

  void connect() {
    _closingByUser = false;
    unawaited(_openSocket());
  }

  /// Builds the endpoint with Uri rather than string interpolation. Tokens
  /// are opaque bearer credentials and may contain reserved URL characters;
  /// queryParameters guarantees they remain one token value instead of
  /// accidentally changing the request query.
  ///
  /// The token is never part of the address: it travels as the
  /// "hydra.bearer" subprotocol.
  static Uri buildConnectionUri({
    required String host,
    required int port,
    String? token,
    // True to open wss:// instead of ws:// - set this from the same
    // HydraApiClient.usesTls that already probed this server (see that
    // class's own getHydraInfo()), never guessed independently: a plain
    // WebSocket has no HTTP response of its own to detect TLS-only from.
    bool useTls = false,
  }) => Uri(
    scheme: useTls ? 'wss' : 'ws',
    host: host,
    port: port,
    path: '/ws',
    queryParameters: token == null ? null : {'remoteApiVersion': '2'},
  );

  Future<void> _openSocket() async {
    onStatus(WsStatus.connecting);
    final generation = ++_generation;
    final bearer = token;
    if (bearer != null && !_subprotocolToken.hasMatch(bearer)) {
      // A token with characters a subprotocol cannot carry is not a token this
      // server issued; it must not be pasted into the address instead.
      onStatus(WsStatus.disconnected);
      onError(const HydraError(HydraErrorKind.wsAuthRejected));
      return;
    }
    // remoteApiVersion=2 declares this connection understands a real
    // targeted delta; a server that doesn't recognize it just keeps sending
    // the full tree under "delta" like before.
    final url = buildConnectionUri(
      host: host,
      port: port,
      token: token,
      useTls: useTls,
    );
    var opened = false;
    try {
      final channel = IOWebSocketChannel.connect(
        url,
        protocols: bearer != null ? [wsTokenSubprotocol, bearer] : null,
        pingInterval: pingInterval,
        customClient: createHttpClient(),
      );
      _channel = channel;
      _sub = channel.stream.listen(
        (raw) {
          if (generation != _generation) return;
          // A binary frame is not part of this protocol: ignore it rather
          // than let the cast throw inside the listener.
          if (raw is String) _handleMessage(raw);
        },
        onDone: () {
          if (generation != _generation) return;
          onStatus(WsStatus.disconnected);
          if (channel.closeCode == wsClosePolicyViolation) {
            // The token is expired or invalid. Retrying the exact same token
            // forever only spins against a server that will never accept it;
            // report it once and stop. The caller renews the session and
            // opens a new connection.
            _closingByUser = true;
            _channel = null;
            onError(const HydraError(HydraErrorKind.wsAuthRejected));
            return;
          }
          _channel = null;
          _scheduleReconnect(wasOpen: opened);
        },
        onError: (Object e) {
          if (generation != _generation) return;
          // A refused handshake is handled by the catch below (it also gets
          // here as a stream error); a connection that opened and then broke
          // is reported here.
          if (!opened) return;
          onStatus(WsStatus.disconnected);
          onError(HydraError(HydraErrorKind.wsConnectionLost, {'error': '$e'}));
          _channel = null;
          _scheduleReconnect(wasOpen: true);
        },
        cancelOnError: true,
      );
      // channel.ready completes once the HTTP upgrade succeeded. Without
      // waiting for it, "connected" was reported for a socket the server
      // rejected before the handshake finished.
      await channel.ready;
      if (_closingByUser || generation != _generation) return;
      opened = true;
      _failedAttempts = 0;
      onStatus(WsStatus.connected);
    } catch (e) {
      if (generation != _generation || _closingByUser) return;
      onStatus(WsStatus.disconnected);
      onError(HydraError(HydraErrorKind.wsConnectFailed, {'error': '$e'}));
      _channel = null;
      _scheduleReconnect(wasOpen: false);
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
      onError(HydraError(HydraErrorKind.serverMessage, {'message': err}));
      return;
    }
    final type = msg['type'];
    if (type == 'claims') {
      onClaims?.call(msg);
      return;
    }
    if (type == 'delta' && msg['schema'] == 2 && msg.containsKey('robotId')) {
      final handler = onDelta;
      if (handler != null) {
        handler(msg);
        return;
      }
    }
    if (type != 'settings' && type != 'delta') return;
    final payload = msg['payload'];
    if (payload is! Map<String, dynamic>) return;
    // Every full snapshot is applied: this app never writes over the socket,
    // so there is no echo of its own to filter out, and filtering "identical"
    // snapshots made a state changed by deltas in between look current when
    // another client put the previous full state back.
    onSettings(payload);
  }

  /// Sends a "settings" envelope over the open socket. Returns false if no
  /// socket is open.
  bool send(Map<String, dynamic> payload) {
    final payloadJson = jsonEncode(payload);
    if (payloadJson == _lastPayloadJson) return true;
    final channel = _channel;
    if (channel == null) return false;
    channel.sink.add(jsonEncode({'type': 'settings', 'payload': payload}));
    _lastPayloadJson = payloadJson;
    return true;
  }

  void _scheduleReconnect({required bool wasOpen}) {
    if (_closingByUser) return;
    if (!wasOpen) _failedAttempts++;
    final capped = reconnectBackoff(_failedAttempts);
    // A little jitter, so many phones do not reconnect in the same instant
    // after the server restarts.
    final jitter = Duration(milliseconds: _random.nextInt(500));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(capped + jitter, () {
      if (!_closingByUser) unawaited(_openSocket());
    });
  }

  void disconnect() {
    _closingByUser = true;
    _generation++;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    onStatus(WsStatus.disconnected);
  }
}
