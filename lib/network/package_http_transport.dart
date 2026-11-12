// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/package_http_transport.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The adapter that gives the shared API client of the SDK package
// (clients/dart_app_common) its transport: it sends the request through a
// package:http client (the app's TLS-pinned one, or a test double) and hands
// the answer back as text.
// =============================================================================

import 'package:http/http.dart' as http;
import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show HttpRequestData, HttpResponseData, HttpTransport;
import 'listen_only_gate.dart';

class PackageHttpTransport implements HttpTransport {
  PackageHttpTransport(this._client);

  final http.Client _client;

  @override
  Future<HttpResponseData> send(HttpRequestData request) async {
    if (ListenOnlyGate.enabled && !ListenOnlyGate.allows(request.method, request.path, request.body)) {
      return ListenOnlyGate.refusal(request.path);
    }
    final req = http.Request(request.method, Uri.parse(request.url))..headers.addAll(request.headers);
    final body = request.body;
    if (body != null) req.body = body;
    final resp = await http.Response.fromStream(await _client.send(req));
    return HttpResponseData(resp.statusCode, resp.body, path: request.path);
  }

  @override
  void close() => _client.close();
}
