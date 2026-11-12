// =============================================================================
// HYDRA-UMC DSI (Flutter) - network/listen_only_gate.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Listen-only mode at the door of the network: the view model already drops every command but STOP and the safe-mode
// disable; this gate also refuses, before anything leaves the panel, every other write to the server (settings, push and
// presence registration, files, ...). A write is any request that is not GET or HEAD. Let through: STOP (the global one and a
// robot command that is stop or disable) and the sign-in, the renewal and the end of the session.
// =============================================================================

import 'dart:convert';

import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show HttpResponseData;

class ListenOnlyGate {
  ListenOnlyGate._();

  /// Set by the view model with the switch of the settings; off until the person turns it on.
  static bool enabled = false;

  static const Set<String> _allowedCommands = {'stop', 'disable'};
  static const Set<String> _sessionNames = {'login', 'refresh', 'logout'};

  /// Whether a request may leave the app while the mode is on. Pure. The path is read by its segments.
  static bool allows(String method, String path, String? body) {
    final m = method.toUpperCase();
    if (m == 'GET' || m == 'HEAD') return true;
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty || parts.first != 'api') return false;
    final rest = parts.sublist(1);
    if (rest.length == 1 && (_sessionNames.contains(rest[0]) || rest[0] == 'stop-all')) return true;
    if (rest.length == 2 && rest[0] == 'device' && rest[1] == 'login') return true;
    if (rest.length == 3 && rest[0] == 'robot' && rest[2] == 'command' && body != null) {
      try {
        final decoded = jsonDecode(body);
        return decoded is Map && _allowedCommands.contains(decoded['command']);
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// The answer of a refused write: 423, as if the server had locked the route, and nothing was sent.
  static HttpResponseData refusal(String path) =>
      HttpResponseData(423, jsonEncode({'error': 'Listen only is on: nothing is written from this panel except STOP.', 'code': 'listen-only'}), path: path);
}
