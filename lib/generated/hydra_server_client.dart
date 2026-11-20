// Generated from the server contract by tools/generate_clients.py. Do not edit.
// ignore_for_file: unused_element

// The transport hands back the decoded JSON model: Map, List, String, int, double, bool or null. Every object of the
// contract is a class with fromJson (reads that model) and toJson (writes it again); no JSON library is needed.

typedef HydraCameraProcessStatus = Map<String, HydraCameraProcessStatusValue>;

typedef HydraPassthrough = Map<String, dynamic>;

typedef HydraSupervisorSnapshot = Map<String, dynamic>;

/// One line of the audit record: the hash chain (seq, prev, hash) around the event. The keys of an event the server adds later are kept.
class HydraAuditEntry {
  const HydraAuditEntry({
    required this.seq,
    required this.ts,
    required this.prev,
    required this.hash,
    required this.type,
    required this.outcome,
    this.userId,
    this.username,
    this.controllerId,
    this.ip,
    this.robotId,
    this.detail,
    this.additionalProperties = const <String, dynamic>{},
  });

  factory HydraAuditEntry.fromJson(Map<String, dynamic> json) => HydraAuditEntry(
        seq: (json['seq'] as num).toInt(),
        ts: json['ts'] as String,
        prev: json['prev'] as String,
        hash: json['hash'] as String,
        type: json['type'] as String,
        outcome: json['outcome'] as String,
        userId: json['userId'],
        username: json['username'] == null ? null : json['username'] as String,
        controllerId: json['controllerId'] == null ? null : json['controllerId'] as String,
        ip: json['ip'] == null ? null : json['ip'] as String,
        robotId: json['robotId'] == null ? null : (json['robotId'] as num).toInt(),
        detail: json['detail'] == null ? null : _hydraMap(json['detail']),
        additionalProperties: _hydraMap(<String, dynamic>{for (final entry in json.entries) if (!_knownKeys.contains(entry.key)) entry.key: entry.value}),
      );

  static const Set<String> _knownKeys = <String>{'seq', 'ts', 'prev', 'hash', 'type', 'outcome', 'userId', 'username', 'controllerId', 'ip', 'robotId', 'detail'};

  final int seq;
  final String ts;
  final String prev;
  final String hash;
  /// Short stable name of the event: claim, release, force-claim, force-release, safety-limits, jog-arm, stop-all, table-move...
  final String type;
  final String outcome;
  /// The id of the account (any JSON value).
  final dynamic userId;
  final String? username;
  final String? controllerId;
  final String? ip;
  final int? robotId;
  final Map<String, dynamic>? detail;
  /// The keys the contract does not list, kept as they came.
  final Map<String, dynamic> additionalProperties;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{...additionalProperties};
    hydraOut['seq'] = seq;
    hydraOut['ts'] = ts;
    hydraOut['prev'] = prev;
    hydraOut['hash'] = hash;
    hydraOut['type'] = type;
    hydraOut['outcome'] = outcome;
    final hydraField6 = userId;
    if (hydraField6 != null) hydraOut['userId'] = hydraField6;
    final hydraField7 = username;
    if (hydraField7 != null) hydraOut['username'] = hydraField7;
    final hydraField8 = controllerId;
    if (hydraField8 != null) hydraOut['controllerId'] = hydraField8;
    final hydraField9 = ip;
    if (hydraField9 != null) hydraOut['ip'] = hydraField9;
    final hydraField10 = robotId;
    if (hydraField10 != null) hydraOut['robotId'] = hydraField10;
    final hydraField11 = detail;
    if (hydraField11 != null) hydraOut['detail'] = hydraField11;
    return hydraOut;
  }
}

/// GET /api/audit as JSON: the newest entries (oldest first) and, with ?verify=1, the check of the hash chain. The same entries come as lines of JSON with ?format=jsonl.
class HydraAuditReport {
  const HydraAuditReport({
    required this.enabled,
    required this.lockedOff,
    required this.entries,
    this.verification,
  });

  factory HydraAuditReport.fromJson(Map<String, dynamic> json) => HydraAuditReport(
        enabled: json['enabled'] as bool,
        lockedOff: json['lockedOff'] as bool,
        entries: (json['entries'] as List).map((v0) => HydraAuditEntry.fromJson(_hydraMap(v0))).toList(),
        verification: json['verification'] == null ? null : HydraAuditVerification.fromJson(_hydraMap(json['verification'])),
      );

  final bool enabled;
  final bool lockedOff;
  final List<HydraAuditEntry> entries;
  final HydraAuditVerification? verification;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['enabled'] = enabled;
    hydraOut['lockedOff'] = lockedOff;
    hydraOut['entries'] = entries.map((v0) => v0.toJson()).toList();
    final hydraField3 = verification;
    if (hydraField3 != null) hydraOut['verification'] = hydraField3.toJson();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraAuditVerification {
  const HydraAuditVerification({
    required this.ok,
    required this.entries,
    this.brokenAtSeq,
    this.reason,
  });

  factory HydraAuditVerification.fromJson(Map<String, dynamic> json) => HydraAuditVerification(
        ok: json['ok'] as bool,
        entries: (json['entries'] as num).toInt(),
        brokenAtSeq: json['brokenAtSeq'] == null ? null : (json['brokenAtSeq'] as num).toInt(),
        reason: json['reason'] == null ? null : json['reason'] as String,
      );

  final bool ok;
  final int entries;
  final int? brokenAtSeq;
  final String? reason;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['ok'] = ok;
    hydraOut['entries'] = entries;
    final hydraField2 = brokenAtSeq;
    if (hydraField2 != null) hydraOut['brokenAtSeq'] = hydraField2;
    final hydraField3 = reason;
    if (hydraField3 != null) hydraOut['reason'] = hydraField3;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraBluetoothScan {
  const HydraBluetoothScan({
    required this.success,
    required this.devices,
  });

  factory HydraBluetoothScan.fromJson(Map<String, dynamic> json) => HydraBluetoothScan(
        success: json['success'] as bool,
        devices: (json['devices'] as List).map((v0) => _hydraMap(v0)).toList(),
      );

  final bool success;
  final List<Map<String, dynamic>> devices;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['devices'] = devices;
    return hydraOut;
  }
}

/// The outcome of a command sent through the gateway: it was published, and the bridge answered (result holds its answer) or did not answer in time (result null).
class HydraBridgeCommandAccepted {
  const HydraBridgeCommandAccepted({
    required this.accepted,
    required this.result,
  });

  factory HydraBridgeCommandAccepted.fromJson(Map<String, dynamic> json) => HydraBridgeCommandAccepted(
        accepted: json['accepted'] as bool,
        result: json['result'],
      );

  final bool accepted;
  /// The answer the bridge published on the result topic, as it published it; null when none arrived in time.
  final dynamic result;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['accepted'] = accepted;
    hydraOut['result'] = result;
    return hydraOut;
  }
}

/// The bridges the gateway has seen on the broker.
class HydraBridgeList {
  const HydraBridgeList({
    required this.connected,
    required this.bridges,
  });

  factory HydraBridgeList.fromJson(Map<String, dynamic> json) => HydraBridgeList(
        connected: json['connected'] as bool,
        bridges: (json['bridges'] as List).map((v0) => HydraBridgeState.fromJson(_hydraMap(v0))).toList(),
      );

  /// Whether the gateway is connected to the broker now.
  final bool connected;
  final List<HydraBridgeState> bridges;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['connected'] = connected;
    hydraOut['bridges'] = bridges.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// What the gateway knows of one machine bridge from its retained topics: whether it is available (null when it never said), its last state and health report as the bridge published them, and when the last of them arrived.
class HydraBridgeState {
  const HydraBridgeState({
    required this.name,
    required this.available,
    required this.state,
    required this.health,
    required this.updatedAt,
  });

  factory HydraBridgeState.fromJson(Map<String, dynamic> json) => HydraBridgeState(
        name: json['name'] as String,
        available: json['available'] == null ? null : json['available'] as bool,
        state: json['state'],
        health: json['health'],
        updatedAt: json['updatedAt'] == null ? null : json['updatedAt'] as String,
      );

