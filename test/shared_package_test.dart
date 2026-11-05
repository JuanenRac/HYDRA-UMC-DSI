// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/shared_package_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// What this app keeps of the code it shares through the SDK package: the set of continuous commands the
// package knows is the one of the generated command contract, the controller id keeps the prefix of this
// app, and the error kinds of the socket map to the kinds this app shows.
// =============================================================================

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydra_umc_dsi/models/access.dart';
import 'package:hydra_umc_dsi/models/contract_v2.dart';
import 'package:hydra_umc_dsi/models/robot_command_contract.dart';
import 'package:hydra_umc_dsi/network/hydra_websocket.dart';

void main() {
  test('the continuous commands of the shared package include those of the generated contract', () {
    expect(continuousCommands.containsAll(RobotCommandContract.continuous), isTrue);
  });

  test('a controller id has the prefix of this app and passes the check of the server', () {
    final id = generateControllerId(Random(7));
    expect(id.startsWith('dsi-'), isTrue);
    expect(isValidControllerId(id), isTrue);
  });

  test('the address of the socket never carries the token', () {
    final uri = HydraWebSocket.buildConnectionUri(host: 'h', port: 3000, token: 'a.b.c', useTls: true);
    expect(uri.scheme, 'wss');
    expect(uri.toString().contains('a.b.c'), isFalse);
  });
}
