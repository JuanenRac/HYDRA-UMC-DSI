// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/three_d_screen.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Deliberately NOT a port of HYDRA-UMC-IOS-CONTROL's/HYDRA-UMC-ANDROID-CONTROL's
// own 3D screen - both of those embed HYDRA-UMC-STUDIO's real Three.js scene
// in a WebView. That approach cannot carry over here for two independent
// reasons, either one enough on its own:
//
//   1. webview_flutter ships NO Linux desktop implementation at all (only
//      Android/iOS/macOS - see https://pub.dev/packages/webview_flutter,
//      "Platform Support" table) - this app's real target. Embedding it
//      would build fine on this Windows dev machine (which also has no
//      Linux-specific concern) but throw a MissingPluginException the
//      moment this screen opened on the actual CM5.
//   2. Even where webview_flutter *is* available, a full browser engine
//      rendering a Three.js scene is a meaningfully heavier runtime load
//      than the rest of this app combined - a real concern on a
//      low-power embedded CM5 driving a DSI touchscreen directly, unlike
//      a phone/tablet with its own dedicated GPU driver stack and a
//      user who can just close the app if it gets hot.
//
// This screen instead draws a small native, dependency-free isometric
// position/orientation indicator (CustomPainter, no 3D engine, no mesh
// data) for the selected robot's live X/Y/Z - genuinely useful for a
// "where is the tool head right now" glance without needing the real
// per-model mesh/kinematics HYDRA-UMC-STUDIO's own scene renders. The
// real, full 3D scene stays one tap away on the HDMI-connected monitor
// this board also drives (see SONNET/HYDRA-UMC-DSI/chat.TXT section 1 -
// HDMI + this DSI touchscreen are two coexisting control surfaces on the
// same board, not a replacement of one by the other) - a clear on-screen
// note says so rather than silently offering a degraded 3D view with no
// explanation. Revisit if a lightweight native 3D package (e.g. a
// `flutter_gl`/Filament-style renderer with real mesh loading, the same
// unfinished path HYDRA-UMC-ANDROID-CONTROL's own NativeThreeDScreen.kt
// explored) becomes worth the added complexity for this screen -
// tracked in SONNET/HYDRA-UMC-DSI/mejoras_futuras.txt.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hydra_state.dart';
import '../state/robot_view_model.dart';

class ThreeDScreen extends StatelessWidget {
  const ThreeDScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RobotViewModel>();
    final robot = vm.selectedRobot;

    if (robot == null) {
      return const Center(child: Text('No robot selected', style: TextStyle(color: Colors.grey)));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${robot.name} - live position',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Simplified schematic view - the full 3D scene (real robot mesh, kinematics) is available on this board\'s own HDMI-connected monitor via the browser UI.',
                    style: TextStyle(fontSize: 12, color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF0A0C10), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
              child: CustomPaint(
                painter: _IsometricAxisPainter(
                  x: robot.posAxis('x'),
                  y: robot.posAxis('y'),
                  z: robot.posAxis('z'),
                  online: robot.online,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _readout(robot),
        ],
      ),
    );
  }

  Widget _readout(RobotView robot) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _axisChip('X', robot.posAxis('x'), const Color(0xFFF43F5E)),
        const SizedBox(width: 16),
        _axisChip('Y', robot.posAxis('y'), const Color(0xFF10B981)),
        const SizedBox(width: 16),
        _axisChip('Z', robot.posAxis('z'), const Color(0xFF00E5FF)),
      ],
    );
  }

  Widget _axisChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text('$label: ${value.toStringAsFixed(1)}', style: TextStyle(color: color, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
    );
  }
}

/// Draws a fixed isometric X/Y/Z axis triad plus a marker at the robot's
/// current position, scaled into view - a schematic reference point, not a
/// to-scale rendering of any real robot geometry.
class _IsometricAxisPainter extends CustomPainter {
  final double x, y, z;
  final bool online;
  const _IsometricAxisPainter({required this.x, required this.y, required this.z, required this.online});

  static const double _isoAngle = math.pi / 6; // 30 degrees

  Offset _project(Offset center, double scale, double px, double py, double pz) {
    // Standard isometric projection: X to the lower-right, Y to the
    // lower-left, Z straight up.
    final dx = (px - py) * math.cos(_isoAngle);
    final dy = (px + py) * math.sin(_isoAngle) - pz;
    return Offset(center.dx + dx * scale, center.dy + dy * scale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + size.height * 0.15);
    const axisLen = 100.0;
    final origin = _project(center, 1, 0, 0, 0);

    final axisPaint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    void drawAxis(double dx, double dy, double dz, Color color, String label) {
      final end = _project(center, 1, dx * axisLen, dy * axisLen, dz * axisLen);
      canvas.drawLine(origin, end, axisPaint..color = color.withValues(alpha: 0.6));
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, end + const Offset(4, -4));
    }

    drawAxis(1, 0, 0, const Color(0xFFF43F5E), 'X');
    drawAxis(0, 1, 0, const Color(0xFF10B981), 'Y');
    drawAxis(0, 0, 1, const Color(0xFF00E5FF), 'Z');

    // Grid on the XY ground plane for scale reference.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = -2; i <= 2; i++) {
      canvas.drawLine(
        _project(center, 1, i * 40.0, -80, 0),
        _project(center, 1, i * 40.0, 80, 0),
        gridPaint,
      );
      canvas.drawLine(
        _project(center, 1, -80, i * 40.0, 0),
        _project(center, 1, 80, i * 40.0, 0),
        gridPaint,
      );
    }

    // Scale the reported position into a legible range on screen (clamped -
    // real robot travel is typically hundreds of mm, far larger than this
    // widget's own pixel budget) rather than a literal 1:1 mm-to-pixel
    // mapping.
    final clampedX = (x / 4).clamp(-90.0, 90.0);
    final clampedY = (y / 4).clamp(-90.0, 90.0);
    final clampedZ = (z / 4).clamp(-60.0, 90.0);
    final marker = _project(center, 1, clampedX, clampedY, clampedZ);

    // Drop line from marker to the ground plane, for depth legibility.
    final ground = _project(center, 1, clampedX, clampedY, 0);
    canvas.drawLine(marker, ground, Paint()..color = Colors.white24..strokeWidth = 1);

    final markerColor = online ? const Color(0xFF00E5FF) : Colors.grey;
    canvas.drawCircle(marker, 9, Paint()..color = markerColor.withValues(alpha: 0.25));
    canvas.drawCircle(marker, 5, Paint()..color = markerColor);
  }

  @override
  bool shouldRepaint(covariant _IsometricAxisPainter oldDelegate) =>
      oldDelegate.x != x || oldDelegate.y != y || oldDelegate.z != z || oldDelegate.online != online;
}
