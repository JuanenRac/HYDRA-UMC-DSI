// =============================================================================
// HYDRA-UMC CONTROL (DSI/Flutter) - ui/widgets/server_options_dialog.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Seven switches of the server with where each value comes from (administrators
// only). A value fixed by the environment of the server is locked, a change that
// lowers the protection is asked about first, and a server that predates an option
// simply does not show it.
// =============================================================================

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/server_security.dart';
import '../../state/robot_view_model.dart';

String serverOptionsFailureText(AppLocalizations l10n, ServerOptionsFailure failure) => switch (failure) {
      ServerOptionsFailure.unavailable => l10n.serverOptionsFailureUnavailable,
      ServerOptionsFailure.session => l10n.serverOptionsFailureSession,
      ServerOptionsFailure.forbidden => l10n.serverOptionsFailureForbidden,
      ServerOptionsFailure.network => l10n.serverOptionsFailureNetwork,
      ServerOptionsFailure.other => l10n.serverOptionsFailureOther,
    };

String protectionLoweringText(AppLocalizations l10n, ProtectionLowering lowering) => switch (lowering) {
      ProtectionLowering.healthOpen => l10n.serverOptionsHealthConfirm,
      ProtectionLowering.recordAddress => l10n.serverOptionsAddressConfirm,
      ProtectionLowering.cameraOpen => l10n.serverOptionsConfirmCamera,
      ProtectionLowering.wsQueryToken => l10n.serverOptionsConfirmWs,
      ProtectionLowering.logRedactionOff => l10n.serverOptionsConfirmLog,
      ProtectionLowering.voiceSignatureOff => l10n.serverOptionsConfirmVoice,
    };

String optionSourceText(AppLocalizations l10n, OptionSource source) => switch (source) {
      OptionSource.env => l10n.serverOptionsSourceEnv,
      OptionSource.config => l10n.serverOptionsSourceConfig,
      OptionSource.defaultValue => l10n.serverOptionsSourceDefault,
    };

class ServerOptionsDialog extends StatefulWidget {
  final RobotViewModel vm;
  const ServerOptionsDialog({super.key, required this.vm});

  @override
  State<ServerOptionsDialog> createState() => _ServerOptionsDialogState();
}

class _ServerOptionsDialogState extends State<ServerOptionsDialog> {
  ServerSecurityValues? _values;
  ServerSecurityOptions? _shownFor;

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.vm.refreshServerOptions());
  }

  @override
  void dispose() {
    widget.vm.removeListener(_changed);
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n, ServerSecurityOptions current, ServerSecurityValues values) async {
    final lowering = current.lowerings(values);
    if (lowering.isNotEmpty) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const ValueKey('server-options-confirm'),
          title: Text(l10n.serverOptionsConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final item in lowering) Text('- ${protectionLoweringText(l10n, item)}')],
          ),
          actions: [
            TextButton(key: const ValueKey('server-options-confirm-no'), onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.securityCancel)),
            TextButton(key: const ValueKey('server-options-confirm-yes'), onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.serverOptionsConfirmYes)),
          ],
        ),
      );
      if (go != true) return;
    }
    await widget.vm.saveServerOptions(values);
  }

  Widget _row(ServerOption? option, bool checked, String label, String? help, ValueChanged<bool> onChanged, AppLocalizations l10n, String id) {
    if (option == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Switch(key: ValueKey('server-option-$id'), value: checked, onChanged: option.locked ? null : onChanged),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (help != null) Text(help, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(optionSourceText(l10n, option.source), style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = widget.vm;
    final options = vm.serverOptions;
    if (!identical(options, _shownFor)) {
      _shownFor = options;
      _values = options?.toValues();
    }
    final values = _values;
    final failure = vm.serverOptionsFailure;
    final busy = vm.serverOptionsBusy;

    final children = <Widget>[
      Text(l10n.serverOptionsIntro, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      if (failure != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(serverOptionsFailureText(l10n, failure), key: const ValueKey('server-options-failure'), style: const TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.bold)),
        ),
    ];
    if (options != null && values != null) {
      if (options.isEmpty) {
        children.add(Text(l10n.serverOptionsNone, style: const TextStyle(color: Colors.grey, fontSize: 12)));
      } else {
        void set(ServerSecurityValues next) => setState(() => _values = next);
        children.addAll([
          _row(options.healthOpen, values.healthOpen, l10n.serverOptionsHealthLabel, l10n.serverOptionsHealthHelp, (v) => set(values.copyWith(healthOpen: v)), l10n, 'health'),
          _row(options.publishGlobalStop, values.publishGlobalStop, l10n.serverOptionsStopLabel, l10n.serverOptionsStopHelp, (v) => set(values.copyWith(publishGlobalStop: v)), l10n, 'stop'),
          _row(options.recordAddress, values.recordAddress, l10n.serverOptionsAddressLabel, l10n.serverOptionsAddressHelp, (v) => set(values.copyWith(recordAddress: v)), l10n, 'address'),
          _row(options.cameraOpen, values.cameraOpen, l10n.serverOptionsCameraLabel, l10n.serverOptionsExposureHelp, (v) => set(values.copyWith(cameraOpen: v)), l10n, 'camera'),
          _row(options.wsQueryToken, values.wsQueryToken, l10n.serverOptionsWsLabel, null, (v) => set(values.copyWith(wsQueryToken: v)), l10n, 'ws'),
          _row(options.logRedaction, values.logRedaction, l10n.serverOptionsLogLabel, null, (v) => set(values.copyWith(logRedaction: v)), l10n, 'log'),
          _row(options.voiceSignature, values.voiceSignature, l10n.serverOptionsVoiceLabel, null, (v) => set(values.copyWith(voiceSignature: v)), l10n, 'voice'),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('server-options-save'),
            onPressed: busy || options.patch(values) == null ? null : () => _save(l10n, options, values),
            child: Text(l10n.serverOptionsSave),
          ),
          if (vm.serverOptionsSaved && failure == null)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(l10n.serverOptionsSaved, key: const ValueKey('server-options-saved'), style: const TextStyle(fontSize: 12))),
        ]);
      }
    }

    return AlertDialog(
      key: const ValueKey('server-options-dialog'),
      title: Text(l10n.serverOptionsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
      ),
      actions: [
        TextButton(key: const ValueKey('server-options-refresh'), onPressed: busy ? null : () => vm.refreshServerOptions(), child: Text(l10n.auditRefresh)),
        TextButton(key: const ValueKey('server-options-close'), onPressed: () => Navigator.of(context).pop(), child: Text(l10n.auditClose)),
      ],
    );
  }
}
