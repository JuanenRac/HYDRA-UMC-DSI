// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/hydra_websocket_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Found while auditing the code:
// network/hydra_websocket.dart (175 lines, real Timer-based reconnection)
// had no dedicated test - this app's other tests (uptime formatting,
// localization, the view model) never touch reconnection state.
//
// Real end-to-end tests against a real local dart:io WebSocket server
// (HttpServer + WebSocketTransformer), not a mock: WebSocketChannel.connect()
// - what HydraWebSocket calls internally - is a real dart:io socket under
// the hood on this platform, so a real local server is what actually
// exercises the real onDone/onError/_scheduleReconnect logic, not just the
// message-parsing half a fake transport would leave untested.
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/network/hydra_websocket.dart';
import 'package:hydra_umc_dsi/state/hydra_error.dart';

/// A tiny, real local WebSocket server - accepts every real upgrade
/// request and reports each real connected socket on [onConnect], so a
/// test can send real frames to it or close it to force a real drop.
class _FakeHydraServer {
  final HttpServer server;
  final _onConnect = StreamController<WebSocket>.broadcast();

  _FakeHydraServer(this.server) {
    server.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _onConnect.add(socket);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    });
  }

  static Future<_FakeHydraServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _FakeHydraServer(server);
  }

  int get port => server.port;
  Stream<WebSocket> get onConnect => _onConnect.stream;

  Future<void> close() async {
    await _onConnect.close();
    await server.close(force: true);
  }
}

