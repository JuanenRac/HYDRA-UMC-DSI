// =============================================================================
// HYDRA-UMC DSI (Flutter) - update/ed25519.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Ed25519 (RFC 8032) and SHA-512 in plain Dart, for the one thing this app
// checks offline: the signature of a downloaded release asset against the
// pinned public key of the releases. No platform code and no package, so the
// same bytes verify the same way in the app and in its tests. Signing is here
// only so the tests can make throwaway keys; the app never holds a private key.
// =============================================================================

import 'dart:typed_data';

const List<int> _k = [
  (0x428a2f98 << 32) | 0xd728ae22,
  (0x71374491 << 32) | 0x23ef65cd,
  (0xb5c0fbcf << 32) | 0xec4d3b2f,
  (0xe9b5dba5 << 32) | 0x8189dbbc,
  (0x3956c25b << 32) | 0xf348b538,
  (0x59f111f1 << 32) | 0xb605d019,
  (0x923f82a4 << 32) | 0xaf194f9b,
  (0xab1c5ed5 << 32) | 0xda6d8118,
  (0xd807aa98 << 32) | 0xa3030242,
  (0x12835b01 << 32) | 0x45706fbe,
  (0x243185be << 32) | 0x4ee4b28c,
  (0x550c7dc3 << 32) | 0xd5ffb4e2,
  (0x72be5d74 << 32) | 0xf27b896f,
  (0x80deb1fe << 32) | 0x3b1696b1,
  (0x9bdc06a7 << 32) | 0x25c71235,
  (0xc19bf174 << 32) | 0xcf692694,
  (0xe49b69c1 << 32) | 0x9ef14ad2,
  (0xefbe4786 << 32) | 0x384f25e3,
  (0x0fc19dc6 << 32) | 0x8b8cd5b5,
  (0x240ca1cc << 32) | 0x77ac9c65,
  (0x2de92c6f << 32) | 0x592b0275,
  (0x4a7484aa << 32) | 0x6ea6e483,
  (0x5cb0a9dc << 32) | 0xbd41fbd4,
  (0x76f988da << 32) | 0x831153b5,
  (0x983e5152 << 32) | 0xee66dfab,
  (0xa831c66d << 32) | 0x2db43210,
  (0xb00327c8 << 32) | 0x98fb213f,
  (0xbf597fc7 << 32) | 0xbeef0ee4,
  (0xc6e00bf3 << 32) | 0x3da88fc2,
  (0xd5a79147 << 32) | 0x930aa725,
  (0x06ca6351 << 32) | 0xe003826f,
  (0x14292967 << 32) | 0x0a0e6e70,
  (0x27b70a85 << 32) | 0x46d22ffc,
  (0x2e1b2138 << 32) | 0x5c26c926,
  (0x4d2c6dfc << 32) | 0x5ac42aed,
  (0x53380d13 << 32) | 0x9d95b3df,
  (0x650a7354 << 32) | 0x8baf63de,
  (0x766a0abb << 32) | 0x3c77b2a8,
  (0x81c2c92e << 32) | 0x47edaee6,
  (0x92722c85 << 32) | 0x1482353b,
  (0xa2bfe8a1 << 32) | 0x4cf10364,
  (0xa81a664b << 32) | 0xbc423001,
  (0xc24b8b70 << 32) | 0xd0f89791,
  (0xc76c51a3 << 32) | 0x0654be30,
  (0xd192e819 << 32) | 0xd6ef5218,
  (0xd6990624 << 32) | 0x5565a910,
  (0xf40e3585 << 32) | 0x5771202a,
  (0x106aa070 << 32) | 0x32bbd1b8,
  (0x19a4c116 << 32) | 0xb8d2d0c8,
  (0x1e376c08 << 32) | 0x5141ab53,
  (0x2748774c << 32) | 0xdf8eeb99,
  (0x34b0bcb5 << 32) | 0xe19b48a8,
  (0x391c0cb3 << 32) | 0xc5c95a63,
  (0x4ed8aa4a << 32) | 0xe3418acb,
  (0x5b9cca4f << 32) | 0x7763e373,
  (0x682e6ff3 << 32) | 0xd6b2b8a3,
  (0x748f82ee << 32) | 0x5defb2fc,
  (0x78a5636f << 32) | 0x43172f60,
  (0x84c87814 << 32) | 0xa1f0ab72,
  (0x8cc70208 << 32) | 0x1a6439ec,
  (0x90befffa << 32) | 0x23631e28,
  (0xa4506ceb << 32) | 0xde82bde9,
  (0xbef9a3f7 << 32) | 0xb2c67915,
  (0xc67178f2 << 32) | 0xe372532b,
  (0xca273ece << 32) | 0xea26619c,
  (0xd186b8c7 << 32) | 0x21c0c207,
  (0xeada7dd6 << 32) | 0xcde0eb1e,
  (0xf57d4f7f << 32) | 0xee6ed178,
  (0x06f067aa << 32) | 0x72176fba,
  (0x0a637dc5 << 32) | 0xa2c898a6,
  (0x113f9804 << 32) | 0xbef90dae,
  (0x1b710b35 << 32) | 0x131c471b,
  (0x28db77f5 << 32) | 0x23047d84,
  (0x32caab7b << 32) | 0x40c72493,
  (0x3c9ebe0a << 32) | 0x15c9bebc,
  (0x431d67c4 << 32) | 0x9c100d4c,
  (0x4cc5d4be << 32) | 0xcb3e42b6,
  (0x597f299c << 32) | 0xfc657e2a,
  (0x5fcb6fab << 32) | 0x3ad6faec,
  (0x6c44198c << 32) | 0x4a475817,
];

