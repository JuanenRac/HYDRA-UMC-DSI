// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/metrics_screen.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// New screen, not a straight port - HYDRA-UMC-ANDROID-CONTROL and
// HYDRA-UMC-IOS-CONTROL both fold system metrics into a corner of their
// own Dashboard screen; the DSI user interface explicitly calls out
// "metricas de sistema" as its own
// catalog entry, so it gets a dedicated tab here with room for the CM5
// host's own hostname/controller/robot counts (state/robot_view_model.dart's
// hydraInfo, from GET /api/hydra-info) alongside the same CPU/memory/temp/
// uptime tiles the other two apps already show - same data source
// (GET /api/system/metrics), just given a full screen of touch-legible
// real estate instead of a thin bar.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/robot_view_model.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RobotViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final metrics = vm.metrics;
    final info = vm.hydraInfo;

    if (metrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.metricsHostTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _MetricTile(icon: Icons.memory, label: l10n.metricsCpuLoad, value: '${metrics.cpuLoad}%', color: _loadColor(metrics.cpuLoad)),
              _MetricTile(
                icon: Icons.storage,
                label: l10n.metricsMemoryUsage,
                value: '${metrics.memoryUsage}%',
                color: _loadColor(metrics.memoryUsage),
              ),
              _MetricTile(
                icon: Icons.thermostat,
                label: l10n.metricsTemperature,
                value: '${metrics.temp.toStringAsFixed(1)}°C',
                color: _tempColor(metrics.temp),
              ),
              _MetricTile(icon: Icons.timer, label: l10n.metricsUptime, value: _formatUptime(metrics.uptime), color: const Color(0xFF00E5FF)),
            ],
          ),
          const SizedBox(height: 28),
          if (info != null) ...[
            Text(l10n.metricsServerTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _MetricTile(
                  icon: Icons.dns,
                  label: l10n.metricsHostname,
                  value: '${info['hostname'] ?? '?'}',
                  color: Colors.white70,
                  small: true,
                ),
                _MetricTile(
                  icon: Icons.developer_board,
                  label: l10n.metricsControllers,
                  value: '${info['controllerCount'] ?? 0}',
                  color: Colors.white70,
                  small: true,
                ),
                _MetricTile(
                  icon: Icons.precision_manufacturing,
                  label: l10n.metricsRobots,
                  value: '${info['robotCount'] ?? 0}',
                  color: Colors.white70,
                  small: true,
                ),
                _MetricTile(
                  icon: Icons.tag,
                  label: l10n.metricsAppVersion,
                  value: '${info['appVersion'] ?? '?'}',
                  color: Colors.white70,
                  small: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Color _loadColor(int percent) {
    if (percent >= 85) return const Color(0xFFF43F5E);
    if (percent >= 60) return Colors.amber;
    return const Color(0xFF10B981);
  }

  static Color _tempColor(double celsius) {
    if (celsius >= 75) return const Color(0xFFF43F5E);
    if (celsius >= 60) return Colors.amber;
    return const Color(0xFF10B981);
  }

  static String _formatUptime(int seconds) {
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool small;
  const _MetricTile({required this.icon, required this.label, required this.value, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: small ? 190 : 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12161C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontSize: small ? 18 : 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
