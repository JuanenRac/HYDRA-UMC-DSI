// =============================================================================
// HYDRA-UMC DSI (Flutter) - state/hydra_error.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Ported from HYDRA-UMC-IOS-CONTROL's own state/hydra_error.dart:
// RobotViewModel (a plain ChangeNotifier, no BuildContext of its own) needs
// to report user-facing errors, but only a widget's build() can resolve a
// localized string via AppLocalizations.of(context). HydraError is the
// seam between the two: the view model stores a typed kind + raw
// parameters (never pre-formatted English text), and a widget calls
// localize() with its own AppLocalizations instance whenever it actually
// needs to show one - see ui/login_screen.dart and ui/main_screen.dart.
// =============================================================================

import '../l10n/app_localizations.dart';

enum HydraErrorKind {
  loginFailed,
  loginError,
  fetchFailed,
  robotNotFound,
  notConnected,
  txError,
  unknownCommand,
  wsConnectionLost,
  wsConnectFailed,
  // Raw text relayed verbatim from the server's own {"error": "..."} WS
  // frame (network/hydra_websocket.dart's _handleMessage()) - already
  // resolved server-side, in whatever language the shared backend emits
  // it in, so it is shown as-is rather than run through a template.
  serverMessage,
}

class HydraError {
  final HydraErrorKind kind;
  final Map<String, String> params;
  const HydraError(this.kind, [this.params = const {}]);

  String localize(AppLocalizations l10n) {
    switch (kind) {
      case HydraErrorKind.loginFailed:
        return l10n.errLoginFailed;
      case HydraErrorKind.loginError:
        return l10n.errLoginError(params['error'] ?? '');
      case HydraErrorKind.fetchFailed:
        return l10n.errFetchFailed(params['error'] ?? '');
      case HydraErrorKind.robotNotFound:
        return l10n.errRobotNotFound;
      case HydraErrorKind.notConnected:
        return l10n.errNotConnected;
      case HydraErrorKind.txError:
        return l10n.errTxError(params['command'] ?? '', params['error'] ?? '');
      case HydraErrorKind.unknownCommand:
        return l10n.errUnknownCommand(params['command'] ?? '');
      case HydraErrorKind.wsConnectionLost:
        return l10n.errWsConnectionLost(params['error'] ?? '');
      case HydraErrorKind.wsConnectFailed:
        return l10n.errWsConnectFailed(params['error'] ?? '');
      case HydraErrorKind.serverMessage:
        return params['message'] ?? '';
    }
  }
}
