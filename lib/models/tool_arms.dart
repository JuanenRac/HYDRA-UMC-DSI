// =============================================================================
// HYDRA-UMC DSI (Flutter) - models/tool_arms.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The arm state of the URTC tools as the server relays it (GET /api/tool-arms,
// read only): the last report of each pair of robot and tool, how old it is
// and whether it is stale. A tool is armed when its power stage may act. An
// old report is never shown as safe: a stale armed tool is a warning and a
// stale disarmed tool is unknown. Nothing here arms, disarms or stops anything.
//
// The reading checks the closed shape of the contract: one bad row refuses the
// whole answer, so a half-read list is never shown as the truth.
// =============================================================================

const int maxToolArms = 256;
const int maxToolId = 24;
final RegExp _robot = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,63}$');

/// What one row means to the person looking at it.
enum ToolArmLevel { armed, disarmed, warning, unknown }

/// Why there is no list to show.
enum ToolArmsFailure {
  /// The server has no address of the safety service, or the service was not started with the tool arms (502/503/504, or 404 from the service).
  unavailable,

  /// The server is older than the route (404).
  unsupported,

  /// The session may not read it (401/403).
  forbidden,

  /// Nothing answered.
  network,

  /// Any other status.
  other,

  /// An answer that does not have the shape of the contract.
  shape,
}

class ToolArm {
  final String robot;
  final int toolId;
  final bool armed;
  final String by;
  final int seq;
  final double ageSeconds;
  final bool stale;
  const ToolArm({required this.robot, required this.toolId, required this.armed, required this.by, required this.seq, required this.ageSeconds, required this.stale});
}

class ToolArmsReport {
  final double ttlSeconds;
  final List<ToolArm> arms;
  final int armedCount;
  final int staleCount;

  /// When this panel read it (the age of each row is the age at that moment).
  final DateTime readAt;
  const ToolArmsReport({required this.ttlSeconds, required this.arms, required this.armedCount, required this.staleCount, required this.readAt});

  static bool _whole(Object? v, int min, [int max = 9007199254740991]) => v is int && v >= min && v <= max;

  static Map<String, dynamic> _object(Object? v) => v is Map ? v.cast<String, dynamic>() : const <String, dynamic>{};

  /// The report in an answer; null when anything does not have the shape of the contract.
  static ToolArmsReport? parse(Object? data, DateTime readAt) {
    final r = _object(data);
    if (r['schema_version'] != '1.0') return null;
    final ttl = r['ttlSeconds'];
    if (ttl is! num || !ttl.isFinite || ttl <= 0) return null;
    final rawArms = r['arms'];
    if (rawArms is! List || rawArms.length > maxToolArms) return null;
    if (!_whole(r['armedCount'], 0) || !_whole(r['staleCount'], 0)) return null;
    final arms = <ToolArm>[];
    for (final raw in rawArms) {
      final a = _object(raw);
      final robot = a['robot'];
      if (robot is! String || !_robot.hasMatch(robot)) return null;
      if (!_whole(a['toolId'], 0, maxToolId)) return null;
      final armed = a['armed'];
      final stale = a['stale'];
      if (armed is! bool || stale is! bool) return null;
      final by = a['by'];
      if (by is! String || by.length > 64) return null;
      if (!_whole(a['seq'], 1)) return null;
      final age = a['ageSeconds'];
      if (age is! num || !age.isFinite || age < 0) return null;
      arms.add(ToolArm(robot: robot, toolId: a['toolId'] as int, armed: armed, by: by, seq: a['seq'] as int, ageSeconds: age.toDouble(), stale: stale));
    }
    return ToolArmsReport(ttlSeconds: ttl.toDouble(), arms: arms, armedCount: r['armedCount'] as int, staleCount: r['staleCount'] as int, readAt: readAt);
  }

  /// The age of a row now: the age the server gave plus the time since this panel read it.
  double ageNow(ToolArm arm, DateTime now) {
    final since = now.difference(readAt).inMilliseconds / 1000.0;
    return arm.ageSeconds + (since > 0 ? since : 0);
  }

  /// A stale armed tool is a warning and a stale disarmed tool is unknown: an old report is never shown as safe.
  /// A row is also stale when, by the time this panel shows it, it is older than the time to live of the reports.
  ToolArmLevel levelOf(ToolArm arm, DateTime now) {
    final stale = arm.stale || ageNow(arm, now) > ttlSeconds;
    if (stale) return arm.armed ? ToolArmLevel.warning : ToolArmLevel.unknown;
    return arm.armed ? ToolArmLevel.armed : ToolArmLevel.disarmed;
  }

  /// The rows in the order a person needs them: dangerous first (warning, armed), then unknown, then disarmed; then by robot and tool.
  List<ToolArm> sorted(DateTime now) {
    const rank = {ToolArmLevel.warning: 0, ToolArmLevel.armed: 1, ToolArmLevel.unknown: 2, ToolArmLevel.disarmed: 3};
    final copy = [...arms];
    copy.sort((a, b) {
      final byLevel = rank[levelOf(a, now)]!.compareTo(rank[levelOf(b, now)]!);
      if (byLevel != 0) return byLevel;
      final byRobot = a.robot.compareTo(b.robot);
      return byRobot != 0 ? byRobot : a.toolId.compareTo(b.toolId);
    });
    return copy;
  }
}

/// The age as short text parts: seconds under a minute, minutes under an hour, otherwise hours.
({String unit, int value}) formatToolArmAge(double seconds) {
  if (seconds < 60) return (unit: 's', value: seconds.floor());
  if (seconds < 3600) return (unit: 'min', value: (seconds / 60).floor());
  return (unit: 'h', value: (seconds / 3600).floor());
}
