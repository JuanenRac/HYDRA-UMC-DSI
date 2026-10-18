// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/stop_all.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The global STOP: ONE tap, no long press, no confirmation, every robot.
// StopAllButton is the control (the top bar of the main screen keeps one on
// every tab, and the Control tab carries a big one); StopAllBanner shows what
// happened, robot by robot, and the persistent "STOP not confirmed" state.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/stop_all_result.dart';
import '../../state/hydra_error.dart';
import '../../state/robot_view_model.dart';

class StopAllButton extends StatelessWidget {
  /// A big round button (the Control tab) instead of the compact app-bar one.
  final bool large;
  const StopAllButton({super.key, this.large = false});

  void _stop(BuildContext context) {
    HapticFeedback.heavyImpact();
    // Straight to the server: nothing here waits for a roster refresh.
    context.read<RobotViewModel>().stopAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unconfirmed = context.select<RobotViewModel, bool>((vm) => vm.stopAllUnconfirmed);
    final color = unconfirmed ? const Color(0xFFFF1744) : const Color(0xFFDC2626);
    if (large) {
      return Tooltip(
        message: l10n.stopAllTooltip,
        child: Material(
          color: color,
          shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: unconfirmed ? 0.9 : 0.4), width: 2)),
          child: InkWell(
            key: const Key('stop-all-large'),
            customBorder: const CircleBorder(),
            onTap: () => _stop(context),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Center(
                child: Text(
                  l10n.stopAllLabel,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: l10n.stopAllTooltip,
        child: FilledButton.icon(
          key: const Key('stop-all'),
          onPressed: () => _stop(context),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size(110, 56),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          icon: const Icon(Icons.front_hand, size: 24),
          label: Text(l10n.stopAllLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        ),
      ),
    );
  }
}

/// Below the app bar of every tab: the unconfirmed state, or the newest result.
class StopAllBanner extends StatelessWidget {
  const StopAllBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RobotViewModel>();
    final l10n = AppLocalizations.of(context)!;
    if (vm.stopAllUnconfirmed) {
      return Container(
        key: const Key('stop-all-unconfirmed'),
        width: double.infinity,
        color: const Color(0xFFB91C1C),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                const HydraError(HydraErrorKind.stopNotConfirmed).localize(l10n),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: vm.stopAll,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(l10n.stopAllRetry),
            ),
          ],
        ),
      );
    }
    final result = vm.stopAllResult;
    if (result == null) return const SizedBox.shrink();
    return _ResultBanner(result: result, me: vm.activeServer?.username ?? '', onClose: vm.dismissStopAllResult);
  }
}

class _ResultBanner extends StatelessWidget {
  final StopAllResult result;
  final String me;
  final VoidCallback onClose;
  const _ResultBanner({required this.result, required this.me, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final warn = result.needsAttention;
    final bg = warn ? const Color(0xFFB91C1C) : const Color(0xFF166534);
    final lines = <Widget>[];
    for (final r in result.robots) {
      final other = r.reservedBy != null && r.reservedBy != me;
      final parts = <String>[
        r.stopped ? l10n.stopAllRobotStopped : l10n.stopAllRobotFailed,
        if (other) l10n.stopAllReservedBy(r.reservedBy!),
        if (r.error != null) r.error!,
      ];
      lines.add(Text(
        '${r.stopped ? '✓' : '✗'} ${r.name}: ${parts.join(' - ')}',
        style: TextStyle(color: Colors.white, fontWeight: r.stopped ? FontWeight.w400 : FontWeight.w800, fontSize: 12),
      ));
    }
    return Container(
      key: const Key('stop-all-result'),
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(warn ? Icons.warning_amber_rounded : Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 130),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.stopAllSummary(result.stoppedCount, result.failedCount),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    if (!result.persisted)
                      Text(l10n.stopAllNotSaved, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    if (result.viaFallback) Text(l10n.stopAllRobotByRobot, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ...lines,
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.stopAllClose,
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
