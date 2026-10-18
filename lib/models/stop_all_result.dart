// =============================================================================
// HYDRA-UMC DSI (Flutter) - models/stop_all_result.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The answer of the global STOP (POST /api/stop-all), robot by robot, or the
// same shape built from the per-robot stop commands when the global route was
// not available (rate limit, older server).
// =============================================================================

class StopAllRobot {
  final dynamic robotId;
  final String? controllerId;
  final String name;
  final bool stopped;
  final int valvesOff;
  final int pumpsOff;

  /// The account that held a reservation on this robot, if any. The stop went
  /// through anyway: a safety stop is never blocked by a reservation.
  final String? reservedBy;
  final String? error;

  const StopAllRobot({
    required this.robotId,
    this.controllerId,
    required this.name,
    required this.stopped,
    this.valvesOff = 0,
    this.pumpsOff = 0,
    this.reservedBy,
    this.error,
  });

  factory StopAllRobot.fromJson(Map<String, dynamic> json) {
    int count(dynamic v) => v is num ? v.toInt() : 0;
    return StopAllRobot(
      robotId: json['robotId'],
      controllerId: json['controllerId'] is String ? json['controllerId'] as String : null,
      name: json['name'] is String ? json['name'] as String : '${json['robotId']}',
      stopped: json['stopped'] == true,
      valvesOff: count(json['valvesOff']),
      pumpsOff: count(json['pumpsOff']),
      reservedBy: json['reservedBy'] is String ? json['reservedBy'] as String : null,
      error: json['error'] is String ? json['error'] as String : null,
    );
  }
}

class StopAllResult {
  final bool success;
  final int stoppedCount;
  final int failedCount;

  /// False when the stop is applied and broadcast but the server could not
  /// write its settings file.
  final bool persisted;
  final List<StopAllRobot> robots;

  /// True when the result was built from per-robot stop commands.
  final bool viaFallback;

  const StopAllResult({
    required this.success,
    required this.stoppedCount,
    required this.failedCount,
    required this.persisted,
    required this.robots,
    this.viaFallback = false,
  });

  factory StopAllResult.fromJson(Map<String, dynamic> json) {
    final list = <StopAllRobot>[];
    final raw = json['robots'];
    if (raw is List) {
      for (final r in raw) {
        if (r is Map<String, dynamic>) list.add(StopAllRobot.fromJson(r));
      }
    }
    final stopped = json['stoppedCount'] is num ? (json['stoppedCount'] as num).toInt() : list.where((r) => r.stopped).length;
    final failed = json['failedCount'] is num ? (json['failedCount'] as num).toInt() : list.where((r) => !r.stopped).length;
    return StopAllResult(
      success: json['success'] == true,
      stoppedCount: stopped,
      failedCount: failed,
      persisted: json['persisted'] != false,
      robots: list,
    );
  }

  factory StopAllResult.fromRobots(List<StopAllRobot> robots, {bool viaFallback = false}) {
    final stopped = robots.where((r) => r.stopped).length;
    return StopAllResult(
      success: stopped == robots.length,
      stoppedCount: stopped,
      failedCount: robots.length - stopped,
      persisted: true,
      robots: robots,
      viaFallback: viaFallback,
    );
  }

  /// A failure or an unsaved stop: shown prominently.
  bool get needsAttention => failedCount > 0 || !persisted || !success;
}
