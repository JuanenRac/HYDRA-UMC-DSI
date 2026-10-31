// =============================================================================
// HYDRA-UMC CONTROL (DSI/Flutter) - ui/widgets/connections_dialog.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// A simple view of the apps the server has seen (kind, user, version, sessions
// open now, sign-ins that worked or were refused) and the latest sign-ins and
// sign-outs. The server gives an administrator every entry and any other account
// only its own; it holds no password or token in either list. An address is shown
// only when the server sends one.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/connection_history.dart';
import '../../state/robot_view_model.dart';

String connectionKindName(AppLocalizations l10n, String kind) => switch (kind) {
      'studio' => l10n.connectionsKindStudio,
      'suite' => l10n.connectionsKindSuite,
      'android' => l10n.connectionsKindAndroid,
      'ios' => l10n.connectionsKindIos,
      'dsi' => l10n.connectionsKindDsi,
      'watch' => l10n.connectionsKindWatch,
      'voice' => l10n.connectionsKindVoice,
      _ => l10n.connectionsKindOther,
    };

String connectionActionName(AppLocalizations l10n, String action) => switch (action) {
      'first_seen' => l10n.connectionsActionFirstSeen,
      'login' => l10n.connectionsActionLogin,
      'login_failed' => l10n.connectionsActionLoginFailed,
      'second_factor_failed' => l10n.connectionsActionSecondFactorFailed,
      'logout' => l10n.connectionsActionLogout,
      'session_ended' => l10n.connectionsActionSessionEnded,
      _ => l10n.connectionsActionSessionExpired,
    };

String connectionFailureText(AppLocalizations l10n, ConnectionsFailure failure) => switch (failure) {
      ConnectionsFailure.unavailable => l10n.connectionsFailureUnavailable,
      ConnectionsFailure.session => l10n.connectionsFailureSession,
      ConnectionsFailure.network => l10n.connectionsFailureNetwork,
      ConnectionsFailure.other => l10n.connectionsFailureOther,
    };

String connectionAgoText(AppLocalizations l10n, DateTime then, DateTime now) {
  final (amount, unit) = ConnectionHistory.ago(then, now);
  return switch (unit) {
    's' => l10n.connectionsAgoSeconds(amount),
    'min' => l10n.connectionsAgoMinutes(amount),
    'h' => l10n.connectionsAgoHours(amount),
    _ => l10n.connectionsAgoDays(amount),
  };
}

class ConnectionsDialog extends StatefulWidget {
  final RobotViewModel vm;

  /// The clock the "ago" texts follow, passed in so tests can fix it.
  final DateTime Function() clock;

  const ConnectionsDialog({super.key, required this.vm, this.clock = DateTime.now});

  @override
  State<ConnectionsDialog> createState() => _ConnectionsDialogState();
}

class _ConnectionsDialogState extends State<ConnectionsDialog> {
  Timer? _tick;

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_changed);
    // Read when the dialog opens; the clock only moves the "ago" texts forward.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.vm.refreshConnections());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _changed());
  }

  @override
  void dispose() {
    _tick?.cancel();
    widget.vm.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = widget.vm;
    final clients = vm.connectionClients;
    final events = vm.connectionEvents;
    final failure = vm.connectionsFailure;
    final now = widget.clock();
    const bad = Color(0xFFF87171);

    return AlertDialog(
      key: const ValueKey('connections-dialog'),
      title: Text(l10n.connectionsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.connectionsIntro, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              if (failure != null) ...[
                Text(connectionFailureText(l10n, failure), key: const ValueKey('connections-failure'), style: const TextStyle(color: bad, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
              ],
              Text(l10n.connectionsClients, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (clients != null && clients.isEmpty) Text(l10n.connectionsNoneClients, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (clients != null) for (final c in clients) _clientRow(l10n, c, now),
              const SizedBox(height: 10),
              Text(l10n.connectionsEvents, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (events != null && events.isEmpty) Text(l10n.connectionsNoneEvents, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (events != null) for (final e in events) _eventRow(l10n, e, now),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(key: const ValueKey('connections-refresh'), onPressed: vm.connectionsBusy ? null : () => vm.refreshConnections(), child: Text(l10n.auditRefresh)),
        TextButton(key: const ValueKey('connections-close'), onPressed: () => Navigator.of(context).pop(), child: Text(l10n.auditClose)),
      ],
    );
  }

  Widget _clientRow(AppLocalizations l10n, ConnectionClient c, DateTime now) {
    final origin = switch (c.origin) {
      'local' => l10n.connectionsOriginLocal,
      'remote' => l10n.connectionsOriginRemote,
      _ => null,
    };
    final kind = connectionKindName(l10n, c.kind) + (c.appVersion == null ? '' : ' ${c.appVersion}');
    final line = [kind, origin, c.ip].whereType<String>().join(' - ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              Text(c.user ?? l10n.connectionsNoUser, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (c.twoFactor == true) Text(l10n.connectionsTwoFactor, style: const TextStyle(color: Color(0xFF10B981), fontSize: 11)),
            ],
          ),
          Text(line, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            '${l10n.connectionsSessions(c.activeSessions)}  ${l10n.connectionsLogins(c.loginsOk, c.loginsFailed)}  ${connectionAgoText(l10n, c.lastSeen, now)}',
            style: TextStyle(color: c.activeSessions > 0 ? const Color(0xFF10B981) : Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _eventRow(AppLocalizations l10n, ConnectionEvent e, DateTime now) {
    final who = '${e.user ?? l10n.connectionsNoUser} (${connectionKindName(l10n, e.kind)}${e.appVersion == null ? '' : ' ${e.appVersion}'})';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              Text(connectionActionName(l10n, e.action), style: TextStyle(color: e.isFailure ? const Color(0xFFF87171) : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              Text(connectionAgoText(l10n, e.at, now), style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11)),
            ],
          ),
          Text(who, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