const List<int> _h0 = [
  (0x6a09e667 << 32) | 0xf3bcc908,
  (0xbb67ae85 << 32) | 0x84caa73b,
  (0x3c6ef372 << 32) | 0xfe94f82b,
  (0xa54ff53a << 32) | 0x5f1d36f1,
  (0x510e527f << 32) | 0xade682d1,
  (0x9b05688c << 32) | 0x2b3e6c1f,
  (0x1f83d9ab << 32) | 0xfb41bd6b,
  (0x5be0cd19 << 32) | 0x137e2179,
];

int _rotr(int x, int n) => (x >>> n) | (x << (64 - n));

/// SHA-512 of [data] (FIPS 180-4), 64 bytes.
Uint8List sha512(List<int> data) {
  final length = data.length;
  final padded = <int>[...data, 0x80];
  while (padded.length % 128 != 112) {
    padded.add(0);
  }
  final bits = length * 8;
  for (var i = 0; i < 8; i++) {
    padded.add(0);
  }
  for (var i = 0; i < 8; i++) {
    padded.add((bits >>> (8 * (7 - i))) & 0xff);
  }
  final h = List<int>.of(_h0);
  final w = List<int>.filled(80, 0);
  for (var offset = 0; offset < padded.length; offset += 128) {
    for (var t = 0; t < 16; t++) {
      var v = 0;
      for (var b = 0; b < 8; b++) {
        v = (v << 8) | (padded[offset + t * 8 + b] & 0xff);
      }
      w[t] = v;
    }
    for (var t = 16; t < 80; t++) {
      final s0 = _rotr(w[t - 15], 1) ^ _rotr(w[t - 15], 8) ^ (w[t - 15] >>> 7);
      final s1 = _rotr(w[t - 2], 19) ^ _rotr(w[t - 2], 61) ^ (w[t - 2] >>> 6);
      w[t] = w[t - 16] + s0 + w[t - 7] + s1;
    }
    var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
    for (var t = 0; t < 80; t++) {
      final s1 = _rotr(e, 14) ^ _rotr(e, 18) ^ _rotr(e, 41);
      final ch = (e & f) ^ (~e & g);
      final t1 = hh + s1 + ch + _k[t] + w[t];
      final s0 = _rotr(a, 28) ^ _rotr(a, 34) ^ _rotr(a, 39);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = s0 + maj;
      hh = g;
      g = f;
      f = e;
      e = d + t1;
      d = c;
      c = b;
      b = a;
      a = t1 + t2;
    }
    h[0] += a;
    h[1] += b;
    h[2] += c;
    h[3] += d;
    h[4] += e;
    h[5] += f;
    h[6] += g;
    h[7] += hh;
  }
  final out = Uint8List(64);
  for (var i = 0; i < 8; i++) {
    for (var b = 0; b < 8; b++) {
      out[i * 8 + b] = (h[i] >>> (8 * (7 - b))) & 0xff;
    }
  }
  return out;
}

final BigInt _p = (BigInt.one << 255) - BigInt.from(19);
final BigInt _q = (BigInt.one << 252) + BigInt.parse('27742317777372353535851937790883648493');
final BigInt _d = (BigInt.from(-121665) * BigInt.from(121666).modInverse(_p)) % _p;
final BigInt _sqrtM1 = BigInt.two.modPow((_p - BigInt.one) ~/ BigInt.from(4), _p);

class _Point {
  const _Point(this.x, this.y, this.z, this.t);
  final BigInt x, y, z, t;
}

final _Point _zero = _Point(BigInt.zero, BigInt.one, BigInt.one, BigInt.zero);

_Point _add(_Point a, _Point b) {
  final aa = ((a.y - a.x) * (b.y - b.x)) % _p;
  final bb = ((a.y + a.x) * (b.y + b.x)) % _p;
  final cc = (BigInt.two * a.t * b.t * _d) % _p;
  final dd = (BigInt.two * a.z * b.z) % _p;
  final e = bb - aa, f = dd - cc, g = dd + cc, h = bb + aa;
  return _Point((e * f) % _p, (g * h) % _p, (f * g) % _p, (e * h) % _p);
}

