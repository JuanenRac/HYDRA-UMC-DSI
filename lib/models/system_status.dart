// =============================================================================
// HYDRA-UMC DSI (Flutter) - models/system_status.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// What the System tab reads: the verdict of HYDRA-UMC-SAFETY-ZONES and the
// status of the services of the ecosystem (GET /api/ecosystem/status of the
// server). Both are parsed defensively: a field that is missing or of the
// wrong type never throws, and anything that is not clearly good reads as
// "not confirmed" - a panel next to a robot must never show a green light it
// has not been given.
// =============================================================================

/// The state the safety service reports, in the words of the contract of the SDK.
enum SafetyLevel { ready, warning, danger, inhibited, fault, unknown }

SafetyLevel _levelOf(Object? raw) {
  switch (raw is String ? raw.toLowerCase() : '') {
    case 'ready':
      return SafetyLevel.ready;
    case 'warning':
      return SafetyLevel.warning;
    case 'danger':
      return SafetyLevel.danger;
    case 'inhibited':
      return SafetyLevel.inhibited;
    case 'fault':
      return SafetyLevel.fault;
    default:
      return SafetyLevel.unknown;
  }
}

/// One object found inside one zone, as the safety service lists it (no position: the panel shows where, not how far).
class SafetyBreach {
  final String zoneId;

  /// `danger` or `warning`; anything else the service might send is shown as a warning, never as less than that.
  final bool danger;
  final String objectId;
  const SafetyBreach({required this.zoneId, required this.danger, required this.objectId});
}

/// The last verdict of the safety service (GET /state), with the moment it was read.
class SafetyStatus {
  final SafetyLevel level;

  /// The short reason the service gives (why it is inhibited or in danger), or empty.
  final String reason;

  /// When the service reached the verdict (its own clock), or null.
  final DateTime? reachedAt;

  /// When this panel read it.
  final DateTime readAt;

  /// The service answered but has reached no verdict yet (HTTP 404): not confirmed safe.
  final bool noVerdictYet;

  /// The verdict carries a signature of the service (not checked here: shown so the person knows).
  final bool signed;

  /// The breached zones the service lists (at most as many as it sends), and how many there are in all.
  final List<SafetyBreach> breaches;
  final int breachCount;

  /// How many stop requests the service made for the verdict, or null when it does not say.
  final int? estopRequestCount;

  const SafetyStatus({
    required this.level,
    required this.reason,
    required this.reachedAt,
    required this.readAt,
    this.noVerdictYet = false,
    this.signed = false,
    this.breaches = const [],
    this.breachCount = 0,
    this.estopRequestCount,
  });

  /// A verdict that was reached more than [staleAfter] ago (by the service's clock, or else by ours) is not current.
  bool isStale(DateTime now, Duration staleAfter) {
    final since = reachedAt ?? readAt;
    return now.difference(since) > staleAfter;
  }

  /// Only a current READY is shown as good; every other case needs attention.
  bool isConfirmedReady(DateTime now, Duration staleAfter) => level == SafetyLevel.ready && !isStale(now, staleAfter);

  factory SafetyStatus.parse(Map<String, dynamic> json, DateTime readAt) {
    final sdk = json['sdkSafetyState'];
    final stateMap = sdk is Map ? sdk : const <String, dynamic>{};
    DateTime? reached;
    final ts = stateMap['timestamp_utc'];
    if (ts is String) reached = DateTime.tryParse(ts);
    final reason = json['reason'];
    final listed = <SafetyBreach>[];
    final rawBreaches = json['breaches'];
    if (rawBreaches is List) {
      for (final b in rawBreaches) {
        if (b is! Map) continue;
        final zone = b['zone_id'];
        final object = b['object_id'];
        listed.add(SafetyBreach(zoneId: zone is String ? zone : '', danger: b['level'] == 'danger', objectId: object is String ? object : ''));
      }
    }
    final count = json['breachCount'];
    final stops = json['estopRequestCount'];
    return SafetyStatus(
      level: _levelOf(stateMap['state']),
      reason: reason is String ? reason : '',
      reachedAt: reached,
      readAt: readAt,
      signed: json['sdkSafetyStateSignature'] is Map,
      breaches: listed,
      breachCount: count is int && count >= listed.length ? count : listed.length,
      estopRequestCount: stops is int && stops >= 0 ? stops : null,
    );
  }

  factory SafetyStatus.noVerdict(DateTime readAt) =>
      SafetyStatus(level: SafetyLevel.unknown, reason: '', reachedAt: null, readAt: readAt, noVerdictYet: true);
}

/// Why the safety service could not be read, for the sentence the screen shows.
enum SafetyFailure { unreachable, unauthorized, other }

/// One project of the ecosystem as the server describes it.
class EcosystemProject {
  final String name;
  final String? version;
  final String? family;
  final String? role;
  final String? systemdUnit;
  final String? activeState;
  final String? subState;
  final int? pid;

  /// null = the project declares no service (a library, firmware, a tool): not applicable, never "down".
  final bool? live;

  const EcosystemProject({
    required this.name,
    this.version,
    this.family,
    this.role,
    this.systemdUnit,
    this.activeState,
    this.subState,
    this.pid,
    this.live,
  });

  /// The project runs as a service of this machine (it has a unit or a probe).
  bool get isService => systemdUnit != null || live != null;

  /// Running: the probe answered, or the unit is active.
  bool get isRunning => live == true || activeState == 'active';

  /// The unit exists, is not active and nothing answers.
  bool get isDown => isService && !isRunning;

  static String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

  factory EcosystemProject.parse(Map<String, dynamic> json) => EcosystemProject(
        name: _str(json['name']) ?? '?',
        version: _str(json['version']),
        family: _str(json['family']),
        role: _str(json['role']),
        systemdUnit: _str(json['systemdUnit']),
        activeState: _str(json['activeState']),
        subState: _str(json['subState']),
        pid: json['pid'] is num ? (json['pid'] as num).toInt() : null,
        live: json['live'] is bool ? json['live'] as bool : null,
      );
}

class EcosystemStatus {
  final bool available;
  final DateTime? scannedAt;
  final List<EcosystemProject> projects;

  const EcosystemStatus({required this.available, required this.scannedAt, required this.projects});

  /// Only the projects that run as a service, in alphabetical order.
  List<EcosystemProject> get services {
    final list = projects.where((p) => p.isService).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  int get runningCount => services.where((p) => p.isRunning).length;

  factory EcosystemStatus.parse(Map<String, dynamic> json) {
    final raw = json['projects'];
    final projects = <EcosystemProject>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) projects.add(EcosystemProject.parse(item));
      }
    }
    final at = json['scannedAt'];
    return EcosystemStatus(
      available: json['available'] == true,
      scannedAt: at is String ? DateTime.tryParse(at) : null,
      projects: projects,
    );
  }
}
