// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/status_led.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Green pulsing = active, red solid = inactive - same convention
// HYDRA-UMC-STUDIO's own Dashboard Overview and every control app in this
// ecosystem use. Copied verbatim from HYDRA-UMC-IOS-CONTROL's own
// ui/widgets/status_led.dart.
// =============================================================================

import 'package:flutter/material.dart';

class StatusLed extends StatefulWidget {
  final bool isOn;
  final double size;
  const StatusLed({super.key, required this.isOn, this.size = 12});

  @override
  State<StatusLed> createState() => _StatusLedState();
}

class _StatusLedState extends State<StatusLed> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOn) {
      return _dot(const Color(0xFFF43F5E), 1.0);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _dot(const Color(0xFF10B981), 0.4 + 0.6 * _controller.value),
    );
  }

  Widget _dot(Color color, double opacity) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [BoxShadow(color: color.withValues(alpha: opacity * 0.8), blurRadius: widget.size)],
      ),
    );
  }
}
