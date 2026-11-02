// =============================================================================
// HYDRA-UMC DSI (Flutter) - util/home_reset.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// HOME/RESET takes the selected robot to its zero position through the
// server's `reset` command. It moves a real robot, so this file holds only the
// rules (no network, no screen): when the app refuses to offer it, and the
// confirmation in steps that must all be given, in order, within a time window.
//
// The numbers (switch off by default, steps, window) come from
// docs/robot_command_contract.json through the generated RobotCommandContract,
// so they are not tuned here.
// =============================================================================

import '../l10n/app_localizations.dart';

/// Why the app does not send the reset; [none] means it may go on to the confirmation.
enum HomeResetBlock { none, off, notConnected, offline, safeMode, moving, jogBusy, stopPending, notArmed, role, noPose, notSupported }

/// What the app knows about the robot and the session at the moment of the request.
class HomeResetSituation {
  final bool switchedOn;
  final bool connected;
  final bool robotOnline;

  /// False when the robot is in safe mode (the server refuses everything but STOP then).
  final bool robotEnabled;

  /// A trajectory is playing (paused or not): a reset would fight its setpoint.
  final bool robotPlaying;
  final bool jogInFlight;

  /// The global STOP is being sent or has not been confirmed.
  final bool stopInProgress;

  /// The administrator requires the jog to be armed and it is not.
  final bool needsArming;

  /// The role in the session token (`admin`, `operator`) or null when it cannot be read; the server checks it anyway.
  final String? role;

  /// The robot has a pose to take to zero.
  final bool hasPose;

  /// False once the server answered that it does not know the command.
  final bool serverSupports;

  const HomeResetSituation({
    required this.switchedOn,
    required this.connected,
    required this.robotOnline,
    required this.robotEnabled,
    required this.robotPlaying,
    required this.jogInFlight,
    required this.stopInProgress,
    required this.needsArming,
    required this.role,
    required this.hasPose,
    required this.serverSupports,
  });
}

bool homeResetRoleAllowed(String? role) => role == null || role == 'admin' || role == 'operator';

/// The first reason not to send the reset, in the order a person can fix them; [HomeResetBlock.none] when there is none.
HomeResetBlock homeResetBlockOf(HomeResetSituation s) {
  if (!s.switchedOn) return HomeResetBlock.off;
  if (!s.connected) return HomeResetBlock.notConnected;
  if (!s.serverSupports) return HomeResetBlock.notSupported;
  if (!homeResetRoleAllowed(s.role)) return HomeResetBlock.role;
  if (!s.robotOnline) return HomeResetBlock.offline;
  if (!s.robotEnabled) return HomeResetBlock.safeMode;
  if (s.stopInProgress) return HomeResetBlock.stopPending;
  if (s.robotPlaying) return HomeResetBlock.moving;
  if (s.jogInFlight) return HomeResetBlock.jogBusy;
  if (s.needsArming) return HomeResetBlock.notArmed;
  if (!s.hasPose) return HomeResetBlock.noPose;
  return HomeResetBlock.none;
}

/// The phrase for a [HomeResetBlock], in the language of the panel.
String homeResetBlockText(AppLocalizations l10n, HomeResetBlock block) => switch (block) {
      HomeResetBlock.none => l10n.homeResetBlockedNone,
      HomeResetBlock.off => l10n.homeResetBlockedOff,
      HomeResetBlock.notConnected => l10n.errNotConnected,
      HomeResetBlock.offline => l10n.homeResetBlockedOffline,
      HomeResetBlock.safeMode => l10n.homeResetBlockedSafeMode,
      HomeResetBlock.moving => l10n.homeResetBlockedMoving,
      HomeResetBlock.jogBusy => l10n.homeResetBlockedJog,
      HomeResetBlock.stopPending => l10n.homeResetBlockedStop,
      HomeResetBlock.notArmed => l10n.errJogNotArmed,
      HomeResetBlock.role => l10n.homeResetBlockedRole,
      HomeResetBlock.noPose => l10n.homeResetBlockedNoPose,
      HomeResetBlock.notSupported => l10n.homeResetNotSupported,
    };

/// The result of giving one step of the confirmation: the next step to ask for, or done.
class HomeResetProgress {
  /// The number (1-based) of the step to give now; null when the confirmation is complete.
  final int? next;
  const HomeResetProgress._(this.next);
  const HomeResetProgress.waiting(int next) : this._(next);
  static const HomeResetProgress done = HomeResetProgress._(null);
  bool get isDone => next == null;

  @override
  bool operator ==(Object other) => other is HomeResetProgress && other.next == next;
  @override
  int get hashCode => next.hashCode;
}

/// The confirmation in [steps] steps. [advance] returns the step to ask for next; the last one reports done. A step
/// given after the window has passed starts over, and so does [cancel].
class HomeResetConfirmation {
  final int steps;
  final Duration window;
  final DateTime Function() _clock;
  int _accepted = 0;
  DateTime _startedAt = DateTime.fromMillisecondsSinceEpoch(0);

  HomeResetConfirmation({required this.steps, required this.window, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  bool get _expired => _accepted > 0 && _clock().difference(_startedAt) > window;

  /// The number of the step to show now (1-based); 1 when nothing is under way or the window has passed.
  int get current => _expired ? 1 : _accepted + 1;

  HomeResetProgress advance() {
    if (_expired) _accepted = 0;
    if (_accepted == 0) _startedAt = _clock();
    _accepted += 1;
    if (_accepted >= (steps < 1 ? 1 : steps)) {
      _accepted = 0;
      return HomeResetProgress.done;
    }
    return HomeResetProgress.waiting(_accepted + 1);
  }

  void cancel() => _accepted = 0;
}
