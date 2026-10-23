// =============================================================================
// HYDRA-UMC CONTROL (DSI/Flutter) - ui/widgets/audit_dialog.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The audit record of the server (administrators only): what it wrote down
// about the changes that matter - reservations, forced releases, arming of the
// jog, changes of the safety limits and global stops. Every line is chained to
// the one before it by a SHA-256, so a line changed or removed later shows when
// the chain is verified: here against the lines this app was given, and by the
// server against the whole record. The lines can be copied as the server
// stores them (.jsonl).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contract_v2.dart';
import '../../state/robot_view_model.dart';

/// The most lines the dialog draws; the filter and the size of the window narrow what the server sends.
const int _maxLinesDrawn = 200;

class AuditDialog extends StatefulWidget {
  final RobotViewModel vm;
  const AuditDialog({super.key, required this.vm});

  @override
  State<AuditDialog> createState() => _AuditDialogState();
}

class _AuditDialogState extends State<AuditDialog> {
  // 0 is "all"; 1.. are the types of line the server writes, or the robots.
  int _typeIndex = 0;
  int _robotIndex = 0;
  int _limitIndex = 1;
  bool _verified = false;

  String? get _type => _typeIndex == 0 ? null : AuditRecord.types[_typeIndex - 1];

  dynamic get _robotId {
    final robots = widget.vm.robots;
    return _robotIndex == 0 || _robotIndex > robots.length ? null : robots[_robotIndex - 1].id;
  }

