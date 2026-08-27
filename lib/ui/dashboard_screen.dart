// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/dashboard_screen.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Per-robot cards, reactive in real time via Provider's own ChangeNotifier -
// ported from HYDRA-UMC-IOS-CONTROL's own ui/dashboard_screen.dart. LED
// convention, combined-robot display, and module chips deliberately match
// that panel so the same robot looks and behaves the same way whether it's
// viewed from the browser, a phone, a tablet, or this touchscreen.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hydra_state.dart';
import '../state/robot_view_model.dart';
import 'widgets/status_led.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RobotViewModel>();
    final robots = vm.robots;
    final metrics = vm.metrics;

    return Column(
      children: [
        if (metrics != null) _MetricsBar(metrics: metrics),
        Expanded(
          child: robots.isEmpty
              ? const Center(child: Text('No robots reported by the server', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisExtent: 190,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: robots.length,
                  itemBuilder: (context, i) => _RobotCard(robot: robots[i], allRobots: robots),
                ),
        ),
      ],
    );
  }
}

class _MetricsBar extends StatelessWidget {
  final SystemMetrics metrics;
  const _MetricsBar({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Colors.black.withValues(alpha: 0.3),
      child: Row(
        children: [
          _stat(Icons.memory, '${metrics.cpuLoad}%'),
          const SizedBox(width: 20),
          _stat(Icons.storage, '${metrics.memoryUsage}%'),
          const SizedBox(width: 20),
          _stat(Icons.thermostat, '${metrics.temp.toStringAsFixed(0)}°C'),
          const Spacer(),
          Text('uptime ${(metrics.uptime / 3600).toStringAsFixed(1)}h', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _RobotCard extends StatelessWidget {
  final RobotView robot;
  final List<RobotView> allRobots;
  const _RobotCard({required this.robot, required this.allRobots});

  @override
  Widget build(BuildContext context) {
    // Combined-robot display shown on the FOLLOWER side only, resolved by
    // id - same convention as HYDRA-UMC-STUDIO's own Dashboard Overview.
    final leaders = allRobots.where((other) => other.id != robot.id && other.combinedWith.contains(robot.id)).toList();

    return Card(
      color: robot.online ? const Color(0xFF12161C) : const Color(0xFF0A0C10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: robot.online ? Colors.white12 : Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusLed(isOn: robot.online),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(robot.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16), overflow: TextOverflow.ellipsis),
                ),
                if (robot.online && robot.isPlaying)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: const Text('RUNNING', style: TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            Text('Role: ${robot.role}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (leaders.isNotEmpty)
              Text('Combined With: ${leaders.map((r) => r.name).join(', ')}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
            const SizedBox(height: 6),
            Text(robot.model, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(robot.manufacturer, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
            const Spacer(),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (robot.hasCamera) _chip('CAM', Colors.green),
                if (robot.hasXYTable) _chip('XY', Colors.amber),
                if (robot.hasAtc) _chip('ATC', Colors.blue),
                if (robot.hasPnP) _chip('PNP', Colors.lightBlue),
                if (robot.hasCNC) _chip('CNC', Colors.purple),
                if (robot.hasLaser) _chip('LSR', Colors.red),
                if (robot.hasHeatedBed) _chip('BED', Colors.orange),
                if (robot.hasVacuumTable) _chip('VAC', Colors.teal),
                if (robot.hasRack) _chip('RCK', Colors.pink),
              ],
            ),
            const SizedBox(height: 6),
            if (robot.online)
              Text(
                'X ${robot.posAxis('x').toStringAsFixed(0)}  Y ${robot.posAxis('y').toStringAsFixed(0)}  Z ${robot.posAxis('z').toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontFamily: 'monospace'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color.shade200, fontWeight: FontWeight.bold)),
    );
  }
}
