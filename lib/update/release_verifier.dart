// =============================================================================
// HYDRA-UMC DSI (Flutter) - update/release_verifier.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// What the app checks about a release asset it has downloaded, before it is
// trusted. Two rules, in this order:
//   1. Digest. The release feed publishes `sha256:<hex>` for the asset; the
//      bytes must match it (a feed without a digest cannot be compared). This
//      is the rule of the Android app.
//   2. Release signature. `<asset>.sig` is the base64 Ed25519 signature of the
//      exact bytes of the asset, made with the key of the releases. It is
//      checked only when the switch is on (off by default, so the app behaves
//      as it did before); with it on, a release with no signature, a malformed
//      one or one that does not verify is refused.
// Pure Dart: no network, no private key and no platform code.
// =============================================================================

import 'dart:convert';

import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show downloadMatchesDigest, parseAssetDigest, sha256Hex;

import 'ed25519.dart';

/// The public key of the releases (docs/RELEASE_SIGNING.md of HYDRA-UMC): the one every program of the ecosystem pins.
const String pinnedReleaseKeyHex = '1228393cae6cb9fba1d98e300446956de2bc1e9c5b59cc58035a65dbcf4f2331';

/// The verdict on a downloaded release asset.
enum ReleaseCheck {
  /// Accepted under the rules in force.
  ok,

  /// The feed published a digest and the bytes do not match it.
  digestMismatch,

  /// The signature switch is on and the release has no `.sig`.
  signatureMissing,

  /// The switch is on and the `.sig` is not 64 bytes of base64.
  signatureMalformed,

  /// The switch is on and the signature does not verify against the pinned key.
  signatureInvalid,
}

List<int>? _hexBytes(String hex) {
  if (hex.length.isOdd) return null;
  final out = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    final value = int.tryParse(hex.substring(i, i + 2), radix: 16);
    if (value == null) return null;
    out.add(value);
  }
  return out;
}

/// The 64 bytes of a `.sig` file (base64, with or without a final line break), or `null` when it is not that.
List<int>? decodeSignatureFile(String? text) {
  final trimmed = (text ?? '').trim();
  if (trimmed.isEmpty) return null;
  try {
    final bytes = base64.decode(trimmed);
    return bytes.length == 64 ? bytes : null;
  } on FormatException {
    return null;
  }
}

/// Checks the [bytes] of a downloaded asset. [rawDigest] is the `digest` field of the asset in the release feed and
/// [signatureFile] the text of its `.sig`. The signature counts only when [requireSignature] is true. [publicKeyHex]
/// is the pinned key unless a test gives another.
ReleaseCheck verifyDownloadedRelease(
  List<int> bytes, {
  String? rawDigest,
  String? signatureFile,
  bool requireSignature = false,
  String publicKeyHex = pinnedReleaseKeyHex,
}) {
  if (!downloadMatchesDigest(bytes, rawDigest)) return ReleaseCheck.digestMismatch;
  if (!requireSignature) return ReleaseCheck.ok;
  if ((signatureFile ?? '').trim().isEmpty) return ReleaseCheck.signatureMissing;
  final signature = decodeSignatureFile(signatureFile);
  if (signature == null) return ReleaseCheck.signatureMalformed;
  final key = _hexBytes(publicKeyHex);
  if (key == null || !ed25519Verify(key, bytes, signature)) return ReleaseCheck.signatureInvalid;
  return ReleaseCheck.ok;
}

/// Whether the `<asset>.sha256` file of a release (`<hex>  <name>`) agrees with the bytes. For a release that publishes
/// the list instead of the digest field; `false` when the line is malformed or names another digest.
bool sha256FileMatches(List<int> bytes, String? sha256File) {
  final first = (sha256File ?? '').trim().split(RegExp(r'\s+')).first.toLowerCase();
  return parseAssetDigest('sha256:$first') != null && first == sha256Hex(bytes);
}
