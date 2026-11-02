// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/idle_gate_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The idle lock, the dimming and the screen saver on the screen: the lock only
// exists with a PIN, asks for it, counts wrong tries, keeps STOP within reach,
// the saver waits for a busy robot, and the touch that wakes the panel does
// not also press what is under the finger.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/services/operator_pin.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/widgets/idle_gate.dart';
import 'package:hydra_umc_dsi/util/panel_config.dart';

class _Backend implements SecureTokenBackend {
  final Map<String, String> store = {};
  @override
  Future<void> write(String key, String value) async => store[key] = value;
  @override
  Future<String?> read(String key) async => store[key];
  @override
  Future<void> delete(String key) async => store.remove(key);
}

class _Harness {
  final RobotViewModel vm;
  DateTime now = DateTime(2000, 1, 1, 12);
  int pressed = 0;
  _Harness(this.vm);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<RobotViewModel>.value(
        value: vm,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: IdleGate(
              clock: () => now,
              tick: const Duration(seconds: 1),
              child: Center(child: ElevatedButton(key: const Key('under'), onPressed: () => pressed++, child: const Text('under'))),
            ),
          ),
        ),
      ),
    );
  }

  /// Lets [seconds] go by: the clock of the gate and the timer of the test move together.
  Future<void> wait(WidgetTester tester, int seconds) async {
    for (var i = 0; i < seconds; i++) {
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
  }
}

Future<RobotViewModel> _vm(PanelConfig config, {String? pin}) async {
  final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: config, operatorPin: OperatorPin(backend: _Backend(), maxAttempts: 2, lockoutSeconds: 30));
  if (pin != null) await vm.pin.set(pin);
  return vm;
}

Future<void> _type(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.byKey(Key('pin-key-$d')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('pin-key-ok')));
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('with the lock off, or no PIN, the panel never locks', (tester) async {
    for (final (config, pin) in [(const PanelConfig(), '4821'), (const PanelConfig(idleLockSeconds: 30), null)]) {
      final vm = await _vm(config, pin: pin);
      final h = _Harness(vm);
      await h.pump(tester);
      await h.wait(tester, 120);
      expect(find.byKey(const Key('idle-lock')), findsNothing);
      await tester.tap(find.byKey(const Key('under')));
      expect(h.pressed, 1);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    }
  });

  testWidgets('after the time it locks, hides the screen, keeps STOP and takes the right PIN', (tester) async {
    final vm = await _vm(const PanelConfig(idleLockSeconds: 60), pin: '4821');
    addTearDown(vm.dispose);
    final h = _Harness(vm);
    await h.pump(tester);
    await h.wait(tester, 59);
    expect(find.byKey(const Key('idle-lock')), findsNothing);
    await h.wait(tester, 2);
    expect(find.byKey(const Key('idle-lock')), findsOneWidget);
    expect(find.byKey(const Key('overlay-stop')), findsOneWidget, reason: 'nobody unlocks a panel to stop a robot');

    // The panel below does not answer to touches while it is locked.
    await tester.tap(find.byKey(const Key('under')), warnIfMissed: false);
    expect(h.pressed, 0);

    await _type(tester, '0000');
    expect(find.byKey(const Key('lock-message')), findsOneWidget);
    expect(find.byKey(const Key('idle-lock')), findsOneWidget);

    await _type(tester, '4821');
    expect(find.byKey(const Key('idle-lock')), findsNothing);
    await tester.tap(find.byKey(const Key('under')));
    expect(h.pressed, 1);
  });

  testWidgets('too many wrong PINs lock the pad for a while, even for the right one', (tester) async {
    final vm = await _vm(const PanelConfig(idleLockSeconds: 10), pin: '4821');
    addTearDown(vm.dispose);
    final h = _Harness(vm);
    await h.pump(tester);
    await h.wait(tester, 11);
    await _type(tester, '1111');
    await _type(tester, '2222');
    expect(find.byKey(const Key('lock-message')), findsOneWidget);
    await _type(tester, '4821');
    expect(find.byKey(const Key('idle-lock')), findsOneWidget, reason: 'locked out');
    expect(vm.pin.lockedOutSeconds(), greaterThan(0));
  });

  testWidgets('the saver comes after its time, STOP is on it, and the waking touch is not a press', (tester) async {
    final vm = await _vm(const PanelConfig(dimAfterSeconds: 10, saverAfterSeconds: 20));
    addTearDown(vm.dispose);
    final h = _Harness(vm);
    await h.pump(tester);
    await h.wait(tester, 12);
    expect(find.byKey(const Key('idle-saver')), findsNothing, reason: 'dimmed only');
    await h.wait(tester, 10);
    expect(find.byKey(const Key('idle-saver')), findsOneWidget);
    expect(find.byKey(const Key('overlay-stop')), findsOneWidget);

    // A touch where the button is: it wakes the panel and does not press the button.
    await tester.tapAt(tester.getCenter(find.byKey(const Key('under'), skipOffstage: false)));
    await tester.pump();
    expect(find.byKey(const Key('idle-saver')), findsNothing);
    expect(h.pressed, 0);
    await tester.tap(find.byKey(const Key('under')));
    expect(h.pressed, 1, reason: 'the next touch is a normal one');
  });

  testWidgets('a locked panel that went dark stays dark until touched, then shows the lock', (tester) async {
    final vm = await _vm(const PanelConfig(idleLockSeconds: 30, saverAfterSeconds: 20), pin: '4821');
    addTearDown(vm.dispose);
    final h = _Harness(vm);
    await h.pump(tester);
    await h.wait(tester, 40);
    expect(find.byKey(const Key('idle-saver')), findsOneWidget);
    expect(find.byKey(const Key('idle-lock')), findsNothing);
    await tester.tapAt(const Offset(100, 100));
    await tester.pump();
    expect(find.byKey(const Key('idle-saver')), findsNothing);
    expect(find.byKey(const Key('idle-lock')), findsOneWidget);
  });

  testWidgets('a robot that plays a trajectory keeps the saver away, the lock does not wait', (tester) async {
    final vm = await _vm(const PanelConfig(saverAfterSeconds: 20, idleLockSeconds: 30), pin: '4821');
    addTearDown(vm.dispose);
    vm.state.raw['controllers'] = [
      {
        'id': 'c1',
        'robots': [
          {'id': 1, 'name': 'ARM-1', 'online': true, 'playbackState': {'isPlaying': true, 'isPaused': false}},
        ],
      },
    ];
    expect(vm.panelBusy, isTrue);
    final h = _Harness(vm);
    await h.pump(tester);
    await h.wait(tester, 40);
    expect(find.byKey(const Key('idle-saver')), findsNothing);
    expect(find.byKey(const Key('idle-lock')), findsOneWidget);
  });
}
