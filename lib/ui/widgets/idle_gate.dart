// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/idle_gate.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Watches for touches on the whole panel and does what the settings file says
// after a time without one (util/idle_policy.dart): dim the backlight, show
// the screen saver, and lock the panel until the operator types the PIN.
//
//  * Every touch (and every key of a USB keyboard) counts as activity.
//  * The touch that wakes a dark or locked panel is consumed: it does not also
//    press whatever is under the finger.
//  * Dimming and the saver wait while a robot plays a trajectory or a STOP is
//    unconfirmed; the lock never waits.
//  * The global STOP is on the saver and on the lock screen. Nobody has to
//    unlock a panel to stop a robot.
//  * The lock only exists when a PIN was set, and it is sticky: once the time
//    has passed it stays until the right PIN is typed, even if the settings
//    change meanwhile.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/operator_pin.dart';
import '../../services/panel_backlight.dart';
import '../../state/robot_view_model.dart';
import '../../util/idle_policy.dart';
import 'pin_pad.dart';
import 'stop_all.dart';

class IdleGate extends StatefulWidget {
  final Widget child;

  /// The clock; tests replace it.
  final DateTime Function()? clock;

  /// How often the idle time is looked at.
  final Duration tick;

  const IdleGate({super.key, required this.child, this.clock, this.tick = const Duration(seconds: 1)});

  @override
  State<IdleGate> createState() => _IdleGateState();
}

class _IdleGateState extends State<IdleGate> {
  late DateTime _lastActivity;
  Timer? _timer;
  IdleStage _stage = IdleStage.awake;
  bool _locked = false;
  String? _pinMessage;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _lastActivity = _now();
    HardwareKeyboard.instance.addHandler(_onKey);
    _timer = Timer.periodic(widget.tick, (_) => _look());
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    unawaited(PanelBacklight.instance.setOverride(null));
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    _activity();
    return false; // never consumed: the key still reaches whoever wanted it
  }

  /// Anything that shows the person is there: back to awake. Returns true when the panel was dark or locked.
  bool _activity() {
    final wasDark = _stage != IdleStage.awake;
    _lastActivity = _now();
    if (_stage != IdleStage.awake) {
      _stage = IdleStage.awake;
      unawaited(PanelBacklight.instance.setOverride(null));
      if (mounted) setState(() {});
    }
    return wasDark;
  }

  void _look() {
    if (!mounted) return;
    final vm = context.read<RobotViewModel>();
    final config = vm.panelConfig;
    final idle = _now().difference(_lastActivity);

    var changed = false;
    if (!_locked && idleLockedFor(idle, config, pinSet: vm.pin.isSet)) {
      _locked = true;
      _pinMessage = null;
      changed = true;
    }
    final stage = idleStageFor(idle, config, busy: vm.panelBusy);
    if (stage != _stage) {
      _stage = stage;
      unawaited(PanelBacklight.instance.setOverride(backlightForStage(stage, config)));
      changed = true;
    }
    if (changed) setState(() {});
  }

  void _tryPin(String pin) {
    final vm = context.read<RobotViewModel>();
    final l10n = AppLocalizations.of(context)!;
    switch (vm.pin.check(pin)) {
      case PinCheck.accepted || PinCheck.notSet:
        setState(() {
          _locked = false;
          _pinMessage = null;
          _lastActivity = _now();
        });
      case PinCheck.wrong:
        setState(() => _pinMessage = l10n.lockWrongPin(vm.pin.attemptsLeft));
      case PinCheck.lockedOut:
        setState(() => _pinMessage = l10n.lockLockedOut(vm.pin.lockedOutSeconds()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        // The touch that wakes the saver or the lock screen is the wake-up, nothing else.
        _activity();
      },
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          // The saver comes first: a locked panel that is also dark stays dark until it is touched, and the lock
          // screen is what that touch shows.
          if (_stage == IdleStage.saver)
            const Positioned.fill(child: _SaverOverlay())
          else if (_locked)
            Positioned.fill(child: _LockOverlay(message: _pinMessage, onPin: _tryPin)),
        ],
      ),
    );
  }
}

/// The screen saver: a dark screen with a small clock that moves a little every minute (so no pixel stays lit), and
/// the global STOP. A touch anywhere else wakes the panel.
class _SaverOverlay extends StatelessWidget {
  const _SaverOverlay();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Moves between nine places, one step per minute.
    final slot = now.minute % 9;
    final alignment = Alignment((slot % 3 - 1) * 0.6, ((slot ~/ 3) - 1) * 0.6);
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Container(
      key: const Key('idle-saver'),
      color: Colors.black,
      child: Stack(
        children: [
          Align(alignment: alignment, child: Text(time, style: const TextStyle(color: Color(0xFF334155), fontSize: 64, fontWeight: FontWeight.w200))),
          const Positioned(right: 24, bottom: 24, child: _OverlayStop()),
        ],
      ),
    );
  }
}

class _OverlayStop extends StatelessWidget {
  const _OverlayStop();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FilledButton.icon(
      key: const Key('overlay-stop'),
      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C), minimumSize: const Size(140, 64)),
      onPressed: () => context.read<RobotViewModel>().stopAll(),
      icon: const Icon(Icons.stop),
      label: Text(l10n.cleanModeStop, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _LockOverlay extends StatelessWidget {
  final String? message;
  final ValueChanged<String> onPin;
  const _LockOverlay({required this.message, required this.onPin});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.read<RobotViewModel>();
    final lockedOut = vm.pin.lockedOutSeconds() > 0;
    return Material(
      key: const Key('idle-lock'),
      color: const Color(0xFF07090C),
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48, color: Colors.white54),
                  const SizedBox(height: 8),
                  Text(l10n.lockTitle, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(l10n.lockHint, style: const TextStyle(color: Colors.white60)),
                  const SizedBox(height: 12),
                  PinPad(onSubmit: onPin, disabled: lockedOut, maxLength: 12),
                  SizedBox(
                    height: 28,
                    child: message == null
                        ? null
                        : Text(message!, key: const Key('lock-message'), style: const TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: StopAllBanner()),
          const Positioned(right: 24, bottom: 24, child: _OverlayStop()),
        ],
      ),
    );
  }
}
