// The screens of the interface that runs on the STM32H757 are data (docs/ui, a copy of the files of the HYDRA-UMC repository kept by
// tools/sync_ui_spec.py). This test keeps the app and that data in step: a text that claims to be the same as one of the app is, in all
// eight languages, and every screen of the panel has a screen of the app unless it is one the panel alone has.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _languages = ['en', 'es', 'de', 'fr', 'it', 'ja', 'zh', 'pt'];

// The screen of the app that answers each screen of the panel (the PIN pad of the panel is the modal screen "unlock"). The panel has one the app does not: the alarms.
const _appScreens = {
  'dashboard': 'lib/ui/dashboard_screen.dart',
  'control': 'lib/ui/control_screen.dart',
  'camera': 'lib/ui/camera_screen.dart',
  'position': 'lib/ui/three_d_screen.dart',
  'metrics': 'lib/ui/metrics_screen.dart',
  'system': 'lib/ui/system_screen.dart',
  'settings': 'lib/ui/settings_screen.dart',
  'unlock': 'lib/ui/widgets/pin_pad.dart',
};
const _panelOnly = {'alarms'};

Map<String, dynamic> _read(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final spec = _read('docs/ui/ui_spec.json');
  final i18n = _read('docs/ui/i18n.json');
  final texts = (i18n['keys'] as Map<String, dynamic>).cast<String, Map<String, dynamic>>();

  test('The texts have the eight languages', () {
    expect(i18n['languages'], _languages);
    for (final entry in texts.entries) {
      for (final language in _languages) {
        final text = entry.value[language];
        expect(text is String && text.trim().isNotEmpty, isTrue, reason: '${entry.key} $language');
      }
    }
  });

  test('A text linked to a key of the app is the text of the app, in every language', () {
    var linked = 0;
    for (final language in _languages) {
      final arb = _read('lib/l10n/app_$language.arb');
      for (final entry in texts.entries) {
        final name = entry.value['arb'];
        if (name is String) {
          expect(arb[name], entry.value[language], reason: '${entry.key} ($language) differs from $name');
          if (language == 'en') linked++;
        }
      }
    }
    expect(linked, greaterThan(10));
  });

  test('Every screen of the panel has a screen of the app, except the ones the panel alone has', () {
    final screens = (spec['screens'] as List<dynamic>).map((s) => (s as Map<String, dynamic>)['id'] as String).toList();
    for (final id in screens) {
      if (_panelOnly.contains(id)) continue;
      final file = _appScreens[id];
      expect(file, isNotNull, reason: 'the screen $id has no screen of the app');
      expect(File(file!).existsSync(), isTrue, reason: file);
    }
    expect(_appScreens.keys.toSet().difference(screens.toSet()), isEmpty, reason: 'a screen of the app map that the panel does not have');
  });

  test('The stop button is a global widget of the panel and the app has its own', () {
    final stop = (spec['global_widgets'] as List<dynamic>).where((w) => (w as Map<String, dynamic>)['action'] == 'stop').toList();
    expect(stop.length, 1);
    expect(File('lib/ui/widgets/stop_all.dart').existsSync(), isTrue);
  });

  test('The panel is landscape only and shows a camera thumbnail', () {
    expect((spec['display'] as Map<String, dynamic>)['orientation'], 'landscape');
    final camera = (spec['screens'] as List<dynamic>).cast<Map<String, dynamic>>().firstWhere((s) => s['id'] == 'camera');
    final image = (camera['widgets'] as List<dynamic>).cast<Map<String, dynamic>>().firstWhere((w) => w['kind'] == 'image');
    expect(image['signal'], 'jetson.camera_snapshot');
  });

  test('The PIN pad is a modal screen opened by the banner, and STOP never asks for the PIN', () {
    final screens = (spec['screens'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(screens.firstWhere((s) => s['id'] == 'unlock')['modal'], isTrue);
    final globals = (spec['global_widgets'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(globals.firstWhere((w) => w['id'] == 'banner')['action'], 'nav_unlock');
    final actions = (spec['actions'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(actions.firstWhere((a) => a['id'] == 'stop')['requires'], isEmpty);
    expect(texts['lock.title']!['arb'], 'lockTitle');
    expect(texts['lock.hint']!['arb'], 'lockHint');
    expect(texts['pin.enter']!['arb'], 'pinPadOk');
  });

  test('The listen-only text of the panel is the one of the app', () {
    expect(texts['banner.listen_only']!['arb'], 'controlListenOnlyBanner');
    expect(texts['action.listen_only']!['arb'], 'settingsListenOnly');
  });
}
