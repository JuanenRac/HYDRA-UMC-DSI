// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/digital_readout.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Copied verbatim from HYDRA-UMC-IOS-CONTROL's own
// ui/widgets/digital_readout.dart.
// =============================================================================

import 'package:flutter/material.dart';

class DigitalReadout extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  final int decimals;

  const DigitalReadout({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.color = const Color(0xFF00E5FF),
    this.decimals = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(
            value.toStringAsFixed(decimals),
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
            maxLines: 1,
          ),
          if (unit.isNotEmpty) Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}
