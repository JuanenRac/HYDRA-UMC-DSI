// =============================================================================
// HYDRA-UMC-DSI - test/fake_server_session_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The real client against the one stand-in server of the SDK (a vendored copy of
// conformance/fake-server/hydra_fake_server.py in test/fixtures/fake-server, kept
// identical by tools/sync_sdk_answers.py), which keeps state: a sign-in gives a
// token, a wrong password is refused and the global STOP stops every robot. The
// test is skipped on a machine without Python.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/network/hydra_api_client.dart';

Future<String?> _python() async {
  for (final name in ['python3', 'python', 'py']) {
    try {
      final probe = await Process.run(name, ['--version']);
      if (probe.exitCode == 0) return name;
    } on ProcessException {
      // try the next name
    }
  }
  return null;
}

void main() {
  Process? server;
  var port = 0;
  String? skip;

  setUpAll(() async {
    final python = await _python();
    if (python == null) {
      skip = 'Python is not available, the stand-in server cannot start';
      return;
    }
    server = await Process.start(
      python,
      ['test/fixtures/fake-server/hydra_fake_server.py', '--port', '0'],
      environment: {'HYDRA_FAKE_ANSWERS': 'test/fixtures/server-answers.json'},
    );
    final line = await server!.stdout.transform(utf8.decoder).transform(const LineSplitter()).first;
    port = int.parse(RegExp(r'http://127\.0\.0\.1:(\d+)').firstMatch(line)!.group(1)!);
  });

  tearDownAll(() {
    server?.kill();
  });

  test('a sign-in gives a token, a wrong password is refused and the global stop stops every robot', () async {
    if (skip != null) {
      markTestSkipped(skip!);
      return;
    }
    final client = HydraApiClient('127.0.0.1', port);
    final session = await client.login('admin', 'admin');
    expect(session['token'], isA<String>());
    expect((session['token'] as String).isNotEmpty, isTrue);

    await expectLater(client.login('admin', 'wrong'), throwsA(anything));

    client.authToken = session['token'] as String;
    final stop = await client.postStopAll();
    expect(stop['stoppedCount'], 2);
    expect(stop['failedCount'], 0);
  });
}
