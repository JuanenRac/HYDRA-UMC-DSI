// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/safety_zones_client.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Reads the last verdict of HYDRA-UMC-SAFETY-ZONES (`GET /state`). The service
// runs on the same Compute Module as the panel, so the address is the
// loopback by default (see util/panel_config.dart). It only READS: the panel
// never sends a detection, a heartbeat or a stop through this client.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/system_status.dart';

class SafetyZonesException implements Exception {
  final SafetyFailure failure;
  const SafetyZonesException(this.failure);
  @override
  String toString() => 'SafetyZonesException(${failure.name})';
}

class SafetyZonesClient {
  SafetyZonesClient({required this.host, required this.port, this.token = '', http.Client? client, DateTime Function()? clock})
      : _client = client ?? http.Client(),
        _clock = clock ?? DateTime.now;

  final String host;
  final int port;
  final String token;
  final http.Client _client;
  final DateTime Function() _clock;

  /// The verdict now. A 404 means the service has reached none yet (not confirmed safe); a 401 means the token is
  /// missing or wrong. Anything else that is not a verdict is an exception, never a made-up state.
  Future<SafetyStatus> read() async {
    final headers = <String, String>{if (token.isNotEmpty) 'Authorization': 'Bearer $token'};
    final http.Response resp;
    try {
      resp = await _client.get(Uri.parse('http://$host:$port/state'), headers: headers).timeout(const Duration(seconds: 3));
    } on TimeoutException {
      throw const SafetyZonesException(SafetyFailure.unreachable);
    } catch (_) {
      throw const SafetyZonesException(SafetyFailure.unreachable);
    }
    final now = _clock();
    if (resp.statusCode == 404) return SafetyStatus.noVerdict(now);
    if (resp.statusCode == 401) throw const SafetyZonesException(SafetyFailure.unauthorized);
    if (resp.statusCode != 200) throw const SafetyZonesException(SafetyFailure.other);
    try {
      final body = jsonDecode(resp.body);
      if (body is Map<String, dynamic>) return SafetyStatus.parse(body, now);
    } catch (_) {
      // falls through to the failure below
    }
    throw const SafetyZonesException(SafetyFailure.other);
  }

  void close() => _client.close();
}
