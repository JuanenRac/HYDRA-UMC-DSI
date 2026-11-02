// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/main_screen.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Horizontal touch menu across the top of the fixed 1280x720 frame -
// KlipperScreen-in-spirit navigation (a persistent row of large icon+label
// buttons, not a phone-style bottom nav bar) for industrial touch use. Same
// screen catalog as iOS/Android (Dashboard/Control/Camera/3D/Settings)
// plus a dedicated Metrics tab - the DSI spec calls out system metrics as
// its own catalog entry rather than folding it into the Dashboard the way
// the phone/tablet apps do.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/system_status.dart';
import '../services/panel_backlight.dart';
import '../state/hydra_error.dart';
import '../state/robot_view_model.dart';
import '../state/system_model.dart';
import '../util/panel_config.dart';
import 'camera_screen.dart';
import 'control_screen.dart';
import 'dashboard_screen.dart';
import 'metrics_screen.dart';
import 'settings_screen.dart';
import 'system_screen.dart';
import 'three_d_screen.dart';
import 'widgets/stop_all.dart';

// Screen-cleaning mode duration: a 30-second input lock is a
// real, practical need for a touchscreen mounted on/near industrial
// equipment: an operator wiping the panel down mid-shift shouldn't be
// able to accidentally jog a robot or hit E-STOP through the cloth.
const _screenCleanDuration = Duration(seconds: 30);

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
  HydraError? _lastShownError;

  int? _cleanSecondsLeft;
  Timer? _cleanTimer;

  Timer? _backlightTimer;

  // The schedule by time of day goes through the one owner of the backlight, which also holds the idle dimming
  // (services/panel_backlight.dart): the schedule's own tick must not undo a dimmed or dark screen.
  void _applyBacklightForCurrentHour() => PanelBacklight.instance.applySchedule(DateTime.now().hour);

  void _startScreenClean() {
    _cleanTimer?.cancel();
    setState(() => _cleanSecondsLeft = _screenCleanDuration.inSeconds);
    _cleanTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = (_cleanSecondsLeft ?? 0) - 1;
      if (left <= 0) {
        timer.cancel();
        setState(() => _cleanSecondsLeft = null);
      } else {
        setState(() => _cleanSecondsLeft = left);
      }
    });
  }

  void _stopScreenClean() {
    _cleanTimer?.cancel();
    setState(() => _cleanSecondsLeft = null);
  }

  // The camera knows whether its tab is the one shown: all tabs stay alive
  // side by side (IndexedStack), and a picture stream nobody is looking at is
  // wasted CPU and memory on a panel that also runs the server.
  List<_NavEntry> _entries(AppLocalizations l10n, PanelConfig config) {
    final entries = [
      _NavEntry(Icons.dashboard, l10n.navDashboard, const DashboardScreen()),
      _NavEntry(Icons.gamepad, l10n.navControl, const ControlScreen()),
      _NavEntry(Icons.videocam, l10n.navCamera, CameraScreen(active: _index == 2)),
      _NavEntry(Icons.view_in_ar, l10n.nav3d, const ThreeDScreen()),
      _NavEntry(Icons.monitor_heart, l10n.navMetrics, const MetricsScreen()),
    ];
    // The System tab exists only when the settings file turns something of it on.
    if (config.systemTab) {
      entries.add(_NavEntry(Icons.admin_panel_settings_outlined, l10n.navSystem, const SystemScreen()));
    }
    entries.add(_NavEntry(Icons.settings, l10n.navSettings, const SettingsScreen()));
    return entries;
  }

  // The tab number of the System tab, or -1 when there is none.
  int _systemIndex(PanelConfig config) => config.systemTab ? 5 : -1;

  void _select(int i, PanelConfig config) {
    setState(() => _index = i);
    // The ecosystem is read only while its tab is the one shown.
    if (config.systemTab) context.read<SystemModel>().setVisible(i == _systemIndex(config));
  }

  @override
  void initState() {
    super.initState();
    _applyBacklightForCurrentHour(); // apply once immediately at startup, not just on the first 15-minute tick
    _backlightTimer = Timer.periodic(const Duration(minutes: 15), (_) => _applyBacklightForCurrentHour());
  }

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
    _cleanTimer?.cancel();
    _backlightTimer?.cancel();
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
    final err = _vm?.lastError;
    if (err != null && !identical(err, _lastShownError)) {
      _lastShownError = err;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.localize(AppLocalizations.of(context)!)), backgroundColor: const Color(0xFFB91C1C)),
      );
      // Shown: forget it, so the same error happening again is shown again.
      _vm?.acknowledgeError();
      _lastShownError = null;
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
    final config = context.select<RobotViewModel, PanelConfig>((vm) => vm.panelConfig);
    final l10n = AppLocalizations.of(context)!;
    final entries = _entries(l10n, config);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopNavBar(
                  serverName: serverName ?? 'HYDRA-UMC DSI',
                  connectionStatus: connectionStatus,
                  entries: entries,
                  selectedIndex: _index,
                  onSelect: (i) => _select(i, config),
                  showSafety: config.safetyPanel,
                  onCleanTap: _startScreenClean,
                  cleanTooltip: l10n.cleanScreenTooltip(_screenCleanDuration.inSeconds),
                ),
                const StopAllBanner(),
                Expanded(
                  child: IndexedStack(index: _index, children: entries.map((e) => e.screen).toList()),
                ),
              ],
            ),
            if (_cleanSecondsLeft != null)
              _ScreenCleanOverlay(secondsLeft: _cleanSecondsLeft!, onDismiss: _stopScreenClean),
          ],
        ),
      ),
    );
  }
}

