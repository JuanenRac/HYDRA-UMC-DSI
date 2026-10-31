// =============================================================================
// HYDRA-UMC DSI (Flutter) - models/server_security.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Seven switches of the server (GET/PUT /api/admin/server-config): the health route
// without a sign-in, the announcement of the global stop, the address kept in the
// history of connections, the camera pictures without a ticket, a token in the
// WebSocket address, the blanking of secrets in the log and the signature of a
// spoken confirmation. The reading is tolerant: a server that predates an option
// answers without it and the screen does not show that switch. A value fixed by the
// environment of the server cannot be changed from here, and every change that
// lowers the protection is asked about first.
// =============================================================================

import 'dart:convert';

/// Where the value of an option comes from. An [env] value is fixed by the environment of the server.
enum OptionSource { env, config, defaultValue }

/// One switch as the server reports it.
class ServerOption {
  final bool value;
  final OptionSource source;
  const ServerOption(this.value, this.source);

  bool get locked => source == OptionSource.env;

  @override
  bool operator ==(Object other) => other is ServerOption && other.value == value && other.source == source;

  @override
  int get hashCode => Object.hash(value, source);
}

/// What the switches of the screen say.
class ServerSecurityValues {
  final bool healthOpen;
  final bool publishGlobalStop;
  final bool recordAddress;
  final bool cameraOpen;
  final bool wsQueryToken;
  final bool logRedaction;
  final bool voiceSignature;

  const ServerSecurityValues({
    required this.healthOpen,
    required this.publishGlobalStop,
    required this.recordAddress,
    required this.cameraOpen,
    required this.wsQueryToken,
    required this.logRedaction,
    required this.voiceSignature,
  });

  ServerSecurityValues copyWith({
    bool? healthOpen,
    bool? publishGlobalStop,
    bool? recordAddress,
    bool? cameraOpen,
    bool? wsQueryToken,
    bool? logRedaction,
    bool? voiceSignature,
  }) =>
      ServerSecurityValues(
        healthOpen: healthOpen ?? this.healthOpen,
        publishGlobalStop: publishGlobalStop ?? this.publishGlobalStop,
        recordAddress: recordAddress ?? this.recordAddress,
        cameraOpen: cameraOpen ?? this.cameraOpen,
        wsQueryToken: wsQueryToken ?? this.wsQueryToken,
        logRedaction: logRedaction ?? this.logRedaction,
        voiceSignature: voiceSignature ?? this.voiceSignature,
      );
}

/// The changes that lower the protection of the server; the screen has a sentence for each.
enum ProtectionLowering { healthOpen, recordAddress, cameraOpen, wsQueryToken, logRedactionOff, voiceSignatureOff }

/// Why the options could not be read or saved, for the sentence the screen shows.
enum ServerOptionsFailure { unavailable, session, forbidden, network, other }

/// The switches this app offers; each is null when the server does not report it.
class ServerSecurityOptions {
  final ServerOption? healthOpen;
  final ServerOption? publishGlobalStop;
  final ServerOption? recordAddress;
  final ServerOption? cameraOpen;
  final ServerOption? wsQueryToken;
  final ServerOption? logRedaction;
  final ServerOption? voiceSignature;

  const ServerSecurityOptions({
    this.healthOpen,
    this.publishGlobalStop,
    this.recordAddress,
    this.cameraOpen,
    this.wsQueryToken,
    this.logRedaction,
    this.voiceSignature,
  });

  /// True when the server reports none of them (a server that predates all of these options).
  bool get isEmpty => [healthOpen, publishGlobalStop, recordAddress, cameraOpen, wsQueryToken, logRedaction, voiceSignature].every((o) => o == null);

