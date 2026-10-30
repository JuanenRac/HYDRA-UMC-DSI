// =============================================================================
// HYDRA-UMC-DSI - network/tls_settings.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// How this app reaches the server, and what it trusts.
//
//   - HTTPS (and WSS) first, always. Plain HTTP/WS is used only when the user
//     turned it on (allowPlainHttp, off by default), and only toward a server
//     on the local network unless allowPlainRemote is on too: the session
//     token would otherwise travel readable across the Internet.
//   - A server with a self-signed certificate is trusted by its SHA-256
//     fingerprint (pinnedFingerprint). The fingerprint is read from the
//     server once, shown to the person, and kept only after they confirm it
//     (trust on first use). From then on only a certificate with exactly that
//     fingerprint is accepted; host name and issuer are not checked, the
//     fingerprint is the identity.
//   - Without a fingerprint, customCaPem (a PEM with one or more CA
//     certificates) replaces the system certificates as the only trusted
//     issuer. With neither, the system certificates decide.
//
// The same module, with the same behaviour, is in HYDRA-UMC-IOS-CONTROL and
// mirrors the TLS settings of HYDRA-UMC-ANDROID-CONTROL.
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sha256.dart';

/// The TLS choices of the person using the app.
class TlsSettings {
  /// Allows plain HTTP/WS after HTTPS has been tried. Off: only HTTPS is used.
  final bool allowPlainHttp;

  /// Allows plain HTTP/WS to a server outside the local network (needs
  /// [allowPlainHttp]). Off by default.
  final bool allowPlainRemote;

  /// SHA-256 of the one server certificate to accept, as 64 lowercase hex
  /// digits; empty for none.
  final String pinnedFingerprint;

  /// PEM text with the certificates of the only issuers to trust; empty for
  /// the system certificates.
  final String customCaPem;

  const TlsSettings({
    this.allowPlainHttp = false,
    this.allowPlainRemote = false,
    this.pinnedFingerprint = '',
    this.customCaPem = '',
  });

  /// What is wrong with these settings, or null when they can be saved. Blank
  /// fields are fine.
  TlsProblem? validate() {
    if (pinnedFingerprint.trim().isNotEmpty && TlsFingerprint.normalize(pinnedFingerprint) == null) {
      return TlsProblem.fingerprintInvalid;
    }
    if (customCaPem.trim().isNotEmpty && TlsPem.parse(customCaPem).isEmpty) {
      return TlsProblem.caInvalid;
    }
    return null;
  }

  /// The settings with the fingerprint in its canonical form and the PEM trimmed.
  TlsSettings normalized() => TlsSettings(
        allowPlainHttp: allowPlainHttp,
        allowPlainRemote: allowPlainHttp && allowPlainRemote,
        pinnedFingerprint: TlsFingerprint.normalize(pinnedFingerprint) ?? pinnedFingerprint.trim(),
        customCaPem: customCaPem.trim(),
      );

  TlsSettings copyWith({
    bool? allowPlainHttp,
    bool? allowPlainRemote,
    String? pinnedFingerprint,
    String? customCaPem,
  }) =>
      TlsSettings(
        allowPlainHttp: allowPlainHttp ?? this.allowPlainHttp,
        allowPlainRemote: allowPlainRemote ?? this.allowPlainRemote,
        pinnedFingerprint: pinnedFingerprint ?? this.pinnedFingerprint,
        customCaPem: customCaPem ?? this.customCaPem,
      );

  /// Whether a plain (unencrypted) connection to [host] is allowed. Traffic to
  /// this same machine (loopback) never leaves it and is always allowed; the
  /// rest needs [allowPlainHttp], and a host outside the local network needs
  /// [allowPlainRemote] too.
  bool plainAllowedFor(String host) =>
      TlsPolicy.isLoopback(host) || (allowPlainHttp && (allowPlainRemote || TlsPolicy.isLocalHost(host)));

  @override
  bool operator ==(Object other) =>
      other is TlsSettings &&
      other.allowPlainHttp == allowPlainHttp &&
      other.allowPlainRemote == allowPlainRemote &&
      other.pinnedFingerprint == pinnedFingerprint &&
      other.customCaPem == customCaPem;

  @override
  int get hashCode => Object.hash(allowPlainHttp, allowPlainRemote, pinnedFingerprint, customCaPem);
}

