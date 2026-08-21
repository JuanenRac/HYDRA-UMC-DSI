// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/settings_screen.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Ported from HYDRA-UMC-IOS-CONTROL's own ui/settings_screen.dart, with
// the discovery/hostname fields from hydraInfo (see
// state/robot_view_model.dart) added since this screen doubles as the
// "about this connection" view a kiosk operator would otherwise have no
// way to reach.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/robot_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RobotViewModel>();
    final server = vm.activeServer;
    final info = vm.hydraInfo;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
          leading: const Icon(Icons.dns),
          title: Text(server?.displayName ?? 'Not connected'),
          subtitle: Text(server != null ? '${server.host}:${server.port}' : ''),
        ),
        ListTile(
          leading: const Icon(Icons.wifi_tethering),
          title: Text('Status: ${vm.connectionStatus}'),
        ),
        if (info != null) ...[
          ListTile(leading: const Icon(Icons.dns_outlined), title: Text('Product: ${info['product'] ?? '?'}')),
          ListTile(leading: const Icon(Icons.numbers), title: Text('Remote API version: ${info['remoteApiVersion'] ?? '?'}')),
          ListTile(leading: const Icon(Icons.tag), title: Text('App version: ${info['appVersion'] ?? '?'}')),
        ],
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Sign Out'),
          onTap: () => vm.logout(),
        ),
      ],
    );
  }
}
