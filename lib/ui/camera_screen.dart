// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/camera_screen.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Ported from HYDRA-UMC-IOS-CONTROL's own ui/camera_screen.dart - the
// hand-rolled MjpegView (widgets/mjpeg_view.dart) has no platform
// dependency, so this screen needed no real change beyond touch-sized
// controls, unlike ui/three_d_screen.dart which had to be redesigned
// entirely around Linux desktop's lack of a WebView implementation.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/robot_view_model.dart';
import 'widgets/mjpeg_view.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  dynamic _selectedId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RobotViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final robots = vm.robots;
    if (robots.isEmpty) {
      return Center(child: Text(l10n.controlNoRobots, style: const TextStyle(color: Colors.grey)));
    }
    _selectedId ??= robots.first.id;
    final robot = robots.firstWhere((r) => r.id == _selectedId, orElse: () => robots.first);
    final server = vm.activeServer;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 320,
                child: DropdownButtonFormField<dynamic>(
                  initialValue: robot.id,
                  decoration: InputDecoration(labelText: l10n.cameraLabel, border: const OutlineInputBorder(), isDense: true),
                  items: robots
                      .map((r) => DropdownMenuItem(value: r.id, child: Text('${r.name}${r.hasCamera ? '' : l10n.cameraDisabledSuffix}')))
                      .toList(),
                  onChanged: (id) => setState(() => _selectedId = id),
                ),
              ),
              const Spacer(),
              Text(
                robot.hasCamera ? l10n.cameraEnabled : l10n.cameraDisabled,
                style: TextStyle(color: robot.hasCamera ? const Color(0xFF4CAF50) : const Color(0xFFEF5350), fontWeight: FontWeight.bold),
              ),
              Switch(
                value: robot.hasCamera,
                onChanged: (enabled) => vm.setVisionEnabled(robot.id, enabled),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
              child: robot.hasCamera && server != null
                  ? MjpegView(url: '${server.baseUrl}/api/camera/${robot.id}/stream')
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_off, color: Colors.grey, size: 56),
                          const SizedBox(height: 10),
                          Text(l10n.cameraDisabled, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                          Text(l10n.cameraUseSwitch, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