  final String name;
  /// True while the bridge is online (or its health report is not a FAULT), false when offline, null when it published neither.
  final bool? available;
  /// The last retained state of the bridge exactly as it published it (null when it published none).
  final dynamic state;
  /// The last retained HealthReport of the bridge (null when it publishes none).
  final dynamic health;
  final String? updatedAt;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['name'] = name;
    hydraOut['available'] = available;
    hydraOut['state'] = state;
    hydraOut['health'] = health;
    hydraOut['updatedAt'] = updatedAt;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraCameraCapture {
  const HydraCameraCapture({
    required this.success,
    required this.cameraId,
    required this.filename,
    this.capturedAt,
    this.sizeBytes,
    this.startedAt,
    this.stoppedAt,
  });

  factory HydraCameraCapture.fromJson(Map<String, dynamic> json) => HydraCameraCapture(
        success: json['success'] as bool,
        cameraId: (json['cameraId'] as num).toInt(),
        filename: json['filename'] as String,
        capturedAt: json['capturedAt'] == null ? null : json['capturedAt'] as String,
        sizeBytes: json['sizeBytes'] == null ? null : (json['sizeBytes'] as num).toInt(),
        startedAt: json['startedAt'] == null ? null : json['startedAt'] as String,
        stoppedAt: json['stoppedAt'] == null ? null : json['stoppedAt'] as String,
      );

  final bool success;
  final int cameraId;
  final String filename;
  final String? capturedAt;
  final int? sizeBytes;
  final String? startedAt;
  final String? stoppedAt;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['cameraId'] = cameraId;
    hydraOut['filename'] = filename;
    final hydraField3 = capturedAt;
    if (hydraField3 != null) hydraOut['capturedAt'] = hydraField3;
    final hydraField4 = sizeBytes;
    if (hydraField4 != null) hydraOut['sizeBytes'] = hydraField4;
    final hydraField5 = startedAt;
    if (hydraField5 != null) hydraOut['startedAt'] = hydraField5;
    final hydraField6 = stoppedAt;
    if (hydraField6 != null) hydraOut['stoppedAt'] = hydraField6;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraCameraMediaList {
  const HydraCameraMediaList({
    required this.items,
  });

  factory HydraCameraMediaList.fromJson(Map<String, dynamic> json) => HydraCameraMediaList(
        items: (json['items'] as List).map((v0) => HydraCameraMediaListItemsItem.fromJson(_hydraMap(v0))).toList(),
      );

  final List<HydraCameraMediaListItemsItem> items;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['items'] = items.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraCameraMediaListItemsItem {
  const HydraCameraMediaListItemsItem({
    required this.cameraId,
    required this.kind,
    required this.filename,
    required this.sizeBytes,
    required this.capturedAt,
    required this.recording,
    this.durationMs,
    this.frameCount,
  });

  factory HydraCameraMediaListItemsItem.fromJson(Map<String, dynamic> json) => HydraCameraMediaListItemsItem(
        cameraId: (json['cameraId'] as num).toInt(),
        kind: json['kind'] as String,
        filename: json['filename'] as String,
        sizeBytes: (json['sizeBytes'] as num).toInt(),
        capturedAt: json['capturedAt'] as String,
        recording: json['recording'] as bool,
        durationMs: json['durationMs'] == null ? null : (json['durationMs'] as num).toInt(),
        frameCount: json['frameCount'] == null ? null : (json['frameCount'] as num).toInt(),
      );

  final int cameraId;
  final String kind;
  final String filename;
  final int sizeBytes;
  final String capturedAt;
  final bool recording;
  final int? durationMs;
  final int? frameCount;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['cameraId'] = cameraId;
    hydraOut['kind'] = kind;
    hydraOut['filename'] = filename;
    hydraOut['sizeBytes'] = sizeBytes;
    hydraOut['capturedAt'] = capturedAt;
    hydraOut['recording'] = recording;
    final hydraField6 = durationMs;
    if (hydraField6 != null) hydraOut['durationMs'] = hydraField6;
    final hydraField7 = frameCount;
    if (hydraField7 != null) hydraOut['frameCount'] = hydraField7;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraCameraProcessStatusValue {
  const HydraCameraProcessStatusValue({
    required this.status,
    required this.lastError,
    required this.port,
  });

  factory HydraCameraProcessStatusValue.fromJson(Map<String, dynamic> json) => HydraCameraProcessStatusValue(
        status: json['status'] as String,
        lastError: json['lastError'] == null ? null : json['lastError'] as String,
        port: (json['port'] as num).toInt(),
      );

  final String status;
  final String? lastError;
  final int port;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['status'] = status;
    hydraOut['lastError'] = lastError;
    hydraOut['port'] = port;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraCanotaFlash {
  const HydraCanotaFlash({
    required this.success,
    required this.finalPhase,
  });

  factory HydraCanotaFlash.fromJson(Map<String, dynamic> json) => HydraCanotaFlash(
        success: json['success'] as bool,
        finalPhase: json['finalPhase'] as String,
      );

  final bool success;
  final String finalPhase;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['finalPhase'] = finalPhase;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraClaimList {
  const HydraClaimList({
    required this.claims,
  });

  factory HydraClaimList.fromJson(Map<String, dynamic> json) => HydraClaimList(
        claims: (json['claims'] as List).map((v0) => HydraClaimView.fromJson(_hydraMap(v0))).toList(),
      );

  final List<HydraClaimView> claims;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['claims'] = claims.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// One robot that has an active claim: who holds it, from which controller, until when and until when its jog is armed.
class HydraClaimView {
  const HydraClaimView({
    required this.robotId,
    this.robotName,
    this.cellId,
    this.ownerId,
    required this.ownerUsername,
    this.controllerId,
    required this.claimedAt,
    required this.expiresAt,
    this.jogArmedUntil,
  });

  factory HydraClaimView.fromJson(Map<String, dynamic> json) => HydraClaimView(
        robotId: (json['robotId'] as num).toInt(),
        robotName: json['robotName'] == null ? null : json['robotName'] as String,
        cellId: json['cellId'],
        ownerId: json['ownerId'],
        ownerUsername: json['ownerUsername'] as String,
        controllerId: json['controllerId'] == null ? null : json['controllerId'] as String,
        claimedAt: json['claimedAt'] as num,
        expiresAt: json['expiresAt'] as num,
        jogArmedUntil: json['jogArmedUntil'] == null ? null : json['jogArmedUntil'] as num,
      );

  final int robotId;
  final String? robotName;
  /// The id of the controller the robot belongs to (any JSON value; the server does not fix its type).
  final dynamic cellId;
  /// The id of the account that holds the claim (any JSON value).
  final dynamic ownerId;
  final String ownerUsername;
  final String? controllerId;
  /// Milliseconds since the epoch.
  final num claimedAt;
  /// Milliseconds since the epoch.
  final num expiresAt;
  /// Milliseconds since the epoch; null when the jog is not armed.
  final num? jogArmedUntil;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['robotId'] = robotId;
    final hydraField1 = robotName;
    if (hydraField1 != null) hydraOut['robotName'] = hydraField1;
    final hydraField2 = cellId;
    if (hydraField2 != null) hydraOut['cellId'] = hydraField2;
    final hydraField3 = ownerId;
    if (hydraField3 != null) hydraOut['ownerId'] = hydraField3;
    hydraOut['ownerUsername'] = ownerUsername;
    final hydraField5 = controllerId;
    if (hydraField5 != null) hydraOut['controllerId'] = hydraField5;
    hydraOut['claimedAt'] = claimedAt;
    hydraOut['expiresAt'] = expiresAt;
    final hydraField8 = jogArmedUntil;
    if (hydraField8 != null) hydraOut['jogArmedUntil'] = hydraField8;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraClients {
  const HydraClients({
    required this.clients,
  });

  factory HydraClients.fromJson(Map<String, dynamic> json) => HydraClients(
        clients: (json['clients'] as List).map((v0) => _hydraMap(v0)).toList(),
      );

  final List<Map<String, dynamic>> clients;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['clients'] = clients;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraConnectionClient {
  const HydraConnectionClient({
    required this.schemaVersion,
    required this.id,
    required this.kind,
    this.user,
    this.appVersion,
    this.origin,
    this.twoFactor,
    required this.firstSeenUtc,
    required this.lastSeenUtc,
    this.lastFailureUtc,
    required this.activeSessions,
    required this.loginsOk,
    required this.loginsFailed,
    this.ip,
    this.agent,
  });

  factory HydraConnectionClient.fromJson(Map<String, dynamic> json) => HydraConnectionClient(
        schemaVersion: json['schema_version'] as String,
        id: json['id'] as String,
        kind: json['kind'] as String,
        user: json['user'] == null ? null : json['user'] as String,
        appVersion: json['app_version'] == null ? null : json['app_version'] as String,
        origin: json['origin'] == null ? null : json['origin'] as String,
        twoFactor: json['two_factor'] == null ? null : json['two_factor'] as bool,
        firstSeenUtc: json['first_seen_utc'] as String,
        lastSeenUtc: json['last_seen_utc'] as String,
        lastFailureUtc: json['last_failure_utc'] == null ? null : json['last_failure_utc'] as String,
        activeSessions: (json['active_sessions'] as num).toInt(),
        loginsOk: (json['logins_ok'] as num).toInt(),
        loginsFailed: (json['logins_failed'] as num).toInt(),
        ip: json['ip'] == null ? null : json['ip'] as String,
        agent: json['agent'] == null ? null : json['agent'] as String,
      );

  final String schemaVersion;
  final String id;
  final String kind;
  final String? user;
  final String? appVersion;
  final String? origin;
  final bool? twoFactor;
  final String firstSeenUtc;
  final String lastSeenUtc;
  final String? lastFailureUtc;
  final int activeSessions;
  final int loginsOk;
  final int loginsFailed;
  /// Administrators only, and only when connections.recordAddress is on.
  final String? ip;
  /// Administrators only, and only when connections.recordAddress is on.
  final String? agent;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['schema_version'] = schemaVersion;
    hydraOut['id'] = id;
    hydraOut['kind'] = kind;
    final hydraField3 = user;
    if (hydraField3 != null) hydraOut['user'] = hydraField3;
    final hydraField4 = appVersion;
    if (hydraField4 != null) hydraOut['app_version'] = hydraField4;
    final hydraField5 = origin;
    if (hydraField5 != null) hydraOut['origin'] = hydraField5;
    final hydraField6 = twoFactor;
    if (hydraField6 != null) hydraOut['two_factor'] = hydraField6;
    hydraOut['first_seen_utc'] = firstSeenUtc;
    hydraOut['last_seen_utc'] = lastSeenUtc;
    final hydraField9 = lastFailureUtc;
    if (hydraField9 != null) hydraOut['last_failure_utc'] = hydraField9;
    hydraOut['active_sessions'] = activeSessions;
    hydraOut['logins_ok'] = loginsOk;
    hydraOut['logins_failed'] = loginsFailed;
    final hydraField13 = ip;
    if (hydraField13 != null) hydraOut['ip'] = hydraField13;
    final hydraField14 = agent;
    if (hydraField14 != null) hydraOut['agent'] = hydraField14;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraConnectionClientList {
  const HydraConnectionClientList({
    required this.clients,
  });

  factory HydraConnectionClientList.fromJson(Map<String, dynamic> json) => HydraConnectionClientList(
        clients: (json['clients'] as List).map((v0) => HydraConnectionClient.fromJson(_hydraMap(v0))).toList(),
      );

  final List<HydraConnectionClient> clients;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['clients'] = clients.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraConnectionEvent {
  const HydraConnectionEvent({
    required this.schemaVersion,
    required this.id,
    required this.atUtc,
    required this.action,
    required this.clientKind,
    required this.clientId,
    this.user,
    this.origin,
    this.twoFactor,
    this.appVersion,
    this.ip,
    this.agent,
  });

  factory HydraConnectionEvent.fromJson(Map<String, dynamic> json) => HydraConnectionEvent(
        schemaVersion: json['schema_version'] as String,
        id: (json['id'] as num).toInt(),
        atUtc: json['at_utc'] as String,
        action: json['action'] as String,
        clientKind: json['client_kind'] as String,
        clientId: json['client_id'] as String,
        user: json['user'] == null ? null : json['user'] as String,
        origin: json['origin'] == null ? null : json['origin'] as String,
        twoFactor: json['two_factor'] == null ? null : json['two_factor'] as bool,
        appVersion: json['app_version'] == null ? null : json['app_version'] as String,
        ip: json['ip'] == null ? null : json['ip'] as String,
        agent: json['agent'] == null ? null : json['agent'] as String,
      );

  final String schemaVersion;
  final int id;
  final String atUtc;
  final String action;
  final String clientKind;
  final String clientId;
  final String? user;
  final String? origin;
  final bool? twoFactor;
  final String? appVersion;
  /// Administrators only, and only when connections.recordAddress is on.
  final String? ip;
  /// Administrators only, and only when connections.recordAddress is on.
  final String? agent;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['schema_version'] = schemaVersion;
    hydraOut['id'] = id;
    hydraOut['at_utc'] = atUtc;
    hydraOut['action'] = action;
    hydraOut['client_kind'] = clientKind;
    hydraOut['client_id'] = clientId;
    final hydraField6 = user;
    if (hydraField6 != null) hydraOut['user'] = hydraField6;
    final hydraField7 = origin;
    if (hydraField7 != null) hydraOut['origin'] = hydraField7;
    final hydraField8 = twoFactor;
    if (hydraField8 != null) hydraOut['two_factor'] = hydraField8;
    final hydraField9 = appVersion;
    if (hydraField9 != null) hydraOut['app_version'] = hydraField9;
    final hydraField10 = ip;
    if (hydraField10 != null) hydraOut['ip'] = hydraField10;
    final hydraField11 = agent;
    if (hydraField11 != null) hydraOut['agent'] = hydraField11;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraConnectionEventList {
  const HydraConnectionEventList({
    required this.events,
  });

  factory HydraConnectionEventList.fromJson(Map<String, dynamic> json) => HydraConnectionEventList(
        events: (json['events'] as List).map((v0) => HydraConnectionEvent.fromJson(_hydraMap(v0))).toList(),
      );

  final List<HydraConnectionEvent> events;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['events'] = events.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// A device token just issued. The token is in this answer and nowhere else: the server does not keep it.
class HydraDeviceTokenIssued {
  const HydraDeviceTokenIssued({
    required this.id,
    required this.name,
    required this.username,
    required this.createdAt,
    required this.expiresAt,
    required this.revokedAt,
    required this.lastUsedAt,
    required this.state,
    required this.token,
  });

  factory HydraDeviceTokenIssued.fromJson(Map<String, dynamic> json) => HydraDeviceTokenIssued(
        id: json['id'] as String,
        name: json['name'] as String,
        username: json['username'] as String,
        createdAt: json['createdAt'] as String,
        expiresAt: json['expiresAt'] as String,
        revokedAt: json['revokedAt'] == null ? null : json['revokedAt'] as String,
        lastUsedAt: json['lastUsedAt'] == null ? null : json['lastUsedAt'] as String,
        state: json['state'] as String,
        token: json['token'] as String,
      );

  /// The id of the token (22 URL-safe characters); the token itself is never kept.
  final String id;
  /// What the administrator called the device.
  final String name;
  /// The account the device signs in as.
  final String username;
  final String createdAt;
  final String expiresAt;
  final String? revokedAt;
  final String? lastUsedAt;
  final String state;
  /// Signed token of one device; the device presents it on POST /api/device/login.
  final String token;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['id'] = id;
    hydraOut['name'] = name;
    hydraOut['username'] = username;
    hydraOut['createdAt'] = createdAt;
    hydraOut['expiresAt'] = expiresAt;
    hydraOut['revokedAt'] = revokedAt;
    hydraOut['lastUsedAt'] = lastUsedAt;
    hydraOut['state'] = state;
    hydraOut['token'] = token;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraDeviceTokenList {
  const HydraDeviceTokenList({
    required this.items,
  });

  factory HydraDeviceTokenList.fromJson(Map<String, dynamic> json) => HydraDeviceTokenList(
        items: (json['items'] as List).map((v0) => HydraDeviceTokenView.fromJson(_hydraMap(v0))).toList(),
      );

  final List<HydraDeviceTokenView> items;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['items'] = items.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraDeviceTokenRevoked {
  const HydraDeviceTokenRevoked({
    required this.revoked,
    required this.sessionsEnded,
  });

  factory HydraDeviceTokenRevoked.fromJson(Map<String, dynamic> json) => HydraDeviceTokenRevoked(
        revoked: json['revoked'] as bool,
        sessionsEnded: (json['sessionsEnded'] as num).toInt(),
      );

  final bool revoked;
  final int sessionsEnded;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['revoked'] = revoked;
    hydraOut['sessionsEnded'] = sessionsEnded;
    return hydraOut;
  }
}

/// A device token as the administrator sees it: who it is for and until when, never the token.
class HydraDeviceTokenView {
  const HydraDeviceTokenView({
    required this.id,
    required this.name,
    required this.username,
    required this.createdAt,
    required this.expiresAt,
    required this.revokedAt,
    required this.lastUsedAt,
    required this.state,
  });

  factory HydraDeviceTokenView.fromJson(Map<String, dynamic> json) => HydraDeviceTokenView(
        id: json['id'] as String,
        name: json['name'] as String,
        username: json['username'] as String,
        createdAt: json['createdAt'] as String,
        expiresAt: json['expiresAt'] as String,
        revokedAt: json['revokedAt'] == null ? null : json['revokedAt'] as String,
        lastUsedAt: json['lastUsedAt'] == null ? null : json['lastUsedAt'] as String,
        state: json['state'] as String,
      );

  /// The id of the token (22 URL-safe characters); the token itself is never kept.
  final String id;
  /// What the administrator called the device.
  final String name;
  /// The account the device signs in as.
  final String username;
  final String createdAt;
  final String expiresAt;
  final String? revokedAt;
  final String? lastUsedAt;
  final String state;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['id'] = id;
    hydraOut['name'] = name;
    hydraOut['username'] = username;
    hydraOut['createdAt'] = createdAt;
    hydraOut['expiresAt'] = expiresAt;
    hydraOut['revokedAt'] = revokedAt;
    hydraOut['lastUsedAt'] = lastUsedAt;
    hydraOut['state'] = state;
    return hydraOut;
  }
}

/// The health of the services of the ecosystem. Only on a server where ecosystemHealth.enabled is on (404 otherwise); for an operator or an administrator. The port, health path, unit and active state of a service are only in the answer to an administrator.
class HydraEcosystemHealth {
  const HydraEcosystemHealth({
    required this.schemaVersion,
    required this.generatedAtUtc,
    required this.available,
    required this.summary,
    required this.services,
    required this.certificate,
    required this.warnings,
  });

  factory HydraEcosystemHealth.fromJson(Map<String, dynamic> json) => HydraEcosystemHealth(
        schemaVersion: json['schema_version'] as String,
        generatedAtUtc: json['generated_at_utc'] as String,
        available: json['available'] as bool,
        summary: HydraEcosystemHealthSummary.fromJson(_hydraMap(json['summary'])),
        services: (json['services'] as List).map((v0) => HydraEcosystemHealthServicesItem.fromJson(_hydraMap(v0))).toList(),
        certificate: json['certificate'] == null ? null : HydraEcosystemHealthCertificate.fromJson(_hydraMap(json['certificate'])),
        warnings: (json['warnings'] as List).map((v0) => HydraEcosystemHealthWarningsItem.fromJson(_hydraMap(v0))).toList(),
      );

  final String schemaVersion;
  final String generatedAtUtc;
  /// False when the sibling checkouts could not be scanned (no services then).
  final bool available;
  final HydraEcosystemHealthSummary summary;
  final List<HydraEcosystemHealthServicesItem> services;
  /// The TLS certificate of this server; null when it runs without TLS. state is ok, expiring (fewer days left than warn_days), expired or unreadable.
  final HydraEcosystemHealthCertificate? certificate;
  final List<HydraEcosystemHealthWarningsItem> warnings;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['schema_version'] = schemaVersion;
    hydraOut['generated_at_utc'] = generatedAtUtc;
    hydraOut['available'] = available;
    hydraOut['summary'] = summary.toJson();
    hydraOut['services'] = services.map((v0) => v0.toJson()).toList();
    hydraOut['certificate'] = certificate?.toJson();
    hydraOut['warnings'] = warnings.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// The TLS certificate of this server; null when it runs without TLS. state is ok, expiring (fewer days left than warn_days), expired or unreadable.
class HydraEcosystemHealthCertificate {
  const HydraEcosystemHealthCertificate({
    this.state,
    this.notAfterUtc,
    this.daysLeft,
    this.warnDays,
  });

  factory HydraEcosystemHealthCertificate.fromJson(Map<String, dynamic> json) => HydraEcosystemHealthCertificate(
        state: json['state'] == null ? null : json['state'] as String,
        notAfterUtc: json['not_after_utc'] == null ? null : json['not_after_utc'] as String,
        daysLeft: json['days_left'] == null ? null : (json['days_left'] as num).toInt(),
        warnDays: json['warn_days'] == null ? null : (json['warn_days'] as num).toInt(),
      );

  final String? state;
  final String? notAfterUtc;
  final int? daysLeft;
  final int? warnDays;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = state;
    if (hydraField0 != null) hydraOut['state'] = hydraField0;
    final hydraField1 = notAfterUtc;
    if (hydraField1 != null) hydraOut['not_after_utc'] = hydraField1;
    final hydraField2 = daysLeft;
    if (hydraField2 != null) hydraOut['days_left'] = hydraField2;
    final hydraField3 = warnDays;
    if (hydraField3 != null) hydraOut['warn_days'] = hydraField3;
    return hydraOut;
  }
}

/// state is ok, degraded, down or unknown; reason is a short code the clients translate. version_expected comes from the manifest, version_reported from the HealthReport of the service; drift is true only when both are known and differ.
class HydraEcosystemHealthServicesItem {
  const HydraEcosystemHealthServicesItem({
    required this.name,
    required this.family,
    required this.role,
    required this.state,
    required this.reason,
    required this.versionExpected,
    required this.versionReported,
    required this.drift,
    required this.lastSeenUtc,
    required this.latencyMs,
    this.port,
    this.healthPath,
    this.systemdUnit,
    this.activeState,
  });

  factory HydraEcosystemHealthServicesItem.fromJson(Map<String, dynamic> json) => HydraEcosystemHealthServicesItem(
        name: json['name'] as String,
        family: json['family'] == null ? null : json['family'] as String,
        role: json['role'] == null ? null : json['role'] as String,
        state: json['state'] as String,
        reason: json['reason'] as String,
        versionExpected: json['version_expected'] == null ? null : json['version_expected'] as String,
        versionReported: json['version_reported'] == null ? null : json['version_reported'] as String,
        drift: json['drift'] as bool,
        lastSeenUtc: json['last_seen_utc'] == null ? null : json['last_seen_utc'] as String,
        latencyMs: json['latency_ms'] == null ? null : (json['latency_ms'] as num).toInt(),
        port: json['port'] == null ? null : (json['port'] as num).toInt(),
        healthPath: json['health_path'] == null ? null : json['health_path'] as String,
        systemdUnit: json['systemd_unit'] == null ? null : json['systemd_unit'] as String,
        activeState: json['active_state'] == null ? null : json['active_state'] as String,
      );

  final String name;
  final String? family;
  final String? role;
  final String state;
  final String reason;
  final String? versionExpected;
  final String? versionReported;
  final bool drift;
  final String? lastSeenUtc;
  final int? latencyMs;
  /// Administrators only.
  final int? port;
  /// Administrators only.
  final String? healthPath;
  /// Administrators only.
  final String? systemdUnit;
  /// Administrators only.
  final String? activeState;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['name'] = name;
    hydraOut['family'] = family;
    hydraOut['role'] = role;
    hydraOut['state'] = state;
    hydraOut['reason'] = reason;
    hydraOut['version_expected'] = versionExpected;
    hydraOut['version_reported'] = versionReported;
    hydraOut['drift'] = drift;
    hydraOut['last_seen_utc'] = lastSeenUtc;
    hydraOut['latency_ms'] = latencyMs;
    final hydraField10 = port;
    if (hydraField10 != null) hydraOut['port'] = hydraField10;
    final hydraField11 = healthPath;
    if (hydraField11 != null) hydraOut['health_path'] = hydraField11;
    final hydraField12 = systemdUnit;
    if (hydraField12 != null) hydraOut['systemd_unit'] = hydraField12;
    final hydraField13 = activeState;
    if (hydraField13 != null) hydraOut['active_state'] = hydraField13;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraEcosystemHealthSummary {
  const HydraEcosystemHealthSummary({
    required this.total,
    required this.ok,
    required this.degraded,
    required this.down,
    required this.unknown,
    required this.drift,
  });

  factory HydraEcosystemHealthSummary.fromJson(Map<String, dynamic> json) => HydraEcosystemHealthSummary(
        total: (json['total'] as num).toInt(),
        ok: (json['ok'] as num).toInt(),
        degraded: (json['degraded'] as num).toInt(),
        down: (json['down'] as num).toInt(),
        unknown: (json['unknown'] as num).toInt(),
        drift: (json['drift'] as num).toInt(),
      );

  final int total;
  final int ok;
  final int degraded;
  final int down;
  final int unknown;
  final int drift;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['total'] = total;
    hydraOut['ok'] = ok;
    hydraOut['degraded'] = degraded;
    hydraOut['down'] = down;
    hydraOut['unknown'] = unknown;
    hydraOut['drift'] = drift;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraEcosystemHealthWarningsItem {
  const HydraEcosystemHealthWarningsItem({
    required this.code,
    this.service,
  });

  factory HydraEcosystemHealthWarningsItem.fromJson(Map<String, dynamic> json) => HydraEcosystemHealthWarningsItem(
        code: json['code'] as String,
        service: json['service'] == null ? null : json['service'] as String,
      );

  final String code;
  final String? service;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['code'] = code;
    final hydraField1 = service;
    if (hydraField1 != null) hydraOut['service'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraEcosystemStatus {
  const HydraEcosystemStatus({
    required this.available,
    required this.scannedAt,
    required this.projects,
  });

  factory HydraEcosystemStatus.fromJson(Map<String, dynamic> json) => HydraEcosystemStatus(
        available: json['available'] as bool,
        scannedAt: json['scannedAt'] as String,
        projects: (json['projects'] as List).map((v0) => HydraEcosystemStatusProjectsItem.fromJson(_hydraMap(v0))).toList(),
      );

  final bool available;
  final String scannedAt;
  final List<HydraEcosystemStatusProjectsItem> projects;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['available'] = available;
    hydraOut['scannedAt'] = scannedAt;
    hydraOut['projects'] = projects.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraEcosystemStatusProjectsItem {
  const HydraEcosystemStatusProjectsItem({
    required this.name,
    this.role,
    this.stack,
    this.maturity,
    this.family,
    this.version,
    this.deploymentTarget,
    this.servicePort,
    this.serviceHealthPath,
    this.serviceHost,
    this.systemdUnit,
    this.pid,
    this.activeState,
    this.subState,
    this.live,
  });

  factory HydraEcosystemStatusProjectsItem.fromJson(Map<String, dynamic> json) => HydraEcosystemStatusProjectsItem(
        name: json['name'] as String,
        role: json['role'] == null ? null : json['role'] as String,
        stack: json['stack'] == null ? null : json['stack'] as String,
        maturity: json['maturity'] == null ? null : json['maturity'] as String,
        family: json['family'] == null ? null : json['family'] as String,
        version: json['version'] == null ? null : json['version'] as String,
        deploymentTarget: json['deploymentTarget'] == null ? null : json['deploymentTarget'] as String,
        servicePort: json['servicePort'] == null ? null : (json['servicePort'] as num).toInt(),
        serviceHealthPath: json['serviceHealthPath'] == null ? null : json['serviceHealthPath'] as String,
        serviceHost: json['serviceHost'] == null ? null : json['serviceHost'] as String,
        systemdUnit: json['systemdUnit'] == null ? null : json['systemdUnit'] as String,
        pid: json['pid'] == null ? null : (json['pid'] as num).toInt(),
        activeState: json['activeState'] == null ? null : json['activeState'] as String,
        subState: json['subState'] == null ? null : json['subState'] as String,
        live: json['live'] == null ? null : json['live'] as bool,
      );

  final String name;
  final String? role;
  final String? stack;
  final String? maturity;
  final String? family;
  final String? version;
  final String? deploymentTarget;
  final int? servicePort;
  final String? serviceHealthPath;
  final String? serviceHost;
  final String? systemdUnit;
  final int? pid;
  final String? activeState;
  final String? subState;
  final bool? live;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['name'] = name;
    final hydraField1 = role;
    if (hydraField1 != null) hydraOut['role'] = hydraField1;
    final hydraField2 = stack;
    if (hydraField2 != null) hydraOut['stack'] = hydraField2;
    final hydraField3 = maturity;
    if (hydraField3 != null) hydraOut['maturity'] = hydraField3;
    final hydraField4 = family;
    if (hydraField4 != null) hydraOut['family'] = hydraField4;
    final hydraField5 = version;
    if (hydraField5 != null) hydraOut['version'] = hydraField5;
    final hydraField6 = deploymentTarget;
    if (hydraField6 != null) hydraOut['deploymentTarget'] = hydraField6;
    final hydraField7 = servicePort;
    if (hydraField7 != null) hydraOut['servicePort'] = hydraField7;
    final hydraField8 = serviceHealthPath;
    if (hydraField8 != null) hydraOut['serviceHealthPath'] = hydraField8;
    final hydraField9 = serviceHost;
    if (hydraField9 != null) hydraOut['serviceHost'] = hydraField9;
    final hydraField10 = systemdUnit;
    if (hydraField10 != null) hydraOut['systemdUnit'] = hydraField10;
    final hydraField11 = pid;
    if (hydraField11 != null) hydraOut['pid'] = hydraField11;
    final hydraField12 = activeState;
    if (hydraField12 != null) hydraOut['activeState'] = hydraField12;
    final hydraField13 = subState;
    if (hydraField13 != null) hydraOut['subState'] = hydraField13;
    final hydraField14 = live;
    if (hydraField14 != null) hydraOut['live'] = hydraField14;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraError {
  const HydraError({
    required this.error,
  });

  factory HydraError.fromJson(Map<String, dynamic> json) => HydraError(
        error: json['error'] as String,
      );

  final String error;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['error'] = error;
    return hydraOut;
  }
}

/// The progress file of tools/fleet_update.py (hydra-fleet-update/1). A run whose heartbeat stopped is reported as interrupted.
class HydraFleetUpdateReport {
  const HydraFleetUpdateReport({
    required this.schema,
    required this.id,
    required this.mode,
    required this.state,
    required this.startedAt,
    required this.updatedAt,
    required this.error,
    required this.stoppedAt,
    required this.requireSignedTags,
    required this.disk,
    required this.services,
  });

  factory HydraFleetUpdateReport.fromJson(Map<String, dynamic> json) => HydraFleetUpdateReport(
        schema: json['schema'] as String,
        id: json['id'] as String,
        mode: json['mode'] as String,
        state: json['state'] as String,
        startedAt: json['startedAt'] as String,
        updatedAt: json['updatedAt'] as String,
        error: json['error'] as String,
        stoppedAt: json['stoppedAt'] as String,
        requireSignedTags: json['requireSignedTags'] as bool,
        disk: HydraFleetUpdateReportDisk.fromJson(_hydraMap(json['disk'])),
        services: (json['services'] as List).map((v0) => HydraFleetUpdateRow.fromJson(_hydraMap(v0))).toList(),
      );

  final String schema;
  final String id;
  final String mode;
  final String state;
  final String startedAt;
  final String updatedAt;
  final String error;
  final String stoppedAt;
  final bool requireSignedTags;
  final HydraFleetUpdateReportDisk disk;
  final List<HydraFleetUpdateRow> services;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['schema'] = schema;
    hydraOut['id'] = id;
    hydraOut['mode'] = mode;
    hydraOut['state'] = state;
    hydraOut['startedAt'] = startedAt;
    hydraOut['updatedAt'] = updatedAt;
    hydraOut['error'] = error;
    hydraOut['stoppedAt'] = stoppedAt;
    hydraOut['requireSignedTags'] = requireSignedTags;
    hydraOut['disk'] = disk.toJson();
    hydraOut['services'] = services.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraFleetUpdateReportDisk {
  const HydraFleetUpdateReportDisk({
    required this.rootFreeMb,
    required this.workspaceFreeMb,
  });

  factory HydraFleetUpdateReportDisk.fromJson(Map<String, dynamic> json) => HydraFleetUpdateReportDisk(
        rootFreeMb: json['rootFreeMb'] == null ? null : (json['rootFreeMb'] as num).toInt(),
        workspaceFreeMb: json['workspaceFreeMb'] == null ? null : (json['workspaceFreeMb'] as num).toInt(),
      );

  final int? rootFreeMb;
  final int? workspaceFreeMb;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['rootFreeMb'] = rootFreeMb;
    hydraOut['workspaceFreeMb'] = workspaceFreeMb;
    return hydraOut;
  }
}

/// One program of the device in the update of everything installed: its versions, what the plan does with it and where its steps are.
class HydraFleetUpdateRow {
  const HydraFleetUpdateRow({
    required this.name,
    required this.kind,
    required this.repo,
    required this.installed,
    required this.latest,
    required this.action,
    required this.reason,
    required this.state,
    required this.step,
    this.substep,
    this.substeps,
    required this.detail,
    required this.error,
    required this.order,
    this.elapsedS,
    this.freeMb,
    this.needMb,
    this.unitRestored,
    required this.log,
  });

  factory HydraFleetUpdateRow.fromJson(Map<String, dynamic> json) => HydraFleetUpdateRow(
        name: json['name'] as String,
        kind: json['kind'] as String,
        repo: json['repo'] as String,
        installed: json['installed'] == null ? null : json['installed'] as String,
        latest: json['latest'] == null ? null : json['latest'] as String,
        action: json['action'] as String,
        reason: json['reason'] as String,
        state: json['state'] as String,
        step: json['step'] as String,
        substep: json['substep'] == null ? null : json['substep'] as String,
        substeps: json['substeps'] == null ? null : (json['substeps'] as num).toInt(),
        detail: json['detail'] as String,
        error: json['error'] as String,
        order: (json['order'] as num).toInt(),
        elapsedS: json['elapsedS'] == null ? null : (json['elapsedS'] as num).toInt(),
        freeMb: json['freeMb'] == null ? null : (json['freeMb'] as num).toInt(),
        needMb: json['needMb'] == null ? null : (json['needMb'] as num).toInt(),
        unitRestored: json['unitRestored'] == null ? null : json['unitRestored'] as bool,
        log: (json['log'] as List).map((v0) => HydraFleetUpdateRowLogItem.fromJson(_hydraMap(v0))).toList(),
      );

  final String name;
  final String kind;
  final String repo;
  final String? installed;
  final String? latest;
  final String action;
  final String reason;
  final String state;
  final String step;
  final String? substep;
  final int? substeps;
  final String detail;
  final String error;
  final int order;
  final int? elapsedS;
  final int? freeMb;
  final int? needMb;
  final bool? unitRestored;
  final List<HydraFleetUpdateRowLogItem> log;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['name'] = name;
    hydraOut['kind'] = kind;
    hydraOut['repo'] = repo;
    hydraOut['installed'] = installed;
    hydraOut['latest'] = latest;
    hydraOut['action'] = action;
    hydraOut['reason'] = reason;
    hydraOut['state'] = state;
    hydraOut['step'] = step;
    final hydraField9 = substep;
    if (hydraField9 != null) hydraOut['substep'] = hydraField9;
    final hydraField10 = substeps;
    if (hydraField10 != null) hydraOut['substeps'] = hydraField10;
    hydraOut['detail'] = detail;
    hydraOut['error'] = error;
    hydraOut['order'] = order;
    final hydraField14 = elapsedS;
    if (hydraField14 != null) hydraOut['elapsedS'] = hydraField14;
    final hydraField15 = freeMb;
    if (hydraField15 != null) hydraOut['freeMb'] = hydraField15;
    final hydraField16 = needMb;
    if (hydraField16 != null) hydraOut['needMb'] = hydraField16;
    final hydraField17 = unitRestored;
    if (hydraField17 != null) hydraOut['unitRestored'] = hydraField17;
    hydraOut['log'] = log.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraFleetUpdateRowLogItem {
  const HydraFleetUpdateRowLogItem({
    required this.at,
    required this.text,
  });

  factory HydraFleetUpdateRowLogItem.fromJson(Map<String, dynamic> json) => HydraFleetUpdateRowLogItem(
        at: json['at'] as String,
        text: json['text'] as String,
      );

  final String at;
  final String text;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['at'] = at;
    hydraOut['text'] = text;
    return hydraOut;
  }
}

/// Whether applying is switched on, whether a look or a run is going on, and the progress file (null before the first look).
class HydraFleetUpdateStatus {
  const HydraFleetUpdateStatus({
    required this.applyEnabled,
    required this.busy,
    required this.report,
  });

  factory HydraFleetUpdateStatus.fromJson(Map<String, dynamic> json) => HydraFleetUpdateStatus(
        applyEnabled: json['applyEnabled'] as bool,
        busy: json['busy'] as bool,
        report: json['report'] == null ? null : HydraFleetUpdateReport.fromJson(_hydraMap(json['report'])),
      );

  final bool applyEnabled;
  final bool busy;
  final HydraFleetUpdateReport? report;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['applyEnabled'] = applyEnabled;
    hydraOut['busy'] = busy;
    hydraOut['report'] = report?.toJson();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetAdminRobotIdsResult {
  const HydraGetAdminRobotIdsResult({
    required this.ok,
    required this.ambiguousCount,
    required this.ambiguous,
  });

  factory HydraGetAdminRobotIdsResult.fromJson(Map<String, dynamic> json) => HydraGetAdminRobotIdsResult(
        ok: json['ok'] as bool,
        ambiguousCount: (json['ambiguousCount'] as num).toInt(),
        ambiguous: (json['ambiguous'] as List).map((v0) => HydraGetAdminRobotIdsResultAmbiguousItem.fromJson(_hydraMap(v0))).toList(),
      );

  /// False while at least one robot id is used by more than one robot.
  final bool ok;
  final int ambiguousCount;
  /// The routes by these ids answer 409 robot_id_ambiguous. Controller ids only.
  final List<HydraGetAdminRobotIdsResultAmbiguousItem> ambiguous;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['ok'] = ok;
    hydraOut['ambiguousCount'] = ambiguousCount;
    hydraOut['ambiguous'] = ambiguous.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetAdminRobotIdsResultAmbiguousItem {
  const HydraGetAdminRobotIdsResultAmbiguousItem({
    required this.robotId,
    required this.controllers,
  });

  factory HydraGetAdminRobotIdsResultAmbiguousItem.fromJson(Map<String, dynamic> json) => HydraGetAdminRobotIdsResultAmbiguousItem(
        robotId: (json['robotId'] as num).toInt(),
        controllers: (json['controllers'] as List).map((v0) => v0 as String).toList(),
      );

  final int robotId;
  final List<String> controllers;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['robotId'] = robotId;
    hydraOut['controllers'] = controllers;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetConnectorHubGateSettingsResult {
  const HydraGetConnectorHubGateSettingsResult({
    required this.allowLoopbackNoIdentity,
    this.loopbackSwitchAllowed,
    this.verifiesTokens,
    this.persisted,
  });

  factory HydraGetConnectorHubGateSettingsResult.fromJson(Map<String, dynamic> json) => HydraGetConnectorHubGateSettingsResult(
        allowLoopbackNoIdentity: json['allowLoopbackNoIdentity'] as bool,
        loopbackSwitchAllowed: json['loopbackSwitchAllowed'] == null ? null : json['loopbackSwitchAllowed'] as bool,
        verifiesTokens: json['verifiesTokens'] == null ? null : json['verifiesTokens'] as bool,
        persisted: json['persisted'] == null ? null : json['persisted'] as bool,
      );

  final bool allowLoopbackNoIdentity;
  final bool? loopbackSwitchAllowed;
  final bool? verifiesTokens;
  final bool? persisted;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['allowLoopbackNoIdentity'] = allowLoopbackNoIdentity;
    final hydraField1 = loopbackSwitchAllowed;
    if (hydraField1 != null) hydraOut['loopbackSwitchAllowed'] = hydraField1;
    final hydraField2 = verifiesTokens;
    if (hydraField2 != null) hydraOut['verifiesTokens'] = hydraField2;
    final hydraField3 = persisted;
    if (hydraField3 != null) hydraOut['persisted'] = hydraField3;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetDroidEstopSettingsResult {
  const HydraGetDroidEstopSettingsResult({
    required this.enabled,
    this.running,
  });

  factory HydraGetDroidEstopSettingsResult.fromJson(Map<String, dynamic> json) => HydraGetDroidEstopSettingsResult(
        enabled: json['enabled'] as bool,
        running: json['running'] == null ? null : json['running'] as bool,
      );

  final bool enabled;
  final bool? running;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['enabled'] = enabled;
    final hydraField1 = running;
    if (hydraField1 != null) hydraOut['running'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetHilBridgeSettingsResult {
  const HydraGetHilBridgeSettingsResult({
    required this.requireTwinPass,
    this.locked,
    this.persisted,
    this.ready,
    this.canChange,
  });

  factory HydraGetHilBridgeSettingsResult.fromJson(Map<String, dynamic> json) => HydraGetHilBridgeSettingsResult(
        requireTwinPass: json['requireTwinPass'] as bool,
        locked: json['locked'] == null ? null : json['locked'] as bool,
        persisted: json['persisted'] == null ? null : json['persisted'] as bool,
        ready: json['ready'] == null ? null : json['ready'] as bool,
        canChange: json['canChange'] == null ? null : json['canChange'] as bool,
      );

  final bool requireTwinPass;
  final bool? locked;
  final bool? persisted;
  final bool? ready;
  final bool? canChange;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['requireTwinPass'] = requireTwinPass;
    final hydraField1 = locked;
    if (hydraField1 != null) hydraOut['locked'] = hydraField1;
    final hydraField2 = persisted;
    if (hydraField2 != null) hydraOut['persisted'] = hydraField2;
    final hydraField3 = ready;
    if (hydraField3 != null) hydraOut['ready'] = hydraField3;
    final hydraField4 = canChange;
    if (hydraField4 != null) hydraOut['canChange'] = hydraField4;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetOpsAgentProposalsResult {
  const HydraGetOpsAgentProposalsResult({
    required this.pending,
    this.decided,
  });

  factory HydraGetOpsAgentProposalsResult.fromJson(Map<String, dynamic> json) => HydraGetOpsAgentProposalsResult(
        pending: (json['pending'] as List).map((v0) => _hydraMap(v0)).toList(),
        decided: json['decided'] == null ? null : (json['decided'] as List).map((v0) => _hydraMap(v0)).toList(),
      );

  final List<Map<String, dynamic>> pending;
  final List<Map<String, dynamic>>? decided;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['pending'] = pending;
    final hydraField1 = decided;
    if (hydraField1 != null) hydraOut['decided'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetRobotByIdResult {
  const HydraGetRobotByIdResult({
    required this.robot,
    required this.revision,
    this.cellId,
  });

  factory HydraGetRobotByIdResult.fromJson(Map<String, dynamic> json) => HydraGetRobotByIdResult(
        robot: _hydraMap(json['robot']),
        revision: json['revision'] as String,
        cellId: json['cellId'],
      );

  final Map<String, dynamic> robot;
  final String revision;
  /// The id of the controller the robot belongs to (null when it is in none).
  final dynamic cellId;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['robot'] = robot;
    hydraOut['revision'] = revision;
    final hydraField2 = cellId;
    if (hydraField2 != null) hydraOut['cellId'] = hydraField2;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetRos2BridgeSettingsResult {
  const HydraGetRos2BridgeSettingsResult({
    required this.requireSros2,
    required this.active,
    required this.restartNeeded,
    required this.canChange,
    required this.environmentReady,
  });

  factory HydraGetRos2BridgeSettingsResult.fromJson(Map<String, dynamic> json) => HydraGetRos2BridgeSettingsResult(
        requireSros2: json['requireSros2'] as bool,
        active: json['active'] as bool,
        restartNeeded: json['restartNeeded'] as bool,
        canChange: json['canChange'] as bool,
        environmentReady: json['environmentReady'] as bool,
      );

  final bool requireSros2;
  final bool active;
  final bool restartNeeded;
  final bool canChange;
  final bool environmentReady;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['requireSros2'] = requireSros2;
    hydraOut['active'] = active;
    hydraOut['restartNeeded'] = restartNeeded;
    hydraOut['canChange'] = canChange;
    hydraOut['environmentReady'] = environmentReady;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetSemanticPlannerSettingsResult {
  const HydraGetSemanticPlannerSettingsResult({
    required this.requireIdentity,
    this.verifiesTokens,
    this.persisted,
  });

  factory HydraGetSemanticPlannerSettingsResult.fromJson(Map<String, dynamic> json) => HydraGetSemanticPlannerSettingsResult(
        requireIdentity: json['requireIdentity'] as bool,
        verifiesTokens: json['verifiesTokens'] == null ? null : json['verifiesTokens'] as bool,
        persisted: json['persisted'] == null ? null : json['persisted'] as bool,
      );

  final bool requireIdentity;
  final bool? verifiesTokens;
  final bool? persisted;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['requireIdentity'] = requireIdentity;
    final hydraField1 = verifiesTokens;
    if (hydraField1 != null) hydraOut['verifiesTokens'] = hydraField1;
    final hydraField2 = persisted;
    if (hydraField2 != null) hydraOut['persisted'] = hydraField2;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetTelemetryAggregateResultItem {
  const HydraGetTelemetryAggregateResultItem({
    required this.bucketStart,
    required this.value,
    required this.count,
  });

  factory HydraGetTelemetryAggregateResultItem.fromJson(Map<String, dynamic> json) => HydraGetTelemetryAggregateResultItem(
        bucketStart: json['bucketStart'] as num,
        value: json['value'] as num,
        count: json['count'] as num,
      );

  final num bucketStart;
  final num value;
  final num count;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['bucketStart'] = bucketStart;
    hydraOut['value'] = value;
    hydraOut['count'] = count;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetTelemetryDownsamplePlanResult {
  const HydraGetTelemetryDownsamplePlanResult({
    required this.plan,
    required this.hash,
    this.tiers,
    this.knownKinds,
    this.switches,
    this.audit,
  });

  factory HydraGetTelemetryDownsamplePlanResult.fromJson(Map<String, dynamic> json) => HydraGetTelemetryDownsamplePlanResult(
        plan: HydraGetTelemetryDownsamplePlanResultPlan.fromJson(_hydraMap(json['plan'])),
        hash: json['hash'] as String,
        tiers: json['tiers'] == null ? null : (json['tiers'] as List).map((v0) => _hydraMap(v0)).toList(),
        knownKinds: json['knownKinds'] == null ? null : (json['knownKinds'] as List).map((v0) => v0 as String).toList(),
        switches: json['switches'] == null ? null : HydraGetTelemetryDownsamplePlanResultSwitches.fromJson(_hydraMap(json['switches'])),
        audit: json['audit'] == null ? null : (json['audit'] as List).map((v0) => _hydraMap(v0)).toList(),
      );

  final HydraGetTelemetryDownsamplePlanResultPlan plan;
  final String hash;
  final List<Map<String, dynamic>>? tiers;
  final List<String>? knownKinds;
  final HydraGetTelemetryDownsamplePlanResultSwitches? switches;
  final List<Map<String, dynamic>>? audit;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['plan'] = plan.toJson();
    hydraOut['hash'] = hash;
    final hydraField2 = tiers;
    if (hydraField2 != null) hydraOut['tiers'] = hydraField2;
    final hydraField3 = knownKinds;
    if (hydraField3 != null) hydraOut['knownKinds'] = hydraField3;
    final hydraField4 = switches;
    if (hydraField4 != null) hydraOut['switches'] = hydraField4.toJson();
    final hydraField5 = audit;
    if (hydraField5 != null) hydraOut['audit'] = hydraField5;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetTelemetryDownsamplePlanResultPlan {
  const HydraGetTelemetryDownsamplePlanResultPlan({
    required this.tiers,
    required this.delete,
  });

  factory HydraGetTelemetryDownsamplePlanResultPlan.fromJson(Map<String, dynamic> json) => HydraGetTelemetryDownsamplePlanResultPlan(
        tiers: (json['tiers'] as List).map((v0) => HydraGetTelemetryDownsamplePlanResultPlanTiersItem.fromJson(_hydraMap(v0))).toList(),
        delete: json['delete'] as bool,
      );

  final List<HydraGetTelemetryDownsamplePlanResultPlanTiersItem> tiers;
  final bool delete;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['tiers'] = tiers.map((v0) => v0.toJson()).toList();
    hydraOut['delete'] = delete;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetTelemetryDownsamplePlanResultPlanTiersItem {
  const HydraGetTelemetryDownsamplePlanResultPlanTiersItem({
    required this.kind,
    required this.field,
    this.raw,
    this.bucket,
    this.fineBucket,
    this.rollupRetention,
    this.fineRetention,
  });

  factory HydraGetTelemetryDownsamplePlanResultPlanTiersItem.fromJson(Map<String, dynamic> json) => HydraGetTelemetryDownsamplePlanResultPlanTiersItem(
        kind: json['kind'] as String,
        field: json['field'] as String,
        raw: json['raw'],
        bucket: json['bucket'],
        fineBucket: json['fineBucket'],
        rollupRetention: json['rollupRetention'],
        fineRetention: json['fineRetention'],
      );

  final String kind;
  final String field;
  /// How long raw points are kept: milliseconds or text such as 30d.
  final dynamic raw;
  /// Width of the rollup bucket.
  final dynamic bucket;
  /// Width of the fine rollup bucket.
  final dynamic fineBucket;
  /// How long rollups are kept.
  final dynamic rollupRetention;
  /// How long fine rollups are kept.
  final dynamic fineRetention;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['kind'] = kind;
    hydraOut['field'] = field;
    final hydraField2 = raw;
    if (hydraField2 != null) hydraOut['raw'] = hydraField2;
    final hydraField3 = bucket;
    if (hydraField3 != null) hydraOut['bucket'] = hydraField3;
    final hydraField4 = fineBucket;
    if (hydraField4 != null) hydraOut['fineBucket'] = hydraField4;
    final hydraField5 = rollupRetention;
    if (hydraField5 != null) hydraOut['rollupRetention'] = hydraField5;
    final hydraField6 = fineRetention;
    if (hydraField6 != null) hydraOut['fineRetention'] = hydraField6;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetTelemetryDownsamplePlanResultSwitches {
  const HydraGetTelemetryDownsamplePlanResultSwitches({
    this.allowDelete,
    this.deleteRequestedByPlan,
    this.deleteOldSwitch,
    this.effectiveMode,
    this.fineRollups,
    this.autoIntervalSeconds,
  });

  factory HydraGetTelemetryDownsamplePlanResultSwitches.fromJson(Map<String, dynamic> json) => HydraGetTelemetryDownsamplePlanResultSwitches(
        allowDelete: json['allowDelete'] == null ? null : json['allowDelete'] as bool,
        deleteRequestedByPlan: json['deleteRequestedByPlan'] == null ? null : json['deleteRequestedByPlan'] as bool,
        deleteOldSwitch: json['deleteOldSwitch'] == null ? null : json['deleteOldSwitch'] as bool,
        effectiveMode: json['effectiveMode'] == null ? null : json['effectiveMode'] as String,
        fineRollups: json['fineRollups'] == null ? null : json['fineRollups'] as bool,
        autoIntervalSeconds: json['autoIntervalSeconds'] == null ? null : json['autoIntervalSeconds'] as num,
      );

  final bool? allowDelete;
  final bool? deleteRequestedByPlan;
  final bool? deleteOldSwitch;
  final String? effectiveMode;
  final bool? fineRollups;
  final num? autoIntervalSeconds;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = allowDelete;
    if (hydraField0 != null) hydraOut['allowDelete'] = hydraField0;
    final hydraField1 = deleteRequestedByPlan;
    if (hydraField1 != null) hydraOut['deleteRequestedByPlan'] = hydraField1;
    final hydraField2 = deleteOldSwitch;
    if (hydraField2 != null) hydraOut['deleteOldSwitch'] = hydraField2;
    final hydraField3 = effectiveMode;
    if (hydraField3 != null) hydraOut['effectiveMode'] = hydraField3;
    final hydraField4 = fineRollups;
    if (hydraField4 != null) hydraOut['fineRollups'] = hydraField4;
    final hydraField5 = autoIntervalSeconds;
    if (hydraField5 != null) hydraOut['autoIntervalSeconds'] = hydraField5;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGetTelemetryQueryResultItem {
  const HydraGetTelemetryQueryResultItem({
    required this.sourceId,
    required this.kind,
    required this.field,
    required this.timestamp,
    required this.value,
  });

  factory HydraGetTelemetryQueryResultItem.fromJson(Map<String, dynamic> json) => HydraGetTelemetryQueryResultItem(
        sourceId: json['sourceId'] as String,
        kind: json['kind'] as String,
        field: json['field'] as String,
        timestamp: json['timestamp'] as num,
        value: json['value'] as num,
      );

  final String sourceId;
  final String kind;
  final String field;
  final num timestamp;
  final num value;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['sourceId'] = sourceId;
    hydraOut['kind'] = kind;
    hydraOut['field'] = field;
    hydraOut['timestamp'] = timestamp;
    hydraOut['value'] = value;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraGlobalStopReleased {
  const HydraGlobalStopReleased({
    required this.success,
    required this.announced,
  });

  factory HydraGlobalStopReleased.fromJson(Map<String, dynamic> json) => HydraGlobalStopReleased(
        success: json['success'] as bool,
        announced: json['announced'] as bool,
      );

  final bool success;
  /// Whether the retained READY went out on the MQTT bridge (false when announcing is not configured or the broker is not connected).
  final bool announced;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['announced'] = announced;
    return hydraOut;
  }
}

/// The HealthReport contract of the SDK. Nothing else about the host is in it.
class HydraHealthReport {
  const HydraHealthReport({
    required this.schemaVersion,
    required this.state,
    required this.timestampUtc,
    required this.checks,
    this.service,
  });

  factory HydraHealthReport.fromJson(Map<String, dynamic> json) => HydraHealthReport(
        schemaVersion: json['schema_version'] as String,
        state: json['state'] as String,
        timestampUtc: json['timestamp_utc'] as String,
        checks: _hydraMap(json['checks']),
        service: json['service'] == null ? null : json['service'] as String,
      );

  final String schemaVersion;
  final String state;
  final String timestampUtc;
  final Map<String, dynamic> checks;
  final String? service;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['schema_version'] = schemaVersion;
    hydraOut['state'] = state;
    hydraOut['timestamp_utc'] = timestampUtc;
    hydraOut['checks'] = checks;
    final hydraField4 = service;
    if (hydraField4 != null) hydraOut['service'] = hydraField4;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraHydraInfo {
  const HydraHydraInfo({
    required this.schemaVersion,
    required this.product,
    required this.remoteApiVersion,
    required this.appVersion,
    required this.hostname,
    required this.controllerCount,
    required this.robotCount,
    required this.uptimeSeconds,
    this.addresses,
  });

  factory HydraHydraInfo.fromJson(Map<String, dynamic> json) => HydraHydraInfo(
        schemaVersion: json['schema_version'] as String,
        product: json['product'] as String,
        remoteApiVersion: (json['remoteApiVersion'] as num).toInt(),
        appVersion: json['appVersion'] as String,
        hostname: json['hostname'] as String,
        controllerCount: (json['controllerCount'] as num).toInt(),
        robotCount: (json['robotCount'] as num).toInt(),
        uptimeSeconds: (json['uptimeSeconds'] as num).toInt(),
        addresses: json['addresses'] == null ? null : (json['addresses'] as List).map((v0) => v0 as String).toList(),
      );

  final String schemaVersion;
  final String product;
  final int remoteApiVersion;
  final String appVersion;
  final String hostname;
  final int controllerCount;
  final int robotCount;
  final int uptimeSeconds;
  /// The addresses of this server on the local network. Present only while an administrator allowed it (discovery.advertiseAddress); a client must not rely on it.
  final List<String>? addresses;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['schema_version'] = schemaVersion;
    hydraOut['product'] = product;
    hydraOut['remoteApiVersion'] = remoteApiVersion;
    hydraOut['appVersion'] = appVersion;
    hydraOut['hostname'] = hostname;
    hydraOut['controllerCount'] = controllerCount;
    hydraOut['robotCount'] = robotCount;
    hydraOut['uptimeSeconds'] = uptimeSeconds;
    final hydraField8 = addresses;
    if (hydraField8 != null) hydraOut['addresses'] = hydraField8;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraInfoTicket {
  const HydraInfoTicket({
    required this.ticket,
    required this.expiresInSeconds,
  });

  factory HydraInfoTicket.fromJson(Map<String, dynamic> json) => HydraInfoTicket(
        ticket: json['ticket'] as String,
        expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
      );

  /// Signed ticket for the read-only information routes; it goes in the address as ?ticket=.
  final String ticket;
  final int expiresInSeconds;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['ticket'] = ticket;
    hydraOut['expiresInSeconds'] = expiresInSeconds;
    return hydraOut;
  }
}

/// A JSON Web Key Set (RFC 7517) with the public Ed25519 keys that verify the EdDSA sign-in tokens: the active one and, during the overlap of a rotation, the previous one. Public parameters only.
class HydraJwksDocument {
  const HydraJwksDocument({
    required this.keys,
  });

  factory HydraJwksDocument.fromJson(Map<String, dynamic> json) => HydraJwksDocument(
        keys: (json['keys'] as List).map((v0) => HydraJwksDocumentKeysItem.fromJson(_hydraMap(v0))).toList(),
      );

  final List<HydraJwksDocumentKeysItem> keys;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['keys'] = keys.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraJwksDocumentKeysItem {
  const HydraJwksDocumentKeysItem({
    required this.kty,
    required this.crv,
    required this.x,
    required this.kid,
    required this.use,
    required this.alg,
  });

  factory HydraJwksDocumentKeysItem.fromJson(Map<String, dynamic> json) => HydraJwksDocumentKeysItem(
        kty: json['kty'] as String,
        crv: json['crv'] as String,
        x: json['x'] as String,
        kid: json['kid'] as String,
        use: json['use'] as String,
        alg: json['alg'] as String,
      );

  final String kty;
  final String crv;
  /// The public key, base64url.
  final String x;
  /// The key id (the RFC 7638 thumbprint, shortened); the header of each token names it.
  final String kid;
  final String use;
  final String alg;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['kty'] = kty;
    hydraOut['crv'] = crv;
    hydraOut['x'] = x;
    hydraOut['kid'] = kid;
    hydraOut['use'] = use;
    hydraOut['alg'] = alg;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraJwtKeyRotated {
  const HydraJwtKeyRotated({
    required this.success,
    required this.kid,
    required this.algorithm,
    required this.keys,
    required this.jwksPath,
  });

  factory HydraJwtKeyRotated.fromJson(Map<String, dynamic> json) => HydraJwtKeyRotated(
        success: json['success'] as bool,
        kid: json['kid'] as String,
        algorithm: json['algorithm'] as String,
        keys: (json['keys'] as List).map((v0) => HydraJwtKeyRotatedKeysItem.fromJson(_hydraMap(v0))).toList(),
        jwksPath: json['jwksPath'] as String,
      );

  final bool success;
  /// The key id of the new active key.
  final String kid;
  final String algorithm;
  final List<HydraJwtKeyRotatedKeysItem> keys;
  final String jwksPath;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['kid'] = kid;
    hydraOut['algorithm'] = algorithm;
    hydraOut['keys'] = keys.map((v0) => v0.toJson()).toList();
    hydraOut['jwksPath'] = jwksPath;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraJwtKeyRotatedKeysItem {
  const HydraJwtKeyRotatedKeysItem({
    required this.kid,
    required this.createdAt,
    required this.retiredAt,
    required this.active,
    required this.acceptedUntil,
  });

  factory HydraJwtKeyRotatedKeysItem.fromJson(Map<String, dynamic> json) => HydraJwtKeyRotatedKeysItem(
        kid: json['kid'] as String,
        createdAt: (json['createdAt'] as num).toInt(),
        retiredAt: json['retiredAt'] == null ? null : (json['retiredAt'] as num).toInt(),
        active: json['active'] as bool,
        acceptedUntil: json['acceptedUntil'] == null ? null : (json['acceptedUntil'] as num).toInt(),
      );

  final String kid;
  /// Unix seconds.
  final int createdAt;
  /// Unix seconds; null for the active key.
  final int? retiredAt;
  final bool active;
  /// Unix seconds at which a retired key stops being accepted and published; null for the active key.
  final int? acceptedUntil;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['kid'] = kid;
    hydraOut['createdAt'] = createdAt;
    hydraOut['retiredAt'] = retiredAt;
    hydraOut['active'] = active;
    hydraOut['acceptedUntil'] = acceptedUntil;
    return hydraOut;
  }
}

/// The state of the token signing keys. Never any private part.
class HydraJwtKeys {
  const HydraJwtKeys({
    required this.algorithm,
    required this.keys,
    required this.jwksPath,
  });

  factory HydraJwtKeys.fromJson(Map<String, dynamic> json) => HydraJwtKeys(
        algorithm: json['algorithm'] as String,
        keys: (json['keys'] as List).map((v0) => HydraJwtKeysKeysItem.fromJson(_hydraMap(v0))).toList(),
        jwksPath: json['jwksPath'] as String,
      );

  final String algorithm;
  final List<HydraJwtKeysKeysItem> keys;
  final String jwksPath;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['algorithm'] = algorithm;
    hydraOut['keys'] = keys.map((v0) => v0.toJson()).toList();
    hydraOut['jwksPath'] = jwksPath;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraJwtKeysKeysItem {
  const HydraJwtKeysKeysItem({
    required this.kid,
    required this.createdAt,
    required this.retiredAt,
    required this.active,
    required this.acceptedUntil,
  });

  factory HydraJwtKeysKeysItem.fromJson(Map<String, dynamic> json) => HydraJwtKeysKeysItem(
        kid: json['kid'] as String,
        createdAt: (json['createdAt'] as num).toInt(),
        retiredAt: json['retiredAt'] == null ? null : (json['retiredAt'] as num).toInt(),
        active: json['active'] as bool,
        acceptedUntil: json['acceptedUntil'] == null ? null : (json['acceptedUntil'] as num).toInt(),
      );

  final String kid;
  /// Unix seconds.
  final int createdAt;
  /// Unix seconds; null for the active key.
  final int? retiredAt;
  final bool active;
  /// Unix seconds at which a retired key stops being accepted and published; null for the active key.
  final int? acceptedUntil;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['kid'] = kid;
    hydraOut['createdAt'] = createdAt;
    hydraOut['retiredAt'] = retiredAt;
    hydraOut['active'] = active;
    hydraOut['acceptedUntil'] = acceptedUntil;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraLiveActivityRegistered {
  const HydraLiveActivityRegistered({
    required this.registered,
  });

  factory HydraLiveActivityRegistered.fromJson(Map<String, dynamic> json) => HydraLiveActivityRegistered(
        registered: json['registered'] as bool,
      );

  final bool registered;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['registered'] = registered;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraLiveActivityRemoved {
  const HydraLiveActivityRemoved({
    required this.removed,
  });

  factory HydraLiveActivityRemoved.fromJson(Map<String, dynamic> json) => HydraLiveActivityRemoved(
        removed: json['removed'] as bool,
      );

  final bool removed;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['removed'] = removed;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraLogLines {
  const HydraLogLines({
    required this.lines,
  });

  factory HydraLogLines.fromJson(Map<String, dynamic> json) => HydraLogLines(
        lines: (json['lines'] as List).map((v0) => v0 as String).toList(),
      );

  final List<String> lines;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['lines'] = lines;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraLoginResult {
  const HydraLoginResult({
    required this.success,
    required this.token,
    required this.refreshToken,
    required this.role,
  });

  factory HydraLoginResult.fromJson(Map<String, dynamic> json) => HydraLoginResult(
        success: json['success'] as bool,
        token: json['token'] as String,
        refreshToken: json['refreshToken'] as String,
        role: json['role'] as String,
      );

  final bool success;
  final String token;
  final String refreshToken;
  final String role;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['token'] = token;
    hydraOut['refreshToken'] = refreshToken;
    hydraOut['role'] = role;
    return hydraOut;
  }
}

/// What one run of the deploy tool of the operating system image did (status, install, rollback or prune). `result` is the JSON the tool printed on success (the state of the components, or the list of removed releases) and null otherwise; `message` is the last lines the tool printed on its error output, cut to a fixed size.
class HydraMaintenanceOutcome {
  const HydraMaintenanceOutcome({
    required this.ok,
    required this.action,
    required this.exitCode,
    required this.timedOut,
    required this.result,
    required this.message,
  });

  factory HydraMaintenanceOutcome.fromJson(Map<String, dynamic> json) => HydraMaintenanceOutcome(
        ok: json['ok'] as bool,
        action: json['action'] as String,
        exitCode: (json['exitCode'] as num).toInt(),
        timedOut: json['timedOut'] as bool,
        result: json['result'],
        message: json['message'] as String,
      );

  final bool ok;
  final String action;
  final int exitCode;
  final bool timedOut;
  final dynamic result;
  final String message;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['ok'] = ok;
    hydraOut['action'] = action;
    hydraOut['exitCode'] = exitCode;
    hydraOut['timedOut'] = timedOut;
    hydraOut['result'] = result;
    hydraOut['message'] = message;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraModelList {
  const HydraModelList({
    required this.models,
  });

  factory HydraModelList.fromJson(Map<String, dynamic> json) => HydraModelList(
        models: (json['models'] as List).map((v0) => _hydraMap(v0)).toList(),
      );

  final List<Map<String, dynamic>> models;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['models'] = models;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraModelSubmitted {
  const HydraModelSubmitted({
    required this.success,
    required this.slug,
  });

  factory HydraModelSubmitted.fromJson(Map<String, dynamic> json) => HydraModelSubmitted(
        success: json['success'] as bool,
        slug: json['slug'] as String,
      );

  final bool success;
  final String slug;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['slug'] = slug;
    return hydraOut;
  }
}

/// The last health frame that the kinematic brain heard from the controller board in a slot, read from the SPI bridge. Only on a server where nodeHealth.enabled is on (404 otherwise); for an operator or an administrator. Read only.
class HydraNodeHealth {
  const HydraNodeHealth({
    required this.online,
    required this.slot,
    required this.heard,
    this.ageMs,
    this.sequence,
    this.flags,
    this.flagNames,
    this.txErrors,
    this.rxErrors,
    this.stalls,
    this.uptimeS,
    required this.source,
  });

  factory HydraNodeHealth.fromJson(Map<String, dynamic> json) => HydraNodeHealth(
        online: json['online'] as bool,
        slot: (json['slot'] as num).toInt(),
        heard: json['heard'] == null ? null : json['heard'] as bool,
        ageMs: json['ageMs'] == null ? null : (json['ageMs'] as num).toInt(),
        sequence: json['sequence'] == null ? null : (json['sequence'] as num).toInt(),
        flags: json['flags'] == null ? null : (json['flags'] as num).toInt(),
        flagNames: json['flagNames'] == null ? null : (json['flagNames'] as List).map((v0) => v0 as String).toList(),
        txErrors: json['txErrors'] == null ? null : (json['txErrors'] as num).toInt(),
        rxErrors: json['rxErrors'] == null ? null : (json['rxErrors'] as num).toInt(),
        stalls: json['stalls'] == null ? null : (json['stalls'] as num).toInt(),
        uptimeS: json['uptimeS'] == null ? null : (json['uptimeS'] as num).toInt(),
        source: json['source'] as String,
      );

  /// False when the brain did not answer (its build has the health query off, or the link is down): then only slot and source carry anything.
  final bool online;
  final int slot;
  /// True when the brain has heard a health frame of the slot, false when it never has, null when it did not answer.
  final bool? heard;
  /// How long ago the brain heard it, in steps of 100 ms.
  final int? ageMs;
  final int? sequence;
  final int? flags;
  final List<String>? flagNames;
  final int? txErrors;
  final int? rxErrors;
  final int? stalls;
  /// Seconds since the board started, in steps of 16 (4080 means 4080 or more).
  final int? uptimeS;
  final String source;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['online'] = online;
    hydraOut['slot'] = slot;
    hydraOut['heard'] = heard;
    final hydraField3 = ageMs;
    if (hydraField3 != null) hydraOut['ageMs'] = hydraField3;
    final hydraField4 = sequence;
    if (hydraField4 != null) hydraOut['sequence'] = hydraField4;
    final hydraField5 = flags;
    if (hydraField5 != null) hydraOut['flags'] = hydraField5;
    final hydraField6 = flagNames;
    if (hydraField6 != null) hydraOut['flagNames'] = hydraField6;
    final hydraField7 = txErrors;
    if (hydraField7 != null) hydraOut['txErrors'] = hydraField7;
    final hydraField8 = rxErrors;
    if (hydraField8 != null) hydraOut['rxErrors'] = hydraField8;
    final hydraField9 = stalls;
    if (hydraField9 != null) hydraOut['stalls'] = hydraField9;
    final hydraField10 = uptimeS;
    if (hydraField10 != null) hydraOut['uptimeS'] = hydraField10;
    hydraOut['source'] = source;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraOperatorPresence {
  const HydraOperatorPresence({
    required this.state,
    required this.lastSequence,
    required this.secondsSinceBeat,
    required this.action,
    required this.timeoutSeconds,
    required this.degradedRobots,
  });

  factory HydraOperatorPresence.fromJson(Map<String, dynamic> json) => HydraOperatorPresence(
        state: json['state'] as String,
        lastSequence: json['lastSequence'] == null ? null : (json['lastSequence'] as num).toInt(),
        secondsSinceBeat: json['secondsSinceBeat'] == null ? null : (json['secondsSinceBeat'] as num).toInt(),
        action: json['action'] as String,
        timeoutSeconds: json['timeoutSeconds'] as num,
        degradedRobots: (json['degradedRobots'] as List).map((v0) => (v0 as num).toInt()).toList(),
      );

  final String state;
  final int? lastSequence;
  final int? secondsSinceBeat;
  final String action;
  final num timeoutSeconds;
  final List<int> degradedRobots;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['state'] = state;
    hydraOut['lastSequence'] = lastSequence;
    hydraOut['secondsSinceBeat'] = secondsSinceBeat;
    hydraOut['action'] = action;
    hydraOut['timeoutSeconds'] = timeoutSeconds;
    hydraOut['degradedRobots'] = degradedRobots;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraOperatorPresenceAck {
  const HydraOperatorPresenceAck({
    required this.accepted,
    required this.duplicate,
    required this.stale,
    required this.state,
    required this.sequence,
    required this.action,
    required this.timeoutSeconds,
  });

  factory HydraOperatorPresenceAck.fromJson(Map<String, dynamic> json) => HydraOperatorPresenceAck(
        accepted: json['accepted'] as bool,
        duplicate: json['duplicate'] as bool,
        stale: json['stale'] as bool,
        state: json['state'] as String,
        sequence: (json['sequence'] as num).toInt(),
        action: json['action'] as String,
        timeoutSeconds: json['timeoutSeconds'] as num,
      );

  final bool accepted;
  final bool duplicate;
  final bool stale;
  final String state;
  final int sequence;
  final String action;
  final num timeoutSeconds;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['accepted'] = accepted;
    hydraOut['duplicate'] = duplicate;
    hydraOut['stale'] = stale;
    hydraOut['state'] = state;
    hydraOut['sequence'] = sequence;
    hydraOut['action'] = action;
    hydraOut['timeoutSeconds'] = timeoutSeconds;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostAdminDeviceTokensBody {
  const HydraPostAdminDeviceTokensBody({
    required this.name,
    required this.username,
    this.ttlDays,
    required this.confirm,
  });

  factory HydraPostAdminDeviceTokensBody.fromJson(Map<String, dynamic> json) => HydraPostAdminDeviceTokensBody(
        name: json['name'] as String,
        username: json['username'] as String,
        ttlDays: json['ttlDays'] == null ? null : json['ttlDays'] as num,
        confirm: json['confirm'] as bool,
      );

  final String name;
  final String username;
  final num? ttlDays;
  final bool confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['name'] = name;
    hydraOut['username'] = username;
    final hydraField2 = ttlDays;
    if (hydraField2 != null) hydraOut['ttlDays'] = hydraField2;
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostAdminFleetUpdateApplyBody {
  const HydraPostAdminFleetUpdateApplyBody({
    this.services,
    required this.confirm,
  });

  factory HydraPostAdminFleetUpdateApplyBody.fromJson(Map<String, dynamic> json) => HydraPostAdminFleetUpdateApplyBody(
        services: json['services'] == null ? null : (json['services'] as List).map((v0) => v0 as String).toList(),
        confirm: json['confirm'] as bool,
      );

  final List<String>? services;
  final bool confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = services;
    if (hydraField0 != null) hydraOut['services'] = hydraField0;
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostAdminFleetUpdateResumeBody {
  const HydraPostAdminFleetUpdateResumeBody({
    required this.service,
    required this.confirm,
  });

  factory HydraPostAdminFleetUpdateResumeBody.fromJson(Map<String, dynamic> json) => HydraPostAdminFleetUpdateResumeBody(
        service: json['service'] as String,
        confirm: json['confirm'] as bool,
      );

  final String service;
  final bool confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['service'] = service;
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostAdminMaintenanceInstallBody {
  const HydraPostAdminMaintenanceInstallBody({
    required this.package,
    this.allowDowngrade,
    required this.confirm,
  });

  factory HydraPostAdminMaintenanceInstallBody.fromJson(Map<String, dynamic> json) => HydraPostAdminMaintenanceInstallBody(
        package: json['package'] as String,
        allowDowngrade: json['allowDowngrade'] == null ? null : json['allowDowngrade'] as bool,
        confirm: json['confirm'] as bool,
      );

  final String package;
  final bool? allowDowngrade;
  final bool confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['package'] = package;
    final hydraField1 = allowDowngrade;
    if (hydraField1 != null) hydraOut['allowDowngrade'] = hydraField1;
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostAdminMaintenancePruneBody {
  const HydraPostAdminMaintenancePruneBody({
    required this.component,
    this.keep,
    required this.confirm,
  });

  factory HydraPostAdminMaintenancePruneBody.fromJson(Map<String, dynamic> json) => HydraPostAdminMaintenancePruneBody(
        component: json['component'] as String,
        keep: json['keep'] == null ? null : json['keep'] as num,
        confirm: json['confirm'] as bool,
      );

  final String component;
  final num? keep;
  final bool confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['component'] = component;
    final hydraField1 = keep;
    if (hydraField1 != null) hydraOut['keep'] = hydraField1;
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostAdminMaintenanceRollbackBody {
  const HydraPostAdminMaintenanceRollbackBody({
    required this.component,
    required this.confirm,
  });

  factory HydraPostAdminMaintenanceRollbackBody.fromJson(Map<String, dynamic> json) => HydraPostAdminMaintenanceRollbackBody(
        component: json['component'] as String,
        confirm: json['confirm'] as bool,
      );

  final String component;
  final bool confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['component'] = component;
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostAdminSelfUpdateApplyBody {
  const HydraPostAdminSelfUpdateApplyBody({
    required this.component,
    required this.confirm,
  });

  factory HydraPostAdminSelfUpdateApplyBody.fromJson(Map<String, dynamic> json) => HydraPostAdminSelfUpdateApplyBody(
        component: json['component'] as String,
        confirm: json['confirm'] as bool,
      );

  final String component;
  final bool confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['component'] = component;
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostAdminSelfUpdateRollbackBody {
  const HydraPostAdminSelfUpdateRollbackBody({
    required this.component,
    required this.confirm,
  });

  factory HydraPostAdminSelfUpdateRollbackBody.fromJson(Map<String, dynamic> json) => HydraPostAdminSelfUpdateRollbackBody(
        component: json['component'] as String,
        confirm: json['confirm'] as bool,
      );

  final String component;
  final bool confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['component'] = component;
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostCameraByIdPtzBody {
  const HydraPostCameraByIdPtzBody({
    required this.host,
    this.port,
    this.username,
    this.password,
    this.channel,
    this.pan,
    this.tilt,
    this.zoom,
  });

  factory HydraPostCameraByIdPtzBody.fromJson(Map<String, dynamic> json) => HydraPostCameraByIdPtzBody(
        host: json['host'] as String,
        port: json['port'] == null ? null : (json['port'] as num).toInt(),
        username: json['username'] == null ? null : json['username'] as String,
        password: json['password'] == null ? null : json['password'] as String,
        channel: json['channel'] == null ? null : (json['channel'] as num).toInt(),
        pan: json['pan'] == null ? null : json['pan'] as num,
        tilt: json['tilt'] == null ? null : json['tilt'] as num,
        zoom: json['zoom'] == null ? null : json['zoom'] as num,
      );

  final String host;
  final int? port;
  final String? username;
  final String? password;
  final int? channel;
  final num? pan;
  final num? tilt;
  final num? zoom;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['host'] = host;
    final hydraField1 = port;
    if (hydraField1 != null) hydraOut['port'] = hydraField1;
    final hydraField2 = username;
    if (hydraField2 != null) hydraOut['username'] = hydraField2;
    final hydraField3 = password;
    if (hydraField3 != null) hydraOut['password'] = hydraField3;
    final hydraField4 = channel;
    if (hydraField4 != null) hydraOut['channel'] = hydraField4;
    final hydraField5 = pan;
    if (hydraField5 != null) hydraOut['pan'] = hydraField5;
    final hydraField6 = tilt;
    if (hydraField6 != null) hydraOut['tilt'] = hydraField6;
    final hydraField7 = zoom;
    if (hydraField7 != null) hydraOut['zoom'] = hydraField7;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostCameraDiscoverRtspPathBody {
  const HydraPostCameraDiscoverRtspPathBody({
    required this.host,
    this.port,
    this.username,
    this.password,
  });

  factory HydraPostCameraDiscoverRtspPathBody.fromJson(Map<String, dynamic> json) => HydraPostCameraDiscoverRtspPathBody(
        host: json['host'] as String,
        port: json['port'] == null ? null : (json['port'] as num).toInt(),
        username: json['username'] == null ? null : json['username'] as String,
        password: json['password'] == null ? null : json['password'] as String,
      );

  final String host;
  final int? port;
  final String? username;
  final String? password;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['host'] = host;
    final hydraField1 = port;
    if (hydraField1 != null) hydraOut['port'] = hydraField1;
    final hydraField2 = username;
    if (hydraField2 != null) hydraOut['username'] = hydraField2;
    final hydraField3 = password;
    if (hydraField3 != null) hydraOut['password'] = hydraField3;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostConnectorHubGateSettingsBody {
  const HydraPostConnectorHubGateSettingsBody({
    required this.allowLoopbackNoIdentity,
    this.confirm,
  });

  factory HydraPostConnectorHubGateSettingsBody.fromJson(Map<String, dynamic> json) => HydraPostConnectorHubGateSettingsBody(
        allowLoopbackNoIdentity: json['allowLoopbackNoIdentity'] as bool,
        confirm: json['confirm'] == null ? null : json['confirm'] as bool,
      );

  final bool allowLoopbackNoIdentity;
  final bool? confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['allowLoopbackNoIdentity'] = allowLoopbackNoIdentity;
    final hydraField1 = confirm;
    if (hydraField1 != null) hydraOut['confirm'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostConnectorHubGateSettingsResult {
  const HydraPostConnectorHubGateSettingsResult({
    required this.allowLoopbackNoIdentity,
    this.loopbackSwitchAllowed,
    this.verifiesTokens,
    this.persisted,
    this.changed,
  });

  factory HydraPostConnectorHubGateSettingsResult.fromJson(Map<String, dynamic> json) => HydraPostConnectorHubGateSettingsResult(
        allowLoopbackNoIdentity: json['allowLoopbackNoIdentity'] as bool,
        loopbackSwitchAllowed: json['loopbackSwitchAllowed'] == null ? null : json['loopbackSwitchAllowed'] as bool,
        verifiesTokens: json['verifiesTokens'] == null ? null : json['verifiesTokens'] as bool,
        persisted: json['persisted'] == null ? null : json['persisted'] as bool,
        changed: json['changed'] == null ? null : json['changed'] as bool,
      );

  final bool allowLoopbackNoIdentity;
  final bool? loopbackSwitchAllowed;
  final bool? verifiesTokens;
  final bool? persisted;
  final bool? changed;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['allowLoopbackNoIdentity'] = allowLoopbackNoIdentity;
    final hydraField1 = loopbackSwitchAllowed;
    if (hydraField1 != null) hydraOut['loopbackSwitchAllowed'] = hydraField1;
    final hydraField2 = verifiesTokens;
    if (hydraField2 != null) hydraOut['verifiesTokens'] = hydraField2;
    final hydraField3 = persisted;
    if (hydraField3 != null) hydraOut['persisted'] = hydraField3;
    final hydraField4 = changed;
    if (hydraField4 != null) hydraOut['changed'] = hydraField4;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostDeviceLoginBody {
  const HydraPostDeviceLoginBody({
    required this.token,
  });

  factory HydraPostDeviceLoginBody.fromJson(Map<String, dynamic> json) => HydraPostDeviceLoginBody(
        token: json['token'] as String,
      );

  final String token;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['token'] = token;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostDroidEstopSettingsBody {
  const HydraPostDroidEstopSettingsBody({
    required this.enabled,
    required this.confirm,
  });

  factory HydraPostDroidEstopSettingsBody.fromJson(Map<String, dynamic> json) => HydraPostDroidEstopSettingsBody(
        enabled: json['enabled'] as bool,
        confirm: json['confirm'] as bool,
      );

  final bool enabled;
  final bool confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['enabled'] = enabled;
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostDroidEstopSettingsResult {
  const HydraPostDroidEstopSettingsResult({
    required this.enabled,
    this.running,
    this.changed,
  });

  factory HydraPostDroidEstopSettingsResult.fromJson(Map<String, dynamic> json) => HydraPostDroidEstopSettingsResult(
        enabled: json['enabled'] as bool,
        running: json['running'] == null ? null : json['running'] as bool,
        changed: json['changed'] == null ? null : json['changed'] as bool,
      );

  final bool enabled;
  final bool? running;
  final bool? changed;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['enabled'] = enabled;
    final hydraField1 = running;
    if (hydraField1 != null) hydraOut['running'] = hydraField1;
    final hydraField2 = changed;
    if (hydraField2 != null) hydraOut['changed'] = hydraField2;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostHardwareFramEraseBody {
  const HydraPostHardwareFramEraseBody({
    required this.confirm,
  });

  factory HydraPostHardwareFramEraseBody.fromJson(Map<String, dynamic> json) => HydraPostHardwareFramEraseBody(
        confirm: json['confirm'] as String,
      );

  final String confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostHilBridgeSettingsBody {
  const HydraPostHilBridgeSettingsBody({
    required this.requireTwinPass,
    required this.confirm,
  });

  factory HydraPostHilBridgeSettingsBody.fromJson(Map<String, dynamic> json) => HydraPostHilBridgeSettingsBody(
        requireTwinPass: json['requireTwinPass'] as bool,
        confirm: json['confirm'] as bool,
      );

  final bool requireTwinPass;
  final bool confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['requireTwinPass'] = requireTwinPass;
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostHilBridgeSettingsResult {
  const HydraPostHilBridgeSettingsResult({
    required this.requireTwinPass,
    this.locked,
    this.persisted,
    this.ready,
    this.canChange,
    this.changed,
  });

  factory HydraPostHilBridgeSettingsResult.fromJson(Map<String, dynamic> json) => HydraPostHilBridgeSettingsResult(
        requireTwinPass: json['requireTwinPass'] as bool,
        locked: json['locked'] == null ? null : json['locked'] as bool,
        persisted: json['persisted'] == null ? null : json['persisted'] as bool,
        ready: json['ready'] == null ? null : json['ready'] as bool,
        canChange: json['canChange'] == null ? null : json['canChange'] as bool,
        changed: json['changed'] == null ? null : json['changed'] as bool,
      );

  final bool requireTwinPass;
  final bool? locked;
  final bool? persisted;
  final bool? ready;
  final bool? canChange;
  final bool? changed;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['requireTwinPass'] = requireTwinPass;
    final hydraField1 = locked;
    if (hydraField1 != null) hydraOut['locked'] = hydraField1;
    final hydraField2 = persisted;
    if (hydraField2 != null) hydraOut['persisted'] = hydraField2;
    final hydraField3 = ready;
    if (hydraField3 != null) hydraOut['ready'] = hydraField3;
    final hydraField4 = canChange;
    if (hydraField4 != null) hydraOut['canChange'] = hydraField4;
    final hydraField5 = changed;
    if (hydraField5 != null) hydraOut['changed'] = hydraField5;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostInfoTicketBody {
  const HydraPostInfoTicketBody({
    this.ttlSeconds,
  });

  factory HydraPostInfoTicketBody.fromJson(Map<String, dynamic> json) => HydraPostInfoTicketBody(
        ttlSeconds: json['ttlSeconds'],
      );

  final dynamic ttlSeconds;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = ttlSeconds;
    if (hydraField0 != null) hydraOut['ttlSeconds'] = hydraField0;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostIntegrationsTestConnectionBody {
  const HydraPostIntegrationsTestConnectionBody({
    required this.host,
    required this.port,
  });

  factory HydraPostIntegrationsTestConnectionBody.fromJson(Map<String, dynamic> json) => HydraPostIntegrationsTestConnectionBody(
        host: json['host'] as String,
        port: (json['port'] as num).toInt(),
      );

  final String host;
  final int port;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['host'] = host;
    hydraOut['port'] = port;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostLoginBody {
  const HydraPostLoginBody({
    required this.username,
    required this.password,
    this.totp,
  });

  factory HydraPostLoginBody.fromJson(Map<String, dynamic> json) => HydraPostLoginBody(
        username: json['username'] as String,
        password: json['password'] as String,
        totp: json['totp'] == null ? null : json['totp'] as String,
      );

  final String username;
  final String password;
  final String? totp;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['username'] = username;
    hydraOut['password'] = password;
    final hydraField2 = totp;
    if (hydraField2 != null) hydraOut['totp'] = hydraField2;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostLogoutBody {
  const HydraPostLogoutBody({
    this.refreshToken,
  });

  factory HydraPostLogoutBody.fromJson(Map<String, dynamic> json) => HydraPostLogoutBody(
        refreshToken: json['refreshToken'] == null ? null : json['refreshToken'] as String,
      );

  final String? refreshToken;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = refreshToken;
    if (hydraField0 != null) hydraOut['refreshToken'] = hydraField0;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostModelsSubmitBody {
  const HydraPostModelsSubmitBody({
    this.category,
    this.meshFiles,
    this.name,
    this.overwrite,
    this.urdfFilename,
    this.urdfXml,
  });

  factory HydraPostModelsSubmitBody.fromJson(Map<String, dynamic> json) => HydraPostModelsSubmitBody(
        category: json['category'],
        meshFiles: json['meshFiles'],
        name: json['name'],
        overwrite: json['overwrite'],
        urdfFilename: json['urdfFilename'],
        urdfXml: json['urdfXml'],
      );

  final dynamic category;
  final dynamic meshFiles;
  final dynamic name;
  final dynamic overwrite;
  final dynamic urdfFilename;
  final dynamic urdfXml;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = category;
    if (hydraField0 != null) hydraOut['category'] = hydraField0;
    final hydraField1 = meshFiles;
    if (hydraField1 != null) hydraOut['meshFiles'] = hydraField1;
    final hydraField2 = name;
    if (hydraField2 != null) hydraOut['name'] = hydraField2;
    final hydraField3 = overwrite;
    if (hydraField3 != null) hydraOut['overwrite'] = hydraField3;
    final hydraField4 = urdfFilename;
    if (hydraField4 != null) hydraOut['urdfFilename'] = hydraField4;
    final hydraField5 = urdfXml;
    if (hydraField5 != null) hydraOut['urdfXml'] = hydraField5;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostOperatorConfirmationsBody {
  const HydraPostOperatorConfirmationsBody({
    required this.action,
    required this.jobId,
    required this.confirm,
    this.ttlSeconds,
  });

  factory HydraPostOperatorConfirmationsBody.fromJson(Map<String, dynamic> json) => HydraPostOperatorConfirmationsBody(
        action: json['action'] as String,
        jobId: json['job_id'] as String,
        confirm: json['confirm'] as bool,
        ttlSeconds: json['ttl_seconds'] == null ? null : (json['ttl_seconds'] as num).toInt(),
      );

  final String action;
  final String jobId;
  final bool confirm;
  final int? ttlSeconds;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['action'] = action;
    hydraOut['job_id'] = jobId;
    hydraOut['confirm'] = confirm;
    final hydraField3 = ttlSeconds;
    if (hydraField3 != null) hydraOut['ttl_seconds'] = hydraField3;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostOperatorConfirmationsResult {
  const HydraPostOperatorConfirmationsResult({
    required this.token,
    required this.action,
    required this.jobId,
    required this.expiresAt,
    required this.ttlSeconds,
    required this.singleUse,
  });

  factory HydraPostOperatorConfirmationsResult.fromJson(Map<String, dynamic> json) => HydraPostOperatorConfirmationsResult(
        token: json['token'] as String,
        action: json['action'] as String,
        jobId: json['job_id'] as String,
        expiresAt: (json['expires_at'] as num).toInt(),
        ttlSeconds: (json['ttl_seconds'] as num).toInt(),
        singleUse: json['single_use'] as bool,
      );

  /// A JWT (HS256) valid once, for this action and this job only. Never stored or logged by the server.
  final String token;
  final String action;
  final String jobId;
  /// Unix seconds.
  final int expiresAt;
  final int ttlSeconds;
  final bool singleUse;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['token'] = token;
    hydraOut['action'] = action;
    hydraOut['job_id'] = jobId;
    hydraOut['expires_at'] = expiresAt;
    hydraOut['ttl_seconds'] = ttlSeconds;
    hydraOut['single_use'] = singleUse;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostOperatorPresenceBody {
  const HydraPostOperatorPresenceBody({
    this.type,
    this.protocolVersion,
    required this.sequence,
    required this.intervalSeconds,
    required this.state,
  });

  factory HydraPostOperatorPresenceBody.fromJson(Map<String, dynamic> json) => HydraPostOperatorPresenceBody(
        type: json['type'] == null ? null : json['type'] as String,
        protocolVersion: json['protocolVersion'] == null ? null : (json['protocolVersion'] as num).toInt(),
        sequence: (json['sequence'] as num).toInt(),
        intervalSeconds: json['intervalSeconds'] as num,
        state: json['state'] as String,
      );

  final String? type;
  final int? protocolVersion;
  final int sequence;
  final num intervalSeconds;
  final String state;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = type;
    if (hydraField0 != null) hydraOut['type'] = hydraField0;
    final hydraField1 = protocolVersion;
    if (hydraField1 != null) hydraOut['protocolVersion'] = hydraField1;
    hydraOut['sequence'] = sequence;
    hydraOut['intervalSeconds'] = intervalSeconds;
    hydraOut['state'] = state;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostOpsAgentProposalsDecideBody {
  const HydraPostOpsAgentProposalsDecideBody({
    required this.incidentId,
    required this.decision,
    this.confirm,
  });

  factory HydraPostOpsAgentProposalsDecideBody.fromJson(Map<String, dynamic> json) => HydraPostOpsAgentProposalsDecideBody(
        incidentId: json['incidentId'] as String,
        decision: json['decision'] as String,
        confirm: json['confirm'] == null ? null : json['confirm'] as bool,
      );

  final String incidentId;
  final String decision;
  final bool? confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['incidentId'] = incidentId;
    hydraOut['decision'] = decision;
    final hydraField2 = confirm;
    if (hydraField2 != null) hydraOut['confirm'] = hydraField2;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostOpsAgentProposalsDecideResult {
  const HydraPostOpsAgentProposalsDecideResult({
    this.decision,
  });

  factory HydraPostOpsAgentProposalsDecideResult.fromJson(Map<String, dynamic> json) => HydraPostOpsAgentProposalsDecideResult(
        decision: json['decision'] == null ? null : json['decision'] as String,
      );

  final String? decision;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = decision;
    if (hydraField0 != null) hydraOut['decision'] = hydraField0;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostPushDevicesBody {
  const HydraPostPushDevicesBody({
    required this.token,
    required this.platform,
    this.locale,
  });

  factory HydraPostPushDevicesBody.fromJson(Map<String, dynamic> json) => HydraPostPushDevicesBody(
        token: json['token'] as String,
        platform: json['platform'] as String,
        locale: json['locale'] == null ? null : json['locale'] as String,
      );

  final String token;
  final String platform;
  final String? locale;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['token'] = token;
    hydraOut['platform'] = platform;
    final hydraField2 = locale;
    if (hydraField2 != null) hydraOut['locale'] = hydraField2;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostPushLiveActivitiesBody {
  const HydraPostPushLiveActivitiesBody({
    required this.activityToken,
    required this.robotId,
  });

  factory HydraPostPushLiveActivitiesBody.fromJson(Map<String, dynamic> json) => HydraPostPushLiveActivitiesBody(
        activityToken: json['activityToken'] as String,
        robotId: json['robotId'] as String,
      );

  final String activityToken;
  final String robotId;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['activityToken'] = activityToken;
    hydraOut['robotId'] = robotId;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostRefreshBody {
  const HydraPostRefreshBody({
    required this.refreshToken,
  });

  factory HydraPostRefreshBody.fromJson(Map<String, dynamic> json) => HydraPostRefreshBody(
        refreshToken: json['refreshToken'] as String,
      );

  final String refreshToken;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['refreshToken'] = refreshToken;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostRobotByIdClaimBody {
  const HydraPostRobotByIdClaimBody({
    this.ttlMs,
    this.force,
    this.reason,
    this.controllerId,
  });

  factory HydraPostRobotByIdClaimBody.fromJson(Map<String, dynamic> json) => HydraPostRobotByIdClaimBody(
        ttlMs: json['ttlMs'] == null ? null : json['ttlMs'] as num,
        force: json['force'] == null ? null : json['force'] as bool,
        reason: json['reason'] == null ? null : json['reason'] as String,
        controllerId: json['controllerId'] == null ? null : json['controllerId'] as String,
      );

  final num? ttlMs;
  final bool? force;
  final String? reason;
  final String? controllerId;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = ttlMs;
    if (hydraField0 != null) hydraOut['ttlMs'] = hydraField0;
    final hydraField1 = force;
    if (hydraField1 != null) hydraOut['force'] = hydraField1;
    final hydraField2 = reason;
    if (hydraField2 != null) hydraOut['reason'] = hydraField2;
    final hydraField3 = controllerId;
    if (hydraField3 != null) hydraOut['controllerId'] = hydraField3;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostRobotByIdClaimResult {
  const HydraPostRobotByIdClaimResult({
    required this.success,
    required this.reservation,
    required this.reservationHistory,
    required this.revision,
  });

  factory HydraPostRobotByIdClaimResult.fromJson(Map<String, dynamic> json) => HydraPostRobotByIdClaimResult(
        success: json['success'] as bool,
        reservation: _hydraMap(json['reservation']),
        reservationHistory: (json['reservationHistory'] as List).map((v0) => _hydraMap(v0)).toList(),
        revision: json['revision'] as String,
      );

  final bool success;
  final Map<String, dynamic> reservation;
  final List<Map<String, dynamic>> reservationHistory;
  final String revision;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['reservation'] = reservation;
    hydraOut['reservationHistory'] = reservationHistory;
    hydraOut['revision'] = revision;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostRobotByIdCommandBody {
  const HydraPostRobotByIdCommandBody({
    required this.command,
    this.params,
    this.seq,
    this.controllerId,
  });

  factory HydraPostRobotByIdCommandBody.fromJson(Map<String, dynamic> json) => HydraPostRobotByIdCommandBody(
        command: json['command'] as String,
        params: json['params'] == null ? null : _hydraMap(json['params']),
        seq: json['seq'] == null ? null : (json['seq'] as num).toInt(),
        controllerId: json['controllerId'] == null ? null : json['controllerId'] as String,
      );

  /// One of the commands the server knows (an unknown one answers 400).
  final String command;
  final Map<String, dynamic>? params;
  final int? seq;
  final String? controllerId;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['command'] = command;
    final hydraField1 = params;
    if (hydraField1 != null) hydraOut['params'] = hydraField1;
    final hydraField2 = seq;
    if (hydraField2 != null) hydraOut['seq'] = hydraField2;
    final hydraField3 = controllerId;
    if (hydraField3 != null) hydraOut['controllerId'] = hydraField3;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostRobotByIdCommandResult {
  const HydraPostRobotByIdCommandResult({
    required this.success,
    this.affectedCount,
    required this.revision,
    this.operationId,
    this.operation,
    this.lifecycle,
    this.applied,
    this.warnings,
  });

  factory HydraPostRobotByIdCommandResult.fromJson(Map<String, dynamic> json) => HydraPostRobotByIdCommandResult(
        success: json['success'] as bool,
        affectedCount: json['affectedCount'] == null ? null : json['affectedCount'] as num,
        revision: json['revision'] as String,
        operationId: json['operation_id'] == null ? null : json['operation_id'] as String,
        operation: json['operation'] == null ? null : _hydraMap(json['operation']),
        lifecycle: json['lifecycle'] == null ? null : _hydraMap(json['lifecycle']),
        applied: json['applied'] == null ? null : _hydraMap(json['applied']),
        warnings: json['warnings'] == null ? null : List<dynamic>.from(json['warnings'] as List),
      );

  final bool success;
  final num? affectedCount;
  final String revision;
  final String? operationId;
  final Map<String, dynamic>? operation;
  final Map<String, dynamic>? lifecycle;
  final Map<String, dynamic>? applied;
  final List<dynamic>? warnings;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    final hydraField1 = affectedCount;
    if (hydraField1 != null) hydraOut['affectedCount'] = hydraField1;
    hydraOut['revision'] = revision;
    final hydraField3 = operationId;
    if (hydraField3 != null) hydraOut['operation_id'] = hydraField3;
    final hydraField4 = operation;
    if (hydraField4 != null) hydraOut['operation'] = hydraField4;
    final hydraField5 = lifecycle;
    if (hydraField5 != null) hydraOut['lifecycle'] = hydraField5;
    final hydraField6 = applied;
    if (hydraField6 != null) hydraOut['applied'] = hydraField6;
    final hydraField7 = warnings;
    if (hydraField7 != null) hydraOut['warnings'] = hydraField7;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostRobotByIdJogArmBody {
  const HydraPostRobotByIdJogArmBody({
    required this.armed,
    this.ttlMs,
    this.controllerId,
  });

  factory HydraPostRobotByIdJogArmBody.fromJson(Map<String, dynamic> json) => HydraPostRobotByIdJogArmBody(
        armed: json['armed'] as bool,
        ttlMs: json['ttlMs'] == null ? null : json['ttlMs'] as num,
        controllerId: json['controllerId'] == null ? null : json['controllerId'] as String,
      );

  final bool armed;
  final num? ttlMs;
  final String? controllerId;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['armed'] = armed;
    final hydraField1 = ttlMs;
    if (hydraField1 != null) hydraOut['ttlMs'] = hydraField1;
    final hydraField2 = controllerId;
    if (hydraField2 != null) hydraOut['controllerId'] = hydraField2;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostRobotByIdJogArmResult {
  const HydraPostRobotByIdJogArmResult({
    required this.success,
    required this.armed,
    this.expiresAt,
    this.ttlMs,
  });

  factory HydraPostRobotByIdJogArmResult.fromJson(Map<String, dynamic> json) => HydraPostRobotByIdJogArmResult(
        success: json['success'] as bool,
        armed: json['armed'] as bool,
        expiresAt: json['expiresAt'] == null ? null : json['expiresAt'] as num,
        ttlMs: json['ttlMs'] == null ? null : json['ttlMs'] as num,
      );

  final bool success;
  final bool armed;
  final num? expiresAt;
  final num? ttlMs;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['armed'] = armed;
    final hydraField2 = expiresAt;
    if (hydraField2 != null) hydraOut['expiresAt'] = hydraField2;
    final hydraField3 = ttlMs;
    if (hydraField3 != null) hydraOut['ttlMs'] = hydraField3;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostRobotByIdReleaseBody {
  const HydraPostRobotByIdReleaseBody({
    this.reason,
    this.controllerId,
  });

  factory HydraPostRobotByIdReleaseBody.fromJson(Map<String, dynamic> json) => HydraPostRobotByIdReleaseBody(
        reason: json['reason'] == null ? null : json['reason'] as String,
        controllerId: json['controllerId'] == null ? null : json['controllerId'] as String,
      );

  final String? reason;
  final String? controllerId;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = reason;
    if (hydraField0 != null) hydraOut['reason'] = hydraField0;
    final hydraField1 = controllerId;
    if (hydraField1 != null) hydraOut['controllerId'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostRobotByIdReleaseResult {
  const HydraPostRobotByIdReleaseResult({
    required this.success,
    required this.reservationHistory,
    required this.revision,
  });

  factory HydraPostRobotByIdReleaseResult.fromJson(Map<String, dynamic> json) => HydraPostRobotByIdReleaseResult(
        success: json['success'] as bool,
        reservationHistory: (json['reservationHistory'] as List).map((v0) => _hydraMap(v0)).toList(),
        revision: json['revision'] as String,
      );

  final bool success;
  final List<Map<String, dynamic>> reservationHistory;
  final String revision;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['reservationHistory'] = reservationHistory;
    hydraOut['revision'] = revision;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostRos2BridgeSettingsBody {
  const HydraPostRos2BridgeSettingsBody({
    required this.requireSros2,
    required this.confirm,
  });

  factory HydraPostRos2BridgeSettingsBody.fromJson(Map<String, dynamic> json) => HydraPostRos2BridgeSettingsBody(
        requireSros2: json['requireSros2'] as bool,
        confirm: json['confirm'] as bool,
      );

  final bool requireSros2;
  final bool confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['requireSros2'] = requireSros2;
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostRos2BridgeSettingsResult {
  const HydraPostRos2BridgeSettingsResult({
    required this.requireSros2,
    required this.active,
    required this.restartNeeded,
    required this.canChange,
    required this.environmentReady,
    this.changed,
    this.appliesAfterRestart,
  });

  factory HydraPostRos2BridgeSettingsResult.fromJson(Map<String, dynamic> json) => HydraPostRos2BridgeSettingsResult(
        requireSros2: json['requireSros2'] as bool,
        active: json['active'] as bool,
        restartNeeded: json['restartNeeded'] as bool,
        canChange: json['canChange'] as bool,
        environmentReady: json['environmentReady'] as bool,
        changed: json['changed'] == null ? null : json['changed'] as bool,
        appliesAfterRestart: json['appliesAfterRestart'] == null ? null : json['appliesAfterRestart'] as bool,
      );

  final bool requireSros2;
  final bool active;
  final bool restartNeeded;
  final bool canChange;
  final bool environmentReady;
  final bool? changed;
  final bool? appliesAfterRestart;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['requireSros2'] = requireSros2;
    hydraOut['active'] = active;
    hydraOut['restartNeeded'] = restartNeeded;
    hydraOut['canChange'] = canChange;
    hydraOut['environmentReady'] = environmentReady;
    final hydraField5 = changed;
    if (hydraField5 != null) hydraOut['changed'] = hydraField5;
    final hydraField6 = appliesAfterRestart;
    if (hydraField6 != null) hydraOut['appliesAfterRestart'] = hydraField6;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostSemanticPlannerSettingsBody {
  const HydraPostSemanticPlannerSettingsBody({
    required this.requireIdentity,
    this.confirm,
  });

  factory HydraPostSemanticPlannerSettingsBody.fromJson(Map<String, dynamic> json) => HydraPostSemanticPlannerSettingsBody(
        requireIdentity: json['requireIdentity'] as bool,
        confirm: json['confirm'] == null ? null : json['confirm'] as bool,
      );

  final bool requireIdentity;
  final bool? confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['requireIdentity'] = requireIdentity;
    final hydraField1 = confirm;
    if (hydraField1 != null) hydraOut['confirm'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostSemanticPlannerSettingsResult {
  const HydraPostSemanticPlannerSettingsResult({
    required this.requireIdentity,
    this.verifiesTokens,
    this.persisted,
    this.changed,
  });

  factory HydraPostSemanticPlannerSettingsResult.fromJson(Map<String, dynamic> json) => HydraPostSemanticPlannerSettingsResult(
        requireIdentity: json['requireIdentity'] as bool,
        verifiesTokens: json['verifiesTokens'] == null ? null : json['verifiesTokens'] as bool,
        persisted: json['persisted'] == null ? null : json['persisted'] as bool,
        changed: json['changed'] == null ? null : json['changed'] as bool,
      );

  final bool requireIdentity;
  final bool? verifiesTokens;
  final bool? persisted;
  final bool? changed;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['requireIdentity'] = requireIdentity;
    final hydraField1 = verifiesTokens;
    if (hydraField1 != null) hydraOut['verifiesTokens'] = hydraField1;
    final hydraField2 = persisted;
    if (hydraField2 != null) hydraOut['persisted'] = hydraField2;
    final hydraField3 = changed;
    if (hydraField3 != null) hydraOut['changed'] = hydraField3;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostSettingsResult {
  const HydraPostSettingsResult({
    required this.success,
    required this.revision,
    this.warnings,
  });

  factory HydraPostSettingsResult.fromJson(Map<String, dynamic> json) => HydraPostSettingsResult(
        success: json['success'] as bool,
        revision: json['revision'] as String,
        warnings: json['warnings'] == null ? null : (json['warnings'] as List).map((v0) => _hydraMap(v0)).toList(),
      );

  final bool success;
  final String revision;
  final List<Map<String, dynamic>>? warnings;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['revision'] = revision;
    final hydraField2 = warnings;
    if (hydraField2 != null) hydraOut['warnings'] = hydraField2;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostSystemBluetoothPairBody {
  const HydraPostSystemBluetoothPairBody({
    required this.mac,
  });

  factory HydraPostSystemBluetoothPairBody.fromJson(Map<String, dynamic> json) => HydraPostSystemBluetoothPairBody(
        mac: json['mac'] as String,
      );

  final String mac;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['mac'] = mac;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostSystemBluetoothPowerBody {
  const HydraPostSystemBluetoothPowerBody({
    required this.onValue,
  });

  factory HydraPostSystemBluetoothPowerBody.fromJson(Map<String, dynamic> json) => HydraPostSystemBluetoothPowerBody(
        onValue: json['on'] as bool,
      );

  final bool onValue;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['on'] = onValue;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostSystemBluetoothRemoveBody {
  const HydraPostSystemBluetoothRemoveBody({
    required this.mac,
  });

  factory HydraPostSystemBluetoothRemoveBody.fromJson(Map<String, dynamic> json) => HydraPostSystemBluetoothRemoveBody(
        mac: json['mac'] as String,
      );

  final String mac;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['mac'] = mac;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostToolArmsResetBody {
  const HydraPostToolArmsResetBody({
    required this.robot,
    required this.toolId,
    required this.confirm,
  });

  factory HydraPostToolArmsResetBody.fromJson(Map<String, dynamic> json) => HydraPostToolArmsResetBody(
        robot: json['robot'] as String,
        toolId: (json['toolId'] as num).toInt(),
        confirm: json['confirm'] as String,
      );

  final String robot;
  final int toolId;
  final String confirm;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['robot'] = robot;
    hydraOut['toolId'] = toolId;
    hydraOut['confirm'] = confirm;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostTotpBeginBody {
  const HydraPostTotpBeginBody({
    required this.password,
  });

  factory HydraPostTotpBeginBody.fromJson(Map<String, dynamic> json) => HydraPostTotpBeginBody(
        password: json['password'] as String,
      );

  final String password;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['password'] = password;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostTotpConfirmBody {
  const HydraPostTotpConfirmBody({
    required this.code,
  });

  factory HydraPostTotpConfirmBody.fromJson(Map<String, dynamic> json) => HydraPostTotpConfirmBody(
        code: json['code'] as String,
      );

  final String code;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['code'] = code;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostTotpDisableBody {
  const HydraPostTotpDisableBody({
    required this.password,
    required this.code,
  });

  factory HydraPostTotpDisableBody.fromJson(Map<String, dynamic> json) => HydraPostTotpDisableBody(
        password: json['password'] as String,
        code: json['code'] as String,
      );

  final String password;
  final String code;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['password'] = password;
    hydraOut['code'] = code;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostTotpRecoveryCodesBody {
  const HydraPostTotpRecoveryCodesBody({
    required this.password,
    required this.code,
  });

  factory HydraPostTotpRecoveryCodesBody.fromJson(Map<String, dynamic> json) => HydraPostTotpRecoveryCodesBody(
        password: json['password'] as String,
        code: json['code'] as String,
      );

  final String password;
  final String code;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['password'] = password;
    hydraOut['code'] = code;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostUploadWorkBody {
  const HydraPostUploadWorkBody({
    required this.folderPath,
    required this.fileName,
    required this.content,
  });

  factory HydraPostUploadWorkBody.fromJson(Map<String, dynamic> json) => HydraPostUploadWorkBody(
        folderPath: json['folderPath'] as String,
        fileName: json['fileName'] as String,
        content: json['content'],
      );

  /// A folder inside the data folder of the server (no .. allowed).
  final String folderPath;
  /// The name of the file; only its last component is used.
  final String fileName;
  /// Any JSON value (the recorded points are an array); the server writes it pretty-printed as the file.
  final dynamic content;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['folderPath'] = folderPath;
    hydraOut['fileName'] = fileName;
    hydraOut['content'] = content;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostUsersBody {
  const HydraPostUsersBody({
    required this.username,
    required this.password,
    required this.role,
  });

  factory HydraPostUsersBody.fromJson(Map<String, dynamic> json) => HydraPostUsersBody(
        username: json['username'] as String,
        password: json['password'] as String,
        role: json['role'] as String,
      );

  final String username;
  final String password;
  final String role;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['username'] = username;
    hydraOut['password'] = password;
    hydraOut['role'] = role;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostVoiceConfirmBody {
  const HydraPostVoiceConfirmBody({
    this.confirmationToken,
  });

  factory HydraPostVoiceConfirmBody.fromJson(Map<String, dynamic> json) => HydraPostVoiceConfirmBody(
        confirmationToken: json['confirmationToken'],
      );

  final dynamic confirmationToken;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = confirmationToken;
    if (hydraField0 != null) hydraOut['confirmationToken'] = hydraField0;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPostVoiceTurnBody {
  const HydraPostVoiceTurnBody({
    this.locale,
    this.requestId,
    this.subject,
  });

  factory HydraPostVoiceTurnBody.fromJson(Map<String, dynamic> json) => HydraPostVoiceTurnBody(
        locale: json['locale'],
        requestId: json['requestId'],
        subject: json['subject'],
      );

  final dynamic locale;
  final dynamic requestId;
  final dynamic subject;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = locale;
    if (hydraField0 != null) hydraOut['locale'] = hydraField0;
    final hydraField1 = requestId;
    if (hydraField1 != null) hydraOut['requestId'] = hydraField1;
    final hydraField2 = subject;
    if (hydraField2 != null) hydraOut['subject'] = hydraField2;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPtzResult {
  const HydraPtzResult({
    required this.ok,
  });

  factory HydraPtzResult.fromJson(Map<String, dynamic> json) => HydraPtzResult(
        ok: json['ok'] as bool,
      );

  final bool ok;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['ok'] = ok;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPushDeviceRegistered {
  const HydraPushDeviceRegistered({
    required this.registered,
  });

  factory HydraPushDeviceRegistered.fromJson(Map<String, dynamic> json) => HydraPushDeviceRegistered(
        registered: json['registered'] as bool,
      );

  final bool registered;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['registered'] = registered;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPushDeviceRemoved {
  const HydraPushDeviceRemoved({
    required this.removed,
  });

  factory HydraPushDeviceRemoved.fromJson(Map<String, dynamic> json) => HydraPushDeviceRemoved(
        removed: json['removed'] as bool,
      );

  final bool removed;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['removed'] = removed;
    return hydraOut;
  }
}

/// The state of the push notifications of the server, for an administrator. It tells whether the credentials of the Apple push service are usable and why not, never the credentials or the device tokens.
class HydraPushStatus {
  const HydraPushStatus({
    required this.enabled,
    required this.configured,
    required this.problem,
    required this.devices,
    required this.sandbox,
    required this.events,
    this.liveActivity,
  });

  factory HydraPushStatus.fromJson(Map<String, dynamic> json) => HydraPushStatus(
        enabled: json['enabled'] as bool,
        configured: json['configured'] as bool,
        problem: json['problem'] == null ? null : json['problem'] as String,
        devices: (json['devices'] as num).toInt(),
        sandbox: json['sandbox'] as bool,
        events: HydraPushStatusEvents.fromJson(_hydraMap(json['events'])),
        liveActivity: json['liveActivity'] == null ? null : HydraPushStatusLiveActivity.fromJson(_hydraMap(json['liveActivity'])),
      );

  final bool enabled;
  final bool configured;
  final String? problem;
  final int devices;
  final bool sandbox;
  final HydraPushStatusEvents events;
  /// The Live Activity on the lock screen: whether it is sent (off by default), the most it may show (status, progress or full; status by default) and how many activities are registered.
  final HydraPushStatusLiveActivity? liveActivity;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['enabled'] = enabled;
    hydraOut['configured'] = configured;
    hydraOut['problem'] = problem;
    hydraOut['devices'] = devices;
    hydraOut['sandbox'] = sandbox;
    hydraOut['events'] = events.toJson();
    final hydraField6 = liveActivity;
    if (hydraField6 != null) hydraOut['liveActivity'] = hydraField6.toJson();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPushStatusEvents {
  const HydraPushStatusEvents({
    required this.jobFinished,
    required this.globalStop,
  });

  factory HydraPushStatusEvents.fromJson(Map<String, dynamic> json) => HydraPushStatusEvents(
        jobFinished: json['jobFinished'] as bool,
        globalStop: json['globalStop'] as bool,
      );

  final bool jobFinished;
  final bool globalStop;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['jobFinished'] = jobFinished;
    hydraOut['globalStop'] = globalStop;
    return hydraOut;
  }
}

/// The Live Activity on the lock screen: whether it is sent (off by default), the most it may show (status, progress or full; status by default) and how many activities are registered.
class HydraPushStatusLiveActivity {
  const HydraPushStatusLiveActivity({
    required this.enabled,
    required this.level,
    required this.activities,
  });

  factory HydraPushStatusLiveActivity.fromJson(Map<String, dynamic> json) => HydraPushStatusLiveActivity(
        enabled: json['enabled'] as bool,
        level: json['level'] as String,
        activities: (json['activities'] as num).toInt(),
      );

  final bool enabled;
  final String level;
  final int activities;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['enabled'] = enabled;
    hydraOut['level'] = level;
    hydraOut['activities'] = activities;
    return hydraOut;
  }
}

/// A patch of the safety limits: only the blocks and keys sent change, each inside the hard limits of the server.
class HydraPutAdminSafetyLimitsBody {
  const HydraPutAdminSafetyLimitsBody({
    this.jog,
    this.temperature,
    this.claims,
    this.audit,
  });

  factory HydraPutAdminSafetyLimitsBody.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsBody(
        jog: json['jog'] == null ? null : HydraPutAdminSafetyLimitsBodyJog.fromJson(_hydraMap(json['jog'])),
        temperature: json['temperature'] == null ? null : HydraPutAdminSafetyLimitsBodyTemperature.fromJson(_hydraMap(json['temperature'])),
        claims: json['claims'] == null ? null : HydraPutAdminSafetyLimitsBodyClaims.fromJson(_hydraMap(json['claims'])),
        audit: json['audit'] == null ? null : HydraPutAdminSafetyLimitsBodyAudit.fromJson(_hydraMap(json['audit'])),
      );

  final HydraPutAdminSafetyLimitsBodyJog? jog;
  final HydraPutAdminSafetyLimitsBodyTemperature? temperature;
  final HydraPutAdminSafetyLimitsBodyClaims? claims;
  final HydraPutAdminSafetyLimitsBodyAudit? audit;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = jog;
    if (hydraField0 != null) hydraOut['jog'] = hydraField0.toJson();
    final hydraField1 = temperature;
    if (hydraField1 != null) hydraOut['temperature'] = hydraField1.toJson();
    final hydraField2 = claims;
    if (hydraField2 != null) hydraOut['claims'] = hydraField2.toJson();
    final hydraField3 = audit;
    if (hydraField3 != null) hydraOut['audit'] = hydraField3.toJson();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsBodyAudit {
  const HydraPutAdminSafetyLimitsBodyAudit({
    this.enabled,
    this.motionIntervalSeconds,
  });

  factory HydraPutAdminSafetyLimitsBodyAudit.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsBodyAudit(
        enabled: json['enabled'] == null ? null : json['enabled'] as bool,
        motionIntervalSeconds: json['motionIntervalSeconds'] == null ? null : json['motionIntervalSeconds'] as num,
      );

  final bool? enabled;
  final num? motionIntervalSeconds;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = enabled;
    if (hydraField0 != null) hydraOut['enabled'] = hydraField0;
    final hydraField1 = motionIntervalSeconds;
    if (hydraField1 != null) hydraOut['motionIntervalSeconds'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsBodyClaims {
  const HydraPutAdminSafetyLimitsBodyClaims({
    this.requireControllerId,
  });

  factory HydraPutAdminSafetyLimitsBodyClaims.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsBodyClaims(
        requireControllerId: json['requireControllerId'] == null ? null : json['requireControllerId'] as bool,
      );

  final bool? requireControllerId;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = requireControllerId;
    if (hydraField0 != null) hydraOut['requireControllerId'] = hydraField0;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsBodyJog {
  const HydraPutAdminSafetyLimitsBodyJog({
    this.armRequired,
    this.armTtlMs,
    this.defaultValue,
    this.models,
  });

  factory HydraPutAdminSafetyLimitsBodyJog.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsBodyJog(
        armRequired: json['armRequired'] == null ? null : json['armRequired'] as bool,
        armTtlMs: json['armTtlMs'] == null ? null : json['armTtlMs'] as num,
        defaultValue: json['default'] == null ? null : HydraPutAdminSafetyLimitsBodyJogDefault.fromJson(_hydraMap(json['default'])),
        models: json['models'] == null ? null : _hydraMap(json['models']),
      );

  final bool? armRequired;
  final num? armTtlMs;
  final HydraPutAdminSafetyLimitsBodyJogDefault? defaultValue;
  final Map<String, dynamic>? models;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = armRequired;
    if (hydraField0 != null) hydraOut['armRequired'] = hydraField0;
    final hydraField1 = armTtlMs;
    if (hydraField1 != null) hydraOut['armTtlMs'] = hydraField1;
    final hydraField2 = defaultValue;
    if (hydraField2 != null) hydraOut['default'] = hydraField2.toJson();
    final hydraField3 = models;
    if (hydraField3 != null) hydraOut['models'] = hydraField3;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsBodyJogDefault {
  const HydraPutAdminSafetyLimitsBodyJogDefault({
    this.maxAmount,
    this.maxAbsolute,
  });

  factory HydraPutAdminSafetyLimitsBodyJogDefault.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsBodyJogDefault(
        maxAmount: json['maxAmount'] == null ? null : json['maxAmount'] as num,
        maxAbsolute: json['maxAbsolute'] == null ? null : json['maxAbsolute'] as num,
      );

  final num? maxAmount;
  final num? maxAbsolute;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = maxAmount;
    if (hydraField0 != null) hydraOut['maxAmount'] = hydraField0;
    final hydraField1 = maxAbsolute;
    if (hydraField1 != null) hydraOut['maxAbsolute'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsBodyTemperature {
  const HydraPutAdminSafetyLimitsBodyTemperature({
    this.defaultValue,
    this.models,
  });

  factory HydraPutAdminSafetyLimitsBodyTemperature.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsBodyTemperature(
        defaultValue: json['default'] == null ? null : HydraPutAdminSafetyLimitsBodyTemperatureDefault.fromJson(_hydraMap(json['default'])),
        models: json['models'] == null ? null : _hydraMap(json['models']),
      );

  final HydraPutAdminSafetyLimitsBodyTemperatureDefault? defaultValue;
  final Map<String, dynamic>? models;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = defaultValue;
    if (hydraField0 != null) hydraOut['default'] = hydraField0.toJson();
    final hydraField1 = models;
    if (hydraField1 != null) hydraOut['models'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsBodyTemperatureDefault {
  const HydraPutAdminSafetyLimitsBodyTemperatureDefault({
    this.bedMaxC,
  });

  factory HydraPutAdminSafetyLimitsBodyTemperatureDefault.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsBodyTemperatureDefault(
        bedMaxC: json['bedMaxC'] == null ? null : json['bedMaxC'] as num,
      );

  final num? bedMaxC;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = bedMaxC;
    if (hydraField0 != null) hydraOut['bedMaxC'] = hydraField0;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsResult {
  const HydraPutAdminSafetyLimitsResult({
    required this.limits,
    this.defaults,
    this.hardLimits,
    required this.success,
  });

  factory HydraPutAdminSafetyLimitsResult.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsResult(
        limits: HydraPutAdminSafetyLimitsResultLimits.fromJson(_hydraMap(json['limits'])),
        defaults: json['defaults'] == null ? null : _hydraMap(json['defaults']),
        hardLimits: json['hardLimits'] == null ? null : _hydraMap(json['hardLimits']),
        success: json['success'] as bool,
      );

  final HydraPutAdminSafetyLimitsResultLimits limits;
  final Map<String, dynamic>? defaults;
  final Map<String, dynamic>? hardLimits;
  final bool success;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['limits'] = limits.toJson();
    final hydraField1 = defaults;
    if (hydraField1 != null) hydraOut['defaults'] = hydraField1;
    final hydraField2 = hardLimits;
    if (hydraField2 != null) hydraOut['hardLimits'] = hydraField2;
    hydraOut['success'] = success;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsResultLimits {
  const HydraPutAdminSafetyLimitsResultLimits({
    this.jog,
    this.temperature,
    this.claims,
    this.audit,
  });

  factory HydraPutAdminSafetyLimitsResultLimits.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsResultLimits(
        jog: json['jog'] == null ? null : HydraPutAdminSafetyLimitsResultLimitsJog.fromJson(_hydraMap(json['jog'])),
        temperature: json['temperature'] == null ? null : HydraPutAdminSafetyLimitsResultLimitsTemperature.fromJson(_hydraMap(json['temperature'])),
        claims: json['claims'] == null ? null : HydraPutAdminSafetyLimitsResultLimitsClaims.fromJson(_hydraMap(json['claims'])),
        audit: json['audit'] == null ? null : HydraPutAdminSafetyLimitsResultLimitsAudit.fromJson(_hydraMap(json['audit'])),
      );

  final HydraPutAdminSafetyLimitsResultLimitsJog? jog;
  final HydraPutAdminSafetyLimitsResultLimitsTemperature? temperature;
  final HydraPutAdminSafetyLimitsResultLimitsClaims? claims;
  final HydraPutAdminSafetyLimitsResultLimitsAudit? audit;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = jog;
    if (hydraField0 != null) hydraOut['jog'] = hydraField0.toJson();
    final hydraField1 = temperature;
    if (hydraField1 != null) hydraOut['temperature'] = hydraField1.toJson();
    final hydraField2 = claims;
    if (hydraField2 != null) hydraOut['claims'] = hydraField2.toJson();
    final hydraField3 = audit;
    if (hydraField3 != null) hydraOut['audit'] = hydraField3.toJson();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsResultLimitsAudit {
  const HydraPutAdminSafetyLimitsResultLimitsAudit({
    this.enabled,
    this.motionIntervalSeconds,
  });

  factory HydraPutAdminSafetyLimitsResultLimitsAudit.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsResultLimitsAudit(
        enabled: json['enabled'] == null ? null : json['enabled'] as bool,
        motionIntervalSeconds: json['motionIntervalSeconds'] == null ? null : json['motionIntervalSeconds'] as num,
      );

  final bool? enabled;
  final num? motionIntervalSeconds;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = enabled;
    if (hydraField0 != null) hydraOut['enabled'] = hydraField0;
    final hydraField1 = motionIntervalSeconds;
    if (hydraField1 != null) hydraOut['motionIntervalSeconds'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsResultLimitsClaims {
  const HydraPutAdminSafetyLimitsResultLimitsClaims({
    this.requireControllerId,
  });

  factory HydraPutAdminSafetyLimitsResultLimitsClaims.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsResultLimitsClaims(
        requireControllerId: json['requireControllerId'] == null ? null : json['requireControllerId'] as bool,
      );

  final bool? requireControllerId;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = requireControllerId;
    if (hydraField0 != null) hydraOut['requireControllerId'] = hydraField0;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsResultLimitsJog {
  const HydraPutAdminSafetyLimitsResultLimitsJog({
    this.armRequired,
    this.armTtlMs,
    this.defaultValue,
    this.models,
  });

  factory HydraPutAdminSafetyLimitsResultLimitsJog.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsResultLimitsJog(
        armRequired: json['armRequired'] == null ? null : json['armRequired'] as bool,
        armTtlMs: json['armTtlMs'] == null ? null : json['armTtlMs'] as num,
        defaultValue: json['default'] == null ? null : HydraPutAdminSafetyLimitsResultLimitsJogDefault.fromJson(_hydraMap(json['default'])),
        models: json['models'] == null ? null : _hydraMap(json['models']),
      );

  final bool? armRequired;
  final num? armTtlMs;
  final HydraPutAdminSafetyLimitsResultLimitsJogDefault? defaultValue;
  final Map<String, dynamic>? models;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = armRequired;
    if (hydraField0 != null) hydraOut['armRequired'] = hydraField0;
    final hydraField1 = armTtlMs;
    if (hydraField1 != null) hydraOut['armTtlMs'] = hydraField1;
    final hydraField2 = defaultValue;
    if (hydraField2 != null) hydraOut['default'] = hydraField2.toJson();
    final hydraField3 = models;
    if (hydraField3 != null) hydraOut['models'] = hydraField3;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsResultLimitsJogDefault {
  const HydraPutAdminSafetyLimitsResultLimitsJogDefault({
    this.maxAmount,
    this.maxAbsolute,
  });

  factory HydraPutAdminSafetyLimitsResultLimitsJogDefault.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsResultLimitsJogDefault(
        maxAmount: json['maxAmount'] == null ? null : json['maxAmount'] as num,
        maxAbsolute: json['maxAbsolute'] == null ? null : json['maxAbsolute'] as num,
      );

  final num? maxAmount;
  final num? maxAbsolute;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = maxAmount;
    if (hydraField0 != null) hydraOut['maxAmount'] = hydraField0;
    final hydraField1 = maxAbsolute;
    if (hydraField1 != null) hydraOut['maxAbsolute'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsResultLimitsTemperature {
  const HydraPutAdminSafetyLimitsResultLimitsTemperature({
    this.defaultValue,
    this.models,
  });

  factory HydraPutAdminSafetyLimitsResultLimitsTemperature.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsResultLimitsTemperature(
        defaultValue: json['default'] == null ? null : HydraPutAdminSafetyLimitsResultLimitsTemperatureDefault.fromJson(_hydraMap(json['default'])),
        models: json['models'] == null ? null : _hydraMap(json['models']),
      );

  final HydraPutAdminSafetyLimitsResultLimitsTemperatureDefault? defaultValue;
  final Map<String, dynamic>? models;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = defaultValue;
    if (hydraField0 != null) hydraOut['default'] = hydraField0.toJson();
    final hydraField1 = models;
    if (hydraField1 != null) hydraOut['models'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminSafetyLimitsResultLimitsTemperatureDefault {
  const HydraPutAdminSafetyLimitsResultLimitsTemperatureDefault({
    this.bedMaxC,
  });

  factory HydraPutAdminSafetyLimitsResultLimitsTemperatureDefault.fromJson(Map<String, dynamic> json) => HydraPutAdminSafetyLimitsResultLimitsTemperatureDefault(
        bedMaxC: json['bedMaxC'] == null ? null : json['bedMaxC'] as num,
      );

  final num? bedMaxC;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = bedMaxC;
    if (hydraField0 != null) hydraOut['bedMaxC'] = hydraField0;
    return hydraOut;
  }
}

/// Every key is optional: port and any of the blocks of the security configuration. A key that is not one of them is ignored.
class HydraPutAdminServerConfigBody {
  const HydraPutAdminServerConfigBody({
    this.port,
    this.aiAccess,
    this.infoAuth,
    this.tls,
    this.ble,
    this.mqtt,
    this.voice,
    this.mavlink,
    this.robots,
    this.connections,
    this.health,
    this.ecosystemHealth,
    this.nodeHealth,
    this.twinRelay,
    this.infoTickets,
    this.deviceTokens,
    this.updateCheck,
    this.discovery,
    this.maintenance,
    this.atc,
    this.detectionHef,
    this.auth,
    this.presence,
    this.push,
    this.trustedNetworks,
    this.rul,
    this.safety,
    this.camera,
    this.install,
    this.websocket,
    this.logging,
    this.rateLimits,
    this.bridges,
    this.jobDispatcher,
    this.ingest,
  });

  factory HydraPutAdminServerConfigBody.fromJson(Map<String, dynamic> json) => HydraPutAdminServerConfigBody(
        port: json['port'] == null ? null : (json['port'] as num).toInt(),
        aiAccess: json['aiAccess'] == null ? null : _hydraMap(json['aiAccess']),
        infoAuth: json['infoAuth'] == null ? null : _hydraMap(json['infoAuth']),
        tls: json['tls'] == null ? null : _hydraMap(json['tls']),
        ble: json['ble'] == null ? null : _hydraMap(json['ble']),
        mqtt: json['mqtt'] == null ? null : _hydraMap(json['mqtt']),
        voice: json['voice'] == null ? null : _hydraMap(json['voice']),
        mavlink: json['mavlink'] == null ? null : _hydraMap(json['mavlink']),
        robots: json['robots'] == null ? null : _hydraMap(json['robots']),
        connections: json['connections'] == null ? null : _hydraMap(json['connections']),
        health: json['health'] == null ? null : _hydraMap(json['health']),
        ecosystemHealth: json['ecosystemHealth'] == null ? null : _hydraMap(json['ecosystemHealth']),
        nodeHealth: json['nodeHealth'] == null ? null : _hydraMap(json['nodeHealth']),
        twinRelay: json['twinRelay'] == null ? null : _hydraMap(json['twinRelay']),
        infoTickets: json['infoTickets'] == null ? null : _hydraMap(json['infoTickets']),
        deviceTokens: json['deviceTokens'] == null ? null : _hydraMap(json['deviceTokens']),
        updateCheck: json['updateCheck'] == null ? null : _hydraMap(json['updateCheck']),
        discovery: json['discovery'] == null ? null : _hydraMap(json['discovery']),
        maintenance: json['maintenance'] == null ? null : _hydraMap(json['maintenance']),
        atc: json['atc'] == null ? null : _hydraMap(json['atc']),
        detectionHef: json['detectionHef'] == null ? null : _hydraMap(json['detectionHef']),
        auth: json['auth'] == null ? null : _hydraMap(json['auth']),
        presence: json['presence'] == null ? null : _hydraMap(json['presence']),
        push: json['push'] == null ? null : _hydraMap(json['push']),
        trustedNetworks: json['trustedNetworks'] == null ? null : _hydraMap(json['trustedNetworks']),
        rul: json['rul'] == null ? null : _hydraMap(json['rul']),
        safety: json['safety'] == null ? null : _hydraMap(json['safety']),
        camera: json['camera'] == null ? null : _hydraMap(json['camera']),
        install: json['install'] == null ? null : _hydraMap(json['install']),
        websocket: json['websocket'] == null ? null : _hydraMap(json['websocket']),
        logging: json['logging'] == null ? null : _hydraMap(json['logging']),
        rateLimits: json['rateLimits'] == null ? null : _hydraMap(json['rateLimits']),
        bridges: json['bridges'] == null ? null : _hydraMap(json['bridges']),
        jobDispatcher: json['jobDispatcher'] == null ? null : _hydraMap(json['jobDispatcher']),
        ingest: json['ingest'] == null ? null : HydraPutAdminServerConfigBodyIngest.fromJson(_hydraMap(json['ingest'])),
      );

  /// The listen port, 1 to 65535; it applies when the server restarts.
  final int? port;
  /// The options of the aiAccess block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? aiAccess;
  /// The options of the infoAuth block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? infoAuth;
  /// The options of the tls block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? tls;
  /// The options of the ble block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? ble;
  /// The options of the mqtt block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? mqtt;
  /// The options of the voice block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? voice;
  /// The options of the mavlink block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? mavlink;
  /// The options of the robots block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? robots;
  /// The options of the connections block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? connections;
  /// The options of the health block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? health;
  /// The options of the ecosystemHealth block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? ecosystemHealth;
  /// The options of the nodeHealth block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? nodeHealth;
  /// The options of the twinRelay block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? twinRelay;
  /// The options of the infoTickets block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? infoTickets;
  /// The options of the deviceTokens block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? deviceTokens;
  /// The options of the updateCheck block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? updateCheck;
  /// The options of the discovery block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? discovery;
  /// The options of the maintenance block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? maintenance;
  /// The options of the atc block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? atc;
  /// The options of the detectionHef block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? detectionHef;
  /// The options of the auth block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? auth;
  /// The options of the presence block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? presence;
  /// The options of the push block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? push;
  /// The options of the trustedNetworks block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? trustedNetworks;
  /// The options of the rul block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? rul;
  /// The options of the safety block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? safety;
  /// The options of the camera block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? camera;
  /// The options of the install block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? install;
  /// The options of the websocket block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? websocket;
  /// The options of the logging block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? logging;
  /// The options of the rateLimits block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? rateLimits;
  /// The options of the bridges block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? bridges;
  /// The options of the jobDispatcher block of the security configuration that the body changes; only the keys sent are changed.
  final Map<String, dynamic>? jobDispatcher;
  /// The ingest switches (each true or false) and the file of the public keys of the operators that sign trajectory proposals; only the keys sent are changed, and an environment variable still locks its switch.
  final HydraPutAdminServerConfigBodyIngest? ingest;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = port;
    if (hydraField0 != null) hydraOut['port'] = hydraField0;
    final hydraField1 = aiAccess;
    if (hydraField1 != null) hydraOut['aiAccess'] = hydraField1;
    final hydraField2 = infoAuth;
    if (hydraField2 != null) hydraOut['infoAuth'] = hydraField2;
    final hydraField3 = tls;
    if (hydraField3 != null) hydraOut['tls'] = hydraField3;
    final hydraField4 = ble;
    if (hydraField4 != null) hydraOut['ble'] = hydraField4;
    final hydraField5 = mqtt;
    if (hydraField5 != null) hydraOut['mqtt'] = hydraField5;
    final hydraField6 = voice;
    if (hydraField6 != null) hydraOut['voice'] = hydraField6;
    final hydraField7 = mavlink;
    if (hydraField7 != null) hydraOut['mavlink'] = hydraField7;
    final hydraField8 = robots;
    if (hydraField8 != null) hydraOut['robots'] = hydraField8;
    final hydraField9 = connections;
    if (hydraField9 != null) hydraOut['connections'] = hydraField9;
    final hydraField10 = health;
    if (hydraField10 != null) hydraOut['health'] = hydraField10;
    final hydraField11 = ecosystemHealth;
    if (hydraField11 != null) hydraOut['ecosystemHealth'] = hydraField11;
    final hydraField12 = nodeHealth;
    if (hydraField12 != null) hydraOut['nodeHealth'] = hydraField12;
    final hydraField13 = twinRelay;
    if (hydraField13 != null) hydraOut['twinRelay'] = hydraField13;
    final hydraField14 = infoTickets;
    if (hydraField14 != null) hydraOut['infoTickets'] = hydraField14;
    final hydraField15 = deviceTokens;
    if (hydraField15 != null) hydraOut['deviceTokens'] = hydraField15;
    final hydraField16 = updateCheck;
    if (hydraField16 != null) hydraOut['updateCheck'] = hydraField16;
    final hydraField17 = discovery;
    if (hydraField17 != null) hydraOut['discovery'] = hydraField17;
    final hydraField18 = maintenance;
    if (hydraField18 != null) hydraOut['maintenance'] = hydraField18;
    final hydraField19 = atc;
    if (hydraField19 != null) hydraOut['atc'] = hydraField19;
    final hydraField20 = detectionHef;
    if (hydraField20 != null) hydraOut['detectionHef'] = hydraField20;
    final hydraField21 = auth;
    if (hydraField21 != null) hydraOut['auth'] = hydraField21;
    final hydraField22 = presence;
    if (hydraField22 != null) hydraOut['presence'] = hydraField22;
    final hydraField23 = push;
    if (hydraField23 != null) hydraOut['push'] = hydraField23;
    final hydraField24 = trustedNetworks;
    if (hydraField24 != null) hydraOut['trustedNetworks'] = hydraField24;
    final hydraField25 = rul;
    if (hydraField25 != null) hydraOut['rul'] = hydraField25;
    final hydraField26 = safety;
    if (hydraField26 != null) hydraOut['safety'] = hydraField26;
    final hydraField27 = camera;
    if (hydraField27 != null) hydraOut['camera'] = hydraField27;
    final hydraField28 = install;
    if (hydraField28 != null) hydraOut['install'] = hydraField28;
    final hydraField29 = websocket;
    if (hydraField29 != null) hydraOut['websocket'] = hydraField29;
    final hydraField30 = logging;
    if (hydraField30 != null) hydraOut['logging'] = hydraField30;
    final hydraField31 = rateLimits;
    if (hydraField31 != null) hydraOut['rateLimits'] = hydraField31;
    final hydraField32 = bridges;
    if (hydraField32 != null) hydraOut['bridges'] = hydraField32;
    final hydraField33 = jobDispatcher;
    if (hydraField33 != null) hydraOut['jobDispatcher'] = hydraField33;
    final hydraField34 = ingest;
    if (hydraField34 != null) hydraOut['ingest'] = hydraField34.toJson();
    return hydraOut;
  }
}

/// The ingest switches (each true or false) and the file of the public keys of the operators that sign trajectory proposals; only the keys sent are changed, and an environment variable still locks its switch.
class HydraPutAdminServerConfigBodyIngest {
  const HydraPutAdminServerConfigBodyIngest({
    this.faultFeed,
    this.scenario,
    this.developerNode,
    this.anomalyFeed,
    this.anomalyVoiceRelay,
    this.voiceChain,
    this.proposalVerify,
    this.proposalKeysFile,
  });

  factory HydraPutAdminServerConfigBodyIngest.fromJson(Map<String, dynamic> json) => HydraPutAdminServerConfigBodyIngest(
        faultFeed: json['faultFeed'] == null ? null : json['faultFeed'] as bool,
        scenario: json['scenario'] == null ? null : json['scenario'] as bool,
        developerNode: json['developerNode'] == null ? null : json['developerNode'] as bool,
        anomalyFeed: json['anomalyFeed'] == null ? null : json['anomalyFeed'] as bool,
        anomalyVoiceRelay: json['anomalyVoiceRelay'] == null ? null : json['anomalyVoiceRelay'] as bool,
        voiceChain: json['voiceChain'] == null ? null : json['voiceChain'] as bool,
        proposalVerify: json['proposalVerify'] == null ? null : json['proposalVerify'] as bool,
        proposalKeysFile: json['proposalKeysFile'] == null ? null : json['proposalKeysFile'] as String,
      );

  final bool? faultFeed;
  final bool? scenario;
  final bool? developerNode;
  final bool? anomalyFeed;
  final bool? anomalyVoiceRelay;
  final bool? voiceChain;
  final bool? proposalVerify;
  final String? proposalKeysFile;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = faultFeed;
    if (hydraField0 != null) hydraOut['faultFeed'] = hydraField0;
    final hydraField1 = scenario;
    if (hydraField1 != null) hydraOut['scenario'] = hydraField1;
    final hydraField2 = developerNode;
    if (hydraField2 != null) hydraOut['developerNode'] = hydraField2;
    final hydraField3 = anomalyFeed;
    if (hydraField3 != null) hydraOut['anomalyFeed'] = hydraField3;
    final hydraField4 = anomalyVoiceRelay;
    if (hydraField4 != null) hydraOut['anomalyVoiceRelay'] = hydraField4;
    final hydraField5 = voiceChain;
    if (hydraField5 != null) hydraOut['voiceChain'] = hydraField5;
    final hydraField6 = proposalVerify;
    if (hydraField6 != null) hydraOut['proposalVerify'] = hydraField6;
    final hydraField7 = proposalKeysFile;
    if (hydraField7 != null) hydraOut['proposalKeysFile'] = hydraField7;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutAdminServerConfigResult {
  const HydraPutAdminServerConfigResult({
    required this.success,
    required this.appliesOnRestart,
    required this.warnings,
    this.additionalProperties = const <String, dynamic>{},
  });

  factory HydraPutAdminServerConfigResult.fromJson(Map<String, dynamic> json) => HydraPutAdminServerConfigResult(
        success: json['success'] as bool,
        appliesOnRestart: json['appliesOnRestart'] as bool,
        warnings: (json['warnings'] as List).map((v0) => v0 as String).toList(),
        additionalProperties: _hydraMap(<String, dynamic>{for (final entry in json.entries) if (!_knownKeys.contains(entry.key)) entry.key: entry.value}),
      );

  static const Set<String> _knownKeys = <String>{'success', 'appliesOnRestart', 'warnings'};

  final bool success;
  final bool appliesOnRestart;
  final List<String> warnings;
  /// The keys the contract does not list, kept as they came.
  final Map<String, dynamic> additionalProperties;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{...additionalProperties};
    hydraOut['success'] = success;
    hydraOut['appliesOnRestart'] = appliesOnRestart;
    hydraOut['warnings'] = warnings;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutSettingsResult {
  const HydraPutSettingsResult({
    required this.success,
    required this.revision,
    this.warnings,
  });

  factory HydraPutSettingsResult.fromJson(Map<String, dynamic> json) => HydraPutSettingsResult(
        success: json['success'] as bool,
        revision: json['revision'] as String,
        warnings: json['warnings'] == null ? null : (json['warnings'] as List).map((v0) => _hydraMap(v0)).toList(),
      );

  final bool success;
  final String revision;
  final List<Map<String, dynamic>>? warnings;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['revision'] = revision;
    final hydraField2 = warnings;
    if (hydraField2 != null) hydraOut['warnings'] = hydraField2;
    return hydraOut;
  }
}

/// plan is the whole plan; expectedHash is the hash read last (the data lake refuses a plan that changed meanwhile); confirmDelete is needed to switch real deletion on; preview only asks what saving would do.
class HydraPutTelemetryDownsamplePlanBody {
  const HydraPutTelemetryDownsamplePlanBody({
    required this.plan,
    this.expectedHash,
    this.confirmDelete,
    this.preview,
  });

  factory HydraPutTelemetryDownsamplePlanBody.fromJson(Map<String, dynamic> json) => HydraPutTelemetryDownsamplePlanBody(
        plan: HydraPutTelemetryDownsamplePlanBodyPlan.fromJson(_hydraMap(json['plan'])),
        expectedHash: json['expectedHash'] == null ? null : json['expectedHash'] as String,
        confirmDelete: json['confirmDelete'] == null ? null : json['confirmDelete'] as bool,
        preview: json['preview'] == null ? null : json['preview'] as bool,
      );

  final HydraPutTelemetryDownsamplePlanBodyPlan plan;
  final String? expectedHash;
  final bool? confirmDelete;
  final bool? preview;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['plan'] = plan.toJson();
    final hydraField1 = expectedHash;
    if (hydraField1 != null) hydraOut['expectedHash'] = hydraField1;
    final hydraField2 = confirmDelete;
    if (hydraField2 != null) hydraOut['confirmDelete'] = hydraField2;
    final hydraField3 = preview;
    if (hydraField3 != null) hydraOut['preview'] = hydraField3;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutTelemetryDownsamplePlanBodyPlan {
  const HydraPutTelemetryDownsamplePlanBodyPlan({
    required this.tiers,
    required this.delete,
  });

  factory HydraPutTelemetryDownsamplePlanBodyPlan.fromJson(Map<String, dynamic> json) => HydraPutTelemetryDownsamplePlanBodyPlan(
        tiers: (json['tiers'] as List).map((v0) => HydraPutTelemetryDownsamplePlanBodyPlanTiersItem.fromJson(_hydraMap(v0))).toList(),
        delete: json['delete'] as bool,
      );

  final List<HydraPutTelemetryDownsamplePlanBodyPlanTiersItem> tiers;
  final bool delete;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['tiers'] = tiers.map((v0) => v0.toJson()).toList();
    hydraOut['delete'] = delete;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutTelemetryDownsamplePlanBodyPlanTiersItem {
  const HydraPutTelemetryDownsamplePlanBodyPlanTiersItem({
    required this.kind,
    required this.field,
    this.raw,
    this.bucket,
    this.fineBucket,
    this.rollupRetention,
    this.fineRetention,
  });

  factory HydraPutTelemetryDownsamplePlanBodyPlanTiersItem.fromJson(Map<String, dynamic> json) => HydraPutTelemetryDownsamplePlanBodyPlanTiersItem(
        kind: json['kind'] as String,
        field: json['field'] as String,
        raw: json['raw'],
        bucket: json['bucket'],
        fineBucket: json['fineBucket'],
        rollupRetention: json['rollupRetention'],
        fineRetention: json['fineRetention'],
      );

  final String kind;
  final String field;
  /// How long raw points are kept: milliseconds or text such as 30d.
  final dynamic raw;
  /// Width of the rollup bucket.
  final dynamic bucket;
  /// Width of the fine rollup bucket.
  final dynamic fineBucket;
  /// How long rollups are kept.
  final dynamic rollupRetention;
  /// How long fine rollups are kept.
  final dynamic fineRetention;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['kind'] = kind;
    hydraOut['field'] = field;
    final hydraField2 = raw;
    if (hydraField2 != null) hydraOut['raw'] = hydraField2;
    final hydraField3 = bucket;
    if (hydraField3 != null) hydraOut['bucket'] = hydraField3;
    final hydraField4 = fineBucket;
    if (hydraField4 != null) hydraOut['fineBucket'] = hydraField4;
    final hydraField5 = rollupRetention;
    if (hydraField5 != null) hydraOut['rollupRetention'] = hydraField5;
    final hydraField6 = fineRetention;
    if (hydraField6 != null) hydraOut['fineRetention'] = hydraField6;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutTelemetryDownsamplePlanResult {
  const HydraPutTelemetryDownsamplePlanResult({
    required this.saved,
    this.preview,
    this.unchanged,
    required this.hash,
    this.previousHash,
    this.tiers,
    this.mode,
    this.changes,
    this.warnings,
    this.effects,
    this.currentEffects,
  });

  factory HydraPutTelemetryDownsamplePlanResult.fromJson(Map<String, dynamic> json) => HydraPutTelemetryDownsamplePlanResult(
        saved: json['saved'] as bool,
        preview: json['preview'] == null ? null : json['preview'] as bool,
        unchanged: json['unchanged'] == null ? null : json['unchanged'] as bool,
        hash: json['hash'] as String,
        previousHash: json['previousHash'] == null ? null : json['previousHash'] as String,
        tiers: json['tiers'] == null ? null : (json['tiers'] as List).map((v0) => _hydraMap(v0)).toList(),
        mode: json['mode'] == null ? null : json['mode'] as String,
        changes: json['changes'] == null ? null : (json['changes'] as List).map((v0) => _hydraMap(v0)).toList(),
        warnings: json['warnings'] == null ? null : (json['warnings'] as List).map((v0) => v0 as String).toList(),
        effects: json['effects'] == null ? null : HydraPutTelemetryDownsamplePlanResultEffects.fromJson(_hydraMap(json['effects'])),
        currentEffects: json['currentEffects'] == null ? null : HydraPutTelemetryDownsamplePlanResultCurrentEffects.fromJson(_hydraMap(json['currentEffects'])),
      );

  final bool saved;
  final bool? preview;
  final bool? unchanged;
  final String hash;
  final String? previousHash;
  final List<Map<String, dynamic>>? tiers;
  final String? mode;
  final List<Map<String, dynamic>>? changes;
  final List<String>? warnings;
  final HydraPutTelemetryDownsamplePlanResultEffects? effects;
  final HydraPutTelemetryDownsamplePlanResultCurrentEffects? currentEffects;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['saved'] = saved;
    final hydraField1 = preview;
    if (hydraField1 != null) hydraOut['preview'] = hydraField1;
    final hydraField2 = unchanged;
    if (hydraField2 != null) hydraOut['unchanged'] = hydraField2;
    hydraOut['hash'] = hash;
    final hydraField4 = previousHash;
    if (hydraField4 != null) hydraOut['previousHash'] = hydraField4;
    final hydraField5 = tiers;
    if (hydraField5 != null) hydraOut['tiers'] = hydraField5;
    final hydraField6 = mode;
    if (hydraField6 != null) hydraOut['mode'] = hydraField6;
    final hydraField7 = changes;
    if (hydraField7 != null) hydraOut['changes'] = hydraField7;
    final hydraField8 = warnings;
    if (hydraField8 != null) hydraOut['warnings'] = hydraField8;
    final hydraField9 = effects;
    if (hydraField9 != null) hydraOut['effects'] = hydraField9.toJson();
    final hydraField10 = currentEffects;
    if (hydraField10 != null) hydraOut['currentEffects'] = hydraField10.toJson();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutTelemetryDownsamplePlanResultCurrentEffects {
  const HydraPutTelemetryDownsamplePlanResultCurrentEffects({
    this.totals,
  });

  factory HydraPutTelemetryDownsamplePlanResultCurrentEffects.fromJson(Map<String, dynamic> json) => HydraPutTelemetryDownsamplePlanResultCurrentEffects(
        totals: json['totals'] == null ? null : HydraPutTelemetryDownsamplePlanResultCurrentEffectsTotals.fromJson(_hydraMap(json['totals'])),
      );

  final HydraPutTelemetryDownsamplePlanResultCurrentEffectsTotals? totals;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = totals;
    if (hydraField0 != null) hydraOut['totals'] = hydraField0.toJson();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutTelemetryDownsamplePlanResultCurrentEffectsTotals {
  const HydraPutTelemetryDownsamplePlanResultCurrentEffectsTotals({
    this.rawPointsToRollUp,
    this.rollupsToExpire,
    this.fineRollupsToExpire,
  });

  factory HydraPutTelemetryDownsamplePlanResultCurrentEffectsTotals.fromJson(Map<String, dynamic> json) => HydraPutTelemetryDownsamplePlanResultCurrentEffectsTotals(
        rawPointsToRollUp: json['rawPointsToRollUp'] == null ? null : json['rawPointsToRollUp'] as num,
        rollupsToExpire: json['rollupsToExpire'] == null ? null : json['rollupsToExpire'] as num,
        fineRollupsToExpire: json['fineRollupsToExpire'] == null ? null : json['fineRollupsToExpire'] as num,
      );

  final num? rawPointsToRollUp;
  final num? rollupsToExpire;
  final num? fineRollupsToExpire;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = rawPointsToRollUp;
    if (hydraField0 != null) hydraOut['rawPointsToRollUp'] = hydraField0;
    final hydraField1 = rollupsToExpire;
    if (hydraField1 != null) hydraOut['rollupsToExpire'] = hydraField1;
    final hydraField2 = fineRollupsToExpire;
    if (hydraField2 != null) hydraOut['fineRollupsToExpire'] = hydraField2;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutTelemetryDownsamplePlanResultEffects {
  const HydraPutTelemetryDownsamplePlanResultEffects({
    this.totals,
  });

  factory HydraPutTelemetryDownsamplePlanResultEffects.fromJson(Map<String, dynamic> json) => HydraPutTelemetryDownsamplePlanResultEffects(
        totals: json['totals'] == null ? null : HydraPutTelemetryDownsamplePlanResultEffectsTotals.fromJson(_hydraMap(json['totals'])),
      );

  final HydraPutTelemetryDownsamplePlanResultEffectsTotals? totals;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = totals;
    if (hydraField0 != null) hydraOut['totals'] = hydraField0.toJson();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutTelemetryDownsamplePlanResultEffectsTotals {
  const HydraPutTelemetryDownsamplePlanResultEffectsTotals({
    this.rawPointsToRollUp,
    this.rollupsToExpire,
    this.fineRollupsToExpire,
  });

  factory HydraPutTelemetryDownsamplePlanResultEffectsTotals.fromJson(Map<String, dynamic> json) => HydraPutTelemetryDownsamplePlanResultEffectsTotals(
        rawPointsToRollUp: json['rawPointsToRollUp'] == null ? null : json['rawPointsToRollUp'] as num,
        rollupsToExpire: json['rollupsToExpire'] == null ? null : json['rollupsToExpire'] as num,
        fineRollupsToExpire: json['fineRollupsToExpire'] == null ? null : json['fineRollupsToExpire'] as num,
      );

  final num? rawPointsToRollUp;
  final num? rollupsToExpire;
  final num? fineRollupsToExpire;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = rawPointsToRollUp;
    if (hydraField0 != null) hydraOut['rawPointsToRollUp'] = hydraField0;
    final hydraField1 = rollupsToExpire;
    if (hydraField1 != null) hydraOut['rollupsToExpire'] = hydraField1;
    final hydraField2 = fineRollupsToExpire;
    if (hydraField2 != null) hydraOut['fineRollupsToExpire'] = hydraField2;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraPutUsersByUsernameBody {
  const HydraPutUsersByUsernameBody({
    this.newUsername,
    this.password,
    this.role,
  });

  factory HydraPutUsersByUsernameBody.fromJson(Map<String, dynamic> json) => HydraPutUsersByUsernameBody(
        newUsername: json['newUsername'] == null ? null : json['newUsername'] as String,
        password: json['password'] == null ? null : json['password'] as String,
        role: json['role'] == null ? null : json['role'] as String,
      );

  final String? newUsername;
  final String? password;
  final String? role;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = newUsername;
    if (hydraField0 != null) hydraOut['newUsername'] = hydraField0;
    final hydraField1 = password;
    if (hydraField1 != null) hydraOut['password'] = hydraField1;
    final hydraField2 = role;
    if (hydraField2 != null) hydraOut['role'] = hydraField2;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraReachable {
  const HydraReachable({
    required this.reachable,
  });

  factory HydraReachable.fromJson(Map<String, dynamic> json) => HydraReachable(
        reachable: json['reachable'] as bool,
      );

  final bool reachable;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['reachable'] = reachable;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraRobotLiveness {
  const HydraRobotLiveness({
    required this.schemaVersion,
    required this.staleAfterS,
    required this.robots,
  });

  factory HydraRobotLiveness.fromJson(Map<String, dynamic> json) => HydraRobotLiveness(
        schemaVersion: json['schema_version'] as String,
        staleAfterS: (json['stale_after_s'] as num).toInt(),
        robots: (json['robots'] as List).map((v0) => HydraRobotLivenessRobotsItem.fromJson(_hydraMap(v0))).toList(),
      );

  final String schemaVersion;
  final int staleAfterS;
  final List<HydraRobotLivenessRobotsItem> robots;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['schema_version'] = schemaVersion;
    hydraOut['stale_after_s'] = staleAfterS;
    hydraOut['robots'] = robots.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// state is live (news within stale_after_s), stale (older news) or unknown (none since the server started). The flag online of the roster is not read.
class HydraRobotLivenessRobotsItem {
  const HydraRobotLivenessRobotsItem({
    required this.controllerId,
    required this.robotId,
    required this.state,
    this.lastUpdateUtc,
    this.ageS,
    this.source,
  });

  factory HydraRobotLivenessRobotsItem.fromJson(Map<String, dynamic> json) => HydraRobotLivenessRobotsItem(
        controllerId: json['controller_id'] as String,
        robotId: (json['robot_id'] as num).toInt(),
        state: json['state'] as String,
        lastUpdateUtc: json['last_update_utc'] == null ? null : json['last_update_utc'] as String,
        ageS: json['age_s'] == null ? null : (json['age_s'] as num).toInt(),
        source: json['source'] == null ? null : json['source'] as String,
      );

  final String controllerId;
  final int robotId;
  final String state;
  final String? lastUpdateUtc;
  final int? ageS;
  /// state (a command or a change of its state) or heartbeat.
  final String? source;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['controller_id'] = controllerId;
    hydraOut['robot_id'] = robotId;
    hydraOut['state'] = state;
    final hydraField3 = lastUpdateUtc;
    if (hydraField3 != null) hydraOut['last_update_utc'] = hydraField3;
    final hydraField4 = ageS;
    if (hydraField4 != null) hydraOut['age_s'] = hydraField4;
    final hydraField5 = source;
    if (hydraField5 != null) hydraOut['source'] = hydraField5;
    return hydraOut;
  }
}

/// What a signed-in client may read of the remaining-useful-life relay: whether an operator may use it and the two limits that size a request. Nothing else; closed (enabled false, 5000 points, 8000 ms) when the configuration is missing or damaged.
class HydraRulConfig {
  const HydraRulConfig({
    required this.enabled,
    required this.maxPoints,
    required this.timeoutMs,
  });

  factory HydraRulConfig.fromJson(Map<String, dynamic> json) => HydraRulConfig(
        enabled: json['enabled'] as bool,
        maxPoints: (json['maxPoints'] as num).toInt(),
        timeoutMs: (json['timeoutMs'] as num).toInt(),
      );

  /// True only when the relay is open to operators (rul.enabled, or HYDRA_UMC_RUL=1).
  final bool enabled;
  /// Largest number of points the relay accepts in one request.
  final int maxPoints;
  /// How long the relay waits for the detector, in milliseconds.
  final int timeoutMs;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['enabled'] = enabled;
    hydraOut['maxPoints'] = maxPoints;
    hydraOut['timeoutMs'] = timeoutMs;
    return hydraOut;
  }
}

/// The limits every client is held to (data/safety-limits.json), as saved by PUT /api/admin/safety-limits.
class HydraSafetyLimitsConfig {
  const HydraSafetyLimitsConfig({
    required this.jog,
    required this.temperature,
    required this.claims,
    required this.audit,
  });

  factory HydraSafetyLimitsConfig.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsConfig(
        jog: HydraSafetyLimitsConfigJog.fromJson(_hydraMap(json['jog'])),
        temperature: HydraSafetyLimitsConfigTemperature.fromJson(_hydraMap(json['temperature'])),
        claims: HydraSafetyLimitsConfigClaims.fromJson(_hydraMap(json['claims'])),
        audit: HydraSafetyLimitsConfigAudit.fromJson(_hydraMap(json['audit'])),
      );

  final HydraSafetyLimitsConfigJog jog;
  final HydraSafetyLimitsConfigTemperature temperature;
  final HydraSafetyLimitsConfigClaims claims;
  final HydraSafetyLimitsConfigAudit audit;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['jog'] = jog.toJson();
    hydraOut['temperature'] = temperature.toJson();
    hydraOut['claims'] = claims.toJson();
    hydraOut['audit'] = audit.toJson();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSafetyLimitsConfigAudit {
  const HydraSafetyLimitsConfigAudit({
    required this.enabled,
    required this.motionIntervalSeconds,
  });

  factory HydraSafetyLimitsConfigAudit.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsConfigAudit(
        enabled: json['enabled'] as bool,
        motionIntervalSeconds: json['motionIntervalSeconds'] as num,
      );

  final bool enabled;
  final num motionIntervalSeconds;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['enabled'] = enabled;
    hydraOut['motionIntervalSeconds'] = motionIntervalSeconds;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSafetyLimitsConfigClaims {
  const HydraSafetyLimitsConfigClaims({
    required this.requireControllerId,
  });

  factory HydraSafetyLimitsConfigClaims.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsConfigClaims(
        requireControllerId: json['requireControllerId'] as bool,
      );

  final bool requireControllerId;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['requireControllerId'] = requireControllerId;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSafetyLimitsConfigJog {
  const HydraSafetyLimitsConfigJog({
    required this.armRequired,
    required this.armTtlMs,
    required this.defaultValue,
    required this.models,
  });

  factory HydraSafetyLimitsConfigJog.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsConfigJog(
        armRequired: json['armRequired'] as bool,
        armTtlMs: json['armTtlMs'] as num,
        defaultValue: HydraSafetyLimitsConfigJogDefault.fromJson(_hydraMap(json['default'])),
        models: <String, HydraSafetyLimitsConfigJogModelsValue>{for (final entry0 in _hydraMap(json['models']).entries) entry0.key: HydraSafetyLimitsConfigJogModelsValue.fromJson(_hydraMap(entry0.value))},
      );

  final bool armRequired;
  final num armTtlMs;
  final HydraSafetyLimitsConfigJogDefault defaultValue;
  /// Per model (lower-case name before the parenthesis), the entries that differ from the default.
  final Map<String, HydraSafetyLimitsConfigJogModelsValue> models;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['armRequired'] = armRequired;
    hydraOut['armTtlMs'] = armTtlMs;
    hydraOut['default'] = defaultValue.toJson();
    hydraOut['models'] = <String, dynamic>{for (final entry0 in models.entries) entry0.key: entry0.value.toJson()};
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSafetyLimitsConfigJogDefault {
  const HydraSafetyLimitsConfigJogDefault({
    required this.maxAmount,
    required this.maxAbsolute,
  });

  factory HydraSafetyLimitsConfigJogDefault.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsConfigJogDefault(
        maxAmount: json['maxAmount'] as num,
        maxAbsolute: json['maxAbsolute'] as num,
      );

  final num maxAmount;
  final num maxAbsolute;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['maxAmount'] = maxAmount;
    hydraOut['maxAbsolute'] = maxAbsolute;
    return hydraOut;
  }
}

/// The limits of a relative and an absolute jog; a model entry names only what it changes.
class HydraSafetyLimitsConfigJogModelsValue {
  const HydraSafetyLimitsConfigJogModelsValue({
    this.maxAmount,
    this.maxAbsolute,
  });

  factory HydraSafetyLimitsConfigJogModelsValue.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsConfigJogModelsValue(
        maxAmount: json['maxAmount'] == null ? null : json['maxAmount'] as num,
        maxAbsolute: json['maxAbsolute'] == null ? null : json['maxAbsolute'] as num,
      );

  final num? maxAmount;
  final num? maxAbsolute;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = maxAmount;
    if (hydraField0 != null) hydraOut['maxAmount'] = hydraField0;
    final hydraField1 = maxAbsolute;
    if (hydraField1 != null) hydraOut['maxAbsolute'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSafetyLimitsConfigTemperature {
  const HydraSafetyLimitsConfigTemperature({
    required this.defaultValue,
    required this.models,
  });

  factory HydraSafetyLimitsConfigTemperature.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsConfigTemperature(
        defaultValue: HydraSafetyLimitsConfigTemperatureDefault.fromJson(_hydraMap(json['default'])),
        models: <String, HydraSafetyLimitsConfigTemperatureModelsValue>{for (final entry0 in _hydraMap(json['models']).entries) entry0.key: HydraSafetyLimitsConfigTemperatureModelsValue.fromJson(_hydraMap(entry0.value))},
      );

  final HydraSafetyLimitsConfigTemperatureDefault defaultValue;
  final Map<String, HydraSafetyLimitsConfigTemperatureModelsValue> models;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['default'] = defaultValue.toJson();
    hydraOut['models'] = <String, dynamic>{for (final entry0 in models.entries) entry0.key: entry0.value.toJson()};
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSafetyLimitsConfigTemperatureDefault {
  const HydraSafetyLimitsConfigTemperatureDefault({
    required this.bedMaxC,
  });

  factory HydraSafetyLimitsConfigTemperatureDefault.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsConfigTemperatureDefault(
        bedMaxC: json['bedMaxC'] as num,
      );

  final num bedMaxC;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['bedMaxC'] = bedMaxC;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSafetyLimitsConfigTemperatureModelsValue {
  const HydraSafetyLimitsConfigTemperatureModelsValue({
    this.bedMaxC,
  });

  factory HydraSafetyLimitsConfigTemperatureModelsValue.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsConfigTemperatureModelsValue(
        bedMaxC: json['bedMaxC'] == null ? null : json['bedMaxC'] as num,
      );

  final num? bedMaxC;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = bedMaxC;
    if (hydraField0 != null) hydraOut['bedMaxC'] = hydraField0;
    return hydraOut;
  }
}

/// GET /api/safety-limits: the limits in force, the defaults, the ceilings no value can pass and, when ?robotId= names a robot, the limits that apply to it.
class HydraSafetyLimitsView {
  const HydraSafetyLimitsView({
    required this.limits,
    required this.defaults,
    required this.hardLimits,
    this.robot,
  });

  factory HydraSafetyLimitsView.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsView(
        limits: HydraSafetyLimitsConfig.fromJson(_hydraMap(json['limits'])),
        defaults: HydraSafetyLimitsConfig.fromJson(_hydraMap(json['defaults'])),
        hardLimits: _hydraMap(json['hardLimits']),
        robot: json['robot'] == null ? null : HydraSafetyLimitsViewRobot.fromJson(_hydraMap(json['robot'])),
      );

  final HydraSafetyLimitsConfig limits;
  final HydraSafetyLimitsConfig defaults;
  /// The fixed ceilings (jogMaxAmount, jogMaxAbsolute, armTtlMs {min,max}, bedMaxC, auditMotionIntervalSeconds {min,max}); the set grows with the server.
  final Map<String, dynamic> hardLimits;
  final HydraSafetyLimitsViewRobot? robot;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['limits'] = limits.toJson();
    hydraOut['defaults'] = defaults.toJson();
    hydraOut['hardLimits'] = hardLimits;
    final hydraField3 = robot;
    if (hydraField3 != null) hydraOut['robot'] = hydraField3.toJson();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSafetyLimitsViewRobot {
  const HydraSafetyLimitsViewRobot({
    required this.id,
    this.model,
    required this.jog,
    required this.temperature,
    this.jogArmedUntil,
  });

  factory HydraSafetyLimitsViewRobot.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsViewRobot(
        id: (json['id'] as num).toInt(),
        model: json['model'] == null ? null : json['model'] as String,
        jog: HydraSafetyLimitsViewRobotJog.fromJson(_hydraMap(json['jog'])),
        temperature: HydraSafetyLimitsViewRobotTemperature.fromJson(_hydraMap(json['temperature'])),
        jogArmedUntil: json['jogArmedUntil'] == null ? null : json['jogArmedUntil'] as num,
      );

  final int id;
  final String? model;
  final HydraSafetyLimitsViewRobotJog jog;
  final HydraSafetyLimitsViewRobotTemperature temperature;
  /// Milliseconds since the epoch; null when the jog is not armed.
  final num? jogArmedUntil;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['id'] = id;
    final hydraField1 = model;
    if (hydraField1 != null) hydraOut['model'] = hydraField1;
    hydraOut['jog'] = jog.toJson();
    hydraOut['temperature'] = temperature.toJson();
    final hydraField4 = jogArmedUntil;
    if (hydraField4 != null) hydraOut['jogArmedUntil'] = hydraField4;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSafetyLimitsViewRobotJog {
  const HydraSafetyLimitsViewRobotJog({
    this.maxAmount,
    this.maxAbsolute,
  });

  factory HydraSafetyLimitsViewRobotJog.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsViewRobotJog(
        maxAmount: json['maxAmount'] == null ? null : json['maxAmount'] as num,
        maxAbsolute: json['maxAbsolute'] == null ? null : json['maxAbsolute'] as num,
      );

  final num? maxAmount;
  final num? maxAbsolute;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = maxAmount;
    if (hydraField0 != null) hydraOut['maxAmount'] = hydraField0;
    final hydraField1 = maxAbsolute;
    if (hydraField1 != null) hydraOut['maxAbsolute'] = hydraField1;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSafetyLimitsViewRobotTemperature {
  const HydraSafetyLimitsViewRobotTemperature({
    this.bedMaxC,
  });

  factory HydraSafetyLimitsViewRobotTemperature.fromJson(Map<String, dynamic> json) => HydraSafetyLimitsViewRobotTemperature(
        bedMaxC: json['bedMaxC'] == null ? null : json['bedMaxC'] as num,
      );

  final num? bedMaxC;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = bedMaxC;
    if (hydraField0 != null) hydraOut['bedMaxC'] = hydraField0;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSelfUpdateItem {
  const HydraSelfUpdateItem({
    required this.id,
    required this.repo,
    required this.installed,
    required this.previous,
    required this.latest,
    required this.state,
    required this.signedPackage,
  });

  factory HydraSelfUpdateItem.fromJson(Map<String, dynamic> json) => HydraSelfUpdateItem(
        id: json['id'] as String,
        repo: json['repo'] as String,
        installed: json['installed'] == null ? null : json['installed'] as String,
        previous: json['previous'] == null ? null : json['previous'] as String,
        latest: json['latest'] == null ? null : json['latest'] as String,
        state: json['state'] as String,
        signedPackage: json['signedPackage'] as bool,
      );

  final String id;
  final String repo;
  final String? installed;
  final String? previous;
  final String? latest;
  final String state;
  /// Whether the newest release carries the package, its hash and its signature.
  final bool signedPackage;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['id'] = id;
    hydraOut['repo'] = repo;
    hydraOut['installed'] = installed;
    hydraOut['previous'] = previous;
    hydraOut['latest'] = latest;
    hydraOut['state'] = state;
    hydraOut['signedPackage'] = signedPackage;
    return hydraOut;
  }
}

/// One update (or way back) of a program of this machine, step by step. It lives in a file, so it can be read again after the server restarts.
class HydraSelfUpdateJob {
  const HydraSelfUpdateJob({
    required this.id,
    required this.action,
    required this.component,
    required this.state,
    required this.fromVersion,
    required this.targetVersion,
    required this.startedAt,
    required this.updatedAt,
    required this.error,
    required this.detail,
    this.packageName,
    required this.log,
    required this.by,
  });

  factory HydraSelfUpdateJob.fromJson(Map<String, dynamic> json) => HydraSelfUpdateJob(
        id: json['id'] as String,
        action: json['action'] as String,
        component: json['component'] as String,
        state: json['state'] as String,
        fromVersion: json['fromVersion'] == null ? null : json['fromVersion'] as String,
        targetVersion: json['targetVersion'] == null ? null : json['targetVersion'] as String,
        startedAt: json['startedAt'] as String,
        updatedAt: json['updatedAt'] as String,
        error: json['error'] == null ? null : json['error'] as String,
        detail: json['detail'] as String,
        packageName: json['packageName'] == null ? null : json['packageName'] as String,
        log: (json['log'] as List).map((v0) => HydraSelfUpdateJobLogItem.fromJson(_hydraMap(v0))).toList(),
        by: json['by'] as String,
      );

  final String id;
  final String action;
  final String component;
  final String state;
  final String? fromVersion;
  final String? targetVersion;
  final String startedAt;
  final String updatedAt;
  final String? error;
  final String detail;
  final String? packageName;
  final List<HydraSelfUpdateJobLogItem> log;
  final String by;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['id'] = id;
    hydraOut['action'] = action;
    hydraOut['component'] = component;
    hydraOut['state'] = state;
    hydraOut['fromVersion'] = fromVersion;
    hydraOut['targetVersion'] = targetVersion;
    hydraOut['startedAt'] = startedAt;
    hydraOut['updatedAt'] = updatedAt;
    hydraOut['error'] = error;
    hydraOut['detail'] = detail;
    final hydraField10 = packageName;
    if (hydraField10 != null) hydraOut['packageName'] = hydraField10;
    hydraOut['log'] = log.map((v0) => v0.toJson()).toList();
    hydraOut['by'] = by;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSelfUpdateJobLogItem {
  const HydraSelfUpdateJobLogItem({
    required this.at,
    required this.step,
    required this.text,
  });

  factory HydraSelfUpdateJobLogItem.fromJson(Map<String, dynamic> json) => HydraSelfUpdateJobLogItem(
        at: json['at'] as String,
        step: json['step'] as String,
        text: json['text'] as String,
      );

  final String at;
  final String step;
  final String text;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['at'] = at;
    hydraOut['step'] = step;
    hydraOut['text'] = text;
    return hydraOut;
  }
}

/// The programs of this machine set against the newest signed release of each, whether applying is switched on, and the job that is going on or the last one.
class HydraSelfUpdateStatus {
  const HydraSelfUpdateStatus({
    required this.checkedAt,
    required this.owner,
    required this.rateLimited,
    required this.items,
    required this.applyEnabled,
    required this.job,
  });

  factory HydraSelfUpdateStatus.fromJson(Map<String, dynamic> json) => HydraSelfUpdateStatus(
        checkedAt: json['checkedAt'] == null ? null : json['checkedAt'] as String,
        owner: json['owner'] as String,
        rateLimited: json['rateLimited'] as bool,
        items: (json['items'] as List).map((v0) => HydraSelfUpdateItem.fromJson(_hydraMap(v0))).toList(),
        applyEnabled: json['applyEnabled'] as bool,
        job: json['job'] == null ? null : HydraSelfUpdateJob.fromJson(_hydraMap(json['job'])),
      );

  final String? checkedAt;
  final String owner;
  final bool rateLimited;
  final List<HydraSelfUpdateItem> items;
  final bool applyEnabled;
  final HydraSelfUpdateJob? job;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['checkedAt'] = checkedAt;
    hydraOut['owner'] = owner;
    hydraOut['rateLimited'] = rateLimited;
    hydraOut['items'] = items.map((v0) => v0.toJson()).toList();
    hydraOut['applyEnabled'] = applyEnabled;
    hydraOut['job'] = job?.toJson();
    return hydraOut;
  }
}

/// The listen port and, besides it, the security options of the server (the groups of PUT /api/admin/server-config: tls, ble, mqtt, voice, auth, ingest...). The groups grow with the server, so a key this list does not name is kept, not dropped.
class HydraServerConfig {
  const HydraServerConfig({
    required this.port,
    required this.pendingPort,
    this.additionalProperties = const <String, dynamic>{},
  });

  factory HydraServerConfig.fromJson(Map<String, dynamic> json) => HydraServerConfig(
        port: (json['port'] as num).toInt(),
        pendingPort: json['pendingPort'] == null ? null : (json['pendingPort'] as num).toInt(),
        additionalProperties: _hydraMap(<String, dynamic>{for (final entry in json.entries) if (!_knownKeys.contains(entry.key)) entry.key: entry.value}),
      );

  static const Set<String> _knownKeys = <String>{'port', 'pendingPort'};

  final int port;
  final int? pendingPort;
  /// The keys the contract does not list, kept as they came.
  final Map<String, dynamic> additionalProperties;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{...additionalProperties};
    hydraOut['port'] = port;
    hydraOut['pendingPort'] = pendingPort;
    return hydraOut;
  }
}

/// The identity this server presents to the services it calls: the switch (auth.serviceIdentity.enabled), whether JWT_SECRET can sign, and which services take the identity. Read-only; the switch is changed with PUT /api/admin/server-config.
class HydraServiceIdentityStatus {
  const HydraServiceIdentityStatus({
    required this.enabled,
    required this.source,
    required this.locked,
    required this.key,
    required this.state,
    required this.services,
    required this.order,
  });

  factory HydraServiceIdentityStatus.fromJson(Map<String, dynamic> json) => HydraServiceIdentityStatus(
        enabled: json['enabled'] as bool,
        source: json['source'] as String,
        locked: json['locked'] as bool,
        key: json['key'] as String,
        state: json['state'] as String,
        services: (json['services'] as List).map((v0) => HydraServiceIdentityStatusServicesItem.fromJson(_hydraMap(v0))).toList(),
        order: (json['order'] as List).map((v0) => v0 as String).toList(),
      );

  final bool enabled;
  final String source;
  /// True when the switch comes from the environment (HYDRA_UMC_SERVICE_IDENTITY) and cannot be changed here.
  final bool locked;
  /// Whether JWT_SECRET can sign: unset, an example value or too short is unusable.
  final String key;
  final String state;
  final List<HydraServiceIdentityStatusServicesItem> services;
  /// The safe order of the steps, as codes the screens translate.
  final List<String> order;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['enabled'] = enabled;
    hydraOut['source'] = source;
    hydraOut['locked'] = locked;
    hydraOut['key'] = key;
    hydraOut['state'] = state;
    hydraOut['services'] = services.map((v0) => v0.toJson()).toList();
    hydraOut['order'] = order;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraServiceIdentityStatusServicesItem {
  const HydraServiceIdentityStatusServicesItem({
    required this.name,
    required this.support,
  });

  factory HydraServiceIdentityStatusServicesItem.fromJson(Map<String, dynamic> json) => HydraServiceIdentityStatusServicesItem(
        name: json['name'] as String,
        support: json['support'] as String,
      );

  /// The short name of the service (the repository name without its prefix).
  final String name;
  final String support;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['name'] = name;
    hydraOut['support'] = support;
    return hydraOut;
  }
}

/// The full settings document. Controllers and their robots are listed under controllers[].robots.
class HydraSettings {
  const HydraSettings({
    this.controllers,
  });

  factory HydraSettings.fromJson(Map<String, dynamic> json) => HydraSettings(
        controllers: json['controllers'] == null ? null : (json['controllers'] as List).map((v0) => _hydraMap(v0)).toList(),
      );

  final List<Map<String, dynamic>>? controllers;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    final hydraField0 = controllers;
    if (hydraField0 != null) hydraOut['controllers'] = hydraField0;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraStopAllResult {
  const HydraStopAllResult({
    required this.success,
    required this.stoppedCount,
    required this.failedCount,
    required this.persisted,
    this.announced,
    required this.robots,
  });

  factory HydraStopAllResult.fromJson(Map<String, dynamic> json) => HydraStopAllResult(
        success: json['success'] as bool,
        stoppedCount: (json['stoppedCount'] as num).toInt(),
        failedCount: (json['failedCount'] as num).toInt(),
        persisted: json['persisted'] as bool,
        announced: json['announced'] == null ? null : json['announced'] as bool,
        robots: (json['robots'] as List).map((v0) => HydraStopAllResultRobotsItem.fromJson(_hydraMap(v0))).toList(),
      );

  final bool success;
  final int stoppedCount;
  final int failedCount;
  final bool persisted;
  /// Present only when announcing a global stop is configured (safety.publishGlobalStop): whether the retained SAFE_STOP went out on the MQTT bridge.
  final bool? announced;
  final List<HydraStopAllResultRobotsItem> robots;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['stoppedCount'] = stoppedCount;
    hydraOut['failedCount'] = failedCount;
    hydraOut['persisted'] = persisted;
    final hydraField4 = announced;
    if (hydraField4 != null) hydraOut['announced'] = hydraField4;
    hydraOut['robots'] = robots.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraStopAllResultRobotsItem {
  const HydraStopAllResultRobotsItem({
    required this.robotId,
    required this.controllerId,
    required this.name,
    required this.stopped,
    required this.valvesOff,
    required this.pumpsOff,
    this.reservedBy,
    this.error,
  });

  factory HydraStopAllResultRobotsItem.fromJson(Map<String, dynamic> json) => HydraStopAllResultRobotsItem(
        robotId: (json['robotId'] as num).toInt(),
        controllerId: json['controllerId'] as String,
        name: json['name'] as String,
        stopped: json['stopped'] as bool,
        valvesOff: (json['valvesOff'] as num).toInt(),
        pumpsOff: (json['pumpsOff'] as num).toInt(),
        reservedBy: json['reservedBy'] == null ? null : json['reservedBy'] as String,
        error: json['error'] == null ? null : json['error'] as String,
      );

  final int robotId;
  final String controllerId;
  final String name;
  final bool stopped;
  final int valvesOff;
  final int pumpsOff;
  final String? reservedBy;
  final String? error;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['robotId'] = robotId;
    hydraOut['controllerId'] = controllerId;
    hydraOut['name'] = name;
    hydraOut['stopped'] = stopped;
    hydraOut['valvesOff'] = valvesOff;
    hydraOut['pumpsOff'] = pumpsOff;
    final hydraField6 = reservedBy;
    if (hydraField6 != null) hydraOut['reservedBy'] = hydraField6;
    final hydraField7 = error;
    if (hydraField7 != null) hydraOut['error'] = hydraField7;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSuccess {
  const HydraSuccess({
    required this.success,
  });

  factory HydraSuccess.fromJson(Map<String, dynamic> json) => HydraSuccess(
        success: json['success'] as bool,
      );

  final bool success;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraSystemMetrics {
  const HydraSystemMetrics({
    required this.cpuLoad,
    required this.memoryUsage,
    required this.temp,
    required this.tempIsReal,
    required this.rp1Temp,
    required this.uptime,
    required this.network,
  });

  factory HydraSystemMetrics.fromJson(Map<String, dynamic> json) => HydraSystemMetrics(
        cpuLoad: json['cpu_load'] as num,
        memoryUsage: json['memory_usage'] as num,
        temp: json['temp'] == null ? null : json['temp'] as num,
        tempIsReal: json['temp_is_real'] as bool,
        rp1Temp: json['rp1_temp'] == null ? null : json['rp1_temp'] as num,
        uptime: json['uptime'] as num,
        network: _hydraMap(json['network']),
      );

  final num cpuLoad;
  final num memoryUsage;
  final num? temp;
  final bool tempIsReal;
  final num? rp1Temp;
  final num uptime;
  final Map<String, dynamic> network;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['cpu_load'] = cpuLoad;
    hydraOut['memory_usage'] = memoryUsage;
    hydraOut['temp'] = temp;
    hydraOut['temp_is_real'] = tempIsReal;
    hydraOut['rp1_temp'] = rp1Temp;
    hydraOut['uptime'] = uptime;
    hydraOut['network'] = network;
    return hydraOut;
  }
}

/// The answer of a reset of the arm state of one URTC tool changer: the robot and the tool that were reset. The reset moves nothing mechanical; it puts the tool changer back to the disarmed state it reports.
class HydraToolArmResetResult {
  const HydraToolArmResetResult({
    required this.success,
    required this.robot,
    required this.toolId,
  });

  factory HydraToolArmResetResult.fromJson(Map<String, dynamic> json) => HydraToolArmResetResult(
        success: json['success'] as bool,
        robot: json['robot'] as String,
        toolId: (json['toolId'] as num).toInt(),
      );

  final bool success;
  final String robot;
  final int toolId;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['robot'] = robot;
    hydraOut['toolId'] = toolId;
    return hydraOut;
  }
}

/// The arm state of the URTC tools as the safety zones service lists it, carried by the server unchanged (the schema tool-arms.schema.json is the contract of the service). The last report of each pair of robot and tool, how old it is, and whether it is stale; a stale report is not counted in armedCount, and a panel shows a stale armed tool as a warning and a stale disarmed tool as unknown. A restart of the service forgets the reports, which a panel sees as an empty list.
class HydraToolArmsReport {
  const HydraToolArmsReport({
    required this.schemaVersion,
    required this.ttlSeconds,
    required this.arms,
    required this.armedCount,
    required this.staleCount,
  });

  factory HydraToolArmsReport.fromJson(Map<String, dynamic> json) => HydraToolArmsReport(
        schemaVersion: json['schema_version'] as String,
        ttlSeconds: json['ttlSeconds'] as num,
        arms: (json['arms'] as List).map((v0) => HydraToolArmsReportArmsItem.fromJson(_hydraMap(v0))).toList(),
        armedCount: (json['armedCount'] as num).toInt(),
        staleCount: (json['staleCount'] as num).toInt(),
      );

  final String schemaVersion;
  final num ttlSeconds;
  final List<HydraToolArmsReportArmsItem> arms;
  final int armedCount;
  final int staleCount;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['schema_version'] = schemaVersion;
    hydraOut['ttlSeconds'] = ttlSeconds;
    hydraOut['arms'] = arms.map((v0) => v0.toJson()).toList();
    hydraOut['armedCount'] = armedCount;
    hydraOut['staleCount'] = staleCount;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraToolArmsReportArmsItem {
  const HydraToolArmsReportArmsItem({
    required this.robot,
    required this.toolId,
    required this.armed,
    this.by,
    required this.seq,
    required this.ageSeconds,
    required this.stale,
  });

  factory HydraToolArmsReportArmsItem.fromJson(Map<String, dynamic> json) => HydraToolArmsReportArmsItem(
        robot: json['robot'] as String,
        toolId: (json['toolId'] as num).toInt(),
        armed: json['armed'] as bool,
        by: json['by'] == null ? null : json['by'] as String,
        seq: (json['seq'] as num).toInt(),
        ageSeconds: json['ageSeconds'] as num,
        stale: json['stale'] as bool,
      );

  final String robot;
  final int toolId;
  final bool armed;
  final String? by;
  final int seq;
  final num ageSeconds;
  final bool stale;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['robot'] = robot;
    hydraOut['toolId'] = toolId;
    hydraOut['armed'] = armed;
    final hydraField3 = by;
    if (hydraField3 != null) hydraOut['by'] = hydraField3;
    hydraOut['seq'] = seq;
    hydraOut['ageSeconds'] = ageSeconds;
    hydraOut['stale'] = stale;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraTotpConfirmed {
  const HydraTotpConfirmed({
    required this.success,
    required this.recoveryCodes,
  });

  factory HydraTotpConfirmed.fromJson(Map<String, dynamic> json) => HydraTotpConfirmed(
        success: json['success'] as bool,
        recoveryCodes: (json['recoveryCodes'] as List).map((v0) => v0 as String).toList(),
      );

  final bool success;
  final List<String> recoveryCodes;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['recoveryCodes'] = recoveryCodes;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraTotpEnrolment {
  const HydraTotpEnrolment({
    required this.success,
    required this.secret,
    required this.uri,
  });

  factory HydraTotpEnrolment.fromJson(Map<String, dynamic> json) => HydraTotpEnrolment(
        success: json['success'] as bool,
        secret: json['secret'] as String,
        uri: json['uri'] as String,
      );

  final bool success;
  final String secret;
  final String uri;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['success'] = success;
    hydraOut['secret'] = secret;
    hydraOut['uri'] = uri;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraTotpStatus {
  const HydraTotpStatus({
    required this.enabled,
    required this.recoveryLeft,
  });

  factory HydraTotpStatus.fromJson(Map<String, dynamic> json) => HydraTotpStatus(
        enabled: json['enabled'] as bool,
        recoveryLeft: (json['recoveryLeft'] as num).toInt(),
      );

  final bool enabled;
  final int recoveryLeft;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['enabled'] = enabled;
    hydraOut['recoveryLeft'] = recoveryLeft;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraUpdateItem {
  const HydraUpdateItem({
    required this.name,
    required this.family,
    required this.installed,
    required this.latest,
    required this.state,
  });

  factory HydraUpdateItem.fromJson(Map<String, dynamic> json) => HydraUpdateItem(
        name: json['name'] as String,
        family: json['family'] == null ? null : json['family'] as String,
        installed: json['installed'] == null ? null : json['installed'] as String,
        latest: json['latest'] == null ? null : json['latest'] as String,
        state: json['state'] as String,
      );

  final String name;
  final String? family;
  final String? installed;
  /// The newest published release, or null when it could not be looked up.
  final String? latest;
  final String state;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['name'] = name;
    hydraOut['family'] = family;
    hydraOut['installed'] = installed;
    hydraOut['latest'] = latest;
    hydraOut['state'] = state;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraUpdateManifestVerdict {
  const HydraUpdateManifestVerdict({
    required this.accepted,
    required this.code,
    required this.keyId,
    required this.requireAsymmetricSignature,
  });

  factory HydraUpdateManifestVerdict.fromJson(Map<String, dynamic> json) => HydraUpdateManifestVerdict(
        accepted: json['accepted'] as bool,
        code: json['code'] as String,
        keyId: json['key_id'] == null ? null : json['key_id'] as String,
        requireAsymmetricSignature: json['require_asymmetric_signature'] as bool,
      );

  final bool accepted;
  final String code;
  /// The key that signed the manifest, or null when it carries no signature.
  final String? keyId;
  /// Whether the switch that refuses a manifest without an Ed25519 signature was on when the manifest was checked.
  final bool requireAsymmetricSignature;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['accepted'] = accepted;
    hydraOut['code'] = code;
    hydraOut['key_id'] = keyId;
    hydraOut['require_asymmetric_signature'] = requireAsymmetricSignature;
    return hydraOut;
  }
}

/// The installed version of each program set against its newest published release. It reports; it never installs anything.
class HydraUpdateReport {
  const HydraUpdateReport({
    required this.checkedAt,
    required this.owner,
    required this.rateLimited,
    required this.items,
  });

  factory HydraUpdateReport.fromJson(Map<String, dynamic> json) => HydraUpdateReport(
        checkedAt: json['checkedAt'] == null ? null : json['checkedAt'] as String,
        owner: json['owner'] as String,
        rateLimited: json['rateLimited'] as bool,
        items: (json['items'] as List).map((v0) => HydraUpdateItem.fromJson(_hydraMap(v0))).toList(),
      );

  final String? checkedAt;
  final String owner;
  /// True when GitHub refused for quota during the look; the programs it did not reach have no newest version.
  final bool rateLimited;
  final List<HydraUpdateItem> items;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['checkedAt'] = checkedAt;
    hydraOut['owner'] = owner;
    hydraOut['rateLimited'] = rateLimited;
    hydraOut['items'] = items.map((v0) => v0.toJson()).toList();
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraUsbDevices {
  const HydraUsbDevices({
    required this.devices,
  });

  factory HydraUsbDevices.fromJson(Map<String, dynamic> json) => HydraUsbDevices(
        devices: (json['devices'] as List).map((v0) => _hydraMap(v0)).toList(),
      );

  final List<Map<String, dynamic>> devices;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['devices'] = devices;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraUserList {
  const HydraUserList({
    required this.users,
  });

  factory HydraUserList.fromJson(Map<String, dynamic> json) => HydraUserList(
        users: (json['users'] as List).map((v0) => _hydraMap(v0)).toList(),
      );

  final List<Map<String, dynamic>> users;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['users'] = users;
    return hydraOut;
  }
}

/// The answer of POST /api/voice/confirm: the confirmation result of the voice interface and whether the server verified its signature. Keys the interface adds are kept.
class HydraVoiceConfirmResult {
  const HydraVoiceConfirmResult({
    required this.type,
    required this.status,
    this.requestId,
    this.intent,
    this.subject,
    required this.verified,
    this.additionalProperties = const <String, dynamic>{},
  });

  factory HydraVoiceConfirmResult.fromJson(Map<String, dynamic> json) => HydraVoiceConfirmResult(
        type: json['type'] as String,
        status: json['status'] as String,
        requestId: json['requestId'] == null ? null : json['requestId'] as String,
        intent: json['intent'] == null ? null : _hydraMap(json['intent']),
        subject: json['subject'] == null ? null : json['subject'] as String,
        verified: json['verified'] as bool,
        additionalProperties: _hydraMap(<String, dynamic>{for (final entry in json.entries) if (!_knownKeys.contains(entry.key)) entry.key: entry.value}),
      );

  static const Set<String> _knownKeys = <String>{'type', 'status', 'requestId', 'intent', 'subject', 'verified'};

  final String type;
  final String status;
  final String? requestId;
  final Map<String, dynamic>? intent;
  final String? subject;
  final bool verified;
  /// The keys the contract does not list, kept as they came.
  final Map<String, dynamic> additionalProperties;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{...additionalProperties};
    hydraOut['type'] = type;
    hydraOut['status'] = status;
    final hydraField2 = requestId;
    if (hydraField2 != null) hydraOut['requestId'] = hydraField2;
    final hydraField3 = intent;
    if (hydraField3 != null) hydraOut['intent'] = hydraField3;
    final hydraField4 = subject;
    if (hydraField4 != null) hydraOut['subject'] = hydraField4;
    hydraOut['verified'] = verified;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraVoiceReply {
  const HydraVoiceReply({
    required this.type,
    required this.requestId,
    required this.text,
    required this.level,
    required this.speak,
    required this.requiresConfirmation,
    this.visualState,
    this.intent,
    this.interpretation,
    this.messageCode,
    this.messageParams,
    this.textLanguage,
    this.confirmationToken,
    this.confirmationValiditySeconds,
  });

  factory HydraVoiceReply.fromJson(Map<String, dynamic> json) => HydraVoiceReply(
        type: json['type'] as String,
        requestId: json['requestId'] as String,
        text: json['text'] as String,
        level: json['level'] as String,
        speak: json['speak'] as bool,
        requiresConfirmation: json['requiresConfirmation'] as bool,
        visualState: json['visualState'] == null ? null : json['visualState'] as String,
        intent: json['intent'] == null ? null : _hydraMap(json['intent']),
        interpretation: json['interpretation'] == null ? null : _hydraMap(json['interpretation']),
        messageCode: json['messageCode'] == null ? null : json['messageCode'] as String,
        messageParams: json['messageParams'] == null ? null : _hydraMap(json['messageParams']),
        textLanguage: json['textLanguage'] == null ? null : json['textLanguage'] as String,
        confirmationToken: json['confirmationToken'] == null ? null : json['confirmationToken'] as String,
        confirmationValiditySeconds: json['confirmationValiditySeconds'] == null ? null : json['confirmationValiditySeconds'] as num,
      );

  final String type;
  final String requestId;
  final String text;
  final String level;
  final bool speak;
  final bool requiresConfirmation;
  final String? visualState;
  final Map<String, dynamic>? intent;
  final Map<String, dynamic>? interpretation;
  final String? messageCode;
  final Map<String, dynamic>? messageParams;
  final String? textLanguage;
  final String? confirmationToken;
  final num? confirmationValiditySeconds;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['type'] = type;
    hydraOut['requestId'] = requestId;
    hydraOut['text'] = text;
    hydraOut['level'] = level;
    hydraOut['speak'] = speak;
    hydraOut['requiresConfirmation'] = requiresConfirmation;
    final hydraField6 = visualState;
    if (hydraField6 != null) hydraOut['visualState'] = hydraField6;
    final hydraField7 = intent;
    if (hydraField7 != null) hydraOut['intent'] = hydraField7;
    final hydraField8 = interpretation;
    if (hydraField8 != null) hydraOut['interpretation'] = hydraField8;
    final hydraField9 = messageCode;
    if (hydraField9 != null) hydraOut['messageCode'] = hydraField9;
    final hydraField10 = messageParams;
    if (hydraField10 != null) hydraOut['messageParams'] = hydraField10;
    final hydraField11 = textLanguage;
    if (hydraField11 != null) hydraOut['textLanguage'] = hydraField11;
    final hydraField12 = confirmationToken;
    if (hydraField12 != null) hydraOut['confirmationToken'] = hydraField12;
    final hydraField13 = confirmationValiditySeconds;
    if (hydraField13 != null) hydraOut['confirmationValiditySeconds'] = hydraField13;
    return hydraOut;
  }
}

/// An object of the server contract.
class HydraWatchStatus {
  const HydraWatchStatus({
    required this.type,
    required this.headline,
    required this.detail,
    required this.level,
    required this.speak,
  });

  factory HydraWatchStatus.fromJson(Map<String, dynamic> json) => HydraWatchStatus(
        type: json['type'] as String,
        headline: json['headline'] as String,
        detail: json['detail'] as String,
        level: json['level'] as String,
        speak: json['speak'] as bool,
      );

  final String type;
  final String headline;
  final String detail;
  final String level;
  final bool speak;

  Map<String, dynamic> toJson() {
    final hydraOut = <String, dynamic>{};
    hydraOut['type'] = type;
    hydraOut['headline'] = headline;
    hydraOut['detail'] = detail;
    hydraOut['level'] = level;
    hydraOut['speak'] = speak;
    return hydraOut;
  }
}

Map<String, dynamic> _hydraMap(Object? value) => Map<String, dynamic>.from(value as Map);

R? _hydraNullable<S, R>(S? value, R Function(S) encode) => value == null ? null : encode(value);

class HydraRequest {
  const HydraRequest(this.method, this.path, this.query, this.body, this.access, {this.headers = const <String, String>{}, this.contentType, this.responseType, this.replyHeaders = const <String>[]});
  final String method;
  final String path;
  final Map<String, String> query;
  final Object? body;
  final String access;
  final Map<String, String> headers;
  /// The media type of a body that is not JSON.
  final String? contentType;
  /// 'text' or 'binary' when the answer is not JSON.
  final String? responseType;
  /// The response headers to hand back in a HydraReply (set for the WithHeaders methods).
  final List<String> replyHeaders;
}

/// The answer of a route that declares response headers: the decoded body and the headers under their declared names (ETag, X-Next-Cursor).
class HydraReply<T> {
  const HydraReply(this.body, this.headers);
  final T body;
  final Map<String, String> headers;
}

/// Carries one request to the server and returns the decoded answer (null when there is none); a request with replyHeaders gets a HydraReply.
typedef HydraTransport = Future<dynamic> Function(HydraRequest request);

String fillPath(String template, Map<String, Object> values) {
  return template.replaceAllMapped(RegExp(r'\{([^}]+)\}'), (match) {
    final value = values[match.group(1)]?.toString();
    if (value == null || value.isEmpty) {
      throw ArgumentError('missing path parameter ${match.group(1)}');
    }
    return Uri.encodeComponent(value);
  });
}

Map<String, String> queryOf(Map<String, Object?> values) {
  return {
    for (final entry in values.entries)
      if (entry.value != null) entry.key: entry.value.toString(),
  };
}

class HydraServerClient {
  HydraServerClient(this._transport);

  final HydraTransport _transport;

  /// GET /.well-known/jwks.json (access: public)
  Future<HydraJwksDocument> getWellKnownJwksJson() async {
    final raw = await _transport(HydraRequest('GET', '/.well-known/jwks.json', const <String, String>{}, null, 'public'));
    return HydraJwksDocument.fromJson(_hydraMap(raw));
  }

  /// GET /api/adapters (access: user)
  Future<Map<String, dynamic>> getAdapters() async {
    final raw = await _transport(HydraRequest('GET', '/api/adapters', const <String, String>{}, null, 'user'));
    return _hydraMap(raw);
  }

  /// GET /api/adapters/{adapterId} (access: user)
  Future<void> getAdaptersByAdapterId({required String adapterId}) async {
    await _transport(HydraRequest('GET', fillPath('/api/adapters/{adapterId}', {'adapterId': adapterId}), const <String, String>{}, null, 'user'));
  }

  /// GET /api/admin/clients (access: admin)
  Future<HydraClients> getAdminClients() async {
    final raw = await _transport(HydraRequest('GET', '/api/admin/clients', const <String, String>{}, null, 'admin'));
    return HydraClients.fromJson(_hydraMap(raw));
  }

  /// GET /api/admin/device-tokens (access: admin)
  Future<HydraDeviceTokenList> getAdminDeviceTokens() async {
    final raw = await _transport(HydraRequest('GET', '/api/admin/device-tokens', const <String, String>{}, null, 'admin'));
    return HydraDeviceTokenList.fromJson(_hydraMap(raw));
  }

  /// POST /api/admin/device-tokens (access: admin)
  Future<HydraDeviceTokenIssued> postAdminDeviceTokens({required HydraPostAdminDeviceTokensBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/admin/device-tokens', const <String, String>{}, body.toJson(), 'admin'));
    return HydraDeviceTokenIssued.fromJson(_hydraMap(raw));
  }

  /// DELETE /api/admin/device-tokens/{id} (access: admin)
  Future<HydraDeviceTokenRevoked> deleteAdminDeviceTokensById({required String id}) async {
    final raw = await _transport(HydraRequest('DELETE', fillPath('/api/admin/device-tokens/{id}', {'id': id}), const <String, String>{}, null, 'admin'));
    return HydraDeviceTokenRevoked.fromJson(_hydraMap(raw));
  }

  /// GET /api/admin/fleet-update (access: admin)
  Future<HydraFleetUpdateStatus> getAdminFleetUpdate() async {
    final raw = await _transport(HydraRequest('GET', '/api/admin/fleet-update', const <String, String>{}, null, 'admin'));
    return HydraFleetUpdateStatus.fromJson(_hydraMap(raw));
  }

  /// POST /api/admin/fleet-update/apply (access: admin)
  Future<HydraFleetUpdateStatus> postAdminFleetUpdateApply({required HydraPostAdminFleetUpdateApplyBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/admin/fleet-update/apply', const <String, String>{}, body.toJson(), 'admin'));
    return HydraFleetUpdateStatus.fromJson(_hydraMap(raw));
  }

  /// POST /api/admin/fleet-update/plan (access: admin)
  Future<HydraFleetUpdateStatus> postAdminFleetUpdatePlan() async {
    final raw = await _transport(HydraRequest('POST', '/api/admin/fleet-update/plan', const <String, String>{}, null, 'admin'));
    return HydraFleetUpdateStatus.fromJson(_hydraMap(raw));
  }

  /// POST /api/admin/fleet-update/resume (access: admin)
  Future<HydraFleetUpdateStatus> postAdminFleetUpdateResume({required HydraPostAdminFleetUpdateResumeBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/admin/fleet-update/resume', const <String, String>{}, body.toJson(), 'admin'));
    return HydraFleetUpdateStatus.fromJson(_hydraMap(raw));
  }

  /// GET /api/admin/jwt-keys (access: admin)
  Future<HydraJwtKeys> getAdminJwtKeys() async {
    final raw = await _transport(HydraRequest('GET', '/api/admin/jwt-keys', const <String, String>{}, null, 'admin'));
    return HydraJwtKeys.fromJson(_hydraMap(raw));
  }

  /// POST /api/admin/jwt-keys/rotate (access: admin)
  Future<HydraJwtKeyRotated> postAdminJwtKeysRotate() async {
    final raw = await _transport(HydraRequest('POST', '/api/admin/jwt-keys/rotate', const <String, String>{}, null, 'admin'));
    return HydraJwtKeyRotated.fromJson(_hydraMap(raw));
  }

  /// GET /api/admin/logs (access: admin)
  Future<HydraLogLines> getAdminLogs({String? lines}) async {
    final raw = await _transport(HydraRequest('GET', '/api/admin/logs', queryOf({'lines': lines}), null, 'admin'));
    return HydraLogLines.fromJson(_hydraMap(raw));
  }

  /// POST /api/admin/maintenance/install (access: admin)
  Future<HydraMaintenanceOutcome> postAdminMaintenanceInstall({required HydraPostAdminMaintenanceInstallBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/admin/maintenance/install', const <String, String>{}, body.toJson(), 'admin'));
    return HydraMaintenanceOutcome.fromJson(_hydraMap(raw));
  }

  /// POST /api/admin/maintenance/prune (access: admin)
  Future<HydraMaintenanceOutcome> postAdminMaintenancePrune({required HydraPostAdminMaintenancePruneBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/admin/maintenance/prune', const <String, String>{}, body.toJson(), 'admin'));
    return HydraMaintenanceOutcome.fromJson(_hydraMap(raw));
  }

  /// POST /api/admin/maintenance/rollback (access: admin)
  Future<HydraMaintenanceOutcome> postAdminMaintenanceRollback({required HydraPostAdminMaintenanceRollbackBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/admin/maintenance/rollback', const <String, String>{}, body.toJson(), 'admin'));
    return HydraMaintenanceOutcome.fromJson(_hydraMap(raw));
  }

  /// GET /api/admin/maintenance/status (access: admin)
  Future<HydraMaintenanceOutcome> getAdminMaintenanceStatus({String? component}) async {
    final raw = await _transport(HydraRequest('GET', '/api/admin/maintenance/status', queryOf({'component': component}), null, 'admin'));
    return HydraMaintenanceOutcome.fromJson(_hydraMap(raw));
  }

  /// GET /api/admin/push (access: admin)
  Future<HydraPushStatus> getAdminPush() async {
    final raw = await _transport(HydraRequest('GET', '/api/admin/push', const <String, String>{}, null, 'admin'));
    return HydraPushStatus.fromJson(_hydraMap(raw));
  }

  /// POST /api/admin/restart (access: admin)
  Future<HydraSuccess> postAdminRestart() async {
    final raw = await _transport(HydraRequest('POST', '/api/admin/restart', const <String, String>{}, null, 'admin'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// GET /api/admin/robot-ids (access: admin)
  Future<HydraGetAdminRobotIdsResult> getAdminRobotIds() async {
    final raw = await _transport(HydraRequest('GET', '/api/admin/robot-ids', const <String, String>{}, null, 'admin'));
    return HydraGetAdminRobotIdsResult.fromJson(_hydraMap(raw));
  }

  /// PUT /api/admin/safety-limits (access: admin)
  Future<HydraPutAdminSafetyLimitsResult> putAdminSafetyLimits({required HydraPutAdminSafetyLimitsBody body}) async {
    final raw = await _transport(HydraRequest('PUT', '/api/admin/safety-limits', const <String, String>{}, body.toJson(), 'admin'));
    return HydraPutAdminSafetyLimitsResult.fromJson(_hydraMap(raw));
  }

  /// GET /api/admin/self-update (access: admin)
  Future<HydraSelfUpdateStatus> getAdminSelfUpdate({String? refresh}) async {
    final raw = await _transport(HydraRequest('GET', '/api/admin/self-update', queryOf({'refresh': refresh}), null, 'admin'));
    return HydraSelfUpdateStatus.fromJson(_hydraMap(raw));
  }

  /// POST /api/admin/self-update/apply (access: admin)
  Future<HydraSelfUpdateJob> postAdminSelfUpdateApply({required HydraPostAdminSelfUpdateApplyBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/admin/self-update/apply', const <String, String>{}, body.toJson(), 'admin'));
    return HydraSelfUpdateJob.fromJson(_hydraMap(raw));
  }

  /// GET /api/admin/self-update/jobs/{id} (access: admin)
  Future<HydraSelfUpdateJob> getAdminSelfUpdateJobsById({required String id}) async {
    final raw = await _transport(HydraRequest('GET', fillPath('/api/admin/self-update/jobs/{id}', {'id': id}), const <String, String>{}, null, 'admin'));
    return HydraSelfUpdateJob.fromJson(_hydraMap(raw));
  }

  /// POST /api/admin/self-update/rollback (access: admin)
  Future<HydraSelfUpdateJob> postAdminSelfUpdateRollback({required HydraPostAdminSelfUpdateRollbackBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/admin/self-update/rollback', const <String, String>{}, body.toJson(), 'admin'));
    return HydraSelfUpdateJob.fromJson(_hydraMap(raw));
  }

  /// GET /api/admin/server-config (access: admin)
  Future<HydraServerConfig> getAdminServerConfig() async {
    final raw = await _transport(HydraRequest('GET', '/api/admin/server-config', const <String, String>{}, null, 'admin'));
    return HydraServerConfig.fromJson(_hydraMap(raw));
  }

  /// PUT /api/admin/server-config (access: admin)
  Future<HydraPutAdminServerConfigResult> putAdminServerConfig({HydraPutAdminServerConfigBody? body}) async {
    final raw = await _transport(HydraRequest('PUT', '/api/admin/server-config', const <String, String>{}, body?.toJson(), 'admin'));
    return HydraPutAdminServerConfigResult.fromJson(_hydraMap(raw));
  }

  /// GET /api/admin/service-identity (access: admin)
  Future<HydraServiceIdentityStatus> getAdminServiceIdentity() async {
    final raw = await _transport(HydraRequest('GET', '/api/admin/service-identity', const <String, String>{}, null, 'admin'));
    return HydraServiceIdentityStatus.fromJson(_hydraMap(raw));
  }

  /// GET /api/admin/updates (access: admin)
  Future<HydraUpdateReport> getAdminUpdates({String? refresh}) async {
    final raw = await _transport(HydraRequest('GET', '/api/admin/updates', queryOf({'refresh': refresh}), null, 'admin'));
    return HydraUpdateReport.fromJson(_hydraMap(raw));
  }

  /// POST /api/admin/updates/manifest/check (access: admin)
  Future<HydraUpdateManifestVerdict> postAdminUpdatesManifestCheck({required Map<String, dynamic> body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/admin/updates/manifest/check', const <String, String>{}, body, 'admin'));
    return HydraUpdateManifestVerdict.fromJson(_hydraMap(raw));
  }

  /// GET /api/anomaly/verdicts (access: user)
  Future<void> getAnomalyVerdicts({String? verdict, String? verify}) async {
    await _transport(HydraRequest('GET', '/api/anomaly/verdicts', queryOf({'verdict': verdict, 'verify': verify}), null, 'user'));
  }

  /// GET /api/audit (access: admin)
  Future<HydraAuditReport> getAudit({String? afterSeq, String? format, String? limit, String? robotId, String? type, String? verify}) async {
    final raw = await _transport(HydraRequest('GET', '/api/audit', queryOf({'afterSeq': afterSeq, 'format': format, 'limit': limit, 'robotId': robotId, 'type': type, 'verify': verify}), null, 'admin'));
    return HydraAuditReport.fromJson(_hydraMap(raw));
  }

  /// GET /api/audit (access: admin); the answer as text, the way the route offers it besides JSON.
  Future<String> getAuditAsText({String? afterSeq, String? format, String? limit, String? robotId, String? type, String? verify}) async {
    return (await _transport(HydraRequest('GET', '/api/audit', queryOf({'afterSeq': afterSeq, 'format': format, 'limit': limit, 'robotId': robotId, 'type': type, 'verify': verify}), null, 'admin', responseType: 'text'))) as String;
  }

  /// GET /api/bridges (access: user)
  Future<HydraBridgeList> getBridges() async {
    final raw = await _transport(HydraRequest('GET', '/api/bridges', const <String, String>{}, null, 'user'));
    return HydraBridgeList.fromJson(_hydraMap(raw));
  }

  /// POST /api/bridges/{name}/cmd/{verb} (access: user)
  Future<HydraBridgeCommandAccepted> postBridgesByNameCmdByVerb({required String name, required String verb, Map<String, dynamic>? body}) async {
    final raw = await _transport(HydraRequest('POST', fillPath('/api/bridges/{name}/cmd/{verb}', {'name': name, 'verb': verb}), const <String, String>{}, body, 'user'));
    return HydraBridgeCommandAccepted.fromJson(_hydraMap(raw));
  }

  /// GET /api/bridges/{name}/state (access: user)
  Future<HydraBridgeState> getBridgesByNameState({required String name}) async {
    final raw = await _transport(HydraRequest('GET', fillPath('/api/bridges/{name}/state', {'name': name}), const <String, String>{}, null, 'user'));
    return HydraBridgeState.fromJson(_hydraMap(raw));
  }

  /// POST /api/camera/discover-rtsp-path (access: admin)
  Future<void> postCameraDiscoverRtspPath({required HydraPostCameraDiscoverRtspPathBody body}) async {
    await _transport(HydraRequest('POST', '/api/camera/discover-rtsp-path', const <String, String>{}, body.toJson(), 'admin'));
  }

  /// GET /api/camera/discover-usb-devices (access: user)
  Future<HydraUsbDevices> getCameraDiscoverUsbDevices() async {
    final raw = await _transport(HydraRequest('GET', '/api/camera/discover-usb-devices', const <String, String>{}, null, 'user'));
    return HydraUsbDevices.fromJson(_hydraMap(raw));
  }

  /// GET /api/camera/media (access: user)
  Future<HydraCameraMediaList> getCameraMedia() async {
    final raw = await _transport(HydraRequest('GET', '/api/camera/media', const <String, String>{}, null, 'user'));
    return HydraCameraMediaList.fromJson(_hydraMap(raw));
  }

  /// GET /api/camera/media/{cameraId}/{kind}/{filename} (access: public)
  Future<void> getCameraMediaByCameraIdByKindByFilename({required int cameraId, required String kind, required String filename}) async {
    await _transport(HydraRequest('GET', fillPath('/api/camera/media/{cameraId}/{kind}/{filename}', {'cameraId': cameraId, 'kind': kind, 'filename': filename}), const <String, String>{}, null, 'public'));
  }

  /// DELETE /api/camera/media/{cameraId}/{kind}/{filename} (access: user)
  Future<HydraCameraCapture> deleteCameraMediaByCameraIdByKindByFilename({required int cameraId, required String kind, required String filename}) async {
    final raw = await _transport(HydraRequest('DELETE', fillPath('/api/camera/media/{cameraId}/{kind}/{filename}', {'cameraId': cameraId, 'kind': kind, 'filename': filename}), const <String, String>{}, null, 'user'));
    return HydraCameraCapture.fromJson(_hydraMap(raw));
  }

  /// POST /api/camera/ticket (access: user)
  Future<void> postCameraTicket() async {
    await _transport(HydraRequest('POST', '/api/camera/ticket', const <String, String>{}, null, 'user'));
  }

  /// POST /api/camera/{id}/ptz (access: admin)
  Future<HydraPtzResult> postCameraByIdPtz({required int id, required HydraPostCameraByIdPtzBody body}) async {
    final raw = await _transport(HydraRequest('POST', fillPath('/api/camera/{id}/ptz', {'id': id}), const <String, String>{}, body.toJson(), 'admin'));
    return HydraPtzResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/camera/{id}/recording/start (access: user)
  Future<HydraCameraCapture> postCameraByIdRecordingStart({required int id}) async {
    final raw = await _transport(HydraRequest('POST', fillPath('/api/camera/{id}/recording/start', {'id': id}), const <String, String>{}, null, 'user'));
    return HydraCameraCapture.fromJson(_hydraMap(raw));
  }

  /// POST /api/camera/{id}/recording/stop (access: user)
  Future<HydraCameraCapture> postCameraByIdRecordingStop({required int id}) async {
    final raw = await _transport(HydraRequest('POST', fillPath('/api/camera/{id}/recording/stop', {'id': id}), const <String, String>{}, null, 'user'));
    return HydraCameraCapture.fromJson(_hydraMap(raw));
  }

  /// POST /api/camera/{id}/snapshot (access: user)
  Future<HydraCameraCapture> postCameraByIdSnapshot({required int id}) async {
    final raw = await _transport(HydraRequest('POST', fillPath('/api/camera/{id}/snapshot', {'id': id}), const <String, String>{}, null, 'user'));
    return HydraCameraCapture.fromJson(_hydraMap(raw));
  }

  /// GET /api/camera/{id}/stream (access: public)
  Future<void> getCameraByIdStream({required int id}) async {
    await _transport(HydraRequest('GET', fillPath('/api/camera/{id}/stream', {'id': id}), const <String, String>{}, null, 'public'));
  }

  /// GET /api/cameras/status (access: user)
  Future<Map<String, HydraCameraProcessStatusValue>> getCamerasStatus() async {
    final raw = await _transport(HydraRequest('GET', '/api/cameras/status', const <String, String>{}, null, 'user'));
    return <String, HydraCameraProcessStatusValue>{for (final entry0 in _hydraMap(raw).entries) entry0.key: HydraCameraProcessStatusValue.fromJson(_hydraMap(entry0.value))};
  }

  /// GET /api/claims (access: user)
  Future<HydraClaimList> getClaims() async {
    final raw = await _transport(HydraRequest('GET', '/api/claims', const <String, String>{}, null, 'user'));
    return HydraClaimList.fromJson(_hydraMap(raw));
  }

  /// List the clients the server has seen (access: user)
  Future<HydraConnectionClientList> getConnectionsClients({String? kind, String? user, String? active}) async {
    final raw = await _transport(HydraRequest('GET', '/api/connections/clients', queryOf({'kind': kind, 'user': user, 'active': active}), null, 'user'));
    return HydraConnectionClientList.fromJson(_hydraMap(raw));
  }

  /// List the history of the sign-ins of the clients (access: user)
  Future<HydraConnectionEventList> getConnectionsEvents({String? kind, String? action, String? user, String? before, String? limit}) async {
    final raw = await _transport(HydraRequest('GET', '/api/connections/events', queryOf({'kind': kind, 'action': action, 'user': user, 'before': before, 'limit': limit}), null, 'user'));
    return HydraConnectionEventList.fromJson(_hydraMap(raw));
  }

  /// GET /api/connector-hub/gate/audit (access: user)
  Future<Map<String, dynamic>> getConnectorHubGateAudit() async {
    final raw = await _transport(HydraRequest('GET', '/api/connector-hub/gate/audit', const <String, String>{}, null, 'user'));
    return _hydraMap(raw);
  }

  /// POST /api/connector-hub/gate/evaluate (access: user)
  Future<Map<String, dynamic>> postConnectorHubGateEvaluate() async {
    final raw = await _transport(HydraRequest('POST', '/api/connector-hub/gate/evaluate', const <String, String>{}, null, 'user'));
    return _hydraMap(raw);
  }

  /// GET /api/connector-hub/gate/settings (access: user)
  Future<HydraGetConnectorHubGateSettingsResult> getConnectorHubGateSettings() async {
    final raw = await _transport(HydraRequest('GET', '/api/connector-hub/gate/settings', const <String, String>{}, null, 'user'));
    return HydraGetConnectorHubGateSettingsResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/connector-hub/gate/settings (access: admin)
  Future<HydraPostConnectorHubGateSettingsResult> postConnectorHubGateSettings({required HydraPostConnectorHubGateSettingsBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/connector-hub/gate/settings', const <String, String>{}, body.toJson(), 'admin'));
    return HydraPostConnectorHubGateSettingsResult.fromJson(_hydraMap(raw));
  }

  /// GET /api/dev-server/status (access: user)
  Future<void> getDevServerStatus({String? verify}) async {
    await _transport(HydraRequest('GET', '/api/dev-server/status', queryOf({'verify': verify}), null, 'user'));
  }

  /// POST /api/device/login (access: public)
  Future<HydraLoginResult> postDeviceLogin({required HydraPostDeviceLoginBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/device/login', const <String, String>{}, body.toJson(), 'public'));
    return HydraLoginResult.fromJson(_hydraMap(raw));
  }

  /// GET /api/droid-estop/settings (access: user)
  Future<HydraGetDroidEstopSettingsResult> getDroidEstopSettings() async {
    final raw = await _transport(HydraRequest('GET', '/api/droid-estop/settings', const <String, String>{}, null, 'user'));
    return HydraGetDroidEstopSettingsResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/droid-estop/settings (access: admin)
  Future<HydraPostDroidEstopSettingsResult> postDroidEstopSettings({required HydraPostDroidEstopSettingsBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/droid-estop/settings', const <String, String>{}, body.toJson(), 'admin'));
    return HydraPostDroidEstopSettingsResult.fromJson(_hydraMap(raw));
  }

  /// GET /api/ecosystem/health (access: user)
  Future<HydraEcosystemHealth> getEcosystemHealth() async {
    final raw = await _transport(HydraRequest('GET', '/api/ecosystem/health', const <String, String>{}, null, 'user'));
    return HydraEcosystemHealth.fromJson(_hydraMap(raw));
  }

  /// GET /api/ecosystem/node-health (access: user)
  Future<HydraNodeHealth> getEcosystemNodeHealth({String? slot}) async {
    final raw = await _transport(HydraRequest('GET', '/api/ecosystem/node-health', queryOf({'slot': slot}), null, 'user'));
    return HydraNodeHealth.fromJson(_hydraMap(raw));
  }

  /// POST /api/ecosystem/service/{unit}/{action} (access: admin)
  Future<HydraSuccess> postEcosystemServiceByUnitByAction({required String unit, required String action}) async {
    final raw = await _transport(HydraRequest('POST', fillPath('/api/ecosystem/service/{unit}/{action}', {'unit': unit, 'action': action}), const <String, String>{}, null, 'admin'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// GET /api/ecosystem/status (access: public)
  Future<HydraEcosystemStatus> getEcosystemStatus() async {
    final raw = await _transport(HydraRequest('GET', '/api/ecosystem/status', const <String, String>{}, null, 'public'));
    return HydraEcosystemStatus.fromJson(_hydraMap(raw));
  }

  /// GET /api/faults (access: user)
  Future<void> getFaults({String? active, String? limit, String? verify}) async {
    await _transport(HydraRequest('GET', '/api/faults', queryOf({'active': active, 'limit': limit, 'verify': verify}), null, 'user'));
  }

  /// POST /api/hardware/canota/flash (access: admin)
  Future<HydraCanotaFlash> postHardwareCanotaFlash({required List<int> body, String? tier, String? slot, String? relay, String? hardwareId, String? versionMajor, String? versionMinor, String? versionPatch, String? signature, String? downgradeFrom, String? target, String? minBootloader}) async {
    final raw = await _transport(HydraRequest('POST', '/api/hardware/canota/flash', queryOf({'tier': tier, 'slot': slot, 'relay': relay, 'hardware_id': hardwareId, 'version_major': versionMajor, 'version_minor': versionMinor, 'version_patch': versionPatch, 'signature': signature, 'downgrade_from': downgradeFrom, 'target': target, 'min_bootloader': minBootloader}), body, 'admin', contentType: 'application/octet-stream'));
    return HydraCanotaFlash.fromJson(_hydraMap(raw));
  }

  /// GET /api/hardware/canota/version (access: user)
  Future<Map<String, dynamic>> getHardwareCanotaVersion({String? relay, String? slot, String? tier}) async {
    final raw = await _transport(HydraRequest('GET', '/api/hardware/canota/version', queryOf({'relay': relay, 'slot': slot, 'tier': tier}), null, 'user'));
    return _hydraMap(raw);
  }

  /// POST /api/hardware/fram/erase (access: admin)
  Future<Map<String, dynamic>> postHardwareFramErase({required HydraPostHardwareFramEraseBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/hardware/fram/erase', const <String, String>{}, body.toJson(), 'admin'));
    return _hydraMap(raw);
  }

  /// POST /api/hardware/fram/selftest (access: admin)
  Future<Map<String, dynamic>> postHardwareFramSelftest() async {
    final raw = await _transport(HydraRequest('POST', '/api/hardware/fram/selftest', const <String, String>{}, null, 'admin'));
    return _hydraMap(raw);
  }

  /// GET /api/hil-bridge/settings (access: user)
  Future<HydraGetHilBridgeSettingsResult> getHilBridgeSettings() async {
    final raw = await _transport(HydraRequest('GET', '/api/hil-bridge/settings', const <String, String>{}, null, 'user'));
    return HydraGetHilBridgeSettingsResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/hil-bridge/settings (access: admin)
  Future<HydraPostHilBridgeSettingsResult> postHilBridgeSettings({required HydraPostHilBridgeSettingsBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/hil-bridge/settings', const <String, String>{}, body.toJson(), 'admin'));
    return HydraPostHilBridgeSettingsResult.fromJson(_hydraMap(raw));
  }

  /// GET /api/hydra-info (access: public)
  Future<HydraHydraInfo> getHydraInfo() async {
    final raw = await _transport(HydraRequest('GET', '/api/hydra-info', const <String, String>{}, null, 'public'));
    return HydraHydraInfo.fromJson(_hydraMap(raw));
  }

  /// POST /api/info/ticket (access: user)
  Future<HydraInfoTicket> postInfoTicket({HydraPostInfoTicketBody? body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/info/ticket', const <String, String>{}, body?.toJson(), 'user'));
    return HydraInfoTicket.fromJson(_hydraMap(raw));
  }

  /// POST /api/ingest/dev-server/status (access: public)
  Future<void> postIngestDevServerStatus() async {
    await _transport(HydraRequest('POST', '/api/ingest/dev-server/status', const <String, String>{}, null, 'public'));
  }

  /// POST /api/ingest/scenario-outcome (access: user)
  Future<void> postIngestScenarioOutcome() async {
    await _transport(HydraRequest('POST', '/api/ingest/scenario-outcome', const <String, String>{}, null, 'user'));
  }

  /// GET /api/ingest/scenario-outcomes (access: user)
  Future<void> getIngestScenarioOutcomes({String? fingerprintKind, String? limit, String? scenarioId, String? verify}) async {
    await _transport(HydraRequest('GET', '/api/ingest/scenario-outcomes', queryOf({'fingerprint_kind': fingerprintKind, 'limit': limit, 'scenario_id': scenarioId, 'verify': verify}), null, 'user'));
  }

  /// POST /api/integrations/test-connection (access: user)
  Future<HydraReachable> postIntegrationsTestConnection({required HydraPostIntegrationsTestConnectionBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/integrations/test-connection', const <String, String>{}, body.toJson(), 'user'));
    return HydraReachable.fromJson(_hydraMap(raw));
  }

  /// POST /api/login (access: public)
  Future<HydraLoginResult> postLogin({required HydraPostLoginBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/login', const <String, String>{}, body.toJson(), 'public'));
    return HydraLoginResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/logout (access: public)
  Future<HydraSuccess> postLogout({HydraPostLogoutBody? body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/logout', const <String, String>{}, body?.toJson(), 'public'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// GET /api/models (access: public)
  Future<HydraModelList> getModels() async {
    final raw = await _transport(HydraRequest('GET', '/api/models', const <String, String>{}, null, 'public'));
    return HydraModelList.fromJson(_hydraMap(raw));
  }

  /// POST /api/models/submit (access: admin)
  Future<HydraModelSubmitted> postModelsSubmit({HydraPostModelsSubmitBody? body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/models/submit', const <String, String>{}, body?.toJson(), 'admin'));
    return HydraModelSubmitted.fromJson(_hydraMap(raw));
  }

  /// GET /api/models/{category}/{slug}/download (access: public)
  Future<void> getModelsByCategoryBySlugDownload({required String category, required String slug}) async {
    await _transport(HydraRequest('GET', fillPath('/api/models/{category}/{slug}/download', {'category': category, 'slug': slug}), const <String, String>{}, null, 'public'));
  }

  /// POST /api/operator/confirmations (access: user)
  Future<HydraPostOperatorConfirmationsResult> postOperatorConfirmations({required HydraPostOperatorConfirmationsBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/operator/confirmations', const <String, String>{}, body.toJson(), 'user'));
    return HydraPostOperatorConfirmationsResult.fromJson(_hydraMap(raw));
  }

  /// GET /api/operator/presence (access: user)
  Future<HydraOperatorPresence> getOperatorPresence() async {
    final raw = await _transport(HydraRequest('GET', '/api/operator/presence', const <String, String>{}, null, 'user'));
    return HydraOperatorPresence.fromJson(_hydraMap(raw));
  }

  /// POST /api/operator/presence (access: user)
  Future<HydraOperatorPresenceAck> postOperatorPresence({required HydraPostOperatorPresenceBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/operator/presence', const <String, String>{}, body.toJson(), 'user'));
    return HydraOperatorPresenceAck.fromJson(_hydraMap(raw));
  }

  /// GET /api/ops-agent/proposals (access: admin)
  Future<HydraGetOpsAgentProposalsResult> getOpsAgentProposals() async {
    final raw = await _transport(HydraRequest('GET', '/api/ops-agent/proposals', const <String, String>{}, null, 'admin'));
    return HydraGetOpsAgentProposalsResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/ops-agent/proposals/decide (access: admin)
  Future<HydraPostOpsAgentProposalsDecideResult> postOpsAgentProposalsDecide({required HydraPostOpsAgentProposalsDecideBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/ops-agent/proposals/decide', const <String, String>{}, body.toJson(), 'admin'));
    return HydraPostOpsAgentProposalsDecideResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/push/devices (access: user)
  Future<HydraPushDeviceRegistered> postPushDevices({required HydraPostPushDevicesBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/push/devices', const <String, String>{}, body.toJson(), 'user'));
    return HydraPushDeviceRegistered.fromJson(_hydraMap(raw));
  }

  /// DELETE /api/push/devices/{token} (access: user)
  Future<HydraPushDeviceRemoved> deletePushDevicesByToken({required String token}) async {
    final raw = await _transport(HydraRequest('DELETE', fillPath('/api/push/devices/{token}', {'token': token}), const <String, String>{}, null, 'user'));
    return HydraPushDeviceRemoved.fromJson(_hydraMap(raw));
  }

  /// POST /api/push/live-activities (access: user)
  Future<HydraLiveActivityRegistered> postPushLiveActivities({required HydraPostPushLiveActivitiesBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/push/live-activities', const <String, String>{}, body.toJson(), 'user'));
    return HydraLiveActivityRegistered.fromJson(_hydraMap(raw));
  }

  /// DELETE /api/push/live-activities/{token} (access: user)
  Future<HydraLiveActivityRemoved> deletePushLiveActivitiesByToken({required String token}) async {
    final raw = await _transport(HydraRequest('DELETE', fillPath('/api/push/live-activities/{token}', {'token': token}), const <String, String>{}, null, 'user'));
    return HydraLiveActivityRemoved.fromJson(_hydraMap(raw));
  }

  /// POST /api/refresh (access: public)
  Future<HydraLoginResult> postRefresh({required HydraPostRefreshBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/refresh', const <String, String>{}, body.toJson(), 'public'));
    return HydraLoginResult.fromJson(_hydraMap(raw));
  }

  /// GET /api/robot/{id} (access: user)
  Future<HydraGetRobotByIdResult> getRobotById({required int id}) async {
    final raw = await _transport(HydraRequest('GET', fillPath('/api/robot/{id}', {'id': id}), const <String, String>{}, null, 'user'));
    return HydraGetRobotByIdResult.fromJson(_hydraMap(raw));
  }

  /// GET /api/robot/{id} (access: user); the reply also holds the response headers ETag.
  Future<HydraReply<HydraGetRobotByIdResult>> getRobotByIdWithHeaders({required int id}) async {
    final reply = (await _transport(HydraRequest('GET', fillPath('/api/robot/{id}', {'id': id}), const <String, String>{}, null, 'user', replyHeaders: const <String>['ETag']))) as HydraReply<dynamic>;
    return HydraReply<HydraGetRobotByIdResult>(HydraGetRobotByIdResult.fromJson(_hydraMap(reply.body)), reply.headers);
  }

  /// POST /api/robot/{id}/claim (access: user)
  Future<HydraPostRobotByIdClaimResult> postRobotByIdClaim({required int id, String? headerIfMatch, String? headerXControllerId, HydraPostRobotByIdClaimBody? body}) async {
    final raw = await _transport(HydraRequest('POST', fillPath('/api/robot/{id}/claim', {'id': id}), const <String, String>{}, body?.toJson(), 'user', headers: queryOf({'If-Match': headerIfMatch, 'X-Controller-Id': headerXControllerId})));
    return HydraPostRobotByIdClaimResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/robot/{id}/claim (access: user); the reply also holds the response headers ETag.
  Future<HydraReply<HydraPostRobotByIdClaimResult>> postRobotByIdClaimWithHeaders({required int id, String? headerIfMatch, String? headerXControllerId, HydraPostRobotByIdClaimBody? body}) async {
    final reply = (await _transport(HydraRequest('POST', fillPath('/api/robot/{id}/claim', {'id': id}), const <String, String>{}, body?.toJson(), 'user', headers: queryOf({'If-Match': headerIfMatch, 'X-Controller-Id': headerXControllerId}), replyHeaders: const <String>['ETag']))) as HydraReply<dynamic>;
    return HydraReply<HydraPostRobotByIdClaimResult>(HydraPostRobotByIdClaimResult.fromJson(_hydraMap(reply.body)), reply.headers);
  }

  /// POST /api/robot/{id}/command (access: user)
  Future<HydraPostRobotByIdCommandResult> postRobotByIdCommand({required int id, required HydraPostRobotByIdCommandBody body, String? headerIfMatch, String? headerXControllerId, String? headerXCorrelationId}) async {
    final raw = await _transport(HydraRequest('POST', fillPath('/api/robot/{id}/command', {'id': id}), const <String, String>{}, body.toJson(), 'user', headers: queryOf({'If-Match': headerIfMatch, 'X-Controller-Id': headerXControllerId, 'X-Correlation-Id': headerXCorrelationId})));
    return HydraPostRobotByIdCommandResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/robot/{id}/heartbeat (access: user)
  Future<HydraSuccess> postRobotByIdHeartbeat({required int id}) async {
    final raw = await _transport(HydraRequest('POST', fillPath('/api/robot/{id}/heartbeat', {'id': id}), const <String, String>{}, null, 'user'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// POST /api/robot/{id}/jog-arm (access: user)
  Future<HydraPostRobotByIdJogArmResult> postRobotByIdJogArm({required int id, required HydraPostRobotByIdJogArmBody body, String? headerXControllerId}) async {
    final raw = await _transport(HydraRequest('POST', fillPath('/api/robot/{id}/jog-arm', {'id': id}), const <String, String>{}, body.toJson(), 'user', headers: queryOf({'X-Controller-Id': headerXControllerId})));
    return HydraPostRobotByIdJogArmResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/robot/{id}/release (access: user)
  Future<HydraPostRobotByIdReleaseResult> postRobotByIdRelease({required int id, String? headerIfMatch, String? headerXControllerId, HydraPostRobotByIdReleaseBody? body}) async {
    final raw = await _transport(HydraRequest('POST', fillPath('/api/robot/{id}/release', {'id': id}), const <String, String>{}, body?.toJson(), 'user', headers: queryOf({'If-Match': headerIfMatch, 'X-Controller-Id': headerXControllerId})));
    return HydraPostRobotByIdReleaseResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/robot/{id}/release (access: user); the reply also holds the response headers ETag.
  Future<HydraReply<HydraPostRobotByIdReleaseResult>> postRobotByIdReleaseWithHeaders({required int id, String? headerIfMatch, String? headerXControllerId, HydraPostRobotByIdReleaseBody? body}) async {
    final reply = (await _transport(HydraRequest('POST', fillPath('/api/robot/{id}/release', {'id': id}), const <String, String>{}, body?.toJson(), 'user', headers: queryOf({'If-Match': headerIfMatch, 'X-Controller-Id': headerXControllerId}), replyHeaders: const <String>['ETag']))) as HydraReply<dynamic>;
    return HydraReply<HydraPostRobotByIdReleaseResult>(HydraPostRobotByIdReleaseResult.fromJson(_hydraMap(reply.body)), reply.headers);
  }

  /// GET /api/robots/liveness (access: user)
  Future<HydraRobotLiveness> getRobotsLiveness() async {
    final raw = await _transport(HydraRequest('GET', '/api/robots/liveness', const <String, String>{}, null, 'user'));
    return HydraRobotLiveness.fromJson(_hydraMap(raw));
  }

  /// GET /api/ros2-bridge/settings (access: user)
  Future<HydraGetRos2BridgeSettingsResult> getRos2BridgeSettings() async {
    final raw = await _transport(HydraRequest('GET', '/api/ros2-bridge/settings', const <String, String>{}, null, 'user'));
    return HydraGetRos2BridgeSettingsResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/ros2-bridge/settings (access: admin)
  Future<HydraPostRos2BridgeSettingsResult> postRos2BridgeSettings({required HydraPostRos2BridgeSettingsBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/ros2-bridge/settings', const <String, String>{}, body.toJson(), 'admin'));
    return HydraPostRos2BridgeSettingsResult.fromJson(_hydraMap(raw));
  }

  /// GET /api/rul/config (access: user)
  Future<HydraRulConfig> getRulConfig() async {
    final raw = await _transport(HydraRequest('GET', '/api/rul/config', const <String, String>{}, null, 'user'));
    return HydraRulConfig.fromJson(_hydraMap(raw));
  }

  /// GET /api/safety-limits (access: user)
  Future<HydraSafetyLimitsView> getSafetyLimits({String? robotId}) async {
    final raw = await _transport(HydraRequest('GET', '/api/safety-limits', queryOf({'robotId': robotId}), null, 'user'));
    return HydraSafetyLimitsView.fromJson(_hydraMap(raw));
  }

  /// GET /api/semantic-planner/settings (access: user)
  Future<HydraGetSemanticPlannerSettingsResult> getSemanticPlannerSettings() async {
    final raw = await _transport(HydraRequest('GET', '/api/semantic-planner/settings', const <String, String>{}, null, 'user'));
    return HydraGetSemanticPlannerSettingsResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/semantic-planner/settings (access: admin)
  Future<HydraPostSemanticPlannerSettingsResult> postSemanticPlannerSettings({required HydraPostSemanticPlannerSettingsBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/semantic-planner/settings', const <String, String>{}, body.toJson(), 'admin'));
    return HydraPostSemanticPlannerSettingsResult.fromJson(_hydraMap(raw));
  }

  /// GET /api/settings (access: user)
  Future<HydraSettings> getSettings() async {
    final raw = await _transport(HydraRequest('GET', '/api/settings', const <String, String>{}, null, 'user'));
    return HydraSettings.fromJson(_hydraMap(raw));
  }

  /// GET /api/settings (access: user); the reply also holds the response headers ETag.
  Future<HydraReply<HydraSettings>> getSettingsWithHeaders() async {
    final reply = (await _transport(HydraRequest('GET', '/api/settings', const <String, String>{}, null, 'user', replyHeaders: const <String>['ETag']))) as HydraReply<dynamic>;
    return HydraReply<HydraSettings>(HydraSettings.fromJson(_hydraMap(reply.body)), reply.headers);
  }

  /// PUT /api/settings (access: admin)
  Future<HydraPutSettingsResult> putSettings({required String headerIfMatch, required HydraSettings body}) async {
    final raw = await _transport(HydraRequest('PUT', '/api/settings', const <String, String>{}, body.toJson(), 'admin', headers: queryOf({'If-Match': headerIfMatch})));
    return HydraPutSettingsResult.fromJson(_hydraMap(raw));
  }

  /// PUT /api/settings (access: admin); the reply also holds the response headers ETag.
  Future<HydraReply<HydraPutSettingsResult>> putSettingsWithHeaders({required String headerIfMatch, required HydraSettings body}) async {
    final reply = (await _transport(HydraRequest('PUT', '/api/settings', const <String, String>{}, body.toJson(), 'admin', headers: queryOf({'If-Match': headerIfMatch}), replyHeaders: const <String>['ETag']))) as HydraReply<dynamic>;
    return HydraReply<HydraPutSettingsResult>(HydraPutSettingsResult.fromJson(_hydraMap(reply.body)), reply.headers);
  }

  /// POST /api/settings (access: admin)
  Future<HydraPostSettingsResult> postSettings({required HydraSettings body, String? headerIfMatch}) async {
    final raw = await _transport(HydraRequest('POST', '/api/settings', const <String, String>{}, body.toJson(), 'admin', headers: queryOf({'If-Match': headerIfMatch})));
    return HydraPostSettingsResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/settings (access: admin); the reply also holds the response headers ETag.
  Future<HydraReply<HydraPostSettingsResult>> postSettingsWithHeaders({required HydraSettings body, String? headerIfMatch}) async {
    final reply = (await _transport(HydraRequest('POST', '/api/settings', const <String, String>{}, body.toJson(), 'admin', headers: queryOf({'If-Match': headerIfMatch}), replyHeaders: const <String>['ETag']))) as HydraReply<dynamic>;
    return HydraReply<HydraPostSettingsResult>(HydraPostSettingsResult.fromJson(_hydraMap(reply.body)), reply.headers);
  }

  /// POST /api/stop-all (access: user)
  Future<HydraStopAllResult> postStopAll() async {
    final raw = await _transport(HydraRequest('POST', '/api/stop-all', const <String, String>{}, null, 'user'));
    return HydraStopAllResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/stop-all/release (access: admin)
  Future<HydraGlobalStopReleased> postStopAllRelease() async {
    final raw = await _transport(HydraRequest('POST', '/api/stop-all/release', const <String, String>{}, null, 'admin'));
    return HydraGlobalStopReleased.fromJson(_hydraMap(raw));
  }

  /// POST /api/system/bluetooth/pair (access: admin)
  Future<void> postSystemBluetoothPair({required HydraPostSystemBluetoothPairBody body}) async {
    await _transport(HydraRequest('POST', '/api/system/bluetooth/pair', const <String, String>{}, body.toJson(), 'admin'));
  }

  /// POST /api/system/bluetooth/power (access: admin)
  Future<HydraSuccess> postSystemBluetoothPower({required HydraPostSystemBluetoothPowerBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/system/bluetooth/power', const <String, String>{}, body.toJson(), 'admin'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// POST /api/system/bluetooth/remove (access: admin)
  Future<HydraSuccess> postSystemBluetoothRemove({required HydraPostSystemBluetoothRemoveBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/system/bluetooth/remove', const <String, String>{}, body.toJson(), 'admin'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// POST /api/system/bluetooth/scan (access: admin)
  Future<HydraBluetoothScan> postSystemBluetoothScan() async {
    final raw = await _transport(HydraRequest('POST', '/api/system/bluetooth/scan', const <String, String>{}, null, 'admin'));
    return HydraBluetoothScan.fromJson(_hydraMap(raw));
  }

  /// GET /api/system/bluetooth/status (access: admin)
  Future<void> getSystemBluetoothStatus() async {
    await _transport(HydraRequest('GET', '/api/system/bluetooth/status', const <String, String>{}, null, 'admin'));
  }

  /// GET /api/system/metrics (access: public)
  Future<HydraSystemMetrics> getSystemMetrics() async {
    final raw = await _transport(HydraRequest('GET', '/api/system/metrics', const <String, String>{}, null, 'public'));
    return HydraSystemMetrics.fromJson(_hydraMap(raw));
  }

  /// POST /api/system/reboot (access: public)
  Future<HydraSuccess> postSystemReboot() async {
    final raw = await _transport(HydraRequest('POST', '/api/system/reboot', const <String, String>{}, null, 'public'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// POST /api/system/shutdown (access: public)
  Future<HydraSuccess> postSystemShutdown() async {
    final raw = await _transport(HydraRequest('POST', '/api/system/shutdown', const <String, String>{}, null, 'public'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// GET /api/system/supervisor (access: public)
  Future<Map<String, dynamic>> getSystemSupervisor() async {
    final raw = await _transport(HydraRequest('GET', '/api/system/supervisor', const <String, String>{}, null, 'public'));
    return _hydraMap(raw);
  }

  /// GET /api/telemetry/aggregate (access: user)
  Future<List<HydraGetTelemetryAggregateResultItem>> getTelemetryAggregate({String? sourceId, String? kind, String? field, String? bucketMs, String? start, String? end, String? before, String? agg}) async {
    final raw = await _transport(HydraRequest('GET', '/api/telemetry/aggregate', queryOf({'sourceId': sourceId, 'kind': kind, 'field': field, 'bucketMs': bucketMs, 'start': start, 'end': end, 'before': before, 'agg': agg}), null, 'user'));
    return (raw as List).map((v0) => HydraGetTelemetryAggregateResultItem.fromJson(_hydraMap(v0))).toList();
  }

  /// GET /api/telemetry/downsample-plan (access: admin)
  Future<HydraGetTelemetryDownsamplePlanResult> getTelemetryDownsamplePlan() async {
    final raw = await _transport(HydraRequest('GET', '/api/telemetry/downsample-plan', const <String, String>{}, null, 'admin'));
    return HydraGetTelemetryDownsamplePlanResult.fromJson(_hydraMap(raw));
  }

  /// PUT /api/telemetry/downsample-plan (access: admin)
  Future<HydraPutTelemetryDownsamplePlanResult> putTelemetryDownsamplePlan({required HydraPutTelemetryDownsamplePlanBody body, String? preview}) async {
    final raw = await _transport(HydraRequest('PUT', '/api/telemetry/downsample-plan', queryOf({'preview': preview}), body.toJson(), 'admin'));
    return HydraPutTelemetryDownsamplePlanResult.fromJson(_hydraMap(raw));
  }

  /// GET /api/telemetry/query (access: user)
  Future<List<HydraGetTelemetryQueryResultItem>> getTelemetryQuery({String? sourceId, String? kind, String? field, String? start, String? end, String? before, String? limit, String? cursor}) async {
    final raw = await _transport(HydraRequest('GET', '/api/telemetry/query', queryOf({'sourceId': sourceId, 'kind': kind, 'field': field, 'start': start, 'end': end, 'before': before, 'limit': limit, 'cursor': cursor}), null, 'user'));
    return (raw as List).map((v0) => HydraGetTelemetryQueryResultItem.fromJson(_hydraMap(v0))).toList();
  }

  /// GET /api/telemetry/query (access: user); the reply also holds the response headers X-Next-Cursor.
  Future<HydraReply<List<HydraGetTelemetryQueryResultItem>>> getTelemetryQueryWithHeaders({String? sourceId, String? kind, String? field, String? start, String? end, String? before, String? limit, String? cursor}) async {
    final reply = (await _transport(HydraRequest('GET', '/api/telemetry/query', queryOf({'sourceId': sourceId, 'kind': kind, 'field': field, 'start': start, 'end': end, 'before': before, 'limit': limit, 'cursor': cursor}), null, 'user', replyHeaders: const <String>['X-Next-Cursor']))) as HydraReply<dynamic>;
    return HydraReply<List<HydraGetTelemetryQueryResultItem>>((reply.body as List).map((v0) => HydraGetTelemetryQueryResultItem.fromJson(_hydraMap(v0))).toList(), reply.headers);
  }

  /// GET /api/tool-arms (access: user)
  Future<HydraToolArmsReport> getToolArms() async {
    final raw = await _transport(HydraRequest('GET', '/api/tool-arms', const <String, String>{}, null, 'user'));
    return HydraToolArmsReport.fromJson(_hydraMap(raw));
  }

  /// POST /api/tool-arms/reset (access: admin)
  Future<HydraToolArmResetResult> postToolArmsReset({required HydraPostToolArmsResetBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/tool-arms/reset', const <String, String>{}, body.toJson(), 'admin'));
    return HydraToolArmResetResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/totp/begin (access: user)
  Future<HydraTotpEnrolment> postTotpBegin({required HydraPostTotpBeginBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/totp/begin', const <String, String>{}, body.toJson(), 'user'));
    return HydraTotpEnrolment.fromJson(_hydraMap(raw));
  }

  /// POST /api/totp/confirm (access: user)
  Future<HydraTotpConfirmed> postTotpConfirm({required HydraPostTotpConfirmBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/totp/confirm', const <String, String>{}, body.toJson(), 'user'));
    return HydraTotpConfirmed.fromJson(_hydraMap(raw));
  }

  /// POST /api/totp/disable (access: user)
  Future<HydraSuccess> postTotpDisable({required HydraPostTotpDisableBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/totp/disable', const <String, String>{}, body.toJson(), 'user'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// POST /api/totp/recovery-codes (access: user)
  Future<HydraTotpConfirmed> postTotpRecoveryCodes({required HydraPostTotpRecoveryCodesBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/totp/recovery-codes', const <String, String>{}, body.toJson(), 'user'));
    return HydraTotpConfirmed.fromJson(_hydraMap(raw));
  }

  /// GET /api/totp/status (access: user)
  Future<HydraTotpStatus> getTotpStatus() async {
    final raw = await _transport(HydraRequest('GET', '/api/totp/status', const <String, String>{}, null, 'user'));
    return HydraTotpStatus.fromJson(_hydraMap(raw));
  }

  /// POST /api/trajectory/proposals/verify (access: user)
  Future<void> postTrajectoryProposalsVerify() async {
    await _transport(HydraRequest('POST', '/api/trajectory/proposals/verify', const <String, String>{}, null, 'user'));
  }

  /// POST /api/upload-work (access: user)
  Future<HydraSuccess> postUploadWork({required HydraPostUploadWorkBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/upload-work', const <String, String>{}, body.toJson(), 'user'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// GET /api/users (access: admin)
  Future<HydraUserList> getUsers() async {
    final raw = await _transport(HydraRequest('GET', '/api/users', const <String, String>{}, null, 'admin'));
    return HydraUserList.fromJson(_hydraMap(raw));
  }

  /// POST /api/users (access: admin)
  Future<HydraSuccess> postUsers({required HydraPostUsersBody body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/users', const <String, String>{}, body.toJson(), 'admin'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// PUT /api/users/{username} (access: admin)
  Future<HydraSuccess> putUsersByUsername({required String username, HydraPutUsersByUsernameBody? body}) async {
    final raw = await _transport(HydraRequest('PUT', fillPath('/api/users/{username}', {'username': username}), const <String, String>{}, body?.toJson(), 'admin'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// DELETE /api/users/{username} (access: admin)
  Future<HydraSuccess> deleteUsersByUsername({required String username}) async {
    final raw = await _transport(HydraRequest('DELETE', fillPath('/api/users/{username}', {'username': username}), const <String, String>{}, null, 'admin'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// DELETE /api/users/{username}/totp (access: admin)
  Future<HydraSuccess> deleteUsersByUsernameTotp({required String username}) async {
    final raw = await _transport(HydraRequest('DELETE', fillPath('/api/users/{username}/totp', {'username': username}), const <String, String>{}, null, 'admin'));
    return HydraSuccess.fromJson(_hydraMap(raw));
  }

  /// GET /api/voice/chain (access: admin)
  Future<void> getVoiceChain({String? limit, String? verify}) async {
    await _transport(HydraRequest('GET', '/api/voice/chain', queryOf({'limit': limit, 'verify': verify}), null, 'admin'));
  }

  /// POST /api/voice/confirm (access: user)
  Future<HydraVoiceConfirmResult> postVoiceConfirm({HydraPostVoiceConfirmBody? body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/voice/confirm', const <String, String>{}, body?.toJson(), 'user'));
    return HydraVoiceConfirmResult.fromJson(_hydraMap(raw));
  }

  /// POST /api/voice/turn (access: user)
  Future<HydraVoiceReply> postVoiceTurn({HydraPostVoiceTurnBody? body}) async {
    final raw = await _transport(HydraRequest('POST', '/api/voice/turn', const <String, String>{}, body?.toJson(), 'user'));
    return HydraVoiceReply.fromJson(_hydraMap(raw));
  }

  /// GET /api/watch/system-status (access: user)
  Future<void> getWatchSystemStatus() async {
    await _transport(HydraRequest('GET', '/api/watch/system-status', const <String, String>{}, null, 'user'));
  }

  /// GET /health (access: public)
  Future<HydraHealthReport> getHealth() async {
    final raw = await _transport(HydraRequest('GET', '/health', const <String, String>{}, null, 'public'));
    return HydraHealthReport.fromJson(_hydraMap(raw));
  }

  /// GET /metrics (access: public)
  Future<void> getMetrics() async {
    await _transport(HydraRequest('GET', '/metrics', const <String, String>{}, null, 'public'));
  }

}

const List<String> hydraClientOperations = [
  'getWellKnownJwksJson',
  'getAdapters',
  'getAdaptersByAdapterId',
  'getAdminClients',
  'getAdminDeviceTokens',
  'postAdminDeviceTokens',
  'deleteAdminDeviceTokensById',
  'getAdminFleetUpdate',
  'postAdminFleetUpdateApply',
  'postAdminFleetUpdatePlan',
  'postAdminFleetUpdateResume',
  'getAdminJwtKeys',
  'postAdminJwtKeysRotate',
  'getAdminLogs',
  'postAdminMaintenanceInstall',
  'postAdminMaintenancePrune',
  'postAdminMaintenanceRollback',
  'getAdminMaintenanceStatus',
  'getAdminPush',
  'postAdminRestart',
  'getAdminRobotIds',
  'putAdminSafetyLimits',
  'getAdminSelfUpdate',
  'postAdminSelfUpdateApply',
  'getAdminSelfUpdateJobsById',
  'postAdminSelfUpdateRollback',
  'getAdminServerConfig',
  'putAdminServerConfig',
  'getAdminServiceIdentity',
  'getAdminUpdates',
  'postAdminUpdatesManifestCheck',
  'getAnomalyVerdicts',
  'getAudit',
  'getBridges',
  'postBridgesByNameCmdByVerb',
  'getBridgesByNameState',
  'postCameraDiscoverRtspPath',
  'getCameraDiscoverUsbDevices',
  'getCameraMedia',
  'getCameraMediaByCameraIdByKindByFilename',
  'deleteCameraMediaByCameraIdByKindByFilename',
  'postCameraTicket',
  'postCameraByIdPtz',
  'postCameraByIdRecordingStart',
  'postCameraByIdRecordingStop',
  'postCameraByIdSnapshot',
  'getCameraByIdStream',
  'getCamerasStatus',
  'getClaims',
  'getConnectionsClients',
  'getConnectionsEvents',
  'getConnectorHubGateAudit',
  'postConnectorHubGateEvaluate',
  'getConnectorHubGateSettings',
  'postConnectorHubGateSettings',
  'getDevServerStatus',
  'postDeviceLogin',
  'getDroidEstopSettings',
  'postDroidEstopSettings',
  'getEcosystemHealth',
  'getEcosystemNodeHealth',
  'postEcosystemServiceByUnitByAction',
  'getEcosystemStatus',
  'getFaults',
  'postHardwareCanotaFlash',
  'getHardwareCanotaVersion',
  'postHardwareFramErase',
  'postHardwareFramSelftest',
  'getHilBridgeSettings',
  'postHilBridgeSettings',
  'getHydraInfo',
  'postInfoTicket',
  'postIngestDevServerStatus',
  'postIngestScenarioOutcome',
  'getIngestScenarioOutcomes',
  'postIntegrationsTestConnection',
  'postLogin',
  'postLogout',
  'getModels',
  'postModelsSubmit',
  'getModelsByCategoryBySlugDownload',
  'postOperatorConfirmations',
  'getOperatorPresence',
  'postOperatorPresence',
  'getOpsAgentProposals',
  'postOpsAgentProposalsDecide',
  'postPushDevices',
  'deletePushDevicesByToken',
  'postPushLiveActivities',
  'deletePushLiveActivitiesByToken',
  'postRefresh',
  'getRobotById',
  'postRobotByIdClaim',
  'postRobotByIdCommand',
  'postRobotByIdHeartbeat',
  'postRobotByIdJogArm',
  'postRobotByIdRelease',
  'getRobotsLiveness',
  'getRos2BridgeSettings',
  'postRos2BridgeSettings',
  'getRulConfig',
  'getSafetyLimits',
  'getSemanticPlannerSettings',
  'postSemanticPlannerSettings',
  'getSettings',
  'putSettings',
  'postSettings',
  'postStopAll',
  'postStopAllRelease',
  'postSystemBluetoothPair',
  'postSystemBluetoothPower',
  'postSystemBluetoothRemove',
  'postSystemBluetoothScan',
  'getSystemBluetoothStatus',
  'getSystemMetrics',
  'postSystemReboot',
  'postSystemShutdown',
  'getSystemSupervisor',
  'getTelemetryAggregate',
  'getTelemetryDownsamplePlan',
  'putTelemetryDownsamplePlan',
  'getTelemetryQuery',
  'getToolArms',
  'postToolArmsReset',
  'postTotpBegin',
  'postTotpConfirm',
  'postTotpDisable',
  'postTotpRecoveryCodes',
  'getTotpStatus',
  'postTrajectoryProposalsVerify',
  'postUploadWork',
  'getUsers',
  'postUsers',
  'putUsersByUsername',
  'deleteUsersByUsername',
  'deleteUsersByUsernameTotp',
  'getVoiceChain',
  'postVoiceConfirm',
  'postVoiceTurn',
  'getWatchSystemStatus',
  'getHealth',
  'getMetrics',
];
