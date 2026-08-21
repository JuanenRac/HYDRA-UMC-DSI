// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/discovery.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Two independent discovery paths, both feeding the same "Scan local
// network" dialog in ui/login_screen.dart, ported from
// HYDRA-UMC-IOS-CONTROL's own network/discovery.dart (same Dart/Flutter
// stack, direct reuse per [[No reference -> reuse, don't invent]]):
//   - discoverMdns(): real mDNS/Bonjour, querying the "_hydra._tcp.local"
//     service server.ts publishes - near-instant on a network that
//     delivers the multicast replies.
//   - scanSubnets(): brute-force GET /api/hydra-info against every host on
//     the device's own local /24(s) - slower, but needs no multicast
//     delivery at all, so it stays the guaranteed fallback.
//
// Honesty note on the Linux target (this app's real deployment, unlike
// iOS-Control): iOS-Control's own header documents a *known, specific*
// blocker there - Apple silently drops multicast receive for any app
// without its dedicated Multicast Networking entitlement, so discoverMdns()
// failing quietly on an unentitled iOS build is expected, not a bug. Linux
// has no equivalent entitlement gate - a normal process can join a
// multicast group and receive mDNS replies with no special permission, so
// that particular failure mode does not apply here. What *is* still
// unverified, same as every other line of this repo (see
// mejoras_futuras.txt item 1 and README.md's own "Honesty note on Linux
// verification"): this has only run in Flutter's Windows desktop
// simulation, never on a real Linux box or the CM5 itself. A minimal kiosk
// image (no NetworkManager/avahi-daemon running, or a systemd-networkd
// setup that doesn't route multicast the way a desktop distro does) could
// still leave discoverMdns() timing out with zero replies even though
// nothing here is wrong - scanSubnets() stays the guaranteed fallback
// either way, exactly like on iOS, since login_screen.dart runs both at
// once and neither path throws on failure.
// =============================================================================

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';

import '../models/server_info.dart';
import 'hydra_api_client.dart';

const String _mdnsServiceType = '_hydra._tcp.local';

/// Queries mDNS/Bonjour for real HYDRA-UMC STUDIO servers (server.ts's own
/// "_hydra._tcp" publish) and resolves every instance found down to a real
/// [ServerInfo] via the same GET /api/hydra-info [scanSubnets] uses, so a
/// match found this way is verified exactly the same way, not just assumed
/// live because mDNS answered. Any failure along the way (no multicast
/// socket permission, MDnsClient.start() throwing on a locked-down
/// platform, a timeout with zero replies) yields nothing rather than
/// throwing - see this file's own header comment on what is/isn't a known
/// blocker on this app's real Linux target, and [scanSubnets] keeps
/// working independently either way since login_screen.dart runs both at
/// once.
Stream<ServerInfo> discoverMdns({Duration timeout = const Duration(seconds: 4)}) async* {
  final client = MDnsClient();
  final seen = <String>{};
  try {
    await client.start();
    final ptrQuery = client
        .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(_mdnsServiceType))
        .timeout(timeout, onTimeout: (sink) => sink.close());
    await for (final ptr in ptrQuery) {
      final srvQuery = client
          .lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))
          .timeout(timeout, onTimeout: (sink) => sink.close());
      await for (final srv in srvQuery) {
        final ipQuery = client
            .lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(srv.target))
            .timeout(timeout, onTimeout: (sink) => sink.close());
        await for (final ip in ipQuery) {
          final host = ip.address.address;
          final port = srv.port;
          if (!seen.add('$host:$port')) continue;
          final apiClient = HydraApiClient(host, port);
          try {
            final info = await apiClient.getHydraInfo();
            if (info != null) yield ServerInfo.fromHydraInfo(host, port, info);
          } finally {
            apiClient.close();
          }
        }
      }
    }
  } catch (_) {
    // Best-effort discovery path - see header comment.
  } finally {
    client.stop();
  }
}

const int defaultPort = 3000;
const int _scanConcurrency = 32;

/// Every distinct /24 prefix ("a.b.c") worth scanning: this device's own
/// non-loopback IPv4 interfaces first, then [lastHost]'s subnet if it
/// differs, then the common-default fallback. Especially useful on this
/// app's own real deployment: the CM5 this app runs on is very likely to
/// itself be the HYDRA-UMC controller it should connect to (server on
/// localhost/its own LAN IP), so a subnet scan finds "itself" as readily
/// as it finds a remote HYDRA-UMC.
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
