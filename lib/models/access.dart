// =============================================================================
// HYDRA-UMC DSI (Flutter) - models/access.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Reservations, safety limits and jog arming of the server (contract v2,
// block 1), as pure data and rules with no network and no widgets:
//   - the controller id of this installation: a reservation belongs to the
//     account AND to the controller that made it, so two clients of one
//     account no longer share one reservation;
//   - the reservations listed by GET /api/claims;
//   - the limits of GET /api/safety-limits?robotId=, and the check that keeps
//     a jog above the limit of the robot's model from being sent at all (the
//     server checks it again).
// =============================================================================

import 'dart:convert';
import 'dart:math';

final RegExp _controllerIdPattern = RegExp(r'^[A-Za-z0-9._:-]{1,64}$');

/// True when [id] is a controller id the server accepts: 1 to 64 characters of
/// letters, digits and `. _ : -`.
bool isValidControllerId(String? id) => id != null && _controllerIdPattern.hasMatch(id);

/// A new controller id for this installation, e.g. `dsi-3fa9c1d27b40`.
String generateControllerId([Random? random]) {
  final r = random ?? Random.secure();
  final hex = List.generate(12, (_) => r.nextInt(16).toRadixString(16)).join();
  return 'dsi-$hex';
}

/// One active reservation of GET /api/claims.
class ClaimInfo {
  final dynamic robotId;
  final String robotName;
  final String ownerUsername;

  /// The controller that holds it; null for a reservation made without one.
  final String? controllerId;

  /// Epoch milliseconds, the server's clock.
  final int expiresAt;

  const ClaimInfo({
    required this.robotId,
    required this.robotName,
    required this.ownerUsername,
    required this.controllerId,
    required this.expiresAt,
  });

  static List<ClaimInfo> listFromJson(Map<String, dynamic> json) {
    final raw = json['claims'];
    if (raw is! List) return const [];
    final out = <ClaimInfo>[];
    for (final item in raw) {
      if (item is! Map || !item.containsKey('robotId')) continue;
      final controller = item['controllerId'];
      out.add(ClaimInfo(
        robotId: item['robotId'],
        robotName: item['robotName'] is String ? item['robotName'] as String : '',
        ownerUsername: item['ownerUsername'] is String ? item['ownerUsername'] as String : '',
        controllerId: controller is String && controller.isNotEmpty ? controller : null,
        expiresAt: item['expiresAt'] is num ? (item['expiresAt'] as num).toInt() : 0,
      ));
    }
    return out;
  }
}

/// Where a robot stands for this installation.
enum ClaimStanding { free, mineHere, mineElsewhere, other }

/// [claim] is the active reservation of the robot (null when free). The same
/// account on another controller is [ClaimStanding.mineElsewhere]: the server
/// refuses it like another account until it is released there. A reservation
/// made without a controller id is the account's own and answers to any controller.
ClaimStanding claimStanding(ClaimInfo? claim, String myUsername, String myControllerId) {
  if (claim == null) return ClaimStanding.free;
  // The controller id is random per installation: only this device can hold a claim under it.
  if (claim.controllerId == myControllerId) return ClaimStanding.mineHere;
  if (myUsername.isEmpty || claim.ownerUsername != myUsername) return ClaimStanding.other;
  if (claim.controllerId == null || claim.controllerId == myControllerId) return ClaimStanding.mineHere;
  return ClaimStanding.mineElsewhere;
}

/// The role the session token carries (`admin` or `operator`), or null when it cannot be read. The server
/// checks the role again on every request; this only decides whether the take-over button is shown.
String? jwtRole(String? token) {
  if (token == null) return null;
  final parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    final role = payload is Map ? payload['role'] : null;
    return role is String && role.isNotEmpty ? role : null;
  } catch (_) {
    return null;
  }
}

/// Whether the take-over button applies: the session is an administrator's and someone else holds the robot.
bool canTakeOverRobot(String? role, ClaimStanding standing) =>
    role == 'admin' && (standing == ClaimStanding.other || standing == ClaimStanding.mineElsewhere);

/// The size of a jog and the range of an absolute jog the server allows for one model.
class JogLimits {
  final double maxAmount;
  final double maxAbsolute;
  const JogLimits(this.maxAmount, this.maxAbsolute);
}

/// The limits that apply to one robot, from GET /api/safety-limits?robotId=.
class RobotSafety {
  final dynamic robotId;
  final JogLimits jog;
  final double bedMaxC;

  /// The administrator requires the jog to be armed before it moves this robot.
  final bool armRequired;
  final int armTtlMs;

  /// Epoch milliseconds (the server's clock) until which the jog of this robot
  /// is armed for this controller; null when it is not.
  final int? jogArmedUntil;

  const RobotSafety({
    required this.robotId,
    required this.jog,
    required this.bedMaxC,
    required this.armRequired,
    required this.armTtlMs,
    required this.jogArmedUntil,
  });

  /// Null when the answer carries no limits for a robot (an older server, or no robotId asked).
  static RobotSafety? fromJson(Map<String, dynamic> json) {
    final robot = json['robot'];
    if (robot is! Map) return null;
    final jog = robot['jog'];
    if (jog is! Map) return null;
    final maxAmount = jog['maxAmount'];
    final maxAbsolute = jog['maxAbsolute'];
    if (maxAmount is! num || maxAbsolute is! num || maxAmount <= 0 || maxAbsolute <= 0) return null;
    final limits = json['limits'];
    final globalJog = limits is Map ? limits['jog'] : null;
    final temperature = robot['temperature'];
    final armedUntil = robot['jogArmedUntil'];
    return RobotSafety(
      robotId: robot['id'],
      jog: JogLimits(maxAmount.toDouble(), maxAbsolute.toDouble()),
      bedMaxC: temperature is Map && temperature['bedMaxC'] is num ? (temperature['bedMaxC'] as num).toDouble() : 0.0,
      armRequired: globalJog is Map && globalJog['armRequired'] == true,
      armTtlMs: globalJog is Map && globalJog['armTtlMs'] is num ? (globalJog['armTtlMs'] as num).toInt() : 60000,
      jogArmedUntil: armedUntil is num && armedUntil > 0 ? armedUntil.toInt() : null,
    );
  }
}

/// The limit a jog of [amount] exceeds, or null when it is within [limits] (or
/// the limits are not known: the server then decides). A relative jog is
/// bounded by `maxAmount`; an absolute target, in either direction, by `maxAbsolute`.
double? jogLimitExceeded(double amount, JogLimits? limits, {bool absolute = false}) {
  if (limits == null) return null;
  final limit = absolute ? limits.maxAbsolute : limits.maxAmount;
  return amount.isNaN || amount.abs() > limit ? limit : null;
}

/// `1000.0` is shown as `1000`, `12.5` as `12.5`.
String formatLimit(double limit) {
  final s = limit.toString();
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}
