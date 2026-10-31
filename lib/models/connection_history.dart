// =============================================================================
// HYDRA-UMC DSI (Flutter) - models/connection_history.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The two answers of the server about who connects (GET /api/connections/clients
// and /events) in the closed shape of the ConnectionClient and ConnectionEvent
// contracts: no password, token or cookie is in either. The address comes only for
// an administrator and only when the server was told to keep it; the panel shows
// it when it comes and never asks for it.
// =============================================================================

import 'dart:convert';

/// The kinds of client the server tells apart.
const List<String> connectionKinds = ['studio', 'suite', 'android', 'ios', 'dsi', 'watch', 'voice', 'other'];

/// The things the history writes down.
const List<String> connectionActions = ['first_seen', 'login', 'login_failed', 'second_factor_failed', 'logout', 'session_ended', 'session_expired'];

/// One application the server has seen.
class ConnectionClient {
  final String id;
  final String kind;
  final String? user;
  final String? appVersion;

  /// "local" or "remote", or null when the server did not say.
  final String? origin;
  final bool? twoFactor;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int activeSessions;
  final int loginsOk;
  final int loginsFailed;
  final String? ip;

  const ConnectionClient({
    required this.id,
    required this.kind,
    required this.user,
    required this.appVersion,
    required this.origin,
    required this.twoFactor,
    required this.firstSeen,
    required this.lastSeen,
    required this.activeSessions,
    required this.loginsOk,
    required this.loginsFailed,
    required this.ip,
  });
}

/// One line of the history.
class ConnectionEvent {
  final int id;
  final DateTime at;
  final String action;
  final String kind;
  final String? user;
  final String? appVersion;

  const ConnectionEvent({required this.id, required this.at, required this.action, required this.kind, required this.user, required this.appVersion});

  /// A refused sign-in or a wrong code of the second step: painted as a warning.
  bool get isFailure => action == 'login_failed' || action == 'second_factor_failed';
}

/// Why the history could not be read, for the sentence the screen shows.
enum ConnectionsFailure { unavailable, session, network, other }

class ConnectionHistory {
  ConnectionHistory._();

  static final RegExp _id = RegExp(r'^[0-9a-f]{16}$');
  static final RegExp _utcDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,9}))?Z$');

  /// An ISO date in UTC as the server writes it (`2026-01-02T03:04:05.678Z`); null for anything else.
  static DateTime? parseDate(Object? text) {
    if (text is! String) return null;
    final m = _utcDate.firstMatch(text);
    if (m == null) return null;
    final p = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
    if (p[1] < 1 || p[1] > 12 || p[2] < 1 || p[2] > 31 || p[3] > 23 || p[4] > 59 || p[5] > 59) return null;
    final ms = int.parse((m.group(7) ?? '').padRight(3, '0').substring(0, 3));
    return DateTime.utc(p[0], p[1], p[2], p[3], p[4], p[5], ms);
  }

  /// A string field, or null when it is absent, null, not a text or empty.
  static String? _text(Map<String, dynamic> json, String name) {
    final value = json[name];
    return value is String && value.isNotEmpty ? value : null;
  }

  static String _kindOf(String? text) => text != null && connectionKinds.contains(text) ? text : 'other';

  static int _count(Object? value) => value is num && value.isFinite ? value.toInt().clamp(0, 1 << 31) : 0;

  /// Reads one client; null when it is not a well-formed entry (a bad identifier or date).
  static ConnectionClient? parseClient(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = _text(raw, 'id');
    if (id == null || !_id.hasMatch(id)) return null;
    final first = parseDate(raw['first_seen_utc']);
    final last = parseDate(raw['last_seen_utc']);
    if (first == null || last == null) return null;
    final origin = _text(raw, 'origin');
    final twoFactor = raw['two_factor'];
    return ConnectionClient(
      id: id,
      kind: _kindOf(_text(raw, 'kind')),
      user: _text(raw, 'user'),
      appVersion: _text(raw, 'app_version'),
      origin: origin == 'local' || origin == 'remote' ? origin : null,
      twoFactor: twoFactor is bool ? twoFactor : null,
      firstSeen: first,
      lastSeen: last,
      activeSessions: _count(raw['active_sessions']),
      loginsOk: _count(raw['logins_ok']),
      loginsFailed: _count(raw['logins_failed']),
      ip: _text(raw, 'ip'),
    );
  }

  /// Reads one event; null when it is not a well-formed entry or its action is not one the server writes.
  static ConnectionEvent? parseEvent(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final action = _text(raw, 'action');
    if (action == null || !connectionActions.contains(action)) return null;
    final at = parseDate(raw['at_utc']);
    final id = raw['id'];
    if (at == null || id is! num || id < 1) return null;
    return ConnectionEvent(
      id: id.toInt(),
      at: at,
      action: action,
      kind: _kindOf(_text(raw, 'client_kind')),
      user: _text(raw, 'user'),
      appVersion: _text(raw, 'app_version'),
    );
  }

  static List<Object?> _list(String body, String name) {
    final decoded = jsonDecode(body);
    final list = decoded is Map<String, dynamic> ? decoded[name] : null;
    return list is List ? list : const [];
  }

  /// The clients of an answer `{ "clients": [...] }`, the most recently seen first; what cannot be read is left out.
  static List<ConnectionClient> parseClients(String body) {
    final clients = [for (final raw in _list(body, 'clients')) parseClient(raw)].whereType<ConnectionClient>().toList();
    clients.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    return clients;
  }

  /// The events of an answer `{ "events": [...] }`, newest first.
  static List<ConnectionEvent> parseEvents(String body) {
    final events = [for (final raw in _list(body, 'events')) parseEvent(raw)].whereType<ConnectionEvent>().toList();
    events.sort((a, b) => b.id.compareTo(a.id));
    return events;
  }

  /// How long ago, short enough for a line: the amount and the unit (`s`, `min`, `h` or `d`).
  static (int, String) ago(DateTime then, DateTime now) {
    final seconds = now.difference(then).inSeconds.clamp(0, 1 << 40);
    if (seconds < 60) return (seconds, 's');
    if (seconds < 3600) return (seconds ~/ 60, 'min');
    if (seconds < 48 * 3600) return (seconds ~/ 3600, 'h');
    return (seconds ~/ 86400, 'd');
  }
}
