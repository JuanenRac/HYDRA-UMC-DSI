// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/can_ota_socket_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The `canota_progress` message reaches its own callback through the socket of the app, against a real local dart:io server. It is a file of its own
// because a file that uses the widget binding answers every HTTP request with 400.
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/models/can_ota_progress.dart';
import 'package:hydra_umc_dsi/network/hydra_websocket.dart';

Map<String, dynamic> _message(Map<String, Object?> payload) => {'type': 'canota_progress', 'payload': payload};

void main() {
  group('the socket of the app', () {
    test('a progress message goes to its own callback and not to the settings one', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request, protocolSelector: (p) => p.contains('hydra.bearer') ? 'hydra.bearer' : null);
        socket.add(jsonEncode(_message({'phase': 'transferring', 'pages_sent': 5, 'pages_total': 20, 'percent': 25})));
      });
      final progress = Completer<Map<String, dynamic>>();
      final settings = <Map<String, dynamic>>[];
      final ws = HydraWebSocket(
        host: '127.0.0.1',
        port: server.port,
        token: 'tok',
        onStatus: (_) {},
        onSettings: settings.add,
        onError: (_) {},
        onCanOtaProgress: (m) {
          if (!progress.isCompleted) progress.complete(m);
        },
      )..connect();
      addTearDown(ws.disconnect);
      final read = CanOtaProgress.fromMessage(await progress.future.timeout(const Duration(seconds: 5)))!;
      expect(read.phase, CanOtaPhase.transferring);
      expect(read.percent, 25);
      expect(settings, isEmpty);
    });
  });
}
