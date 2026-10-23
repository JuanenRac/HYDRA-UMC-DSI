// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/access_models_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The controller id, the reservations, the limits and the jog check: pure rules.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/models/access.dart';

void main() {
  test('a generated controller id is valid for the server', () {
    final id = generateControllerId();
    expect(isValidControllerId(id), isTrue, reason: id);
    expect(id.length, lessThanOrEqualTo(64));
    expect(generateControllerId(), isNot(id));
  });

  test('the controller id follows the server pattern', () {
    expect(isValidControllerId('a.b_c:d-1'), isTrue);
    expect(isValidControllerId(''), isFalse);
    expect(isValidControllerId(null), isFalse);
    expect(isValidControllerId('has space'), isFalse);
    expect(isValidControllerId('x' * 65), isFalse);
    expect(isValidControllerId('x' * 64), isTrue);
  });

  test('reservations are read from the claims answer', () {
    final claims = ClaimInfo.listFromJson({
      'claims': [
        {'robotId': 1, 'robotName': 'A1', 'ownerUsername': 'ana', 'controllerId': 'dsi-1', 'expiresAt': 5000},
        {'robotId': 2, 'robotName': null, 'ownerUsername': 'bob', 'controllerId': null, 'expiresAt': 6000},
        {'nothing': true},
      ],
    });
    expect(claims, hasLength(2));
    expect(claims[0].controllerId, 'dsi-1');
    expect(claims[1].controllerId, isNull, reason: 'a reservation made without a controller id has none');
    expect(claims[1].robotName, '');
    expect(claims[1].expiresAt, 6000);
    expect(ClaimInfo.listFromJson({}), isEmpty);
  });

  test('where a robot stands for this installation', () {
    const mine = ClaimInfo(robotId: 1, robotName: 'A1', ownerUsername: 'ana', controllerId: 'dsi-1', expiresAt: 1);
    expect(claimStanding(null, 'ana', 'dsi-1'), ClaimStanding.free);
    expect(claimStanding(mine, 'ana', 'dsi-1'), ClaimStanding.mineHere);
    expect(claimStanding(mine, 'ana', 'dsi-2'), ClaimStanding.mineElsewhere);
    expect(claimStanding(mine, 'bob', 'dsi-2'), ClaimStanding.other);
    expect(claimStanding(mine, '', 'dsi-2'), ClaimStanding.other, reason: 'a name that is not known is never taken for the owner');
    expect(claimStanding(mine, '', 'dsi-1'), ClaimStanding.mineHere, reason: 'a claim under this controller id is ours whatever the name');
    const open = ClaimInfo(robotId: 1, robotName: 'A1', ownerUsername: 'ana', controllerId: null, expiresAt: 1);
    expect(claimStanding(open, 'ana', 'dsi-2'), ClaimStanding.mineHere, reason: 'a reservation without a controller answers to any controller of the account');
  });

  Map<String, dynamic> answer({Object? armedUntil}) => {
        'limits': {
          'jog': {'armRequired': true, 'armTtlMs': 30000, 'default': {'maxAmount': 100, 'maxAbsolute': 1000}, 'models': {}},
        },
        'robot': {
          'id': 3,
          'model': 'Parol6 (6-DOF)',
          'jog': {'maxAmount': 20, 'maxAbsolute': 500},
          'temperature': {'bedMaxC': 90},
          'jogArmedUntil': armedUntil,
        },
      };

  test('the limits of a robot are read from the safety answer', () {
    final safety = RobotSafety.fromJson(answer())!;
    expect(safety.robotId, 3);
    expect(safety.jog.maxAmount, 20);
    expect(safety.jog.maxAbsolute, 500);
    expect(safety.bedMaxC, 90);
    expect(safety.armRequired, isTrue);
    expect(safety.armTtlMs, 30000);
    expect(safety.jogArmedUntil, isNull);
    expect(RobotSafety.fromJson(answer(armedUntil: 1234567))!.jogArmedUntil, 1234567);
  });

  test('an answer without limits for the robot gives none', () {
    expect(RobotSafety.fromJson({'limits': {}}), isNull);
    expect(RobotSafety.fromJson({'robot': {'id': 1, 'jog': {'maxAmount': 0, 'maxAbsolute': 10}}}), isNull);
    expect(RobotSafety.fromJson({'robot': {'id': 1}}), isNull);
  });

  test('a jog above the limit of the model is caught', () {
    const limits = JogLimits(20, 500);
    expect(jogLimitExceeded(20, limits), isNull);
    expect(jogLimitExceeded(-20, limits), isNull);
    expect(jogLimitExceeded(20.5, limits), 20);
    expect(jogLimitExceeded(-50, limits), 20);
    expect(jogLimitExceeded(499, limits, absolute: true), isNull);
    expect(jogLimitExceeded(-501, limits, absolute: true), 500);
    expect(jogLimitExceeded(double.nan, limits), 20);
  });

  test('without known limits the server decides', () {
    expect(jogLimitExceeded(10000, null), isNull);
  });

  test('limits are shown without a needless decimal', () {
    expect(formatLimit(1000.0), '1000');
    expect(formatLimit(12.5), '12.5');
  });
}