enum TlsProblem { fingerprintInvalid, caInvalid }

/// The settings the clients read when they are created; the view model fills
/// it when the app starts and when the person saves a change.
class TlsSettingsStore {
  static TlsSettings current = const TlsSettings();
}

/// SHA-256 fingerprints of certificates.
class TlsFingerprint {
  static final _hex64 = RegExp(r'^[0-9a-f]{64}$');

  /// Lowercase hex without separators, or null when [input] is not 64
  /// hexadecimal digits (colons, spaces and dashes are ignored).
  static String? normalize(String input) {
    final cleaned = input.replaceAll(RegExp(r'[:\-\s]'), '').toLowerCase();
    return _hex64.hasMatch(cleaned) ? cleaned : null;
  }

  /// The fingerprint of a DER encoded certificate.
  static String ofDer(List<int> der) => sha256Hex(der);

  /// The usual display form: uppercase pairs separated by colons.
  static String display(String hex) {
    final upper = hex.toUpperCase();
    final pairs = <String>[];
    for (var i = 0; i + 1 < upper.length; i += 2) {
      pairs.add(upper.substring(i, i + 2));
    }
    return pairs.join(':');
  }

  /// Equal strings, compared without stopping at the first difference.
  static bool equal(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

/// PEM certificates.
class TlsPem {
  static final _block = RegExp(r'-----BEGIN CERTIFICATE-----([\s\S]*?)-----END CERTIFICATE-----');

  /// The DER bytes of every certificate in [pem]; empty when the text holds
  /// none or is damaged.
  static List<Uint8List> parse(String pem) {
    final result = <Uint8List>[];
    for (final match in _block.allMatches(pem)) {
      final body = match.group(1)!.replaceAll(RegExp(r'\s'), '');
      if (body.isEmpty) return const [];
      try {
        final der = base64.decode(body);
        if (der.isEmpty) return const [];
        result.add(der);
      } on FormatException {
        return const [];
      }
    }
    return result;
  }
}

/// Where a server is: decides when plain traffic may be used at all.
class TlsPolicy {
  /// True for the address of this same machine.
  static bool isLoopback(String host) {
    var h = host.trim().toLowerCase();
    if (h.startsWith('[') && h.endsWith(']')) h = h.substring(1, h.length - 1);
    return h == 'localhost' || h == '::1' || RegExp(r'^127\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(h);
  }

  /// True for loopback, private (RFC 1918), link-local and unique-local
  /// addresses, and for single-label or .local/.lan/.home.arpa names.
  static bool isLocalHost(String host) {
    var h = host.trim().toLowerCase();
    if (h.startsWith('[') && h.endsWith(']')) h = h.substring(1, h.length - 1);
    if (h.isEmpty) return false;
    if (h == 'localhost') return true;
    if (h.contains(':')) return h == '::1' || h.startsWith('fe80:') || h.startsWith('fc') || h.startsWith('fd');
    final octets = h.split('.');
    if (octets.length == 4 && octets.every((o) => int.tryParse(o) != null && int.parse(o) >= 0 && int.parse(o) <= 255)) {
      final a = int.parse(octets[0]);
      final b = int.parse(octets[1]);
      return a == 10 || a == 127 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168) || (a == 169 && b == 254);
    }
    // an incomplete or odd number, not a name
    if (octets.every((o) => o.isNotEmpty && RegExp(r'^\d+$').hasMatch(o))) return false;
    return octets.length == 1 || h.endsWith('.local') || h.endsWith('.lan') || h.endsWith('.home.arpa');
  }
}

/// Loads and saves [TlsSettings]. Nothing stored means the defaults: HTTPS
/// only, no fingerprint, no CA.
class TlsPrefs {
  static const _keyAllowPlain = 'hydra_tls_allow_plain_http';
  static const _keyAllowPlainRemote = 'hydra_tls_allow_plain_remote';
  static const _keyPin = 'hydra_tls_pinned_fingerprint';
  static const _keyCa = 'hydra_tls_custom_ca_pem';

  Future<TlsSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return TlsSettings(
      allowPlainHttp: prefs.getBool(_keyAllowPlain) ?? false,
      allowPlainRemote: prefs.getBool(_keyAllowPlainRemote) ?? false,
      pinnedFingerprint: prefs.getString(_keyPin) ?? '',
      customCaPem: prefs.getString(_keyCa) ?? '',
    );
  }

  Future<void> save(TlsSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAllowPlain, settings.allowPlainHttp);
    await prefs.setBool(_keyAllowPlainRemote, settings.allowPlainRemote);
    await prefs.setString(_keyPin, settings.pinnedFingerprint);
    await prefs.setString(_keyCa, settings.customCaPem);
  }
}

