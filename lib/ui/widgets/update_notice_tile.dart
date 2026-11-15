// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/update_notice_tile.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The switch "Tell me about new versions" and, while it is on, the button that reads the list of releases. Off before any
// choice: nothing is read from the network until the person turns it on and asks. Nothing is downloaded or installed.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show ReleaseAvailable, ReleaseFeedFailed, ReleaseFeedResult, ReleaseUpToDate;

import '../../l10n/app_localizations.dart';
import '../../network/client_prefs.dart';
import '../../update/update_notice.dart';

class UpdateNoticeTile extends StatefulWidget {
  const UpdateNoticeTile({super.key, this.prefs, this.check});

  final ClientPrefs? prefs;

  /// How the list of releases is read; the real check unless a test gives another.
  final Future<ReleaseFeedResult> Function()? check;

  @override
  State<UpdateNoticeTile> createState() => _UpdateNoticeTileState();
}

class _UpdateNoticeTileState extends State<UpdateNoticeTile> {
  late final ClientPrefs _prefs = widget.prefs ?? ClientPrefs();
  bool _on = false;
  bool _busy = false;
  ReleaseFeedResult? _result;

  @override
  void initState() {
    super.initState();
    _prefs.loadUpdateNotice().then((value) {
      if (mounted) setState(() => _on = value);
    });
  }

  Future<void> _change(bool value) async {
    setState(() {
      _on = value;
      if (!value) _result = null;
    });
    await _prefs.saveUpdateNotice(value);
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    final result = await (widget.check ?? checkForNewVersion)();
    if (mounted) {
      setState(() {
        _busy = false;
        _result = result;
      });
    }
  }

  String? _message(AppLocalizations l10n) {
    final result = _result;
    if (result is ReleaseAvailable) return l10n.settingsUpdateAvailable('${result.release.version}');
    if (result is ReleaseUpToDate) return l10n.settingsUpdateUpToDate;
    if (result is ReleaseFeedFailed) return l10n.settingsUpdateCheckFailed;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = _message(l10n);
    final page = _result is ReleaseAvailable ? (_result as ReleaseAvailable).release.pageUrl : null;
    return Column(
      children: [
        SwitchListTile(
          key: const Key('settings-update-notice'),
          secondary: const Icon(Icons.system_update_alt),
          title: Text(l10n.settingsUpdateNotice),
          subtitle: Text(l10n.settingsUpdateNoticeSubtitle),
          value: _on,
          onChanged: _change,
        ),
        if (_on)
          ListTile(
            key: const Key('settings-update-check'),
            leading: _busy ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
            title: Text(l10n.settingsUpdateCheckNow),
            subtitle: message == null
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message, key: const Key('settings-update-result')),
                      if (page != null) SelectableText(page, key: const Key('settings-update-page')),
                    ],
                  ),
            onTap: _busy ? null : _check,
          ),
      ],
    );
  }
}
