// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/idle_policy_and_pin_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// What the panel does after a time without a touch (dim, saver, lock) and the
// PIN of the operator: stored only as a digest, counted tries, lock-out that
// grows, no lock at all when there is no PIN to unlock it with.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/services/operator_pin.dart';
import 'package:hydra_umc_dsi/util/idle_policy.dart';
import 'package:hydra_umc_dsi/util/panel_config.dart';

class _Backend implements SecureTokenBackend {
  final Map<String, String> store = {};
  bool failWrites = false;
  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('no secret service');
    store[key] = value;
  }

  @override
  Future<String?> read(String key) async => store[key];
  @override
  Future<void> delete(String key) async => store.remove(key);
}

void main() {
  const config = PanelConfig(dimAfterSeconds: 30, saverAfterSeconds: 120, idleLockSeconds: 300, dimPercent: 20, saverPercent: 5);

  group('idle policy', () {
    test('nothing happens by default', () {
      for (final seconds in [0, 100, 100000]) {
        expect(idleStageFor(Duration(seconds: seconds), PanelConfig.defaults, busy: false), IdleStage.awake);
        expect(idleLockedFor(Duration(seconds: seconds), PanelConfig.defaults, pinSet: true), isFalse);
      }
    });

    test('awake, then dimmed, then the saver', () {
      expect(idleStageFor(const Duration(seconds: 29), config, busy: false), IdleStage.awake);
      expect(idleStageFor(const Duration(seconds: 30), config, busy: false), IdleStage.dimmed);
      expect(idleStageFor(const Duration(seconds: 119), config, busy: false), IdleStage.dimmed);
      expect(idleStageFor(const Duration(seconds: 120), config, busy: false), IdleStage.saver);
    });

    test('a busy panel (a trajectory is playing, a stop is unconfirmed) is never dimmed, unless the file says so', () {
      expect(idleStageFor(const Duration(hours: 1), config, busy: true), IdleStage.awake);
      const careless = PanelConfig(dimAfterSeconds: 30, idleWaitsWhileBusy: false);
      expect(idleStageFor(const Duration(hours: 1), careless, busy: true), IdleStage.dimmed);
    });

    test('the backlight of each stage', () {
      expect(backlightForStage(IdleStage.awake, config), isNull);
      expect(backlightForStage(IdleStage.dimmed, config), 20);
      expect(backlightForStage(IdleStage.saver, config), 5);
    });

    test('the lock needs a PIN and does not wait for a robot', () {
      expect(idleLockedFor(const Duration(seconds: 299), config, pinSet: true), isFalse);
      expect(idleLockedFor(const Duration(seconds: 300), config, pinSet: true), isTrue);
      expect(idleLockedFor(const Duration(hours: 5), config, pinSet: false), isFalse, reason: 'no PIN, no lock: it could never be undone');
    });
  });

  group('operator PIN', () {
    var now = DateTime(2000, 1, 1);
    setUp(() => now = DateTime(2000, 1, 1));

    OperatorPin make(_Backend backend, {int maxAttempts = 3, int lockoutSeconds = 10}) =>
        OperatorPin(backend: backend, clock: () => now, maxAttempts: maxAttempts, lockoutSeconds: lockoutSeconds);

    test('the rules for a new PIN', () {
      expect(pinProblemOf('1234', 4), isNull);
      expect(pinProblemOf('123', 4), PinProblem.tooShort);
      expect(pinProblemOf('12a4', 4), PinProblem.notDigits);
      expect(pinProblemOf('', 4), PinProblem.notDigits);
    });

    test('with no PIN set nothing is accepted for it and nothing is locked', () async {
      final pin = make(_Backend());
      await pin.load();
      expect(pin.isSet, isFalse);
      expect(pin.check('1234'), PinCheck.notSet);
    });

    test('only a salted digest is stored, never the PIN', () async {
      final backend = _Backend();
      final pin = make(backend);
      await pin.set('4821');
      expect(pin.isSet, isTrue);
      expect(backend.store.values.any((v) => v.contains('4821')), isFalse);
      expect(backend.store.length, 2);
      // A second PIN with the same digits gets another salt, so another digest.
      final other = _Backend();
      await make(other).set('4821');
      expect(other.store.values.toSet(), isNot(equals(backend.store.values.toSet())));
    });

    test('the right PIN is accepted after a restart, a wrong one is not', () async {
      final backend = _Backend();
      await make(backend).set('4821');
      final again = make(backend);
      await again.load();
      expect(again.isSet, isTrue);
      expect(again.check('0000'), PinCheck.wrong);
      expect(again.attemptsLeft, 2);
      expect(again.check('4821'), PinCheck.accepted);
      expect(again.attemptsLeft, 3, reason: 'a right PIN clears the count');
    });

    test('too many wrong tries lock it out, and the time grows with each round', () async {
      final pin = make(_Backend(), maxAttempts: 2, lockoutSeconds: 10);
      await pin.set('4821');
      expect(pin.check('1'), PinCheck.wrong);
      expect(pin.check('2'), PinCheck.lockedOut);
      expect(pin.lockedOutSeconds(), inInclusiveRange(9, 11));
      expect(pin.check('4821'), PinCheck.lockedOut, reason: 'even the right one waits');
      now = now.add(const Duration(seconds: 11));
      expect(pin.lockedOutSeconds(), 0);
      expect(pin.check('3'), PinCheck.wrong);
      expect(pin.check('4'), PinCheck.lockedOut);
      expect(pin.lockedOutSeconds(), inInclusiveRange(19, 21), reason: 'the second round doubles it');
      now = now.add(const Duration(seconds: 21));
      expect(pin.check('4821'), PinCheck.accepted);
    });

    test('clearing the PIN forgets it', () async {
      final backend = _Backend();
      final pin = make(backend);
      await pin.set('4821');
      await pin.clear();
      expect(pin.isSet, isFalse);
      expect(backend.store, isEmpty);
      expect(pin.check('4821'), PinCheck.notSet);
    });

    test('without a working secure storage the PIN lives in memory and says so', () async {
      final backend = _Backend()..failWrites = true;
      final pin = make(backend);
      await pin.set('4821');
      expect(pin.memoryOnly, isTrue);
      expect(pin.isSet, isTrue);
      expect(pin.check('4821'), PinCheck.accepted);
      final next = make(backend);
      await next.load();
      expect(next.isSet, isFalse, reason: 'nothing survives a restart');
    });
  });
}
