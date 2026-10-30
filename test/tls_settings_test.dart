// =============================================================================
// HYDRA-UMC-DSI - test/tls_settings_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// HTTPS first, plain HTTP only when allowed, and a pinned certificate: the
// settings, the choice of scheme, and a real TLS server with a self-signed
// certificate.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hydra_umc_dsi/network/hydra_api_client.dart';
import 'package:hydra_umc_dsi/network/tls_settings.dart';

import 'tls_fixture.dart';

const _info = '{"remoteApiVersion":"2","name":"hydra"}';

/// A client that records the address of every request and answers [answer] for it.
MockClient _recording(List<Uri> seen, bool Function(Uri) answers) => MockClient((request) async {
      seen.add(request.url);
      if (answers(request.url)) return http.Response(_info, 200);
      throw http.ClientException('no answer');
    });

void main() {
  tearDown(() => TlsSettingsStore.current = const TlsSettings());

  group('settings', () {
    test('the defaults are HTTPS only, nothing pinned', () {
      const s = TlsSettings();
      expect(s.allowPlainHttp, isFalse);
      expect(s.allowPlainRemote, isFalse);
      expect(s.pinnedFingerprint, isEmpty);
      expect(s.plainAllowedFor('192.168.1.5'), isFalse);
    });

    test('traffic to this same machine never needs the plain switch', () {
      const s = TlsSettings();
      expect(s.plainAllowedFor('127.0.0.1'), isTrue);
      expect(s.plainAllowedFor('localhost'), isTrue);
      expect(s.plainAllowedFor('[::1]'), isTrue);
      expect(s.plainAllowedFor('192.168.1.5'), isFalse);
    });

    test('plain HTTP is allowed only for the local network unless remote is allowed too', () {
      const local = TlsSettings(allowPlainHttp: true);
      expect(local.plainAllowedFor('192.168.1.5'), isTrue);
      expect(local.plainAllowedFor('hydra.local'), isTrue);
      expect(local.plainAllowedFor('8.8.8.8'), isFalse);
      expect(local.plainAllowedFor('example.com'), isFalse);
      const remote = TlsSettings(allowPlainHttp: true, allowPlainRemote: true);
      expect(remote.plainAllowedFor('8.8.8.8'), isTrue);
      // remote without the plain switch means nothing
      expect(const TlsSettings(allowPlainRemote: true).normalized().allowPlainRemote, isFalse);
    });

    test('a fingerprint is accepted with colons, spaces and capitals, and stored canonical', () {
      final s = TlsSettings(pinnedFingerprint: TlsFingerprint.display(kTestCertFingerprint));
      expect(s.validate(), isNull);
      expect(s.normalized().pinnedFingerprint, kTestCertFingerprint);
      expect(const TlsSettings(pinnedFingerprint: 'abc').validate(), TlsProblem.fingerprintInvalid);
      expect(const TlsSettings(pinnedFingerprint: '').validate(), isNull);
    });

    test('a CA text must hold a certificate', () {
      expect(const TlsSettings(customCaPem: 'not a certificate').validate(), TlsProblem.caInvalid);
      expect(TlsSettings(customCaPem: kTestCertPem).validate(), isNull);
      expect(TlsPem.parse(kTestCertPem), hasLength(1));
      expect(TlsPem.parse('-----BEGIN CERTIFICATE-----\n!!!\n-----END CERTIFICATE-----'), isEmpty);
    });

    test('the fingerprint of a certificate is the SHA-256 of its DER', () {
      final der = TlsPem.parse(kTestCertPem).single;
      expect(TlsFingerprint.ofDer(der), kTestCertFingerprint);
      expect(TlsFingerprint.display('0a1b'), '0A:1B');
    });

    test('a pin matches only the right fingerprint inside the validity of the certificate', () {
      final der = TlsPem.parse(kTestCertPem).single;
      final from = DateTime(2020);
      final to = DateTime(2120);
      expect(pinMatches(kTestCertFingerprint, der, from, to, DateTime(2026)), isTrue);
      expect(pinMatches('0' * 64, der, from, to, DateTime(2026)), isFalse);
      expect(pinMatches(kTestCertFingerprint, der, from, to, DateTime(2121)), isFalse);
      expect(pinMatches(kTestCertFingerprint, der, from, to, DateTime(2019)), isFalse);
    });

    test('local hosts', () {
      for (final h in ['localhost', '127.0.0.1', '10.0.0.4', '172.16.0.1', '172.31.9.9', '192.168.0.180', '169.254.1.1', '[::1]', 'fe80::1', 'fd00::2', 'hydra', 'a.local', 'b.lan']) {
        expect(TlsPolicy.isLocalHost(h), isTrue, reason: h);
      }
      for (final h in ['', '8.8.8.8', '172.32.0.1', '11.0.0.1', 'example.com', '1.2.3', '2001:db8::1']) {
        expect(TlsPolicy.isLocalHost(h), isFalse, reason: h);
      }
    });

    test('a TLS failure is told from a server that is just not there', () {
      expect(isTlsFailure(const HandshakeException('CERTIFICATE_VERIFY_FAILED: self signed')), isTrue);
      expect(isTlsFailure(Exception('Connection refused')), isFalse);
    });
  });

  group('which scheme is tried', () {
    test('by default only HTTPS is ever requested, even when nothing answers', () async {
      final seen = <Uri>[];
      final client = HydraApiClient('192.168.1.5', 3000, client: _recording(seen, (_) => false));
      expect(await client.getHydraInfo(), isNull);
      expect(seen, isNotEmpty);
      expect(seen.every((u) => u.scheme == 'https'), isTrue);
      expect(client.usesTls, isTrue);
    });

    test('HTTPS that answers is used and plain HTTP is not touched', () async {
      final seen = <Uri>[];
      TlsSettingsStore.current = const TlsSettings(allowPlainHttp: true);
      final client = HydraApiClient('192.168.1.5', 3000, client: _recording(seen, (u) => u.scheme == 'https'));
      expect(await client.getHydraInfo(), isNotNull);
      expect(seen.map((u) => u.scheme).toSet(), {'https'});
    });

    test('plain HTTP is a second try, only when allowed and local', () async {
      final seen = <Uri>[];
      TlsSettingsStore.current = const TlsSettings(allowPlainHttp: true);
      final client = HydraApiClient('192.168.1.5', 3000, client: _recording(seen, (u) => u.scheme == 'http'));
      expect(await client.getHydraInfo(), isNotNull);
      expect(seen.first.scheme, 'https');
      expect(seen.last.scheme, 'http');
      expect(client.usesTls, isFalse);
    });

    test('plain HTTP to a server outside the local network needs the remote switch', () async {
      final seen = <Uri>[];
      TlsSettingsStore.current = const TlsSettings(allowPlainHttp: true);
      final client = HydraApiClient('203.0.113.9', 3000, client: _recording(seen, (u) => u.scheme == 'http'));
      expect(await client.getHydraInfo(), isNull);
      expect(seen.every((u) => u.scheme == 'https'), isTrue);

      final seen2 = <Uri>[];
      TlsSettingsStore.current = const TlsSettings(allowPlainHttp: true, allowPlainRemote: true);
      final client2 = HydraApiClient('203.0.113.9', 3000, client: _recording(seen2, (u) => u.scheme == 'http'));
      expect(await client2.getHydraInfo(), isNotNull);
    });

    test('a server that was seen over TLS is never retried over plain HTTP', () async {
      final seen = <Uri>[];
      TlsSettingsStore.current = const TlsSettings(allowPlainHttp: true);
      final client = HydraApiClient('192.168.1.5', 3000, useTls: true, client: _recording(seen, (u) => u.scheme == 'http'));
      expect(await client.getHydraInfo(), isNull);
      expect(seen.every((u) => u.scheme == 'https'), isTrue);
    });
  });

  group('a real TLS server with a self-signed certificate', () {
    late HttpServer server;

    setUp(() async {
      final context = SecurityContext()
        ..useCertificateChainBytes(utf8.encode(kTestCertPem))
        ..usePrivateKeyBytes(utf8.encode(kTestKeyPem));
      server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, context);
      server.listen((request) {
        request.response
          ..statusCode = 200
          ..write(_info)
          ..close();
      });
    });

    tearDown(() async => server.close(force: true));

    Future<http.Response> get(http.Client c) => c.get(Uri.parse('https://127.0.0.1:${server.port}/api/hydra-info'));

    test('it is refused without the fingerprint', () async {
      final c = createClient(const TlsSettings());
      await expectLater(get(c), throwsA(anything));
      c.close();
    });

    test('it is accepted with the right fingerprint', () async {
      final c = createClient(const TlsSettings(pinnedFingerprint: kTestCertFingerprint));
      expect((await get(c)).statusCode, 200);
      c.close();
    });

    test('it is refused with another fingerprint', () async {
      final c = createClient(TlsSettings(pinnedFingerprint: '1' * 64));
      await expectLater(get(c), throwsA(anything));
      c.close();
    });

    test('it is accepted when its certificate is the trusted CA', () async {
      final c = createClient(TlsSettings(customCaPem: kTestCertPem));
      expect((await get(c)).statusCode, 200);
      c.close();
    });

    test('the certificate and its fingerprint can be read from the server', () async {
      final cert = await fetchServerCertificate('127.0.0.1', server.port);
      expect(cert, isNotNull);
      expect(cert!.fingerprint, kTestCertFingerprint);
      expect(cert.subject, contains('localhost'));
    });

    test('nothing to read from a port without TLS', () async {
      final plain = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      plain.listen((r) => r.response.close());
      expect(await fetchServerCertificate('127.0.0.1', plain.port, timeout: const Duration(seconds: 2)), isNull);
      await plain.close(force: true);
    });

    test('the API client signs in over HTTPS once the fingerprint is pinned', () async {
      TlsSettingsStore.current = const TlsSettings(pinnedFingerprint: kTestCertFingerprint);
      final client = HydraApiClient('127.0.0.1', server.port);
      final info = await client.getHydraInfo();
      expect(info, isNotNull);
      expect(client.usesTls, isTrue);
      client.close();
    });

    test('the API client does not reach it without the fingerprint', () async {
      TlsSettingsStore.current = const TlsSettings();
      final client = HydraApiClient('127.0.0.1', server.port);
      expect(await client.getHydraInfo(), isNull);
      client.close();
    });
  });
}
