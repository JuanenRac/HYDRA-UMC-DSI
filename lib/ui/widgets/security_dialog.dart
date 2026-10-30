// =============================================================================
// HYDRA-UMC-DSI - ui/widgets/security_dialog.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The security settings of the connection: HTTPS first, plain HTTP only when
// allowed, and the certificate to trust. Opened from the sign-in screen
// (where a self-signed server first has to be trusted) and from Settings.
// The fingerprint of a self-signed server is read from the server, shown, and
// kept only after the person confirms it.
// =============================================================================

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../network/tls_settings.dart';
import '../../state/robot_view_model.dart';

/// Opens the security dialog. [host] and [port] name the server whose
/// certificate "Read from the server" fetches; empty when none is known.
Future<void> showSecurityDialog(
  BuildContext context,
  RobotViewModel vm, {
  String host = '',
  int port = 3000,
  Future<ServerCertificate?> Function(String host, int port)? certificateFetcher,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => SecurityDialog(
      vm: vm,
      host: host,
      port: port,
      certificateFetcher: certificateFetcher ?? fetchServerCertificate,
    ),
  );
}

class SecurityDialog extends StatefulWidget {
  final RobotViewModel vm;
  final String host;
  final int port;
  final Future<ServerCertificate?> Function(String host, int port) certificateFetcher;

  const SecurityDialog({
    super.key,
    required this.vm,
    required this.host,
    required this.port,
    required this.certificateFetcher,
  });

  @override
  State<SecurityDialog> createState() => _SecurityDialogState();
}

class _SecurityDialogState extends State<SecurityDialog> {
  late bool _allowPlain;
  late bool _allowRemote;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _caCtrl;
  ServerCertificate? _fetched;
  String? _message;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    final s = widget.vm.tlsSettings;
    _allowPlain = s.allowPlainHttp;
    _allowRemote = s.allowPlainRemote;
    _pinCtrl = TextEditingController(text: s.pinnedFingerprint.isEmpty ? '' : TlsFingerprint.display(s.pinnedFingerprint));
    _caCtrl = TextEditingController(text: s.customCaPem);
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _caCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch(AppLocalizations l10n) async {
    if (widget.host.trim().isEmpty) {
      setState(() => _message = l10n.securityNeedsHost);
      return;
    }
    setState(() {
      _fetching = true;
      _message = null;
      _fetched = null;
    });
    final cert = await widget.certificateFetcher(widget.host.trim(), widget.port);
    if (!mounted) return;
    setState(() {
      _fetching = false;
      _fetched = cert;
      if (cert == null) _message = l10n.securityFetchFailed('${widget.host}:${widget.port}');
    });
  }

  Future<void> _save(AppLocalizations l10n) async {
    final problem = await widget.vm.setTlsSettings(TlsSettings(
      allowPlainHttp: _allowPlain,
      allowPlainRemote: _allowRemote,
      pinnedFingerprint: _pinCtrl.text,
      customCaPem: _caCtrl.text,
    ));
    if (!mounted) return;
    if (problem == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _message = problem == TlsProblem.fingerprintInvalid ? l10n.securityFingerprintInvalid : l10n.securityCaInvalid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(children: [
        const Icon(Icons.shield_outlined),
        const SizedBox(width: 10),
        Expanded(child: Text(l10n.securityTitle)),
      ]),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.securityIntro),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('security-allow-plain'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.securityAllowPlain),
                subtitle: Text(l10n.securityAllowPlainSubtitle),
                value: _allowPlain,
                onChanged: (v) => setState(() {
                  _allowPlain = v;
                  if (!v) _allowRemote = false;
                }),
              ),
              if (_allowPlain)
                SwitchListTile(
                  key: const Key('security-allow-remote'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.securityAllowRemote),
                  subtitle: Text(l10n.securityAllowRemoteSubtitle),
                  value: _allowRemote,
                  onChanged: (v) => setState(() => _allowRemote = v),
                ),
              const Divider(),
              TextField(
                key: const Key('security-fingerprint'),
                controller: _pinCtrl,
                minLines: 1,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(labelText: l10n.securityFingerprintLabel),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('security-fetch'),
                  onPressed: _fetching ? null : () => _fetch(l10n),
                  icon: _fetching
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download),
                  label: Text(l10n.securityFetch),
                ),
              ),
              if (_fetched != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.securityFetched(_fetched!.subject, TlsFingerprint.display(_fetched!.fingerprint)),
                  key: const Key('security-fetched'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 4),
                FilledButton.tonal(
                  key: const Key('security-trust'),
                  onPressed: () => setState(() {
                    _pinCtrl.text = TlsFingerprint.display(_fetched!.fingerprint);
                    _fetched = null;
                  }),
                  child: Text(l10n.securityTrust),
                ),
              ],
              const Divider(),
              TextField(
                key: const Key('security-ca'),
                controller: _caCtrl,
                minLines: 1,
                maxLines: 5,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: InputDecoration(labelText: l10n.securityCaLabel),
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_message!, key: const Key('security-message'), style: TextStyle(color: scheme.error)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.securityCancel)),
        FilledButton(key: const Key('security-save'), onPressed: () => _save(l10n), child: Text(l10n.securitySave)),
      ],
    );
  }
}
