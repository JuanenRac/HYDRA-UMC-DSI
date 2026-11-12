// =============================================================================
// HYDRA-UMC DSI (Flutter) - util/panel_config.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Every tunable of the panel lives in ONE configuration file, never in the
// code: a plain text file of `key = value` lines (`#` starts a comment). The
// file is looked for, first one wins, at the path of the environment variable
// HYDRA_DSI_CONFIG, then at /etc/hydra-umc/dsi.conf. A missing or unreadable
// file, an unknown key or a value that does not make sense never stops the
// panel: that key keeps its default, and every default is the conservative
// one (each optional feature is off, each timer is off, the reboot button
// restarts only the screen).
//
// See kiosk/dsi.conf.example for every key with its meaning.
// =============================================================================

import 'dart:io';

/// What the reboot button restarts. The whole computer is never restarted
/// unless the person chose [host] here, on purpose.
enum RebootAction {
  /// Only this screen: the app closes and the supervisor of the service starts it again.
  screen,

  /// The services of HYDRA-UMC (the server restarts itself; needs an administrator).
  services,

  /// The whole Compute Module. Needs `reboot_host_allowed = on` as well.
  host;

  static RebootAction? parse(String value) {
    for (final action in RebootAction.values) {
      if (action.name == value) return action;
    }
    return null;
  }
}

class PanelConfig {
  /// Appliance mode: the panel is a fixed screen of the Compute Module. The address is the machine itself, there is
  /// no network scan and no way to point it at another server, and the saved session is used at start-up.
  final bool appliance;

  /// File that holds the signed token of this device (issued by an administrator of the server). In appliance mode the
  /// panel exchanges it for a short sign-in at start-up and whenever the session cannot be renewed, so nobody types
  /// a password at an unattended screen. Empty = off. The file must be readable by the panel account only.
  final String deviceTokenFile;

  /// The on-screen keyboard under the fields of the sign-in screen (a touch panel has no other).
  final bool virtualKeyboard;

  /// Seconds without a touch before the panel locks and asks for the PIN of the operator. 0 = never. It only
  /// locks when a PIN was set on this panel, so it can never lock anyone out.
  final int idleLockSeconds;

  /// Seconds without a touch before the backlight is dimmed. 0 = never.
  final int dimAfterSeconds;

  /// Backlight (percent) while dimmed.
  final int dimPercent;

  /// Seconds without a touch before the screen saver (a dark screen with a moving clock) takes over. 0 = never.
  final int saverAfterSeconds;

  /// Backlight (percent) while the screen saver shows.
  final int saverPercent;

  /// Dimming and the screen saver wait while a robot is playing a trajectory or a stop has not been confirmed.
  final bool idleWaitsWhileBusy;

  /// Wrong PINs in a row before the lock refuses more for [pinLockoutSeconds].
  final int pinMaxAttempts;
  final int pinLockoutSeconds;
  final int pinMinLength;

  /// The reboot button in the System tab.
  final bool rebootButton;
  final RebootAction rebootAction;

  /// Restarting the whole Compute Module is only offered when this is on and [rebootAction] is [RebootAction.host].
  final bool rebootHostAllowed;

  /// The safety panel (state of HYDRA-UMC-SAFETY-ZONES) in the System tab.
  final bool safetyPanel;
  final String safetyHost;
  final int safetyPort;

  /// Bearer token of the safety service, when it asks for one. Part of the file: keep the file readable by its owner only.
  final String safetyToken;
  final int safetyPollSeconds;

  /// A state older than this many seconds is shown as stale, never as "all clear".
  final int safetyStaleSeconds;

  /// The ecosystem view (services of HYDRA-UMC and their health) in the System tab.
  final bool ecosystemView;
  final int ecosystemPollSeconds;

  /// The tool arms view (which URTC tools are armed, read only) in the System tab.
  final bool toolArmsPanel;
  final int toolArmsPollSeconds;

  const PanelConfig({
    this.appliance = false,
    this.deviceTokenFile = '',
    this.virtualKeyboard = false,
    this.idleLockSeconds = 0,
    this.dimAfterSeconds = 0,
    this.dimPercent = 20,
    this.saverAfterSeconds = 0,
    this.saverPercent = 5,
    this.idleWaitsWhileBusy = true,
    this.pinMaxAttempts = 5,
    this.pinLockoutSeconds = 30,
    this.pinMinLength = 4,
    this.rebootButton = false,
    this.rebootAction = RebootAction.screen,
    this.rebootHostAllowed = false,
    this.safetyPanel = false,
    this.safetyHost = '127.0.0.1',
    this.safetyPort = 8108,
    this.safetyToken = '',
    this.safetyPollSeconds = 2,
    this.safetyStaleSeconds = 10,
    this.ecosystemView = false,
    this.ecosystemPollSeconds = 10,
    this.toolArmsPanel = false,
    this.toolArmsPollSeconds = 5,
  });

  /// Every default: the conservative one.
  static const PanelConfig defaults = PanelConfig();

  /// Where the file is looked for when no path is given.
  static const String defaultPath = '/etc/hydra-umc/dsi.conf';

