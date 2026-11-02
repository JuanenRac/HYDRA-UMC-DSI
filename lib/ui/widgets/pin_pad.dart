// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/pin_pad.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// A numeric pad for the PIN of the operator: the lock screen and the dialogs
// that set it use the same one. Keys are sized for a finger (72 x 60 on the
// 1280 x 720 frame). The digits are shown as dots, never as text, and the pad
// forgets what was typed as soon as it hands it over.
// =============================================================================

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class PinPad extends StatefulWidget {
  /// Called with the digits when the person presses OK (never with an empty value).
  final ValueChanged<String> onSubmit;

  /// Most digits the pad takes.
  final int maxLength;

  /// The pad does nothing while this is true (the lock refuses tries for a while).
  final bool disabled;

  const PinPad({super.key, required this.onSubmit, this.maxLength = 12, this.disabled = false});

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _digits = '';

  void _press(String digit) {
    if (widget.disabled || _digits.length >= widget.maxLength) return;
    setState(() => _digits += digit);
  }

  void _back() {
    if (widget.disabled || _digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _submit() {
    if (widget.disabled || _digits.isEmpty) return;
    final value = _digits;
    setState(() => _digits = '');
    widget.onSubmit(value);
  }

  Widget _key(Widget child, VoidCallback onTap, {Key? key, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        width: 72,
        height: 60,
        child: FilledButton.tonal(
          key: key,
          onPressed: widget.disabled ? null : onTap,
          style: FilledButton.styleFrom(backgroundColor: color, padding: EdgeInsets.zero),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget digit(String d) => _key(Text(d, style: const TextStyle(fontSize: 24)), () => _press(d), key: Key('pin-key-$d'));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            key: const Key('pin-dots'),
            children: [for (var i = 0; i < _digits.length; i++) const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.circle, size: 14))],
          ),
        ),
        const SizedBox(height: 8),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) digit(d)]),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _key(const Icon(Icons.backspace_outlined), _back, key: const Key('pin-key-back')),
            digit('0'),
            _key(Text(l10n.pinPadOk, style: const TextStyle(fontWeight: FontWeight.bold)), _submit,
                key: const Key('pin-key-ok'), color: const Color(0xFF15803D)),
          ],
        ),
      ],
    );
  }
}
