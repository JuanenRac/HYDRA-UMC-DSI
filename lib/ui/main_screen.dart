// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/main_screen.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Horizontal touch menu across the top of the fixed 1280x720 frame -
// KlipperScreen-in-spirit navigation (a persistent row of large icon+label
// buttons, not a phone-style bottom nav bar) matching the layout the owner
// asked for in SONNET/HYDRA-UMC-DSI/chat.TXT section 1 ("menu tactil
// horizontal similar en espiritu a HYDRA-UMC-ANDROID-CONTROL"). Same
// screen catalog as iOS/Android (Dashboard/Control/Camera/3D/Settings)
// plus a dedicated Metrics tab - the DSI spec calls out system metrics as
// its own catalog entry rather than folding it into the Dashboard the way
// the phone/tablet apps do.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/robot_view_model.dart';
import 'camera_screen.dart';
import 'control_screen.dart';
import 'dashboard_screen.dart';
import 'metrics_screen.dart';
import 'settings_screen.dart';
import 'three_d_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _NavEntry {
  final IconData icon;
  final String label;
  final Widget screen;
  const _NavEntry(this.icon, this.label, this.screen);
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  RobotViewModel? _vm;
  String _lastShownError = '';

  static const _entries = [
    _NavEntry(Icons.dashboard, 'Dashboard', DashboardScreen()),
    _NavEntry(Icons.gamepad, 'Control', ControlScreen()),
    _NavEntry(Icons.videocam, 'Camera', CameraScreen()),
    _NavEntry(Icons.view_in_ar, '3D View', ThreeDScreen()),
    _NavEntry(Icons.monitor_heart, 'Metrics', MetricsScreen()),
    _NavEntry(Icons.settings, 'Settings', SettingsScreen()),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<RobotViewModel>();
    if (!identical(_vm, vm)) {
      _vm?.removeListener(_onVmChanged);
      _vm = vm;
      _vm!.addListener(_onVmChanged);
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    super.dispose();
  }

  /// Surfaces robot_view_model.dart's own lastError as a SnackBar
  /// regardless of which tab is active - same fix HYDRA-UMC-IOS-CONTROL's
  /// own main_screen.dart applies, doubly important here: a failed E-STOP
  /// on an unattended kiosk panel needs to be visible from whichever tab
  /// the operator happens to be looking at.
  void _onVmChanged() {
    if (!mounted) return;
    final err = _vm?.lastError ?? '';
    if (err.isNotEmpty && err != _lastShownError) {
      _lastShownError = err;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: const Color(0xFFB91C1C)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // context.select instead of context.watch here: this shell only needs
    // the server name + connection status for _TopNavBar. The individual
    // tab screens below (Dashboard/Control/Camera/Metrics/...) each watch
    // RobotViewModel on their own for the fields they need - that part is
    // an accepted ecosystem-wide Provider trade-off (see
    // HYDRA-UMC-IOS-CONTROL's own RobotViewModel Provider pattern), not
    // something this file can fix on its own. But there is no reason for
    // this outer Scaffold/_TopNavBar shell to also rebuild on every 5s
    // metrics tick / 10s hydra-info tick / websocket message that doesn't
    // touch activeServer or connectionStatus - select() only rebuilds this
    // widget when either of those two specific values actually changes.
    final serverName = context.select<RobotViewModel, String?>((vm) => vm.activeServer?.displayName);
    final connectionStatus = context.select<RobotViewModel, String>((vm) => vm.connectionStatus);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopNavBar(
              serverName: serverName ?? 'HYDRA-UMC DSI',
              connectionStatus: connectionStatus,
              entries: _entries,
              selectedIndex: _index,
              onSelect: (i) => setState(() => _index = i),
            ),
            Expanded(
              child: IndexedStack(index: _index, children: _entries.map((e) => e.screen).toList()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fixed-height horizontal bar: server identity + connection LED on the
/// left, one large touch tab per screen filling the rest of the 1280px
/// width. Deliberately not scrollable - 6 tabs at this width comfortably
/// fit fingertip-sized targets without needing to scroll a nav bar, which
/// would be an awkward gesture on a kiosk panel.
class _TopNavBar extends StatelessWidget {
  final String serverName;
  final String connectionStatus;
  final List<_NavEntry> entries;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _TopNavBar({
    required this.serverName,
    required this.connectionStatus,
    required this.entries,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final connected = connectionStatus == 'connected';
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    serverName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < entries.length; i++)
                  Expanded(child: _NavButton(entry: entries[i], selected: i == selectedIndex, onTap: () => onSelect(i))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavEntry entry;
  final bool selected;
  final VoidCallback onTap;
  const _NavButton({required this.entry, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? const Color(0xFF00E5FF) : Colors.transparent, width: 3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(entry.icon, size: 24, color: selected ? const Color(0xFF00E5FF) : Colors.white70),
            const SizedBox(height: 2),
            Text(
              entry.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? const Color(0xFF00E5FF) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
