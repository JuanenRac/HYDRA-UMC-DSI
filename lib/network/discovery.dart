// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/discovery.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Finds servers on the local network, by two independent paths that feed the same
// "Scan local network" sheet of ui/login_screen.dart:
//   - discoverMdns(): mDNS/Bonjour query for the "_hydra._tcp.local" service the
//     server publishes. Linux needs no entitlement to receive multicast, but a minimal
//     kiosk image may still not route it: the query then finishes with nothing found
//     and the sweep below stays the guaranteed fallback.
//   - scanSubnets(): GET /api/hydra-info against every host of the /24 networks of
//     the device. Slower, but needs no multicast, so it is the path that always works.
//
// The sweep itself lives in the shared package of the SDK (clients/dart_app_common);
// this file only supplies the probe (the app's own GET /api/hydra-info) and keeps the
// names the screens and tests already use.
// =============================================================================

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' as common;

import '../models/server_info.dart';
import 'hydra_api_client.dart';
import 'tls_settings.dart';

/// The port a subnet sweep asks.
const int defaultPort = common.defaultDiscoveryPort;

/// The probe of the app: reads the identity of the server at [host]:[port] with
/// [client] and gives it as a [ServerInfo], or null when nothing answers there.
///
/// With [client] every probe goes through that one client and leaves it open;
/// without it every probe opens a discovery client of its own and closes it.
common.ServerProbe discoveryProbe({http.Client? client}) {
  return (String host, int port) async {
    final used = client ?? createDiscoveryClient();
    final apiClient = HydraApiClient(host, port, client: used);
    try {
      final info = await apiClient.getHydraInfo();
      return info == null ? null : ServerInfo.fromHydraInfo(host, port, info, useTls: apiClient.usesTls);
    } finally {
      if (client == null) used.close();
    }
  };
}

/// Queries mDNS/Bonjour for real HYDRA-UMC servers and resolves every instance
/// found down to a [ServerInfo] with the same GET /api/hydra-info [scanSubnets]
/// uses. Any failure along the way yields nothing rather than throwing.
Stream<ServerInfo> discoverMdns({Duration timeout = const Duration(seconds: 4)}) {
  return common.discoverMdns(
    probe: discoveryProbe(),
    timeout: timeout,
  );
}

/// Scans every candidate /24 (the own subnets of the device, plus [lastHost]'s
/// subnet and a common-default fallback) for a real HYDRA-UMC server,
/// yielding each match as soon as it is found.
Stream<ServerInfo> scanSubnets({String? lastHost}) async* {
  final client = createDiscoveryClient();
  try {
    yield* common.scanSubnets(
      probe: discoveryProbe(client: client),
      lastHost: lastHost,
    );
  } finally {
    client.close();
  }
}
