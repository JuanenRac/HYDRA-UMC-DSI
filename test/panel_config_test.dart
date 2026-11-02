// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/panel_config_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The settings file of the panel: every default is the conservative one, a
// bad line never stops the panel, and the whole Compute Module is only ever
// offered when the file chooses it on purpose (twice: the action and the
// permission).
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/util/panel_config.dart';

void main() {
  test('every default is the conservative one', () {
    const c = PanelConfig.defaults;
    expect(c.appliance, isFalse);
    expect(c.virtualKeyboard, isFalse);
    expect(c.idleLockSeconds, 0);
    expect(c.dimAfterSeconds, 0);
    expect(c.saverAfterSeconds, 0);
    expect(c.idleWaitsWhileBusy, isTrue);
    expect(c.rebootButton, isFalse);
    expect(c.rebootAction, RebootAction.screen);
    expect(c.rebootHostAllowed, isFalse);
    expect(c.safetyPanel, isFalse);
    expect(c.ecosystemView, isFalse);
    expect(c.systemTab, isFalse);
    expect(c.hostRebootOffered, isFalse);
    expect(c.safetyHost, '127.0.0.1');
    expect(c.safetyToken, isEmpty);
  });

  test('an empty file, comments and lines without a key give the defaults', () {
    expect(PanelConfig.parse('').appliance, isFalse);
    expect(PanelConfig.parse('# nothing here\n\n   \n= value\njust text\n').virtualKeyboard, isFalse);
  });

  test('values are read, with comments, quotes, capitals and Windows line ends', () {
    final c = PanelConfig.parse('''
# the panel
appliance = ON            # a fixed screen
Virtual_Keyboard = yes
idle_lock_seconds = 120
dim_after_seconds=30
dim_percent = 15
saver_after_seconds = 300
safety_panel = true
safety_host = "10.0.0.5"
safety_port = 9000
safety_token = 'abc 123'
ecosystem_view = 1
reboot_button = on
reboot_action = services
'''.replaceAll('\n', '\r\n'));
    expect(c.appliance, isTrue);
    expect(c.virtualKeyboard, isTrue);
    expect(c.idleLockSeconds, 120);
    expect(c.dimAfterSeconds, 30);
    expect(c.dimPercent, 15);
    expect(c.saverAfterSeconds, 300);
    expect(c.safetyPanel, isTrue);
    expect(c.safetyHost, '10.0.0.5');
    expect(c.safetyPort, 9000);
    expect(c.safetyToken, 'abc 123');
    expect(c.ecosystemView, isTrue);
    expect(c.rebootButton, isTrue);
    expect(c.rebootAction, RebootAction.services);
    expect(c.systemTab, isTrue);
  });

  test('a value that makes no sense keeps the default, and the other keys still count', () {
    final c = PanelConfig.parse('''
idle_lock_seconds = soon
dim_percent = 400
pin_max_attempts = 0
pin_min_length = 2
safety_port = 99999
reboot_action = explode
appliance = maybe
virtual_keyboard = on
''');
    expect(c.idleLockSeconds, 0);
    expect(c.dimPercent, PanelConfig.defaults.dimPercent);
    expect(c.pinMaxAttempts, PanelConfig.defaults.pinMaxAttempts);
    expect(c.pinMinLength, PanelConfig.defaults.pinMinLength);
    expect(c.safetyPort, 8108);
    expect(c.rebootAction, RebootAction.screen);
    expect(c.appliance, isFalse);
    expect(c.virtualKeyboard, isTrue);
  });

  test('the whole Compute Module needs the button, the action and the permission', () {
    expect(PanelConfig.parse('reboot_button = on\nreboot_action = host').hostRebootOffered, isFalse, reason: 'no permission');
    expect(PanelConfig.parse('reboot_button = on\nreboot_host_allowed = on').hostRebootOffered, isFalse, reason: 'the action is the screen');
    expect(PanelConfig.parse('reboot_action = host\nreboot_host_allowed = on').hostRebootOffered, isFalse, reason: 'no button');
    expect(PanelConfig.parse('reboot_button = on\nreboot_action = host\nreboot_host_allowed = on').hostRebootOffered, isTrue);
  });

  test('a missing or unreadable file gives the defaults, and a file is read from the path given', () async {
    expect((await PanelConfig.load(path: '/definitely/not/here.conf')).appliance, isFalse);
    final dir = await Directory.systemTemp.createTemp('dsi_conf');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/dsi.conf')..writeAsStringSync('appliance = on\n');
    expect((await PanelConfig.load(path: file.path)).appliance, isTrue);
    expect((await PanelConfig.load(environment: {'HYDRA_DSI_CONFIG': file.path})).appliance, isTrue);
    expect((await PanelConfig.load(path: dir.path)).appliance, isFalse, reason: 'a directory is not a file');
  });

  test('the example file of the kiosk names only keys the panel understands, and is the appliance setup with nothing risky on', () {
    final text = File('kiosk/dsi.conf.example').readAsStringSync();
    final keys = <String>{};
    for (final line in text.split(RegExp(r'\r?\n'))) {
      final code = line.split('#').first.trim();
      final eq = code.indexOf('=');
      if (eq > 0) keys.add(code.substring(0, eq).trim());
    }
    expect(keys.difference(PanelConfig.knownKeys), isEmpty, reason: 'a key the panel does not read');
    expect(PanelConfig.knownKeys.difference(keys), isEmpty, reason: 'a key the example does not document');
    final c = PanelConfig.parse(text);
    expect(c.appliance, isTrue);
    expect(c.virtualKeyboard, isTrue);
    expect(c.idleLockSeconds, 0);
    expect(c.rebootButton, isFalse);
    expect(c.hostRebootOffered, isFalse);
    expect(c.safetyPanel, isFalse);
    expect(c.ecosystemView, isFalse);
    expect(c.safetyToken, isEmpty);
  });
}
