// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/system_screen.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The System tab. Three cards, each switched on by the settings file
// (util/panel_config.dart) and each off by default:
//
//  * Safety: the verdict of HYDRA-UMC-SAFETY-ZONES. Read only. Anything that
//    is not a current READY (a missing, stale, unreadable or unsigned-in
//    verdict included) is drawn as "not confirmed", never as a green light.
//  * Ecosystem: the services of HYDRA-UMC and whether they run; an
//    administrator can start, stop or restart one (the server checks again).
//  * Restart: the screen (the app closes and its supervisor starts it again),
//    the services (the server restarts itself) and, only when the settings
//    file chose it on purpose, the whole Compute Module. Each asks first.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/system_status.dart';
import '../state/robot_view_model.dart';
import '../state/system_model.dart';
import '../util/panel_config.dart';

/// The colour of a safety level on the card and on the top bar.
Color safetyColor(SafetyLevel level) => switch (level) {
      SafetyLevel.ready => const Color(0xFF10B981),
      SafetyLevel.warning => const Color(0xFFF59E0B),
      SafetyLevel.danger => const Color(0xFFEF4444),
      SafetyLevel.inhibited => const Color(0xFFF97316),
      SafetyLevel.fault => const Color(0xFFEF4444),
      SafetyLevel.unknown => const Color(0xFF64748B),
    };

String safetyLevelText(AppLocalizations l10n, SafetyLevel level) => switch (level) {
      SafetyLevel.ready => l10n.safetyLevelReady,
      SafetyLevel.warning => l10n.safetyLevelWarning,
      SafetyLevel.danger => l10n.safetyLevelDanger,
      SafetyLevel.inhibited => l10n.safetyLevelInhibited,
      SafetyLevel.fault => l10n.safetyLevelFault,
      SafetyLevel.unknown => l10n.safetyLevelUnknown,
    };

String systemActionText(AppLocalizations l10n, SystemActionResult result) => switch (result) {
      SystemActionResult.ok => l10n.rebootRequested,
      SystemActionResult.roleDenied => l10n.rebootRoleOnly,
      SystemActionResult.adminOnly => l10n.rebootAdminOnly,
      SystemActionResult.notAllowed => l10n.rebootHostNotAllowed,
      SystemActionResult.notSupervised => l10n.rebootNotSupervised,
      SystemActionResult.notLocal => l10n.rebootHostNotLocal,
      SystemActionResult.failed => l10n.rebootFailed,
    };