_Point _multiply(BigInt scalar, _Point point) {
  var result = _zero;
  var addend = point;
  var s = scalar;
  while (s > BigInt.zero) {
    if (s.isOdd) result = _add(result, addend);
    addend = _add(addend, addend);
    s >>= 1;
  }
  return result;
}

bool _equal(_Point a, _Point b) =>
    (a.x * b.z - b.x * a.z) % _p == BigInt.zero && (a.y * b.z - b.y * a.z) % _p == BigInt.zero;

BigInt _fromLittleEndian(List<int> bytes) {
  var v = BigInt.zero;
  for (var i = bytes.length - 1; i >= 0; i--) {
    v = (v << 8) | BigInt.from(bytes[i] & 0xff);
  }
  return v;
}

Uint8List _toLittleEndian(BigInt value, int length) {
  final out = Uint8List(length);
  var v = value;
  for (var i = 0; i < length; i++) {
    out[i] = (v & BigInt.from(0xff)).toInt();
    v >>= 8;
  }
  return out;
}

BigInt? _recoverX(BigInt y, int sign) {
  if (y >= _p) return null;
  final x2 = ((y * y - BigInt.one) * (_d * y * y + BigInt.one).modInverse(_p)) % _p;
  if (x2 == BigInt.zero) return sign == 1 ? null : BigInt.zero;
  var x = x2.modPow((_p + BigInt.from(3)) ~/ BigInt.from(8), _p);
  if ((x * x - x2) % _p != BigInt.zero) x = (x * _sqrtM1) % _p;
  if ((x * x - x2) % _p != BigInt.zero) return null;
  if ((x.isOdd ? 1 : 0) != sign) x = _p - x;
  return x;
}

_Point? _decompress(List<int> bytes) {
  if (bytes.length != 32) return null;
  final value = _fromLittleEndian(bytes);
  final sign = (value >> 255).toInt();
  final y = value & ((BigInt.one << 255) - BigInt.one);
  final x = _recoverX(y, sign);
  if (x == null) return null;
  return _Point(x, y, BigInt.one, (x * y) % _p);
}

Uint8List _compress(_Point point) {
  final zInverse = point.z.modInverse(_p);
  final x = (point.x * zInverse) % _p;
  final y = (point.y * zInverse) % _p;
  return _toLittleEndian(y | ((x.isOdd ? BigInt.one : BigInt.zero) << 255), 32);
}

final _Point _base = () {
  final y = (BigInt.from(4) * BigInt.from(5).modInverse(_p)) % _p;
  final x = _recoverX(y, 0)!;
  return _Point(x, y, BigInt.one, (x * y) % _p);
}();

/// Whether [signature] (64 bytes) is a valid Ed25519 signature of [message]
/// under [publicKey] (32 bytes). Anything malformed (a wrong length, a point
/// that is not on the curve, a scalar outside the group order) is `false`.
bool ed25519Verify(List<int> publicKey, List<int> message, List<int> signature) {
  if (publicKey.length != 32 || signature.length != 64) return false;
  final a = _decompress(publicKey);
  if (a == null) return false;
  final rBytes = signature.sublist(0, 32);
  final r = _decompress(rBytes);
  if (r == null) return false;
  final s = _fromLittleEndian(signature.sublist(32));
  if (s >= _q) return false;
  final k = _fromLittleEndian(sha512([...rBytes, ...publicKey, ...message])) % _q;
  return _equal(_multiply(s, _base), _add(r, _multiply(k, a)));
}

BigInt _clampedScalar(List<int> expanded) {
  final low = List<int>.of(expanded.sublist(0, 32));
  low[0] &= 248;
  low[31] &= 127;
  low[31] |= 64;
  return _fromLittleEndian(low);
}

/// The public key of a 32-byte private [seed]. For tests: the app holds no private key.
Uint8List ed25519PublicKey(List<int> seed) => _compress(_multiply(_clampedScalar(sha512(seed)), _base));

/// The signature of [message] with a 32-byte private [seed]. For tests: the app signs nothing.
Uint8List ed25519Sign(List<int> seed, List<int> message) {
  final expanded = sha512(seed);
  final a = _clampedScalar(expanded);
  final publicKey = _compress(_multiply(a, _base));
  final r = _fromLittleEndian(sha512([...expanded.sublist(32), ...message])) % _q;
  final rBytes = _compress(_multiply(r, _base));
  final k = _fromLittleEndian(sha512([...rBytes, ...publicKey, ...message])) % _q;
  final s = (r + k * a) % _q;
  return Uint8List.fromList([...rBytes, ..._toLittleEndian(s, 32)]);
}
