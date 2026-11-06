// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/pairing_widgets.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The same pairing by link as HYDRA-UMC-IOS-CONTROL: the admin page of the server shows a QR code with its address and the
// fingerprint of its certificate; on the panel the link is typed or pasted (with the on-screen keyboard when the panel has
// one). The panel shows what it read and asks before it keeps anything. The switch is off by default and nothing is read
// while it is off.
// =============================================================================

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../network/tls_settings.dart';
import '../../state/robot_view_model.dart';

/// The switch of the pairing and, while it is on, the box for the link and the button that reads it. [controller] and [focus]
/// belong to the sign-in screen so the on-screen keyboard can write into the box; [keyboardType] is `none` on a panel
/// without a system keyboard.
class PairingSection extends StatelessWidget {
  const PairingSection({super.key, required this.vm, required this.controller, this.focus, this.keyboardType});

  final RobotViewModel vm;
  final TextEditingController controller;
  final FocusNode? focus;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('login-pairing'),
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.pairingSwitchLabel),
          subtitle: Text(l10n.pairingSwitchHint, style: const TextStyle(fontSize: 11)),
          value: vm.pairingEnabled,
          onChanged: (value) => vm.setPairingEnabled(value),
        ),
        if (vm.pairingEnabled) ...[
          TextField(
            key: const Key('pairing-link-field'),
            controller: controller,
            focusNode: focus,
            keyboardType: keyboardType ?? TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(labelText: l10n.pairingPasteLabel, border: const OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => OutlinedButton(
              key: const Key('pairing-read-button'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () async {
                      // Not a pairing link at all: said once and the text stays so it can be corrected.
                      final taken = await vm.readPastedPairing(controller.text);
                      if (taken) controller.clear();
                    },
              child: Text(l10n.pairingPasteButton),
            ),
          ),
        ],
      ],
    );
  }
}

/// What the person is asked before a pairing is kept: the name, the address and the fingerprint that will be pinned.
Future<void> showPairingDialog(BuildContext context, RobotViewModel vm) async {
  final l10n = AppLocalizations.of(context)!;
  final offer = vm.pairingOffer;
  if (offer == null) return;
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      key: const Key('pairing-dialog'),
      title: Text(l10n.pairingDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pairingDialogMessage(offer.name, offer.host, offer.port)),
            const SizedBox(height: 8),
            Text(l10n.pairingDialogFingerprint(TlsFingerprint.display(offer.fingerprint)), style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(l10n.pairingDialogPinReplace, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.playConfirmCancel)),
        FilledButton(key: const Key('pairing-confirm'), onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.pairingDialogConfirm)),
      ],
    ),
  );
  if (accepted == true) {
    await vm.confirmPairing();
  } else {
    vm.dismissPairing();
  }
}

/// Wraps the app and opens the question of the pairing over whatever screen is up as soon as there is an offer.
class PairingDialogHost extends StatefulWidget {
  const PairingDialogHost({super.key, required this.vm, required this.navigatorKey, required this.child});

  final RobotViewModel vm;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<PairingDialogHost> createState() => _PairingDialogHostState();
}

class _PairingDialogHostState extends State<PairingDialogHost> {
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_check);
  }

  @override
  void didUpdateWidget(PairingDialogHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm != widget.vm) {
      oldWidget.vm.removeListener(_check);
      widget.vm.addListener(_check);
    }
  }

  @override
  void dispose() {
    widget.vm.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (_showing || widget.vm.pairingOffer == null) return;
    _showing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = widget.navigatorKey.currentContext;
      if (context != null && context.mounted) await showPairingDialog(context, widget.vm);
      _showing = false;
      // Another offer may have arrived meanwhile.
      if (mounted) _check();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
