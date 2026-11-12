// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/login_screen.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Adapted from HYDRA-UMC-IOS-CONTROL's own ui/login_screen.dart for a fixed
// 1280x720 touch panel: same fields and "Scan local network" flow, laid out
// side-by-side instead of stacked full-width so nothing forces a scroll on
// the real hardware, and every tappable target sized for a finger rather
// than a cursor.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/server_info.dart';
import '../network/discovery.dart';
import '../state/robot_view_model.dart';
import '../util/panel_defaults.dart';
import '../state/hydra_error.dart';
import 'widgets/pairing_widgets.dart';
import 'widgets/security_dialog.dart';
import 'widgets/virtual_keyboard.dart';

/// Everything the sign-in screen draws or decides from the view model, as one text: it is redrawn when this text
/// changes and not for the metrics tick or the robots. A field the screen starts to read must be added here
/// (test/selector_rebuild_test.dart checks the fields it has now).
String loginScreenShape(RobotViewModel vm) {
  return [
    vm.panelConfig.appliance,
    vm.panelConfig.virtualKeyboard,
    vm.pairingEnabled,
    vm.pairedStamp,
    vm.pairedHost,
    vm.pairedPort,
    vm.lastError?.kind.name,
    vm.lastError?.params,
  ].join('|');
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _hostCtrl = TextEditingController(text: panelDefaultHost);
  final _portCtrl = TextEditingController(text: '$panelDefaultPort');
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pairingCtrl = TextEditingController();
  bool _isSubmitting = false;
  int _pairedStamp = 0;

  // The on-screen keyboard writes into the field touched last.
  final _hostFocus = FocusNode();
  final _portFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  final _pairingFocus = FocusNode();
  late final Map<FocusNode, TextEditingController> _fields = {
    _hostFocus: _hostCtrl,
    _portFocus: _portCtrl,
    _userFocus: _userCtrl,
    _passFocus: _passCtrl,
    _pairingFocus: _pairingCtrl,
  };
  TextEditingController? _lastTouched;

  @override
  void initState() {
    super.initState();
    for (final entry in _fields.entries) {
      entry.key.addListener(() {
        if (entry.key.hasFocus) _lastTouched = entry.value;
      });
    }
  }

  StreamSubscription<ServerInfo>? _scanSub;
  StreamSubscription<ServerInfo>? _mdnsSub;

  @override
  void dispose() {
    _scanSub?.cancel();
    _mdnsSub?.cancel();
    for (final node in _fields.keys) {
      node.dispose();
    }
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _pairingCtrl.dispose();
    super.dispose();
  }

  /// Runs [discoverMdns] (real mDNS/Bonjour) and [scanSubnets] (brute-force
  /// subnet scan) at the same time and shows results live in a dialog
  /// sized for a touch panel (a bottom sheet works fine too, but a
  /// centered dialog keeps the whole 1280x720 frame visible instead of one
  /// edge of it). Both paths report through the same [found] list, deduped
  /// by [ServerInfo.connectionId] since a server both paths agree on would
  /// otherwise show up twice.
  Future<void> _openScanDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final found = <ServerInfo>[];
    final foundNotifier = ValueNotifier<List<ServerInfo>>(const []);
    var mdnsDone = false;
    var subnetDone = false;
    final scanningNotifier = ValueNotifier<bool>(true);

    void addResult(ServerInfo server) {
      if (found.any((s) => s.connectionId == server.connectionId)) return;
      found.add(server);
      foundNotifier.value = List.of(found);
    }

    void checkDone() {
      if (mdnsDone && subnetDone) scanningNotifier.value = false;
    }

    _mdnsSub?.cancel();
    _mdnsSub = discoverMdns().listen(
      addResult,
      onDone: () {
        mdnsDone = true;
        checkDone();
      },
      onError: (_) {
        mdnsDone = true;
        checkDone();
      },
    );

    _scanSub?.cancel();
    _scanSub = scanSubnets(lastHost: _hostCtrl.text.trim().isEmpty ? null : _hostCtrl.text.trim()).listen(
      addResult,
      onDone: () {
        subnetDone = true;
        checkDone();
      },
      onError: (_) {
        subnetDone = true;
        checkDone();
      },
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(l10n.loginScanTitle)),
              ValueListenableBuilder<bool>(
                valueListenable: scanningNotifier,
                builder: (context, isScanning, _) => isScanning
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle, color: Colors.greenAccent),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            height: 360,
            child: ValueListenableBuilder<List<ServerInfo>>(
              valueListenable: foundNotifier,
              builder: (context, servers, _) {
                if (servers.isEmpty) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: scanningNotifier,
                    builder: (context, isScanning, _) => Center(
                      child: Text(
                        isScanning ? l10n.loginScanSearching : l10n.loginScanNoneFound,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: servers.length,
                  itemBuilder: (context, i) {
                    final s = servers[i];
                    return ListTile(
                      leading: const Icon(Icons.dns, size: 28),
                      title: Text(s.displayName, style: const TextStyle(fontSize: 16)),
                      subtitle: Text('${s.host}:${s.port} · ${s.product.isNotEmpty ? s.product : "HYDRA-UMC STUDIO"}'),
                      onTap: () {
                        _hostCtrl.text = s.host;
                        _portCtrl.text = s.port.toString();
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.scanClose)),
          ],
        );
      },
    );
    if (!mdnsDone) unawaited(_mdnsSub?.cancel());
    if (!subnetDone) unawaited(_scanSub?.cancel());
  }

  Future<void> _submit() async {
    // In appliance mode the panel is a screen of this Compute Module: the address is not the person's to choose.
    final appliance = context.read<RobotViewModel>().panelConfig.appliance;
    final host = appliance ? panelDefaultHost : _hostCtrl.text.trim();
    final port = appliance ? panelDefaultPort : int.tryParse(_portCtrl.text.trim()) ?? panelDefaultPort;
    if (host.isEmpty || _userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    final server = ServerInfo(host: host, port: port, username: _userCtrl.text.trim(), password: _passCtrl.text);
    await context.read<RobotViewModel>().login(server);
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    // Redrawn when something this screen draws changes (see loginScreenShape), not for the metrics tick.
    context.select<RobotViewModel, String>(loginScreenShape);
    final vm = context.read<RobotViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final appliance = vm.panelConfig.appliance;
    final keyboard = vm.panelConfig.virtualKeyboard;
    // With the keyboard on screen the logo goes: 720 pixels have to hold the form and four rows of keys.
    final compact = keyboard;
    final gap = compact ? 8.0 : 24.0;
    // On the touch panel there is no system keyboard: the field must not ask for one.
    final TextInputType? none = keyboard ? TextInputType.none : null;
    // A pairing the person confirmed gives the address of the server: show it in the fields.
    if (vm.pairedStamp != _pairedStamp) {
      _pairedStamp = vm.pairedStamp;
      if (vm.pairedHost != null && vm.pairedPort != null) {
        _hostCtrl.text = vm.pairedHost!;
        _portCtrl.text = '${vm.pairedPort}';
      }
    }
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 16 : 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!compact) ...[
                          const Icon(Icons.precision_manufacturing, size: 72, color: Color(0xFF00E5FF)),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'HYDRA-UMC DSI',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                        const SizedBox(height: 4),
                        Text(appliance ? l10n.loginApplianceSubtitle : l10n.loginSubtitle, style: Theme.of(context).textTheme.bodyMedium),
                        SizedBox(height: gap),
                        if (!appliance) ...[
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _hostCtrl,
                                  focusNode: _hostFocus,
                                  keyboardType: none,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(labelText: l10n.loginServerIp, border: const OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _portCtrl,
                                  focusNode: _portFocus,
                                  keyboardType: none ?? TextInputType.number,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(labelText: l10n.loginPort, border: const OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _isSubmitting ? null : _openScanDialog,
                              icon: const Icon(Icons.wifi_find),
                              label: Text(l10n.loginScanNetwork, style: const TextStyle(fontSize: 15)),
                              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                            ),
                          ),
                        ],
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const Key('login-security'),
                            onPressed: _isSubmitting
                                ? null
                                : () => showSecurityDialog(
                                      context,
                                      vm,
                                      host: appliance ? panelDefaultHost : _hostCtrl.text.trim(),
                                      port: appliance ? panelDefaultPort : int.tryParse(_portCtrl.text.trim()) ?? panelDefaultPort,
                                    ),
                            icon: const Icon(Icons.shield_outlined),
                            label: Text(l10n.securityOpen, style: const TextStyle(fontSize: 15)),
                            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _userCtrl,
                                focusNode: _userFocus,
                                keyboardType: none,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(labelText: l10n.loginUsername, border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _passCtrl,
                                focusNode: _passFocus,
                                keyboardType: none,
                                obscureText: true,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(labelText: l10n.loginPassword, border: const OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 4 : 12),
                        // Pairing by the link of the admin page of the server: off until switched on, asks before it keeps anything.
                        // On an appliance panel the address is fixed, so there is nothing to pair.
                        if (!appliance) PairingSection(vm: vm, controller: _pairingCtrl, focus: _pairingFocus, keyboardType: none),
                        SizedBox(height: gap),
                        if (vm.lastError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(vm.lastError!.localize(l10n), style: const TextStyle(color: Colors.redAccent)),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.login),
                            label: Text(_isSubmitting ? l10n.loginSigningIn : l10n.loginSignIn, style: const TextStyle(fontSize: 17)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (keyboard)
            VirtualKeyboard(
              target: () => _lastTouched ?? (appliance ? _userCtrl : _hostCtrl),
              onEnter: _isSubmitting ? null : _submit,
            ),
        ],
      ),
    );
  }
}
