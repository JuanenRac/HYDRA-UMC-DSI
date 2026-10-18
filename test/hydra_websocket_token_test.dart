// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/hydra_websocket_token_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// How the token reaches the server on the WebSocket, against a real local
// dart:io server:
//   - as the "hydra.bearer" subprotocol, never in the address;
//   - a server from before that subprotocol (it only reads ?token=) refuses
//     the first upgrade, and the client opens the socket again at once with
//     the token in the address, without reporting an error;
//   - a binary frame is ignored instead of throwing inside the listener.
// =============================================================================

import 'dart:async' show StreamController;
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/network/hydra_websocket.dart';
import 'package:hydra_umc_dsi/state/hydra_error.dart';

class _Upgrade {
  final String path;
  final String? protocolHeader;
  _Upgrade(this.path, this.protocolHeader);
}

/// [acceptSubprotocol] false behaves like an older server: it accepts a
/// socket only when the token is in the query string.
Future<(HttpServer, List<_Upgrade>, StreamController<WebSocket>)> _server({required bool acceptSubprotocol}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final seen = <_Upgrade>[];
  final sockets = StreamController<WebSocket>.broadcast();
  server.listen((request) async {
    seen.add(_Upgrade(request.uri.toString(), request.headers.value('sec-websocket-protocol')));
    final hasQueryToken = request.uri.queryParameters.containsKey('token');
    if (!acceptSubprotocol && !hasQueryToken) {
      request.response.statusCode = HttpStatus.unauthorized;
      await request.response.close();
      return;
    }
    final socket = await WebSocketTransformer.upgrade(
      request,
      protocolSelector: (p) => acceptSubprotocol && p.contains('hydra.bearer') ? 'hydra.bearer' : null,
    );
    sockets.add(socket);
  });
  return (server, seen, sockets);
}

void main() {
  test('the token travels as the hydra.bearer subprotocol, never in the address', () async {
    final (server, seen, sockets) = await _server(acceptSubprotocol: true);
    addTearDown(() => server.close(force: true));
    final statuses = <WsStatus>[];
    final ws = HydraWebSocket(
      host: '127.0.0.1',
      port: server.port,
      token: 'tok.en-1',
      onStatus: statuses.add,
      onSettings: (_) {},
      onError: (_) {},
    );
    final connected = sockets.stream.first;
    ws.connect();
    await connected;
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(seen.single.path, isNot(contains('tok.en-1')));
    expect(seen.single.protocolHeader, contains('hydra.bearer'));
    expect(seen.single.protocolHeader, contains('tok.en-1'));
    expect(statuses, contains(WsStatus.connected));
    ws.disconnect();
  });

  test('a server that refuses the subprotocol upgrade gets the token in the address, without an error', () async {
    final (server, seen, sockets) = await _server(acceptSubprotocol: false);
    addTearDown(() => server.close(force: true));
    final errors = <HydraError>[];
    final statuses = <WsStatus>[];
    final ws = HydraWebSocket(
      host: '127.0.0.1',
      port: server.port,
      token: 'tok.en-2',
      onStatus: statuses.add,
      onSettings: (_) {},
      onError: errors.add,
    );
    final connected = sockets.stream.first;
    ws.connect();
    await connected.timeout(const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(seen.length, 2, reason: 'one refused upgrade, then the retry');
    expect(seen.first.protocolHeader, contains('hydra.bearer'));
    expect(seen.last.path, contains('token=tok.en-2'));
    expect(errors, isEmpty, reason: 'the fallback is not an error');
    expect(statuses, contains(WsStatus.connected));
    ws.disconnect();
  });

  test('every full snapshot is delivered, even one identical to the previous full snapshot', () async {
    final (server, _, sockets) = await _server(acceptSubprotocol: true);
    addTearDown(() => server.close(force: true));
    final received = <Map<String, dynamic>>[];
    final ws = HydraWebSocket(
      host: '127.0.0.1',
      port: server.port,
      token: 'tok.en-3',
      onStatus: (_) {},
      onSettings: received.add,
      onError: (_) {},
    );
    final connected = sockets.stream.first;
    ws.connect();
    final socket = await connected;
    final snapshot = jsonEncode({'type': 'settings', 'payload': {'a': 1}});
    socket.add(snapshot);
    socket.add(snapshot);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(received.length, 2, reason: 'a delta in between may have changed the local copy; the snapshot must apply');
    ws.disconnect();
  });

  test('a binary frame is ignored', () async {
    final (server, _, sockets) = await _server(acceptSubprotocol: true);
    addTearDown(() => server.close(force: true));
    final received = <Map<String, dynamic>>[];
    final errors = <HydraError>[];
    final ws = HydraWebSocket(
      host: '127.0.0.1',
      port: server.port,
      token: 'tok.en-4',
      onStatus: (_) {},
      onSettings: received.add,
      onError: errors.add,
    );
    final connected = sockets.stream.first;
    ws.connect();
    final socket = await connected;
    socket.add(<int>[1, 2, 3]);
    socket.add(jsonEncode({'type': 'settings', 'payload': {'ok': true}}));
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(received, [
      {'ok': true},
    ]);
    expect(errors, isEmpty);
    ws.disconnect();
  });
}
