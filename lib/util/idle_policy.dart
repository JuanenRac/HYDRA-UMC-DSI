// =============================================================================
// HYDRA-UMC DSI (Flutter) - util/idle_policy.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// What the panel does after a time without a touch, as a plain function of the
// idle time and the settings: no timers, no screen. The widget that owns the
// timer (ui/widgets/idle_gate.dart) only asks this function.
//
// The order a panel goes through is: awake, dimmed, screen saver, and locked.
// The lock is independent of the other two: it only exists when a PIN was set
// (a panel that cannot be unlocked would be a trap), and it never waits for a
// robot, because an unattended panel next to a moving robot is exactly the
// case the lock is for. Dimming and the saver DO wait while a robot plays a
// trajectory or a stop is unconfirmed, so the person watching the machine
// never loses the picture.
// =============================================================================

import 'panel_config.dart';

enum IdleStage { awake, dimmed, saver }

/// What the panel looks like after [idle] without a touch.
IdleStage idleStageFor(Duration idle, PanelConfig config, {required bool busy}) {
  if (busy && config.idleWaitsWhileBusy) return IdleStage.awake;
  final seconds = idle.inSeconds;
  if (config.saverAfterSeconds > 0 && seconds >= config.saverAfterSeconds) return IdleStage.saver;
  if (config.dimAfterSeconds > 0 && seconds >= config.dimAfterSeconds) return IdleStage.dimmed;
  return IdleStage.awake;
}

/// Whether the panel is locked after [idle] without a touch: the lock is on, and there is a PIN to unlock it with.
bool idleLockedFor(Duration idle, PanelConfig config, {required bool pinSet}) {
  if (!pinSet || config.idleLockSeconds <= 0) return false;
  return idle.inSeconds >= config.idleLockSeconds;
}

/// The backlight (percent) for a stage; null means "the schedule decides" (the panel is awake).
int? backlightForStage(IdleStage stage, PanelConfig config) => switch (stage) {
      IdleStage.awake => null,
      IdleStage.dimmed => config.dimPercent,
      IdleStage.saver => config.saverPercent,
    };
