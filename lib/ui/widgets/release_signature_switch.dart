// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/release_signature_switch.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The switch "Require a release signature". Off before any choice: the digest of
// a downloaded release is still checked, the signature only when this is on.
// =============================================================================

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../network/client_prefs.dart';

class ReleaseSignatureSwitch extends StatefulWidget {
  const ReleaseSignatureSwitch({super.key, this.prefs});

  final ClientPrefs? prefs;

  @override
  State<ReleaseSignatureSwitch> createState() => _ReleaseSignatureSwitchState();
}

class _ReleaseSignatureSwitchState extends State<ReleaseSignatureSwitch> {
  late final ClientPrefs _prefs = widget.prefs ?? ClientPrefs();
  bool _value = false;

  @override
  void initState() {
    super.initState();
    _prefs.loadRequireReleaseSignature().then((value) {
      if (mounted) setState(() => _value = value);
    });
  }

  Future<void> _change(bool value) async {
    setState(() => _value = value);
    await _prefs.saveRequireReleaseSignature(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      key: const Key('settings-require-release-signature'),
      secondary: const Icon(Icons.verified_outlined),
      title: Text(l10n.settingsRequireReleaseSignature),
      subtitle: Text(l10n.settingsRequireReleaseSignatureSubtitle),
      value: _value,
      onChanged: _change,
    );
  }
}
