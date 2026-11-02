// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/virtual_keyboard.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// An on-screen keyboard of our own, because Flutter on Linux brings none and
// the Wayland compositor of the kiosk (cage) does not either: on a touch panel
// with no USB keyboard the sign-in screen could not be filled in. It writes
// into whichever field was touched last, through the field's own controller.
//
// Characters are ASCII (letters, digits and the punctuation of addresses,
// user names and passwords). The keys cannot take the focus away from the
// field: they sit inside ExcludeFocus. Whether it is shown at all is the
// `virtual_keyboard` key of the settings file (util/panel_config.dart).
// =============================================================================

import 'package:flutter/material.dart';

enum _Layer { letters, symbols }

class VirtualKeyboard extends StatefulWidget {
  /// The controller of the field that was touched last, or null when none was yet.
  final TextEditingController? Function() target;

  /// The Enter key (submit the form).
  final VoidCallback? onEnter;

  const VirtualKeyboard({super.key, required this.target, this.onEnter});

  @override
  State<VirtualKeyboard> createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard> {
  _Layer _layer = _Layer.letters;
  bool _shift = false;

  static const _letterRows = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ];
  static const _symbolRows = [
    ['!', '@', '#', r'$', '%', '^', '&', '*', '(', ')'],
    ['-', '_', '=', '+', '[', ']', '{', '}', ';', ':'],
    ['.', ',', '/', '\\', '?', '<', '>', '~', '|'],
  ];

  void _insert(String text) {
    final controller = widget.target();
    if (controller == null) return;
    final value = controller.value;
    final selection = value.selection.isValid ? value.selection : TextSelection.collapsed(offset: value.text.length);
    final start = selection.start.clamp(0, value.text.length);
    final end = selection.end.clamp(0, value.text.length);
    final next = value.text.replaceRange(start, end, text);
    controller.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: start + text.length));
    if (_shift) setState(() => _shift = false);
  }

  void _backspace() {
    final controller = widget.target();
    if (controller == null) return;
    final value = controller.value;
    final selection = value.selection.isValid ? value.selection : TextSelection.collapsed(offset: value.text.length);
    final start = selection.start.clamp(0, value.text.length);
    final end = selection.end.clamp(0, value.text.length);
    if (start != end) {
      controller.value = TextEditingValue(text: value.text.replaceRange(start, end, ''), selection: TextSelection.collapsed(offset: start));
    } else if (start > 0) {
      controller.value = TextEditingValue(text: value.text.replaceRange(start - 1, start, ''), selection: TextSelection.collapsed(offset: start - 1));
    }
  }

  Widget _key(String label, VoidCallback onTap, {double width = 60, Key? key, Color? color, Widget? child}) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        width: width,
        height: 46,
        child: FilledButton.tonal(
          key: key,
          onPressed: onTap,
          style: FilledButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: color),
          child: child ?? Text(label, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  // A row that is wider than the space it gets (a narrow window) shrinks instead of overflowing.
  Widget _fit(Widget row) => FittedBox(fit: BoxFit.scaleDown, child: row);

  @override
  Widget build(BuildContext context) {
    final letters = _layer == _Layer.letters;
    final rows = letters ? _letterRows : _symbolRows;
    String shown(String k) => letters && _shift ? k.toUpperCase() : k;
    return ExcludeFocus(
      child: Container(
        key: const Key('virtual-keyboard'),
        color: const Color(0xFF0D1117),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _fit(Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) _key(d, () => _insert(d), key: Key('vk-$d'))],
            )),
            for (var r = 0; r < rows.length; r++)
              _fit(Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (r == 2 && letters) _key('', () => setState(() => _shift = !_shift), width: 90, key: const Key('vk-shift'), color: _shift ? const Color(0xFF0E7490) : null, child: const Icon(Icons.keyboard_capslock)),
                  for (final k in rows[r]) _key(shown(k), () => _insert(shown(k)), key: Key('vk-$k')),
                  if (r == 2) _key('', _backspace, width: 90, key: const Key('vk-back'), child: const Icon(Icons.backspace_outlined)),
                ],
              )),
            _fit(Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _key(letters ? '#+=' : 'abc', () => setState(() => _layer = letters ? _Layer.symbols : _Layer.letters), width: 90, key: const Key('vk-layer')),
                _key('@', () => _insert('@'), key: const Key('vk-at')),
                _key('.', () => _insert('.'), key: const Key('vk-dot')),
                _key('', () => _insert(' '), width: 340, key: const Key('vk-space'), child: const Icon(Icons.space_bar)),
                _key('-', () => _insert('-'), key: const Key('vk-dash')),
                _key('_', () => _insert('_'), key: const Key('vk-underscore')),
                _key('', () => widget.onEnter?.call(), width: 90, key: const Key('vk-enter'), color: const Color(0xFF15803D), child: const Icon(Icons.keyboard_return)),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