void main() {
  group('HydraWebSocket - real connect/reconnect against a real local server', () {
    late _FakeHydraServer fakeServer;

    setUp(() async {
      fakeServer = await _FakeHydraServer.start();
    });

    tearDown(() async {
      await fakeServer.close();
    });

    test('reports WsStatus.connected only after the real handshake completes', () async {
      final statuses = <WsStatus>[];
      final ws = HydraWebSocket(
        host: '127.0.0.1',
        port: fakeServer.port,
        onStatus: statuses.add,
        onSettings: (_) {},
        onError: (_) {},
      );
      final connected = fakeServer.onConnect.first;
      ws.connect();
      await connected;
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(statuses.first, WsStatus.connecting);
      expect(statuses, contains(WsStatus.connected));
      ws.disconnect();
    });

    test('delivers a real settings payload the server sends', () async {
      Map<String, dynamic>? received;
      final ws = HydraWebSocket(
        host: '127.0.0.1',
        port: fakeServer.port,
        onStatus: (_) {},
        onSettings: (payload) => received = payload,
        onError: (_) {},
      );
      final connected = fakeServer.onConnect.first;
      ws.connect();
      final serverSocket = await connected;
      serverSocket.add(jsonEncode({
        'type': 'settings',
        'payload': {'hello': 'world'},
      }));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(received, {'hello': 'world'});
      ws.disconnect();
    });

    test(
      'reconnects on its own after a real connection drop, then delivers again',
      () async {
        final statuses = <WsStatus>[];
        final ws = HydraWebSocket(
          host: '127.0.0.1',
          port: fakeServer.port,
          onStatus: statuses.add,
          onSettings: (_) {},
          onError: (_) {},
        );
        final firstConnection = fakeServer.onConnect.first;
        ws.connect();
        final serverSocketOne = await firstConnection;

        // A real drop, not a mock event - closes the server's own side of
        // the real socket, forcing HydraWebSocket's real onDone ->
        // _scheduleReconnect path (reconnectDelay later).
        final secondConnection = fakeServer.onConnect.first;
        await serverSocketOne.close();
        final serverSocketTwo = await secondConnection.timeout(reconnectDelay + const Duration(seconds: 10));
        // The server accepting the real second connection and the
        // client's own onStatus(connected) callback (fired after its
        // `await channel.ready`) are two separate real events - give the
        // client a moment to catch up rather than racing it.
        await Future<void>.delayed(const Duration(milliseconds: 300));

        expect(serverSocketTwo, isNotNull);
        expect(statuses, containsAllInOrder([WsStatus.connected, WsStatus.disconnected, WsStatus.connecting, WsStatus.connected]));
        ws.disconnect();
      },
      timeout: Timeout(reconnectDelay + const Duration(seconds: 15)),
    );

    test(
      'disconnect() cancels a pending reconnect and never reconnects again',
      () async {
        final ws = HydraWebSocket(
          host: '127.0.0.1',
          port: fakeServer.port,
          onStatus: (_) {},
          onSettings: (_) {},
          onError: (_) {},
        );
        final firstConnection = fakeServer.onConnect.first;
        ws.connect();
        final serverSocketOne = await firstConnection;
        await serverSocketOne.close();
        // Real user-initiated disconnect BEFORE the scheduled reconnect
        // timer fires - _closingByUser must suppress it.
        ws.disconnect();

        var reconnected = false;
        final sub = fakeServer.onConnect.listen((_) => reconnected = true);
        await Future<void>.delayed(reconnectDelay + const Duration(seconds: 2));
        await sub.cancel();

        expect(reconnected, isFalse);
      },
      timeout: Timeout(reconnectDelay + const Duration(seconds: 15)),
    );

    test(
      'a real 1008 close (server-rejected token) surfaces wsAuthRejected and never reconnects',
      () async {
        // Real bug fixed 2026-09-08: onDone used to always reconnect,
        // unconditionally, despite this file's own header comment already
        // claiming a 1008 close was "treated as sign in again" - a token
        // the server will never accept again just spun forever in
        // "connecting" -> "disconnected" with no visible error at all.
        final statuses = <WsStatus>[];
        final errors = <HydraError>[];
        final ws = HydraWebSocket(
          host: '127.0.0.1',
          port: fakeServer.port,
          token: 'an-expired-token',
          onStatus: statuses.add,
          onSettings: (_) {},
          onError: errors.add,
        );
        final connected = fakeServer.onConnect.first;
        ws.connect();
        final serverSocket = await connected;

        // Real close with the real RFC 6455 code, not a mocked event.
        await serverSocket.close(1008, 'invalid token');
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(errors, hasLength(1));
        expect(errors.single.kind, HydraErrorKind.wsAuthRejected);

        // Real proof of "never reconnects": wait comfortably past
        // reconnectDelay and confirm the server never receives a second
        // real upgrade request.
        var reconnected = false;
        final sub = fakeServer.onConnect.listen((_) => reconnected = true);
        await Future<void>.delayed(reconnectDelay + const Duration(seconds: 2));
        await sub.cancel();

        expect(reconnected, isFalse);
        expect(
          statuses.where((s) => s == WsStatus.connecting).length,
          1,
          reason: 'only the initial connect should ever have happened - no retry after a 1008',
        );
      },
      timeout: Timeout(reconnectDelay + const Duration(seconds: 15)),
    );

    test('reports a real connection error when nothing is listening - a real closed port', () async {
      final port = fakeServer.port;
      await fakeServer.close(); // real port, now genuinely refusing connections

      final errors = <HydraError>[];
      final ws = HydraWebSocket(
        host: '127.0.0.1',
        port: port,
        onStatus: (_) {},
        onSettings: (_) {},
        onError: errors.add,
      );
      ws.connect();
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (errors.isEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      expect(errors, isNotEmpty);
      // Found live, not assumed: web_socket_channel's own stream can
      // report the real refused connection as onError (wsConnectionLost)
      // before HydraWebSocket's own `await channel.ready` gets a chance
      // to throw (wsConnectFailed) - both are the same real "could not
      // connect" outcome from a caller's own point of view.
      expect(
        errors.first.kind,
        anyOf(HydraErrorKind.wsConnectFailed, HydraErrorKind.wsConnectionLost),
      );
      ws.disconnect();
    });
  });
}
