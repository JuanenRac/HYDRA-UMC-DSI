// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/control_screen.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Ported from HYDRA-UMC-IOS-CONTROL's own ui/control_screen.dart, laid out
// side-by-side (jog pad left, telemetry/sliders/IO right) instead of a
// single scrolling column - this app's fixed 1280x720 frame has the width
// to spare and none of the vertical room a phone has, so the original
// vertical stack would force a scroll on every real jog session. The
// emergency control is the global STOP (ui/widgets/stop_all.dart): one
// tap, no confirmation, every robot. The round per-robot stop next to
// play/pause keeps its long-press protection (a quick tap only gives a short
// haptic + hint): it is a routine stop of the selected robot.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/access.dart';
import '../models/hydra_state.dart';
import '../models/robot_command_contract.dart';
import '../state/robot_view_model.dart';
import '../util/home_reset.dart';
import '../util/play_confirmation.dart';
import 'widgets/access_panel.dart';
import 'widgets/digital_readout.dart';
import 'widgets/joystick_pad.dart';
import 'widgets/stop_all.dart';

/// Everything the control screen (and the reservation panel inside it) draws or decides from the view model, as one
/// text: the screen is redrawn when this text changes and not when only the metrics do. A field the screen starts to
/// read must be added here (test/selector_rebuild_test.dart checks the fields it has now).
String controlScreenShape(RobotViewModel vm) {
  final id = vm.selectedRobotId;
  return jsonEncode([
    vm.robots.map((r) => r.raw).toList(),
    id,
    [for (final c in vm.claims) [c.robotId, c.robotName, c.ownerUsername, c.controllerId, c.expiresAt, c.jogArmedUntil]],
    [
      for (final e in vm.safetyByRobot.entries)
        [e.key, e.value.jog.maxAmount, e.value.jog.maxAbsolute, e.value.bedMaxC, e.value.armRequired, e.value.armTtlMs, e.value.jogArmedUntil],
    ],
    [for (final e in vm.jogArmedUntil.entries) [e.key, e.value.millisecondsSinceEpoch]],
    vm.accessBusy,
    vm.conditionalMode.toString(),
    vm.confirmPlay,
    vm.listenOnly,
    vm.homeResetEnabled,
    vm.homeResetBlock(id).name,
    vm.isAdmin,
    id != null && vm.jogNeedsArming(id),
    vm.stopAllInFlight,
    vm.stopAllUnconfirmed,
    vm.apiClient != null,
  ]);
}

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  String _jogTarget = 'robot';

  // The jog step is the one the server keeps for the robot, so every client that shows it uses the same (the `jogStep`
  // command); this is only the list the dropdown offers and the step used before the server has told one.
  static const List<double> _jogSteps = [0.1, 1.0, 5.0, 10.0, 25.0, 50.0, 90.0, 100.0];
  static const double _defaultJogStep = 10.0;

  // Reservations and the safety limits of the selected robot's model are read
  // from the server when this screen opens, when the robot changes and every
  // 15 s while it stays open; a 1 s clock drives the countdown of the jog arming.
  Timer? _accessTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  dynamic _accessRobotId;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Only a countdown needs the clock (the arming of the jog, a reservation about to run out): with none under
      // way, redrawing the whole screen every second is wasted work on a panel that also runs the server.
      if (!mounted) return;
      final vm = context.read<RobotViewModel>();
      if (vm.jogArmedUntil.isNotEmpty || vm.claims.isNotEmpty) setState(() => _now = DateTime.now());
    });
    _accessTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      // The server pushes the reservations when they change: while a push is recent the poll does not ask for them.
      if (mounted) context.read<RobotViewModel>().refreshAccess(fromPoll: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RobotViewModel>().refreshAccess();
    });
  }

  @override
  void dispose() {
    _accessTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Redrawn when something this screen draws or decides changes (see controlScreenShape), not for the metrics tick.
    context.select<RobotViewModel, String>(controlScreenShape);
    final vm = context.read<RobotViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final robots = vm.robots;
    final robot = vm.selectedRobot;

    if (robot != null && _accessRobotId != robot.id) {
      _accessRobotId = robot.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) vm.refreshAccess();
      });
    }

    if (robots.isEmpty) {
      return Center(child: Text(l10n.controlNoRobots, style: const TextStyle(color: Colors.grey)));
    }

    final listenOnly = vm.listenOnly;
    return Column(
      children: [
        if (listenOnly)
          Container(
            key: const Key('listen-only-banner'),
            width: double.infinity,
            color: const Color(0xFF334155),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.hearing, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.controlListenOnlyBanner)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: 320,
            child: DropdownButtonFormField<dynamic>(
              initialValue: robot?.id,
              decoration: InputDecoration(labelText: l10n.controlRobotLabel, border: const OutlineInputBorder(), isDense: true),
              items: robots.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
              onChanged: (id) => vm.selectRobot(id),
            ),
          ),
        ),
        if (robot != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: jog pad + target/step selectors.
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      if (robot.hasXYTable) _targetSelector(l10n),
                      const SizedBox(height: 8),
                      _jogStepSelector(vm, robot, l10n),
                      const SizedBox(height: 12),
                      JoystickPad(
                        // Not while a trajectory is running: the server's
                        // playback and a jog would both write the same setpoint.
                        // When the administrator requires it, the jog also waits for
                        // the explicit arming (AccessPanel).
                        enabled: !listenOnly && robot.online && !(robot.isPlaying && !robot.isPaused) && !vm.jogNeedsArming(robot.id, _now),
                        onJog: (dx, dy, dz) {
                          HapticFeedback.selectionClick();
                          vm.jogXYZ(_jogTarget, dx, dy, dz, robot.jogStepOr(_defaultJogStep, _jogSteps));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Right: telemetry, speed/accel, valves/pumps.
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          AccessPanel(vm: vm, robotId: robot.id, now: _now),
                          const SizedBox(height: 12),
                          Wrap(spacing: 10, runSpacing: 10, children: _telemetryTiles(robot)),
                          const SizedBox(height: 20),
                          IgnorePointer(
                            ignoring: listenOnly,
                            child: Opacity(
                              opacity: listenOnly ? 0.4 : 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _speedAccelSliders(vm, robot, l10n),
                                  const SizedBox(height: 16),
                                  _ioRow(vm, robot, l10n),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(child: Center(child: Text(l10n.controlSelectRobot, style: const TextStyle(color: Colors.grey)))),
        _playbackBar(vm, robot, l10n),
      ],
    );
  }

  List<Widget> _telemetryTiles(RobotView robot) {
    return [
      DigitalReadout(label: 'X', value: robot.posAxis('x')),
      DigitalReadout(label: 'Y', value: robot.posAxis('y')),
      DigitalReadout(label: 'Z', value: robot.posAxis('z')),
      DigitalReadout(label: 'J1', value: robot.joint('j1'), color: Colors.amber),
      DigitalReadout(label: 'J2', value: robot.joint('j2'), color: Colors.amber),
      DigitalReadout(label: 'J3', value: robot.joint('j3'), color: Colors.amber),
    ];
  }

  Widget _targetSelector(AppLocalizations l10n) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'robot', label: Text(l10n.controlTargetArm)),
        ButtonSegment(value: 'xytable', label: Text(l10n.controlTargetXyTable)),
      ],
      selected: {_jogTarget},
      onSelectionChanged: (s) => setState(() => _jogTarget = s.first),
    );
  }

  Widget _jogStepSelector(RobotViewModel vm, RobotView robot, AppLocalizations l10n) {
    const steps = _jogSteps;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.controlStepLabel, style: const TextStyle(color: Colors.grey)),
        DropdownButton<double>(
          value: robot.jogStepOr(_defaultJogStep, steps),
          items: steps.map((s) => DropdownMenuItem(value: s, child: Text(s.toString()))).toList(),
          onChanged: (v) {
            if (v != null) vm.setJogStep(v);
          },
        ),
      ],
    );
  }

  Widget _speedAccelSliders(RobotViewModel vm, RobotView robot, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: 90, child: Text(l10n.controlSpeed, style: const TextStyle(color: Colors.grey))),
            Expanded(
              child: Slider(
                value: robot.speed.clamp(10, 500),
                min: 10,
                max: 500,
                divisions: 49,
                label: '${robot.speed.toStringAsFixed(0)}%',
                onChanged: (v) => vm.setSpeed(v, robot.acceleration),
              ),
            ),
            SizedBox(width: 48, child: Text('${robot.speed.toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF00E5FF)))),
          ],
        ),
        Row(
          children: [
            SizedBox(width: 90, child: Text(l10n.controlAcceleration, style: const TextStyle(color: Colors.grey))),
            Expanded(
              child: Slider(
                value: robot.acceleration.clamp(10, 500),
                min: 10,
                max: 500,
                divisions: 49,
                label: '${robot.acceleration.toStringAsFixed(0)}%',
                onChanged: (v) => vm.setSpeed(robot.speed, v),
              ),
            ),
            SizedBox(width: 48, child: Text('${robot.acceleration.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.amber))),
          ],
        ),
      ],
    );
  }

  Widget _ioRow(RobotViewModel vm, RobotView robot, AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      children: [
        for (var i = 0; i < robot.valves.length; i++)
          FilterChip(
            label: Text(l10n.controlValve(i)),
            selected: (robot.valves[i] ?? false) as bool,
            onSelected: (_) => vm.toggleValve(i),
          ),
        for (var i = 0; i < robot.pumps.length; i++)
          FilterChip(
            label: Text(l10n.controlPump(i)),
            selected: (robot.pumps[i] ?? false) as bool,
            onSelected: (_) => vm.togglePump(i),
          ),
      ],
    );
  }

  /// PLAY: asks first (what will run, at which speed, who has the robot reserved) unless the person turned that off.
  Future<void> _play(RobotViewModel vm, RobotView robot, AppLocalizations l10n) async {
    if (!playNeedsConfirmation(askBeforePlay: vm.confirmPlay, robotIsPlaying: robot.isPlaying)) {
      vm.sendCommand('play');
      return;
    }
    final String reservation;
    switch (vm.claimStandingOf(robot.id)) {
      case ClaimStanding.free:
        reservation = l10n.playConfirmFree;
      case ClaimStanding.mineHere:
      case ClaimStanding.mineElsewhere:
        reservation = l10n.playConfirmMine;
      case ClaimStanding.other:
        reservation = l10n.playConfirmOther(vm.claimOf(robot.id)?.ownerUsername ?? '');
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.playConfirmTitle),
        content: Text(l10n.playConfirmMessage(robot.name, recordedPointsCount(robot.raw), playSpeedPercent(robot.speed), reservation)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.playConfirmCancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.playConfirmStart)),
        ],
      ),
    );
    if (go == true && mounted) vm.sendCommand('play');
  }

  Widget _playbackBar(RobotViewModel vm, RobotView? robot, AppLocalizations l10n) {
    final isCombined = (robot?.combinedWith.isNotEmpty ?? false);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF12161C), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const StopAllButton(large: true),
          const SizedBox(width: 40),
          IconButton.filled(
            onPressed: !vm.listenOnly && robot != null && robot.online ? () => _play(vm, robot, l10n) : null,
            icon: const Icon(Icons.play_arrow),
            iconSize: 28,
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF15803D), minimumSize: const Size(56, 56)),
          ),
          const SizedBox(width: 20),
          IconButton.filled(
            onPressed: !vm.listenOnly && robot != null && robot.online && robot.isPlaying ? () => vm.sendCommand('pause') : null,
            icon: Icon(robot?.isPaused == true ? Icons.play_arrow : Icons.pause),
            iconSize: 28,
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFB45309), minimumSize: const Size(56, 56)),
          ),
          const SizedBox(width: 40),
          _LongPressButton(
            color: robot?.isEnabled == false ? const Color(0xFF047857) : const Color(0xFF475569),
            icon: robot?.isEnabled == false ? Icons.power_settings_new : Icons.power_off,
            tooltip: robot?.isEnabled == false ? l10n.controlEnableHold : l10n.controlDisableHold,
            // Anyone signed in can disable a robot (like a stop); only an administrator is offered the enable.
            enabled: robot != null && (robot.isEnabled ? true : (vm.isAdmin && !vm.listenOnly)),
            onConfirm: () {
              HapticFeedback.mediumImpact();
              vm.sendCommand(robot?.isEnabled == false ? 'enable' : 'disable');
            },
          ),
          const SizedBox(width: 20),
          _LongPressButton(
            color: const Color(0xFF991B1B),
            icon: Icons.stop,
            tooltip: isCombined ? l10n.controlStopAllHold : l10n.controlStopHold,
            enabled: robot != null && robot.online && (robot.isPlaying || robot.isPaused),
            onConfirm: () {
              HapticFeedback.mediumImpact();
              vm.sendCommand('stop');
            },
          ),
          // HOME/RESET: drawn only when the person switched it on in the settings; two confirmations.
          if (vm.homeResetEnabled && !vm.listenOnly && robot != null) ...[
            const SizedBox(width: 40),
            _homeResetButton(vm, robot, l10n),
          ],
        ],
      ),
    );
  }

  /// HOME/RESET: a reason not to send (safe mode, playing, no permission...) is shown as a phrase instead of opening
  /// anything; otherwise the first confirmation opens, then the second, and only the second one sends the command.
  Widget _homeResetButton(RobotViewModel vm, RobotView robot, AppLocalizations l10n) {
    final block = vm.homeResetBlock(robot.id, _now);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          key: const Key('home-reset-button'),
          onPressed: () => _homeReset(vm, robot, l10n),
          icon: const Icon(Icons.home),
          label: Text(l10n.homeResetButton),
          style: OutlinedButton.styleFrom(minimumSize: const Size(140, 56)),
        ),
        if (block != HomeResetBlock.none)
          SizedBox(
            width: 220,
            child: Text(homeResetBlockText(l10n, block),
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ),
      ],
    );
  }

  Future<void> _homeReset(RobotViewModel vm, RobotView robot, AppLocalizations l10n) async {
    final block = vm.homeResetBlock(robot.id, _now);
    if (block != HomeResetBlock.none) {
      vm.homeReset(); // says why it is not sent
      return;
    }
    final confirmation = vm.homeResetConfirmation..cancel();
    var step = 1;
    while (mounted) {
      final last = step >= RobotCommandContract.homeResetConfirmSteps;
      final go = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(last ? l10n.homeResetStep2Title : l10n.homeResetStep1Title(robot.name)),
          content: Text(last ? l10n.homeResetStep2Message(robot.name) : l10n.homeResetStep1Message),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.playConfirmCancel)),
            FilledButton(
              key: Key(last ? 'home-reset-confirm-last' : 'home-reset-confirm-first'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(last ? l10n.homeResetStep2Button : l10n.homeResetStep1Button),
            ),
          ],
        ),
      );
      if (go != true) {
        confirmation.cancel();
        return;
      }
      final progress = confirmation.advance();
      if (progress.isDone) {
        if (mounted) vm.homeReset();
        return;
      }
      step = progress.next!;
    }
  }
}

/// Only a genuine long-press triggers [onConfirm] - a quick tap just gives
/// haptic + visual feedback that holding is required.
class _LongPressButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String tooltip;
  final VoidCallback onConfirm;
  final bool enabled;
  const _LongPressButton({required this.color, required this.icon, required this.tooltip, required this.onConfirm, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onLongPress: enabled ? onConfirm : null,
        onTap: enabled ? () => HapticFeedback.selectionClick() : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.6), width: 2)),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}
