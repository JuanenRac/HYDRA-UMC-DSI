// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/release_verifier_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The check of a downloaded release: the digest rule of the Android app, then
// (only with the switch on) the release signature. Keys are made here at run
// time; the pinned key of the releases is never used to sign.
// =============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show sha256Hex;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/network/client_prefs.dart';
import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show ed25519PublicKey, ed25519Sign;
import 'package:hydra_umc_dsi/update/release_verifier.dart';

String toHex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  final seed = Uint8List.fromList(List<int>.generate(32, (i) => (i * 13 + 9) & 255));
  final keyHex = toHex(ed25519PublicKey(seed));
  final asset = Uint8List.fromList(List<int>.generate(300, (i) => (i * 11 + 5) & 255));
  final signature = '${base64.encode(ed25519Sign(seed, asset))}\n';
  final digest = 'sha256:${sha256Hex(asset)}';

  ReleaseCheck check({List<int>? bytes, String? rawDigest, String? sig, bool require = true, String? key}) => verifyDownloadedRelease(
    bytes ?? asset,
    rawDigest: rawDigest,
    signatureFile: sig,
    requireSignature: require,
    publicKeyHex: key ?? keyHex,
  );

  test('the pinned key is the key of the releases written in the release-signing page', () {
    expect(pinnedReleaseKeyHex, '1228393cae6cb9fba1d98e300446956de2bc1e9c5b59cc58035a65dbcf4f2331');
    expect(pinnedReleaseKeyHex.length, 64);
  });

  group('switch off (the default): the rule of the Android app', () {
    test('no digest published: accepted, the signature is not looked at', () {
      expect(check(require: false), ReleaseCheck.ok);
      expect(check(require: false, sig: 'not base64 at all'), ReleaseCheck.ok);
    });
    test('a digest that matches is accepted and one that does not is refused', () {
      expect(check(require: false, rawDigest: digest), ReleaseCheck.ok);
      expect(check(require: false, rawDigest: digest.toUpperCase()), ReleaseCheck.ok);
      expect(check(require: false, rawDigest: 'sha256:${'0' * 64}'), ReleaseCheck.digestMismatch);
    });
    test('a digest of another algorithm or length counts as not published', () {
      expect(check(require: false, rawDigest: 'md5:abcd'), ReleaseCheck.ok);
      expect(check(require: false, rawDigest: 'sha256:abcd'), ReleaseCheck.ok);
    });
  });

  group('switch on', () {
    test('a valid signature (with or without the final line break) is accepted', () {
      expect(check(sig: signature, rawDigest: digest), ReleaseCheck.ok);
      expect(check(sig: signature.trim()), ReleaseCheck.ok);
    });
    test('no signature, an empty one and a blank one are missing', () {
      expect(check(), ReleaseCheck.signatureMissing);
      expect(check(sig: ''), ReleaseCheck.signatureMissing);
      expect(check(sig: ' \n'), ReleaseCheck.signatureMissing);
    });
    test('text that is not base64 or not 64 bytes is malformed', () {
      expect(check(sig: '!!!!'), ReleaseCheck.signatureMalformed);
      expect(check(sig: base64.encode(List<int>.filled(63, 1))), ReleaseCheck.signatureMalformed);
      expect(check(sig: base64.encode(List<int>.filled(65, 1))), ReleaseCheck.signatureMalformed);
    });
    test('a signature of other bytes, of another key or with a changed bit is invalid', () {
      expect(check(sig: signature, bytes: [...asset, 0]), ReleaseCheck.signatureInvalid);
      expect(check(sig: signature, key: toHex(ed25519PublicKey(Uint8List(32)))), ReleaseCheck.signatureInvalid);
      final broken = ed25519Sign(seed, asset)..[10] ^= 1;
      expect(check(sig: base64.encode(broken)), ReleaseCheck.signatureInvalid);
      expect(check(sig: signature, key: 'zz'), ReleaseCheck.signatureInvalid);
    });
    test('the real pinned key does not accept a signature made with a throwaway key', () {
      expect(verifyDownloadedRelease(asset, signatureFile: signature, requireSignature: true), ReleaseCheck.signatureInvalid);
    });
    test('a digest that does not match is refused first, even with a valid signature', () {
      expect(check(sig: signature, rawDigest: 'sha256:${'0' * 64}'), ReleaseCheck.digestMismatch);
    });
  });

  group('the .sha256 file', () {
    test('matches the bytes, ignoring case and the file name', () {
      expect(sha256FileMatches(asset, '${sha256Hex(asset)}  hydra.ipa\n'), isTrue);
      expect(sha256FileMatches(asset, '${sha256Hex(asset).toUpperCase()}  hydra.ipa'), isTrue);
    });
    test('refuses another digest, an empty file and a malformed line', () {
      expect(sha256FileMatches(asset, '${'0' * 64}  hydra.ipa'), isFalse);
      expect(sha256FileMatches(asset, ''), isFalse);
      expect(sha256FileMatches(asset, null), isFalse);
      expect(sha256FileMatches(asset, 'zzzz  hydra.ipa'), isFalse);
    });
  });

  group('the switch is kept', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    test('off before any choice, then kept', () async {
      final prefs = ClientPrefs();
      expect(await prefs.loadRequireReleaseSignature(), isFalse);
      await prefs.saveRequireReleaseSignature(true);
      expect(await prefs.loadRequireReleaseSignature(), isTrue);
      await prefs.saveRequireReleaseSignature(false);
      expect(await prefs.loadRequireReleaseSignature(), isFalse);
    });
  });
}