/// Full-screen scrim shown while "screen cleaning mode" is active - an
/// AbsorbPointer swallows every touch underneath it (nothing in
/// Dashboard/Control/Camera/... ever sees them), so an operator can wipe
/// the panel down without accidentally jogging a robot or hitting
/// E-STOP through the cloth. Auto-dismisses when the countdown reaches
/// zero; a long-press on the countdown itself ends it early (a quick
/// accidental tap during cleaning must NOT dismiss it, or the whole
/// point of this mode is defeated - see onLongPress below, not onTap).
class _ScreenCleanOverlay extends StatelessWidget {
  final int secondsLeft;
  final VoidCallback onDismiss;
  const _ScreenCleanOverlay({required this.secondsLeft, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: Stack(
        children: [
          // Layer 1: absorbs every touch meant for the app underneath -
          // this is the whole point of the mode. Deliberately does NOT
          // wrap the dismiss control below: AbsorbPointer blocks pointer
          // events from reaching its OWN descendants too, so nesting the
          // long-press GestureDetector inside this would have made
          // dismissal permanently unreachable.
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(color: Colors.black.withValues(alpha: 0.88)),
            ),
          ),
          // Layer 2: the actual dismiss control, stacked on top (not a
          // descendant of layer 1) so its own long-press still reaches it.
          // The cleaning mode must never leave the robot without a way to stop
          // it: one tap on this button is the same global STOP as the one in the top bar,
          // on top of the absorbing layer.
          Positioned(
            right: 24,
            bottom: 24,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C), minimumSize: const Size(140, 64)),
              onPressed: () => context.read<RobotViewModel>().stopAll(),
              icon: const Icon(Icons.stop),
              label: Text(l10n.cleanModeStop, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          // What the STOP did (or that it was not confirmed) must be seen here too.
          const Positioned(top: 0, left: 0, right: 0, child: StopAllBanner()),
          Positioned.fill(
            child: Center(
              child: GestureDetector(
                onLongPress: onDismiss,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cleaning_services, size: 64, color: Colors.white54),
                    const SizedBox(height: 16),
                    Text(
                      l10n.cleanModeTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.cleanModeBody(secondsLeft),
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.cleanModeDismissHint,
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
  final VoidCallback onCleanTap;
  final String cleanTooltip;
  final bool showSafety;

  const _TopNavBar({
    required this.serverName,
    required this.connectionStatus,
    required this.entries,
    required this.selectedIndex,
    required this.onSelect,
    required this.onCleanTap,
    required this.cleanTooltip,
    this.showSafety = false,
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
          if (showSafety) const _SafetyChip(),
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: Colors.white70),
            tooltip: cleanTooltip,
            onPressed: onCleanTap,
          ),
          const VerticalDivider(width: 1),
          // The global STOP: one tap, every robot, on every tab.
          const StopAllButton(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// The state of the safety service at a glance, on every tab: a shield that is green only for a current READY.
/// Redrawn only when the level changes.
class _SafetyChip extends StatelessWidget {
  const _SafetyChip();

  @override
  Widget build(BuildContext context) {
    final level = context.select<SystemModel, SafetyLevel>((m) => m.safetyLevel);
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: '${l10n.systemSafetyTitle}: ${safetyLevelText(l10n, level)}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(level == SafetyLevel.ready ? Icons.verified_user : Icons.gpp_maybe, key: const Key('safety-chip'), color: safetyColor(level)),
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
