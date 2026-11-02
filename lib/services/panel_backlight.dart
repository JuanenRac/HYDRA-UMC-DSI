// =============================================================================
// HYDRA-UMC DSI (Flutter) - services/panel_backlight.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// One owner for the backlight. Two things want it: the schedule by time of day
// (services/backlight.dart, every 15 minutes) and the idle dimming (the
// screen saver and the dim after some time without a touch). The idle value
// wins while it lasts, the schedule is what the panel goes back to on the
// first touch. Without this the schedule's own timer would undo the dimming
// at the next tick.
// =============================================================================

import 'backlight.dart';

class PanelBacklight {
  PanelBacklight({BacklightControl? control}) : _control = control ?? BacklightControl();

  /// The one used by the panel. Tests replace it.
  static PanelBacklight instance = PanelBacklight();

  final BacklightControl _control;
  int? _scheduled;
  int? _override;
  int? _lastWritten;

  /// What the backlight is set to now (percent), or null before the first write.
  int? get current => _lastWritten;

  /// The schedule for the hour [hour] (0-23): written unless the idle dimming holds the backlight.
  Future<void> applySchedule(int hour) async {
    _scheduled = brightnessPercentForHour(hour);
    await _write();
  }

  /// Holds the backlight at [percent] (idle dimming) or, with null, gives it back to the schedule.
  Future<void> setOverride(int? percent) async {
    _override = percent;
    await _write();
  }

  Future<void> _write() async {
    final target = _override ?? _scheduled;
    if (target == null || target == _lastWritten) return; // only a real change touches sysfs
    _lastWritten = target;
    await _control.setBrightnessPercent(target);
  }
}
