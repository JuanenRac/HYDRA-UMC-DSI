// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/session_storage_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// What is kept on the device and how the picture stream is read:
//   - a login replaces the stored refresh token (an absent one deletes the old
//     one); the renewal path keeps its older behaviour;
//   - the scheme a server was seen on is remembered;
//   - the newest complete picture frame is the one shown.
// =============================================================================

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/ui/widgets/mjpeg_view.dart';

class _FakeSecureBackend implements SecureTokenBackend {
  final Map<String, String> store = {};
  @override
  Future<void> write(String key, String value) async => store[key] = value;
  @override
  Future<String?> read(String key) async => store[key];
  @override
  Future<void> delete(String key) async => store.remove(key);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a login with no refresh token deletes the one left by a previous account', () async {
    final secure = _FakeSecureBackend();
    final prefs = AuthPrefs(secureBackend: secure);
    await prefs.saveToken('t1', 'alice', refreshToken: 'alice-refresh');

    await prefs.saveToken('t2', 'bob', replaceRefreshToken: true);

    expect(await prefs.loadRefreshToken(), isNull);
    expect(secure.store.containsKey('hydra_refresh_token'), isFalse);
  });

  test('the scheme a server was seen on is remembered', () async {
    final prefs = AuthPrefs(secureBackend: _FakeSecureBackend());
    expect(await prefs.loadUseTls(), isFalse);

    await prefs.saveUseTls(true);

    expect(await prefs.loadUseTls(), isTrue);
  });

  group('findLastJpegFrame', () {
    Uint8List bytes(List<int> v) => Uint8List.fromList(v);

    test('finds nothing without a complete frame', () {
      expect(findLastJpegFrame(bytes([0xFF, 0xD8, 1, 2, 3])), isNull);
      expect(findLastJpegFrame(bytes([1, 2, 3, 0xFF, 0xD9])), isNull);
    });

    test('returns the newest complete frame, not the oldest', () {
      final data = bytes([
        0xFF, 0xD8, 1, 1, 0xFF, 0xD9, // old frame
        0xFF, 0xD8, 2, 2, 2, 0xFF, 0xD9, // newest frame
        0xFF, 0xD8, 3, // the start of the next one
      ]);

      final found = findLastJpegFrame(data)!;

      expect(found.start, 6);
      expect(found.end, 13);
    });
  });
}
