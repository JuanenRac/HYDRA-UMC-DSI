// =============================================================================
// HYDRA-UMC DSI (Flutter) - services/operator_pin.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The PIN of the operator: the short code that unlocks the panel after the
// idle lock (util/idle_policy.dart). It is NOT a second account and it does
// not replace the sign-in of the server: it only stops somebody walking past
// from touching a panel that was left unattended, and the global STOP stays
// reachable on the lock screen.
//
// Only a salted, repeated SHA-256 of the PIN is kept (in the same secure
// storage as the session), never the PIN itself. Wrong PINs are counted: after
// the configured number in a row the lock refuses every try for a while, and
// the time grows with each round, so a short code cannot be walked through.
// If the secure storage does not work (a bare image without a Secret Service),
// the PIN lives in memory for this run only and the panel says so.
// =============================================================================

import 'dart:convert';
import 'dart:math';

import '../models/sha256.dart';
import '../network/auth_prefs.dart';

/// Why a PIN was not accepted when it was set.
enum PinProblem { tooShort, notDigits }

/// The check of a PIN while the lock is shown.
enum PinCheck { accepted, wrong, lockedOut, notSet }

PinProblem? pinProblemOf(String pin, int minLength) {
  if (!RegExp(r'^[0-9]+$').hasMatch(pin)) return PinProblem.notDigits;
  if (pin.length < minLength) return PinProblem.tooShort;
  return null;
}

/// The repeated, salted digest that is stored instead of the PIN.
String pinDigest(String pin, String salt, {int rounds = 4000}) {
  var h = utf8.encode('$salt:$pin');
  var hex = '';
  for (var i = 0; i < rounds; i++) {
    hex = sha256Hex(h);
    h = utf8.encode('$hex:$salt');
  }
  return hex;
}

class OperatorPin {
  OperatorPin({SecureTokenBackend? backend, DateTime Function()? clock, this.maxAttempts = 5, this.lockoutSeconds = 30})
      : _backend = backend ?? FlutterSecureStorageBackend(),
        _clock = clock ?? DateTime.now;

  static const _keySalt = 'hydra_operator_pin_salt';
  static const _keyDigest = 'hydra_operator_pin_digest';

  final SecureTokenBackend _backend;
  final DateTime Function() _clock;
  int maxAttempts;
  int lockoutSeconds;

  String? _salt;
  String? _digest;
  bool _loaded = false;

  /// True when the PIN could only be kept in memory (the secure storage failed).
  bool memoryOnly = false;

  int _failures = 0;
  int _rounds = 0;
  DateTime? _lockedUntil;

  Future<void> load() async {
    try {
      _salt = await _backend.read(_keySalt);
      _digest = await _backend.read(_keyDigest);
    } catch (_) {
      // Nothing stored that can be read: the panel behaves as if no PIN was set.
    }
    _loaded = true;
  }

  bool get isSet => _loaded && _salt != null && _digest != null;

  /// Seconds the lock still refuses every try; 0 when it does not.
  int lockedOutSeconds() {
    final until = _lockedUntil;
    if (until == null) return 0;
    final left = until.difference(_clock()).inSeconds + 1;
    return left > 0 ? left : 0;
  }

  /// Sets the PIN (the caller has already checked it with [pinProblemOf]).
  Future<void> set(String pin) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final digest = pinDigest(pin, salt);
    try {
      await _backend.write(_keySalt, salt);
      await _backend.write(_keyDigest, digest);
      memoryOnly = false;
    } catch (_) {
      memoryOnly = true;
    }
    _salt = salt;
    _digest = digest;
    _loaded = true;
    _failures = 0;
    _rounds = 0;
    _lockedUntil = null;
  }

  /// Removes the PIN: the idle lock then does nothing.
  Future<void> clear() async {
    _salt = null;
    _digest = null;
    memoryOnly = false;
    _failures = 0;
    _rounds = 0;
    _lockedUntil = null;
    try {
      await _backend.delete(_keySalt);
      await _backend.delete(_keyDigest);
    } catch (_) {
      // Already forgotten here; whatever is left in the store is read as unset on the next start only if it is half-written.
    }
  }

  /// Checks a PIN. Wrong ones are counted; the lock-out grows with each round of [maxAttempts] failures.
  PinCheck check(String pin) {
    if (!isSet) return PinCheck.notSet;
    if (lockedOutSeconds() > 0) return PinCheck.lockedOut;
    if (_constantTimeEquals(pinDigest(pin, _salt!), _digest!)) {
      _failures = 0;
      _rounds = 0;
      _lockedUntil = null;
      return PinCheck.accepted;
    }
    _failures += 1;
    if (_failures >= maxAttempts) {
      _failures = 0;
      _rounds += 1;
      final seconds = lockoutSeconds * (1 << (_rounds - 1).clamp(0, 6).toInt());
      _lockedUntil = _clock().add(Duration(seconds: seconds));
      return PinCheck.lockedOut;
    }
    return PinCheck.wrong;
  }

  /// Wrong tries left before the lock-out starts.
  int get attemptsLeft => maxAttempts - _failures;

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
