// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/joystick_pad.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Jog-pendant-style directional pad - ported from HYDRA-UMC-IOS-CONTROL's
// own ui/widgets/joystick_pad.dart, sized up for a fixed-distance touch
// panel (finger input, no cursor precision) instead of a phone screen held
// at arm's length.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';

const Duration _repeatInterval = Duration(milliseconds: 150);

class JoystickPad extends StatelessWidget {
  /// Called with the signed step multiplier for each axis - e.g. (1,0,0) for +X.
  final void Function(int dx, int dy, int dz) onJog;
  final bool enabled;

  const JoystickPad({super.key, required this.onJog, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _padButton(Icons.north_west, -1, 1, 0),
              _padButton(Icons.north, 0, 1, 0),
              _padButton(Icons.north_east, 1, 1, 0),
              _padButton(Icons.west, -1, 0, 0),
              const Icon(Icons.gps_fixed, color: Colors.white24, size: 24),
              _padButton(Icons.east, 1, 0, 0),
              _padButton(Icons.south_west, -1, -1, 0),
              _padButton(Icons.south, 0, -1, 0),
              _padButton(Icons.south_east, 1, -1, 0),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 64,
          height: 180,
          child: Column(
            children: [
              Expanded(child: _zButton(Icons.keyboard_arrow_up, 1, const Color(0xFF10B981))),
              const SizedBox(height: 6),
              Expanded(child: _zButton(Icons.keyboard_arrow_down, -1, const Color(0xFFF43F5E))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _padButton(IconData icon, int dx, int dy, int dz) {
    return _RepeatButton(
      enabled: enabled,
      onTick: () => onJog(dx, dy, dz),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: const Color(0xFF00E5FF), size: 26),
      ),
    );
  }

  Widget _zButton(IconData icon, int dz, Color color) {
    return _RepeatButton(
      enabled: enabled,
      onTick: () => onJog(0, 0, dz),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}

/// Only a genuine hold repeats jog ticks - a single tap on a touch panel
/// still fires exactly once via onTapDown, same behavior as the iOS/Android
/// versions of this widget.
class _RepeatButton extends StatefulWidget {
  final VoidCallback onTick;
  final Widget child;
  final bool enabled;
  const _RepeatButton({required this.onTick, required this.child, required this.enabled});

  @override
  State<_RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  Timer? _timer;

  void _start() {
    if (!widget.enabled) return;
    widget.onTick();
    _timer?.cancel();
    _timer = Timer.periodic(_repeatInterval, (_) => widget.onTick());
  }

  void _stop() => _timer?.cancel();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _stop(),
      onTapCancel: _stop,
      child: Opacity(opacity: widget.enabled ? 1.0 : 0.3, child: widget.child),
    );
  }
}