/// A dart:io HttpClient that follows [settings]: the pinned fingerprint if
/// there is one, else the custom CA if there is one, else the system
/// certificates. Unusable settings are never applied (the system rules stay).
HttpClient createHttpClient([TlsSettings? settings]) {
  final s = settings ?? TlsSettingsStore.current;
  final pin = TlsFingerprint.normalize(s.pinnedFingerprint);
  if (pin != null) {
    final context = SecurityContext(withTrustedRoots: false);
    final client = HttpClient(context: context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) =>
        pinMatches(pin, cert.der, cert.startValidity, cert.endValidity);
    return client;
  }
  final authorities = TlsPem.parse(s.customCaPem);
  if (authorities.isNotEmpty) {
    final context = SecurityContext(withTrustedRoots: false);
    try {
      context.setTrustedCertificatesBytes(utf8.encode(s.customCaPem.trim()));
    } on TlsException {
      return HttpClient();
    }
    return HttpClient(context: context);
  }
  return HttpClient();
}

/// True when [der] has the fingerprint [pinHex] and [now] is inside the
/// validity of the certificate.
bool pinMatches(String pinHex, List<int> der, DateTime notBefore, DateTime notAfter, [DateTime? now]) {
  if (!TlsFingerprint.equal(TlsFingerprint.ofDer(der), pinHex)) return false;
  final at = now ?? DateTime.now();
  return !at.isBefore(notBefore) && !at.isAfter(notAfter);
}

/// An http.Client that follows [settings] (or [TlsSettingsStore.current]).
http.Client createClient([TlsSettings? settings]) => IOClient(createHttpClient(settings));

/// An http.Client for looking for servers: it accepts any certificate, because
/// it only reads the public identity of a host and sends no credential. What
/// is trusted for the real connection is decided later, by the settings.
http.Client createDiscoveryClient() {
  final client = HttpClient();
  client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  return IOClient(client);
}

/// What was learned by looking at the certificate a server presents.
class ServerCertificate {
  final String fingerprint;
  final String subject;
  final DateTime notBefore;
  final DateTime notAfter;
  const ServerCertificate(this.fingerprint, this.subject, this.notBefore, this.notAfter);
}

/// Connects to [host]:[port] over TLS and returns the certificate the server
/// presents, without trusting it and without sending anything: the person
/// compares its fingerprint with the one the server shows and then decides.
/// Null when no TLS connection could be made.
Future<ServerCertificate?> fetchServerCertificate(
  String host,
  int port, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    final socket = await SecureSocket.connect(
      host,
      port,
      timeout: timeout,
      onBadCertificate: (_) => true,
    );
    try {
      final cert = socket.peerCertificate;
      if (cert == null) return null;
      return ServerCertificate(
        TlsFingerprint.ofDer(cert.der),
        cert.subject,
        cert.startValidity,
        cert.endValidity,
      );
    } finally {
      socket.destroy();
    }
  } catch (_) {
    return null;
  }
}

/// True when [error] says the server's certificate was refused (as opposed to
/// a server that does not speak TLS at all).
bool isCertificateRejection(Object error) {
  final text = '$error'.toUpperCase();
  return text.contains('CERTIFICATE_VERIFY_FAILED') || text.contains('BAD CERTIFICATE') || text.contains('CERTIFICATE');
}

/// True when [error] looks like a failure to set up or trust TLS, as opposed
/// to a server that is simply not there.
bool isTlsFailure(Object error) {
  if (error is HandshakeException || error is TlsException) return true;
  final text = '$error'.toUpperCase();
  return text.contains('CERTIFICATE_VERIFY_FAILED') ||
      text.contains('HANDSHAKEEXCEPTION') ||
      text.contains('WRONG_VERSION_NUMBER') ||
      text.contains('TLSV1_ALERT');
}