class SystemScreen extends StatelessWidget {
  const SystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.select<RobotViewModel, PanelConfig>((vm) => vm.panelConfig);
    final l10n = AppLocalizations.of(context)!;
    final cards = <Widget>[
      if (config.safetyPanel) const Expanded(child: _SafetyCard()),
      if (config.ecosystemView) const Expanded(flex: 2, child: _EcosystemCard()),
      if (config.rebootButton) const Expanded(child: _RestartCard()),
    ];
    if (cards.isEmpty) {
      return Center(child: Text(l10n.systemNothingEnabled, style: const TextStyle(color: Colors.grey)));
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(width: 12), cards[i]],
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Card({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12161C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 20, color: Colors.white70), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          const Divider(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ---- safety ---------------------------------------------------------------------

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.watch<SystemModel>();
    final stale = Duration(seconds: context.read<RobotViewModel>().panelConfig.safetyStaleSeconds);
    final safety = model.safety;
    final level = model.safetyLevel;
    final color = safetyColor(level);

    String? problem;
    if (model.safetyFailure != null) {
      problem = switch (model.safetyFailure!) {
        SafetyFailure.unreachable => l10n.safetyUnreachable,
        SafetyFailure.unauthorized => l10n.safetyUnauthorized,
        SafetyFailure.other => l10n.safetyUnreadable,
      };
    } else if (safety != null && safety.noVerdictYet) {
      problem = l10n.safetyNoVerdict;
    } else if (safety != null && safety.isStale(DateTime.now(), stale)) {
      final since = safety.reachedAt ?? safety.readAt;
      problem = l10n.safetyStale(DateTime.now().difference(since).inSeconds);
    }

    return _Card(
      title: l10n.systemSafetyTitle,
      icon: Icons.shield_outlined,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              key: const Key('safety-state'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6), border: Border.all(color: color)),
              child: Column(
                children: [
                  Text(safetyLevelText(l10n, level).toUpperCase(), style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  if (level != SafetyLevel.ready) Text(l10n.safetyNotConfirmed, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (problem != null) Text(problem, key: const Key('safety-problem'), style: const TextStyle(color: Colors.amber)),
            if (safety != null && !safety.noVerdictYet && safety.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.safetyReason(safety.reason)),
            ],
            if (safety != null && !safety.noVerdictYet && safety.breachCount > 0) ...[
              const SizedBox(height: 8),
              for (var i = 0; i < safety.breaches.length; i++)
                Text(
                  safety.breaches[i].danger
                      ? l10n.safetyBreachDanger(safety.breaches[i].zoneId, safety.breaches[i].objectId)
                      : l10n.safetyBreachWarning(safety.breaches[i].zoneId, safety.breaches[i].objectId),
                  key: Key('safety-breach-$i'),
                  style: TextStyle(color: safety.breaches[i].danger ? Colors.redAccent : Colors.amber),
                ),
              if (safety.breachCount > safety.breaches.length)
                Text(l10n.safetyBreachMore(safety.breachCount - safety.breaches.length), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
            if (safety != null && !safety.noVerdictYet && (safety.estopRequestCount ?? 0) > 0) ...[
              const SizedBox(height: 4),
              Text(l10n.safetyStopsAsked(safety.estopRequestCount!), key: const Key('safety-stops'), style: const TextStyle(color: Colors.redAccent)),
            ],
            if (safety != null && safety.reachedAt != null) ...[
              const SizedBox(height: 8),
              Text(l10n.safetyReachedAt(_clock(safety.reachedAt!.toLocal())), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
            if (safety != null && safety.signed) ...[
              const SizedBox(height: 4),
              Text(l10n.safetySigned, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            Text(l10n.safetyReadOnlyNote, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  static String _clock(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}

// ---- ecosystem ------------------------------------------------------------------

class _EcosystemCard extends StatelessWidget {
  const _EcosystemCard();

  Future<void> _act(BuildContext context, EcosystemProject p, String action) async {
    final l10n = AppLocalizations.of(context)!;
    final model = context.read<SystemModel>();
    final unit = p.systemdUnit;
    if (unit == null) return;
    if (action != 'start') {
      final go = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(action == 'stop' ? l10n.ecoConfirmStop(p.name) : l10n.ecoConfirmRestart(p.name)),
          content: Text(l10n.ecoConfirmBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.playConfirmCancel)),
            FilledButton(key: const Key('eco-confirm'), onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(action == 'stop' ? l10n.ecoStop : l10n.ecoRestart)),
          ],
        ),
      );
      if (go != true || !context.mounted) return;
    }
    final result = await model.serviceAction(unit, action);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result == SystemActionResult.ok ? l10n.ecoActionDone(p.name) : systemActionText(l10n, result))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.watch<SystemModel>();
    final isAdmin = context.select<RobotViewModel, bool>((vm) => vm.isAdmin);
    final eco = model.ecosystem;

    Widget body;
    if (eco == null) {
      body = Center(child: Text(model.ecosystemFailed ? l10n.ecoUnavailable : l10n.ecoLoading, style: const TextStyle(color: Colors.grey)));
    } else if (!eco.available || eco.services.isEmpty) {
      body = Center(child: Text(eco.available ? l10n.ecoNoServices : l10n.ecoUnavailable, style: const TextStyle(color: Colors.grey)));
    } else {
      final services = eco.services;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.ecoSummary(eco.runningCount, services.length), key: const Key('eco-summary'), style: const TextStyle(color: Colors.white70)),
          if (model.ecosystemFailed) Text(l10n.ecoUnavailable, style: const TextStyle(color: Colors.amber, fontSize: 12)),
          if (!isAdmin) Text(l10n.ecoAdminOnly, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, i) {
                final p = services[i];
                final running = p.isRunning;
                final unit = p.systemdUnit;
                // The server refuses its own unit (it has the restart button of its own); no point offering it.
                final controllable = isAdmin && unit != null && unit != 'hydra-umc-server.service' && model.busyUnit == null;
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.circle, size: 12, color: running ? const Color(0xFF10B981) : const Color(0xFFF43F5E)),
                  title: Text(p.name, style: const TextStyle(fontSize: 14)),
                  subtitle: Text('${p.version ?? '-'} · ${running ? l10n.ecoRunning : l10n.ecoStopped}', style: const TextStyle(fontSize: 12)),
                  trailing: model.busyUnit != null && model.busyUnit == unit
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          if (!running) IconButton(key: Key('eco-start-${p.name}'), tooltip: l10n.ecoStart, icon: const Icon(Icons.play_arrow), onPressed: controllable ? () => _act(context, p, 'start') : null),
                          if (running) IconButton(key: Key('eco-restart-${p.name}'), tooltip: l10n.ecoRestart, icon: const Icon(Icons.restart_alt), onPressed: controllable ? () => _act(context, p, 'restart') : null),
                          if (running) IconButton(key: Key('eco-stop-${p.name}'), tooltip: l10n.ecoStop, icon: const Icon(Icons.stop_circle_outlined), onPressed: controllable ? () => _act(context, p, 'stop') : null),
                        ]),
                );
              },
            ),
          ),
        ],
      );
    }
    return _Card(title: l10n.systemEcosystemTitle, icon: Icons.hub_outlined, child: body);
  }
}

