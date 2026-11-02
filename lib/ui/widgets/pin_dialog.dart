// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/pin_dialog.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The dialogs that set, change and remove the PIN of the operator (Settings).
// Setting asks twice; changing or removing asks for the current PIN first, so
// a panel left open cannot have its PIN swapped by whoever walks past. Only an
// administrator is offered them.
// =============================================================================

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/operator_pin.dart';
import '../../state/robot_view_model.dart';
import 'pin_pad.dart';

/// Asks for one PIN on the pad; null when the person cancels.
Future<String?> askPin(BuildContext context, String title, {String? hint, String? error}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 12))),
            if (error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(error, style: const TextStyle(color: Colors.redAccent))),
            PinPad(onSubmit: (pin) => Navigator.of(dialogContext).pop(pin)),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.playConfirmCancel))],
    ),
  );
}

String _problemText(AppLocalizations l10n, PinProblem problem, int minLength) =>
    problem == PinProblem.notDigits ? l10n.pinNotDigits : l10n.pinTooShort(minLength);

/// Checks the current PIN with the lock rules (counted tries, lock-out). Returns true when it was right.
Future<bool> confirmCurrentPin(BuildContext context, RobotViewModel vm) async {
  final l10n = AppLocalizations.of(context)!;
  String? error;
  while (true) {
    final entered = await askPin(context, l10n.pinCurrentTitle, error: error);
    if (entered == null || !context.mounted) return false;
    switch (vm.pin.check(entered)) {
      case PinCheck.accepted:
        return true;
      case PinCheck.notSet:
        return true;
      case PinCheck.wrong:
        error = l10n.lockWrongPin(vm.pin.attemptsLeft);
      case PinCheck.lockedOut:
        error = l10n.lockLockedOut(vm.pin.lockedOutSeconds());
        // Do not keep the dialog looping while it refuses: report once and give up.
        return false;
    }
  }
}

/// Sets a new PIN: asks twice, checks the length and the digits, keeps it. Returns the message to show, or null.
Future<String?> setNewPin(BuildContext context, RobotViewModel vm) async {
  final l10n = AppLocalizations.of(context)!;
  final min = vm.panelConfig.pinMinLength;
  final first = await askPin(context, l10n.pinNewTitle, hint: l10n.pinNewHint(min));
  if (first == null || !context.mounted) return null;
  final problem = pinProblemOf(first, min);
  if (problem != null) return _problemText(l10n, problem, min);
  final second = await askPin(context, l10n.pinRepeatTitle);
  if (second == null || !context.mounted) return null;
  if (second != first) return l10n.pinMismatch;
  await vm.setOperatorPin(first);
  return vm.pin.memoryOnly ? l10n.pinMemoryOnly : l10n.pinSaved;
}
