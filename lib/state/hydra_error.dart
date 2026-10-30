// =============================================================================
// HYDRA-UMC DSI (Flutter) - state/hydra_error.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
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
  // The server closed the WebSocket upgrade with RFC 6455 code 1008
  // (server.ts's own signal for a missing/invalid/expired token) - no
  // server message frame ever arrives for this case (the connection is
  // rejected before any data can flow), so it needs its own kind rather
  // than reusing serverMessage below.
  wsAuthRejected,
  // Raw text relayed verbatim from the server's own {"error": "..."} WS
  // frame (network/hydra_websocket.dart's _handleMessage()) - already
  // resolved server-side, in whatever language the shared backend emits
  // it in, so it is shown as-is rather than run through a template.
  serverMessage,
  // The server refused a command, and why: a robot reserved by another
  // account (409), a command it does not know or a value it cannot take (400),
  // a role without the permission (403), a 200 that carried warnings (nothing
  // applied), and a STOP that never got an answer.
  robotReserved,
  permissionDenied,
  commandRejected,
  commandNotApplied,
  stopNotConfirmed,
  // Reservations and the jog (contract v2): the same account holds the robot
  // from another controller, the reservation names a controller and the request
  // named none, the jog is not armed, and a jog above the limit of the model
  // that was never sent.
  claimOtherController,
  claimControllerRequired,
  jogNotArmed,
  jogOverLimit,
  // A conditional write was refused (412): the robot changed since this app read it.
  revisionChanged,
  // No secure connection could be made (certificate not trusted, or the server
  // does not speak TLS): the person is pointed to the security settings.
  tlsFailed,
  // Safe mode of a robot: it is disabled (every command but STOP is refused), the server option that allows enabling is
  // off, or the account is not an administrator.
  robotDisabled,
  enableNotAllowed,
  adminRequired,
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
      case HydraErrorKind.wsAuthRejected:
        return l10n.errWsAuthRejected;
      case HydraErrorKind.serverMessage:
        return params['message'] ?? '';
      case HydraErrorKind.robotReserved:
        return l10n.errRobotReserved(params['owner'] ?? '');
      case HydraErrorKind.permissionDenied:
        return l10n.errPermissionDenied;
      case HydraErrorKind.commandRejected:
        return l10n.errCommandRejected(params['command'] ?? '', params['reason'] ?? '');
      case HydraErrorKind.commandNotApplied:
        return l10n.errCommandNotApplied(params['command'] ?? '', params['reason'] ?? '');
      case HydraErrorKind.stopNotConfirmed:
        return l10n.errStopNotConfirmed;
      case HydraErrorKind.claimOtherController:
        return l10n.errClaimOtherController(params['detail'] ?? '');
      case HydraErrorKind.claimControllerRequired:
        return l10n.errClaimControllerRequired(params['detail'] ?? '');
      case HydraErrorKind.jogNotArmed:
        return l10n.errJogNotArmed;
      case HydraErrorKind.jogOverLimit:
        return l10n.errJogOverLimit(params['limit'] ?? '');
      case HydraErrorKind.revisionChanged:
        return l10n.errRevisionChanged(params['command'] ?? '');
      case HydraErrorKind.tlsFailed:
        return l10n.errTlsFailed;
      case HydraErrorKind.robotDisabled:
        return l10n.errRobotDisabled(params['command'] ?? '');
      case HydraErrorKind.enableNotAllowed:
        return l10n.errEnableNotAllowed;
      case HydraErrorKind.adminRequired:
        return l10n.errAdminRequired;
    }
  }
}