// ---- restart --------------------------------------------------------------------

class _RestartCard extends StatelessWidget {
  const _RestartCard();

  Future<bool> _confirm(BuildContext context, String title, String body, String button, {Key? key}) async {
    final l10n = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.playConfirmCancel)),
          FilledButton(key: key, onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(button)),
        ],
      ),
    );
    return go == true && context.mounted;
  }

  void _say(BuildContext context, SystemActionResult result) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(systemActionText(l10n, result))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.read<SystemModel>();
    final config = context.select<RobotViewModel, PanelConfig>((vm) => vm.panelConfig);
    // The role of the session decides what is offered; the server checks it again for the parts it takes part in.
    final mayRestart = context.select<RobotViewModel, bool>((vm) => model.roleMayRestart);
    final isAdmin = context.select<RobotViewModel, bool>((vm) => vm.isAdmin);

    Future<void> screen() async {
      if (!await _confirm(context, l10n.rebootScreenButton, l10n.rebootConfirmScreen, l10n.rebootConfirmButton, key: const Key('reboot-confirm-screen'))) return;
      if (!context.mounted) return;
      final result = model.restartScreen();
      if (result != SystemActionResult.ok && context.mounted) _say(context, result);
    }

    Future<void> services() async {
      if (!await _confirm(context, l10n.rebootServicesButton, l10n.rebootConfirmServices, l10n.rebootConfirmButton, key: const Key('reboot-confirm-services'))) return;
      final result = await model.restartServices();
      if (context.mounted) _say(context, result);
    }

    Future<void> host() async {
      if (!await _confirm(context, l10n.rebootHostButton, l10n.rebootConfirmHost, l10n.rebootConfirmButton, key: const Key('reboot-confirm-host-1'))) return;
      if (!context.mounted) return;
      if (!await _confirm(context, l10n.rebootHostButton, l10n.rebootConfirmHostLast, l10n.rebootHostNow, key: const Key('reboot-confirm-host-2'))) return;
      final result = await model.restartHost();
      if (context.mounted) _say(context, result);
    }

    Widget button(Key key, IconData icon, String label, bool enabled, VoidCallback onTap, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              key: key,
              onPressed: enabled ? onTap : null,
              icon: Icon(icon),
              label: Text(label),
              style: FilledButton.styleFrom(backgroundColor: color),
            ),
          ),
        );

    return _Card(
      title: l10n.systemRestartTitle,
      icon: Icons.restart_alt,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.rebootIntro, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            button(const Key('reboot-screen'), Icons.desktop_windows_outlined, l10n.rebootScreenButton, mayRestart, screen),
            button(const Key('reboot-services'), Icons.dns_outlined, l10n.rebootServicesButton, mayRestart && isAdmin, services),
            if (config.hostRebootOffered)
              button(const Key('reboot-host'), Icons.power_settings_new, l10n.rebootHostButton, mayRestart, host, color: const Color(0xFF991B1B)),
            if (!mayRestart) Text(l10n.rebootRoleOnly, style: const TextStyle(color: Colors.amber, fontSize: 12)),
            if (mayRestart && !isAdmin) Text(l10n.rebootAdminOnly, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (!model.supervised) Text(l10n.rebootNotSupervised, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
