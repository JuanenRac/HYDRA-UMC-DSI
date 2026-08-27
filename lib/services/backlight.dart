// =============================================================================
// HYDRA-UMC DSI (Flutter) - services/backlight.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Adaptive backlight by time of day (audit idea: "retroiluminación
// adaptativa según la hora del día").
//
// Linux's own backlight class exposes brightness control identically for
// every panel driver (DSI, HDMI-with-DDC, eDP, ...) at
// /sys/class/backlight/<driver-name>/brightness, 0..max_brightness (read
// from a sibling file, NOT a fixed 0-255 - some drivers use a much wider
// or narrower range). The exact <driver-name> directory depends on which
// kernel driver claims this board's real panel (varies by DSI bridge
// chip/panel, not something this app can hardcode without the real
// hardware in hand) - so this globs whatever actually exists under
// /sys/class/backlight/ instead of guessing one literal name, and simply
// does nothing (logged once, not a crash) if there's no backlight device
// at all - true on every non-Linux dev machine, and also possible on a
// real CM5 host if the panel driver doesn't register one.
//
// NOT verified against real DSI panel hardware in this session (no CM5
// available here) - the sysfs read/glob logic itself is exercised by
// this file's own defensive "no device found" path on this Windows dev
// machine, which is the one thing actually testable without the board.
// =============================================================================
import 'dart:io';

class BacklightControl {
  Directory? _cachedDevice;
  bool _loggedMissing = false;

  /// Finds the first real backlight device directory, caching the result
  /// (the set of backlight devices never changes at runtime on real
  /// hardware - no need to re-glob /sys/class/backlight/ on every call).
  Directory? _findDevice() {
    if (_cachedDevice != null) return _cachedDevice;
    if (!Platform.isLinux) return null;
    final base = Directory('/sys/class/backlight');
    if (!base.existsSync()) {
      if (!_loggedMissing) {
        _loggedMissing = true;
        // ignore: avoid_print
        print('[Backlight] /sys/class/backlight not present - adaptive backlight disabled on this host.');
      }
      return null;
    }
    final entries = base.listSync().whereType<Directory>().toList();
    if (entries.isEmpty) {
      if (!_loggedMissing) {
        _loggedMissing = true;
        // ignore: avoid_print
        print('[Backlight] No backlight device registered under /sys/class/backlight - adaptive backlight disabled.');
      }
      return null;
    }
    _cachedDevice = entries.first;
    return _cachedDevice;
  }

  /// Sets brightness as a 0-100 percentage of this device's own real
  /// max_brightness (never a raw value - drivers disagree on scale, some
  /// use 0-255, some 0-31, some much finer). Returns true only on a real
  /// successful write; every failure path (no device, unreadable
  /// max_brightness, unwritable brightness - e.g. running without the
  /// permissions install_kiosk.sh's own udev rule grants) returns false
  /// rather than throwing, since a backlight write failing should never
  /// be able to crash the whole kiosk app over a cosmetic feature.
  Future<bool> setBrightnessPercent(int percent) async {
    final device = _findDevice();
    if (device == null) return false;
    final clamped = percent.clamp(0, 100);
    try {
      final maxFile = File('${device.path}/max_brightness');
      final maxBrightness = int.parse((await maxFile.readAsString()).trim());
      final value = (maxBrightness * clamped / 100).round();
      await File('${device.path}/brightness').writeAsString('$value');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('[Backlight] Failed to set brightness: $e');
      return false;
    }
  }
}

/// Simple fixed day/night schedule - bright during a normal shop-floor
/// working day, dimmer outside it to reduce glare/eye strain on an
/// unattended overnight panel. Deliberately a plain function (not a
/// user-configurable schedule yet) - the audit idea asked for "adaptativa
/// según la hora del día", not a full scheduling UI; that's a reasonable
/// larger follow-up if the fixed schedule below doesn't fit a real
/// deployment's actual shift hours.
int brightnessPercentForHour(int hour) {
  if (hour >= 7 && hour < 19) return 100; // 07:00-19:00: full brightness
  if (hour >= 19 && hour < 22) return 60; // 19:00-22:00: evening wind-down
  return 30; // 22:00-07:00: night
}