  int get _limit => AuditRecord.limits[_limitIndex];

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(false));
  }

  @override
  void dispose() {
    widget.vm.removeListener(_changed);
    super.dispose();
  }

  Future<void> _load(bool verify) {
    _verified = verify;
    return widget.vm.refreshAudit(verify: verify, type: _type, robotId: _robotId, limit: _limit);
  }

  String _typeName(AppLocalizations l10n, String type) => switch (type) {
        'claim' => l10n.auditTypeClaim,
        'force-claim' => l10n.auditTypeForceClaim,
        'release' => l10n.auditTypeRelease,
        'force-release' => l10n.auditTypeForceRelease,
        'jog-arm' => l10n.auditTypeJogArm,
        'safety-limits' => l10n.auditTypeSafetyLimits,
        'stop-all' => l10n.auditTypeStopAll,
        _ => type,
      };

  String _outcomeName(AppLocalizations l10n, String outcome) => switch (outcome) {
        'ok' => l10n.auditOutcomeOk,
        'refused' => l10n.auditOutcomeRefused,
        'failed' => l10n.auditOutcomeFailed,
        _ => outcome,
      };

  String _failureText(AppLocalizations l10n, AuditFailure failure) => switch (failure) {
        AuditFailure.forbidden => l10n.auditFailureForbidden,
        AuditFailure.unavailable => l10n.auditFailureUnavailable,
        AuditFailure.session => l10n.auditFailureSession,
        AuditFailure.network => l10n.auditFailureNetwork,
        AuditFailure.other => l10n.auditFailureOther,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = widget.vm;
    final robots = vm.robots;
    final read = vm.auditRead;
    final chain = vm.auditChain;
    final failure = vm.auditFailure;
    final busy = vm.auditBusy;
    final names = {for (final r in robots) r.id: r.name};
    const good = Color(0xFF10B981);
    const bad = Color(0xFFF87171);

    final robotLabel = _robotIndex == 0 || _robotIndex > robots.length
        ? l10n.auditAllRobots
        : (robots[_robotIndex - 1].name.isEmpty ? '#${robots[_robotIndex - 1].id}' : robots[_robotIndex - 1].name);

    return AlertDialog(
      key: const ValueKey('audit-dialog'),
      title: Text(l10n.auditTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.auditIntro, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  OutlinedButton(
                    key: const ValueKey('audit-type'),
                    onPressed: () {
                      setState(() => _typeIndex = (_typeIndex + 1) % (AuditRecord.types.length + 1));
                      _load(false);
                    },
                    child: Text(_type == null ? l10n.auditAllTypes : _typeName(l10n, _type!)),
                  ),
                  OutlinedButton(
                    key: const ValueKey('audit-robot'),
                    onPressed: () {
                      setState(() => _robotIndex = (_robotIndex + 1) % (robots.length + 1));
                      _load(false);
                    },
                    child: Text(robotLabel),
                  ),
                  OutlinedButton(
                    key: const ValueKey('audit-limit'),
                    onPressed: () {
                      setState(() => _limitIndex = (_limitIndex + 1) % AuditRecord.limits.length);
                      _load(false);
                    },
                    child: Text(l10n.auditLinesCount(_limit)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  TextButton(key: const ValueKey('audit-refresh'), onPressed: busy ? null : () => _load(false), child: Text(l10n.auditRefresh)),
                  FilledButton(key: const ValueKey('audit-verify'), onPressed: busy ? null : () => _load(true), child: Text(l10n.auditVerify)),
                  TextButton(
                    key: const ValueKey('audit-copy'),
                    onPressed: busy
                        ? null
                        : () async {
                            final text = await vm.exportAudit(type: _type, robotId: _robotId, limit: _limit);
                            if (text != null) await Clipboard.setData(ClipboardData(text: text));
                          },
                    child: Text(l10n.auditShare),
                  ),
                ],
              ),
              if (failure != null) ...[
                const SizedBox(height: 6),
                Text(_failureText(l10n, failure), key: const ValueKey('audit-failure'), style: const TextStyle(color: bad, fontWeight: FontWeight.bold)),
              ],
              if (read != null && !read.enabled) ...[
                const SizedBox(height: 6),
                Text(read.lockedOff ? l10n.auditLockedOff : l10n.auditSwitchedOff, style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
              ],
              if (_verified && read != null) ...[
                const SizedBox(height: 6),
                if (read.verification != null)
                  read.verification!.ok
                      ? Text(l10n.auditServerOk(read.verification!.entries), key: const ValueKey('audit-server-chain'), style: const TextStyle(color: good, fontWeight: FontWeight.bold))
                      : Text(
                          l10n.auditServerBroken('${read.verification!.brokenAtSeq ?? '?'}', read.verification!.reason ?? ''),
                          key: const ValueKey('audit-server-chain'),
                          style: const TextStyle(color: bad, fontWeight: FontWeight.bold),
                        ),
                if (chain != null)
                  chain.ok
                      ? Text(l10n.auditLocalOk(chain.checked, chain.links, chain.gaps), key: const ValueKey('audit-local-chain'), style: const TextStyle(color: good, fontWeight: FontWeight.bold))
                      : Text(
                          chain.reason == 'link' ? l10n.auditLocalBrokenLink('${chain.brokenAtSeq ?? '?'}') : l10n.auditLocalBrokenChanged('${chain.brokenAtSeq ?? '?'}'),
                          key: const ValueKey('audit-local-chain'),
                          style: const TextStyle(color: bad, fontWeight: FontWeight.bold),
                        ),
              ],
              const SizedBox(height: 8),
              if (read != null && read.lines.isEmpty && failure == null) Text(l10n.auditEmpty, style: const TextStyle(color: Colors.grey)),
              // The newest line first.
              if (read != null)
                for (final line in read.lines.reversed.take(_maxLinesDrawn)) _lineRow(l10n, line, names),
            ],
          ),
        ),
      ),
      actions: [TextButton(key: const ValueKey('audit-close'), onPressed: () => Navigator.of(context).pop(), child: Text(l10n.auditClose))],
    );
  }

  Widget _lineRow(AppLocalizations l10n, AuditLine line, Map<dynamic, String> names) {
    final outcomeColor = switch (line.outcome) {
      'ok' => const Color(0xFF10B981),
      'refused' => const Color(0xFFF59E0B),
      _ => const Color(0xFFF87171),
    };
    final who = [line.username, line.controllerId, line.ip].whereType<String>().join('  ');
    final robotName = line.robotId == null ? null : (names[line.robotId]?.isNotEmpty == true ? names[line.robotId]! : '#${line.robotId}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              Text('#${line.seq}', style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 12)),
              Text(_typeName(l10n, line.type), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(_outcomeName(l10n, line.outcome), style: TextStyle(color: outcomeColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          Text(_time(line.ts), style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11)),
          if (who.isNotEmpty) Text(who, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (robotName != null) Text(l10n.auditRobotLabel(robotName), style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (line.detail.isNotEmpty) Text(line.detail, style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11)),
        ],
      ),
    );
  }

  static String _time(String ts) {
    final cleaned = ts.replaceFirst('T', ' ');
    final dot = cleaned.indexOf('.');
    final base = dot < 0 ? cleaned : cleaned.substring(0, dot);
    return base.endsWith('Z') ? base.substring(0, base.length - 1) : base;
  }
}
