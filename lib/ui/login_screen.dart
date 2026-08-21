// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/login_screen.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
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

import '../models/server_info.dart';
import '../network/discovery.dart';
import '../state/robot_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _hostCtrl = TextEditingController(text: '192.168.1.100');
  final _portCtrl = TextEditingController(text: '3000');
  final _userCtrl = TextEditingController(text: 'admin');
  final _passCtrl = TextEditingController(text: 'admin');
  bool _isSubmitting = false;

  StreamSubscription<ServerInfo>? _scanSub;

  @override
  void dispose() {
    _scanSub?.cancel();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// Runs [scanSubnets] and shows results live in a dialog sized for a
  /// touch panel (a bottom sheet works fine too, but a centered dialog
  /// keeps the whole 1280x720 frame visible instead of one edge of it).
  Future<void> _openScanDialog() async {
    final found = <ServerInfo>[];
    final foundNotifier = ValueNotifier<List<ServerInfo>>(const []);
    final scanningNotifier = ValueNotifier<bool>(true);

    _scanSub?.cancel();
    _scanSub = scanSubnets(lastHost: _hostCtrl.text.trim().isEmpty ? null : _hostCtrl.text.trim()).listen(
      (server) {
        if (found.any((s) => s.connectionId == server.connectionId)) return;
        found.add(server);
        foundNotifier.value = List.of(found);
      },
      onDone: () => scanningNotifier.value = false,
      onError: (_) => scanningNotifier.value = false,
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Expanded(child: Text('Scanning local network…')),
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
                        isScanning ? 'Looking for HYDRA-UMC STUDIO servers…' : 'No servers found on this network.',
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
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        );
      },
    );
    unawaited(_scanSub?.cancel());
  }

  Future<void> _submit() async {
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 3000;
    if (host.isEmpty) return;
    setState(() => _isSubmitting = true);
    final server = ServerInfo(host: host, port: port, username: _userCtrl.text.trim(), password: _passCtrl.text);
    await context.read<RobotViewModel>().login(server);
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RobotViewModel>();
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.precision_manufacturing, size: 72, color: Color(0xFF00E5FF)),
                const SizedBox(height: 16),
                Text(
                  'HYDRA-UMC DSI',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                Text('Sign in to a HYDRA-UMC STUDIO server', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _hostCtrl,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(labelText: 'Server IP', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _portCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
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
                    label: const Text('Scan local network', style: TextStyle(fontSize: 15)),
                    style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _userCtrl,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (vm.lastError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(vm.lastError, style: const TextStyle(color: Colors.redAccent)),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.login),
                    label: Text(_isSubmitting ? 'Signing in…' : 'Sign In', style: const TextStyle(fontSize: 17)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
