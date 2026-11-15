// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/generated_transport.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The transport under the generated server client (generated/hydra_server_client.dart).
// It sends each request through the HTTP client of the app (HydraApiCore.call), so the
// pinned TLS policy, the listen-only gate, the renewal of an expired session and the
// headers of the app stay exactly as they are for the requests written by hand, and the
// refused answers keep their distinct errors (HydraApiException with status and code).
//
// What the generated client may ask for but this transport does not carry yet: a binary
// or non-JSON body, an answer that is not JSON and the response headers (HydraReply).
// Those requests stay written by hand; asking for one here throws UnsupportedError, so a
// request that cannot be carried is found by a test and never sent half-made.
// =============================================================================

import 'dart:convert';

import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show HydraApiCore, HydraApiException;

import '../generated/hydra_server_client.dart';

class GeneratedTransport {
  GeneratedTransport(this._core, {this.timeout = const Duration(seconds: 10)});

  final HydraApiCore _core;

  /// The time limit of each request made through this transport.
  final Duration timeout;

  /// The function the generated client takes as its transport.
  Future<dynamic> send(HydraRequest request) async {
    if (request.contentType != null && request.contentType != 'application/json') {
      throw UnsupportedError('${request.method} ${request.path}: a ${request.contentType} body is not carried by the generated transport');
    }
    if (request.responseType != null) {
      throw UnsupportedError('${request.method} ${request.path}: an answer of type ${request.responseType} is not carried by the generated transport');
    }
    if (request.replyHeaders.isNotEmpty) {
      throw UnsupportedError('${request.method} ${request.path}: response headers are not carried by the generated transport');
    }
    final query = request.query.isEmpty ? '' : '?${Uri(queryParameters: request.query).query}';
    final body = request.body;
    final resp = await _core.call(
      request.method,
      '${_core.baseUrl}${request.path}$query',
      headers: {
        ..._core.clientHeaders,
        ..._core.authHeaders,
        ...request.headers,
        if (body != null) 'Content-Type': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
      timeout: timeout,
    );
    _core.throwForStatus(resp);
    if (resp.body.trim().isEmpty) return null;
    try {
      return jsonDecode(resp.body);
    } on FormatException catch (e) {
      throw HydraApiException('Response is not valid JSON: ${e.message}');
    }
  }
}

/// Runs one call of the generated client over [core]. An answer that does not fit the contract (a missing field, a
/// wrong type or no body where one is declared) is a [HydraApiException], like any other answer the app cannot use.
Future<T> callGenerated<T>(HydraApiCore core, Duration timeout, Future<T> Function(HydraServerClient api) run) async {
  try {
    return await run(HydraServerClient(GeneratedTransport(core, timeout: timeout).send));
  } on TypeError catch (e) {
    throw HydraApiException('The answer does not match the server contract: $e');
  }
}
