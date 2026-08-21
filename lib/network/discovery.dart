// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/discovery.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Concurrent local-subnet scan hitting GET /api/hydra-info on every
// candidate host - copied verbatim from HYDRA-UMC-IOS-CONTROL's own
// network/discovery.dart (same Dart/Flutter stack, no port needed).
// Especially useful on this app's own real deployment: the CM5 this app
// runs on is very likely to itself be the HYDRA-UMC controller it should
// connect to (server on localhost/its own LAN IP), so a subnet scan finds
// "itself" as readily as it finds a remote HYDRA-UMC.
// =============================================================================

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/server_info.dart';
import 'hydra_api_client.dart';

const int defaultPort = 3000;
const int _scanConcurrency = 32;

/// Every distinct /24 prefix ("a.b.c") worth scanning: this device's own
/// non-loopback IPv4 interfaces first, then [lastHost]'s subnet if it
/// differs, then the common-default fallback.
Future<List<String>> _candidatePrefixes({String? lastHost}) async {
  final prefixes = <String>{};
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        final parts = addr.address.split('.');
        if (parts.length == 4) prefixes.add(parts.sublist(0, 3).join('.'));
      }
    }
  } on SocketException {
    // No usable interface info - fall through to the lastHost/default
    // fallbacks below.
  }

  if (lastHost != null) {
    final parts = lastHost.split('.');
    if (parts.length == 4) prefixes.add(parts.sublist(0, 3).join('.'));
  }

  if (prefixes.isEmpty) prefixes.add('192.168.1');
  return prefixes.toList();
}

/// Scans every candidate /24 for a real HYDRA-UMC STUDIO server, yielding
/// each match as soon as it's found rather than waiting for the whole
/// sweep to finish.
Stream<ServerInfo> scanSubnets({String? lastHost}) async* {
  final prefixes = await _candidatePrefixes(lastHost: lastHost);

  final client = http.Client();
  try {
    for (final prefix in prefixes) {
      final hosts = List.generate(254, (i) => '$prefix.${i + 1}');
      var index = 0;
      final controller = StreamController<ServerInfo>();
      Future<void> worker() async {
        while (index < hosts.length) {
          final host = hosts[index++];
          final apiClient = HydraApiClient(host, defaultPort, client: client);
          final info = await apiClient.getHydraInfo();
          if (info != null && !controller.isClosed) {
            controller.add(ServerInfo.fromHydraInfo(host, defaultPort, info));
          }
        }
      }

      final workers = List.generate(_scanConcurrency, (_) => worker());
      unawaited(Future.wait(workers).then((_) => controller.close()));
      yield* controller.stream;
    }
  } finally {
    client.close();
  }
}