  /// The values as the screen starts with them; an option the server does not report keeps its safe value.
  ServerSecurityValues toValues() => ServerSecurityValues(
        healthOpen: healthOpen?.value ?? false,
        publishGlobalStop: publishGlobalStop?.value ?? false,
        recordAddress: recordAddress?.value ?? false,
        cameraOpen: cameraOpen?.value ?? false,
        wsQueryToken: wsQueryToken?.value ?? false,
        logRedaction: logRedaction?.value ?? true,
        voiceSignature: voiceSignature?.value ?? false,
      );

  static ServerOption? _option(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final value = raw['value'];
    if (value is! bool) return null;
    final source = switch (raw['source']) {
      'env' => OptionSource.env,
      'config' => OptionSource.config,
      'default' => OptionSource.defaultValue,
      _ => null,
    };
    return source == null ? null : ServerOption(value, source);
  }

  static Object? _at(Map<String, dynamic> root, String group, String name) {
    final node = root[group];
    return node is Map<String, dynamic> ? node[name] : null;
  }

  /// Reads the answer of GET /api/admin/server-config; null when the text is not a JSON object.
  static ServerSecurityOptions? parse(String body) {
    final Object? root;
    try {
      root = jsonDecode(body);
    } catch (_) {
      return null;
    }
    if (root is! Map<String, dynamic>) return null;
    return ServerSecurityOptions(
      healthOpen: _option(_at(root, 'health', 'open')),
      publishGlobalStop: _option(_at(root, 'safety', 'publishGlobalStop')),
      recordAddress: _option(_at(root, 'connections', 'recordAddress')),
      cameraOpen: _option(_at(root, 'camera', 'open')),
      wsQueryToken: _option(_at(root, 'websocket', 'allowQueryToken')),
      logRedaction: _option(_at(root, 'logging', 'redactSecrets')),
      voiceSignature: _option(_at(root, 'voice', 'requireSignature')),
    );
  }

  /// The request body: only what changed, and never an option the server fixes from its environment or does not report.
  /// Null when nothing would be sent.
  Map<String, dynamic>? patch(ServerSecurityValues next) {
    final body = <String, dynamic>{};
    void put(String group, String name, ServerOption? option, bool wanted) {
      if (option == null || option.locked || option.value == wanted) return;
      (body.putIfAbsent(group, () => <String, dynamic>{}) as Map<String, dynamic>)[name] = wanted;
    }

    put('health', 'open', healthOpen, next.healthOpen);
    put('safety', 'publishGlobalStop', publishGlobalStop, next.publishGlobalStop);
    put('connections', 'recordAddress', recordAddress, next.recordAddress);
    put('camera', 'open', cameraOpen, next.cameraOpen);
    put('websocket', 'allowQueryToken', wsQueryToken, next.wsQueryToken);
    put('logging', 'redactSecrets', logRedaction, next.logRedaction);
    put('voice', 'requireSignature', voiceSignature, next.voiceSignature);
    return body.isEmpty ? null : body;
  }

  /// The changes in [next] that lower the protection, in a fixed order. Turning a switch to its safe side never asks, and neither
  /// does the announcement of the global stop (announcing a stop is the safe direction). An option the server fixes is not a change.
  List<ProtectionLowering> lowerings(ServerSecurityValues next) {
    bool rises(ServerOption? o, bool wanted) => o != null && !o.locked && !o.value && wanted;
    bool falls(ServerOption? o, bool wanted) => o != null && !o.locked && o.value && !wanted;
    return [
      if (rises(healthOpen, next.healthOpen)) ProtectionLowering.healthOpen,
      if (rises(recordAddress, next.recordAddress)) ProtectionLowering.recordAddress,
      if (rises(cameraOpen, next.cameraOpen)) ProtectionLowering.cameraOpen,
      if (rises(wsQueryToken, next.wsQueryToken)) ProtectionLowering.wsQueryToken,
      if (falls(logRedaction, next.logRedaction)) ProtectionLowering.logRedactionOff,
      if (falls(voiceSignature, next.voiceSignature)) ProtectionLowering.voiceSignatureOff,
    ];
  }
}
