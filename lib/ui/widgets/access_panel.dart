// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/access_panel.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Shows who holds the selected robot (nobody, this display, the same account on
// another device, or another account), lets the operator reserve and release
// it, lists every reservation of the server and, only when the administrator
// requires it, arms the jog before it moves the robot. Reservations are
// optional: a robot nobody reserved is commanded as before.
// =============================================================================

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/access.dart';
import '../../models/contract_v2.dart';
import '../../state/robot_view_model.dart';
import 'audit_dialog.dart';

class AccessPanel extends StatefulWidget {
  final RobotViewModel vm;
  final dynamic robotId;

  /// The current time, passed in so the countdown of the jog arming follows
  /// the screen's own clock (and tests can fix it).
  final DateTime now;

  const AccessPanel({super.key, required this.vm, required this.robotId, required this.now});

  @override
  State<AccessPanel> createState() => _AccessPanelState();
}

class _AccessPanelState extends State<AccessPanel> {
  bool _showList = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = widget.vm;
    final standing = vm.claimStandingOf(widget.robotId);
    final claim = vm.claimOf(widget.robotId);
    final busy = vm.accessBusy;
    final safety = vm.safetyByRobot[widget.robotId];

    final statusText = switch (standing) {
      ClaimStanding.free => l10n.accessFree,
      ClaimStanding.mineHere => l10n.accessMineHere,
      ClaimStanding.mineElsewhere => l10n.accessMineElsewhere,
      ClaimStanding.other => l10n.accessOther(claim?.ownerUsername ?? ''),
    };
    final statusColor = switch (standing) {
      ClaimStanding.free => Colors.grey,
      ClaimStanding.mineHere => const Color(0xFF10B981),
      _ => const Color(0xFFF59E0B),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.accessTitle.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilledButton(
                  key: const ValueKey('access-reserve'),
                  onPressed: !busy && standing == ClaimStanding.free ? () => vm.claimSelectedRobot() : null,
                  child: Text(l10n.accessReserve),
                ),
                OutlinedButton(
                  key: const ValueKey('access-release'),
                  onPressed: !busy && standing == ClaimStanding.mineHere ? () => vm.releaseSelectedRobot() : null,
                  child: Text(l10n.accessRelease),
                ),
                TextButton(
                  key: const ValueKey('access-list'),
                  onPressed: () => setState(() => _showList = !_showList),
                  child: Text(l10n.accessListShow),
                ),
                // Only for an administrator, only on a robot someone else holds, and never without asking first.
                if (vm.canTakeOver(widget.robotId))
                  OutlinedButton(
                    key: const ValueKey('access-take-over'),
                    onPressed: busy ? null : () => _confirmTakeOver(context, l10n, claim?.ownerUsername ?? ''),
                    child: Text(l10n.accessTakeOver),
                  ),
              ],
            ),
            // The audit record is for administrators only (the server refuses it to anyone else).
            if (vm.isAdmin)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  key: const ValueKey('access-audit'),
                  onPressed: () => showDialog<void>(context: context, builder: (_) => AuditDialog(vm: vm)),
                  child: Text(l10n.auditOpen),
                ),
              ),
            if (_showList) ...[
              if (vm.claims.isEmpty)
                Text(l10n.accessListEmpty, style: const TextStyle(color: Colors.grey))
              else
                for (final c in vm.claims)
                  Text(
                    l10n.accessListItem(c.robotName.isEmpty ? '#${c.robotId}' : c.robotName, c.ownerUsername),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              // Whether a write checks that the robot has not changed since this app read it (If-Match).
              const SizedBox(height: 8),
              Text(l10n.accessConditionalLabel, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              SegmentedButton<ConditionalMode>(
                key: const ValueKey('access-conditional'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: ConditionalMode.standard, label: Text(l10n.accessConditionalStandard)),
                  ButtonSegment(value: ConditionalMode.strict, label: Text(l10n.accessConditionalStrict)),
                  ButtonSegment(value: ConditionalMode.off, label: Text(l10n.accessConditionalOff)),
                ],
                selected: {vm.conditionalMode},
                onSelectionChanged: (s) => vm.setConditionalMode(s.first),
              ),
              Text(l10n.accessConditionalHint, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
            // The jog arming exists only when the administrator turned it on in the server.
            if (safety != null && safety.armRequired) ..._armingSection(l10n, vm, busy),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmTakeOver(BuildContext context, AppLocalizations l10n, String owner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        key: const ValueKey('access-take-over-dialog'),
        title: Text(l10n.accessTakeOverTitle),
        content: Text(l10n.accessTakeOverMessage(owner)),
        actions: [
          TextButton(
            key: const ValueKey('access-take-over-cancel'),
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.accessTakeOverCancel),
          ),
          FilledButton(
            key: const ValueKey('access-take-over-confirm'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.accessTakeOverConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.vm.takeOverSelectedRobot();
  }

  List<Widget> _armingSection(AppLocalizations l10n, RobotViewModel vm, bool busy) {
    final until = vm.jogArmedUntil[widget.robotId];
    final armed = until != null && until.isAfter(widget.now);
    final seconds = armed ? (until.difference(widget.now).inMilliseconds + 999) ~/ 1000 : 0;
    return [
      const SizedBox(height: 12),
      Text(
        armed ? l10n.jogArmed(seconds) : l10n.jogNotArmed,
        style: TextStyle(color: armed ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontWeight: FontWeight.bold),
      ),
      Text(l10n.jogArmHint, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 6),
      FilledButton(
        key: const ValueKey('access-arm'),
        onPressed: busy ? null : () => vm.setJogArmed(!armed),
        child: Text(armed ? l10n.jogDisarm : l10n.jogArm),
      ),
    ];
  }
}
