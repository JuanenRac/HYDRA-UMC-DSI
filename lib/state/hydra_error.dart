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

import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show HydraError, HydraErrorKind;

import '../l10n/app_localizations.dart';
import '../util/home_reset.dart';
import '../util/pairing_link.dart';

/// The typed error (kind and raw parameters) is shared with the other app; the wording below is this app's own.
export 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show HydraError, HydraErrorKind;

extension HydraErrorText on HydraError {
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
      case HydraErrorKind.homeResetBlocked:
        return homeResetBlockText(l10n, HomeResetBlock.values.asNameMap()[params['block']] ?? HomeResetBlock.notSupported);
      case HydraErrorKind.systemActionFailed:
        return l10n.errSystemActionFailed(params['what'] ?? '', params['reason'] ?? '');
      case HydraErrorKind.pairingOff:
        return l10n.pairingOff;
      case HydraErrorKind.pairingProblem:
        return pairingProblemText(l10n, PairingProblem.values.asNameMap()[params['problem']] ?? PairingProblem.notAPairingLink);
      // Kinds only the other app builds: never produced here, so they fall back to the text the caller gave.
      default:
        return params['message'] ?? params['error'] ?? kind.name;
    }
  }
}

/// The phrase for a pairing link that was refused.
String pairingProblemText(AppLocalizations l10n, PairingProblem problem) => switch (problem) {
      PairingProblem.badHost || PairingProblem.missingHost => l10n.pairingProblemHost,
      PairingProblem.badPort => l10n.pairingProblemPort,
      PairingProblem.badFingerprint => l10n.pairingProblemFingerprint,
      PairingProblem.missingFingerprint => l10n.pairingProblemNoFingerprint,
      PairingProblem.badName => l10n.pairingProblemName,
      PairingProblem.notAPairingLink || PairingProblem.empty => l10n.pairingProblemNotLink,
      _ => l10n.pairingProblemGeneric,
    };