  /// Every key the file understands (the example file of the kiosk is checked against this list).
  static const Set<String> knownKeys = {
    'appliance',
    'device_token_file',
    'virtual_keyboard',
    'idle_lock_seconds',
    'dim_after_seconds',
    'dim_percent',
    'saver_after_seconds',
    'saver_percent',
    'idle_waits_while_busy',
    'pin_max_attempts',
    'pin_lockout_seconds',
    'pin_min_length',
    'reboot_button',
    'reboot_action',
    'reboot_host_allowed',
    'safety_panel',
    'safety_host',
    'safety_port',
    'safety_token',
    'safety_poll_seconds',
    'safety_stale_seconds',
    'ecosystem_view',
    'ecosystem_poll_seconds',
    'tool_arms_panel',
    'tool_arms_poll_seconds',
  };

  /// The System tab has something to show.
  bool get systemTab => rebootButton || safetyPanel || ecosystemView || toolArmsPanel;

  /// The whole Compute Module may be restarted from the panel (chosen on purpose, twice).
  bool get hostRebootOffered => rebootButton && rebootAction == RebootAction.host && rebootHostAllowed;

  /// Reads the lines of the file. Unknown keys and values that make no sense are ignored (the default stays).
  factory PanelConfig.parse(String text) {
    final values = <String, String>{};
    for (final raw in text.split('\n')) {
      var line = raw.trim();
      final hash = line.indexOf('#');
      if (hash >= 0) line = line.substring(0, hash).trim();
      final eq = line.indexOf('=');
      if (eq <= 0) continue;
      final key = line.substring(0, eq).trim().toLowerCase();
      var value = line.substring(eq + 1).trim();
      if (value.length >= 2 && (value.startsWith('"') && value.endsWith('"') || value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      values[key] = value;
    }

    bool flag(String key, bool fallback) {
      switch (values[key]?.toLowerCase()) {
        case 'on' || 'true' || 'yes' || '1':
          return true;
        case 'off' || 'false' || 'no' || '0':
          return false;
        default:
          return fallback;
      }
    }

    int number(String key, int fallback, {int min = 0, int max = 86400}) {
      final v = int.tryParse(values[key] ?? '');
      if (v == null || v < min || v > max) return fallback;
      return v;
    }

    String word(String key, String fallback) {
      final v = values[key];
      return v == null || v.isEmpty ? fallback : v;
    }

    const d = PanelConfig.defaults;
    return PanelConfig(
      appliance: flag('appliance', d.appliance),
      deviceTokenFile: values['device_token_file'] ?? d.deviceTokenFile,
      virtualKeyboard: flag('virtual_keyboard', d.virtualKeyboard),
      idleLockSeconds: number('idle_lock_seconds', d.idleLockSeconds),
      dimAfterSeconds: number('dim_after_seconds', d.dimAfterSeconds),
      dimPercent: number('dim_percent', d.dimPercent, max: 100),
      saverAfterSeconds: number('saver_after_seconds', d.saverAfterSeconds),
      saverPercent: number('saver_percent', d.saverPercent, max: 100),
      idleWaitsWhileBusy: flag('idle_waits_while_busy', d.idleWaitsWhileBusy),
      pinMaxAttempts: number('pin_max_attempts', d.pinMaxAttempts, min: 1, max: 20),
      pinLockoutSeconds: number('pin_lockout_seconds', d.pinLockoutSeconds, min: 1, max: 3600),
      pinMinLength: number('pin_min_length', d.pinMinLength, min: 4, max: 12),
      rebootButton: flag('reboot_button', d.rebootButton),
      rebootAction: RebootAction.parse(values['reboot_action']?.toLowerCase() ?? '') ?? d.rebootAction,
      rebootHostAllowed: flag('reboot_host_allowed', d.rebootHostAllowed),
      safetyPanel: flag('safety_panel', d.safetyPanel),
      safetyHost: word('safety_host', d.safetyHost),
      safetyPort: number('safety_port', d.safetyPort, min: 1, max: 65535),
      safetyToken: values['safety_token'] ?? d.safetyToken,
      safetyPollSeconds: number('safety_poll_seconds', d.safetyPollSeconds, min: 1, max: 60),
      safetyStaleSeconds: number('safety_stale_seconds', d.safetyStaleSeconds, min: 2, max: 3600),
      ecosystemView: flag('ecosystem_view', d.ecosystemView),
      ecosystemPollSeconds: number('ecosystem_poll_seconds', d.ecosystemPollSeconds, min: 2, max: 600),
      toolArmsPanel: flag('tool_arms_panel', d.toolArmsPanel),
      toolArmsPollSeconds: number('tool_arms_poll_seconds', d.toolArmsPollSeconds, min: 2, max: 600),
    );
  }

  /// Reads the file at [path] (or the one the environment names, or [defaultPath]); defaults when there is none.
  static Future<PanelConfig> load({String? path, Map<String, String>? environment}) async {
    final env = environment ?? Platform.environment;
    final where = path ?? env['HYDRA_DSI_CONFIG'] ?? defaultPath;
    try {
      final file = File(where);
      if (!await file.exists()) return defaults;
      return PanelConfig.parse(await file.readAsString());
    } catch (_) {
      return defaults;
    }
  }
}
