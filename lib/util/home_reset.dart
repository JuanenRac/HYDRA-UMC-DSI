// =============================================================================
// HYDRA-UMC DSI (Flutter) - util/home_reset.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// HOME/RESET takes the selected robot to its zero position through the server's `reset` command. The rules
// (when the app refuses to offer it, and the confirmation in steps) live in the shared package of the SDK
// (clients/dart_app_common); the phrase for each reason needs the localizations of this app and stays here.
// =============================================================================

import '../l10n/app_localizations.dart';
import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show HomeResetBlock;

export 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show HomeResetBlock, HomeResetSituation, homeResetRoleAllowed, homeResetBlockOf, HomeResetProgress, HomeResetConfirmation;

/// The phrase for a [HomeResetBlock], in the language of the panel.
String homeResetBlockText(AppLocalizations l10n, HomeResetBlock block) => switch (block) {
      HomeResetBlock.none => l10n.homeResetBlockedNone,
      HomeResetBlock.off => l10n.homeResetBlockedOff,
      HomeResetBlock.notConnected => l10n.errNotConnected,
      HomeResetBlock.offline => l10n.homeResetBlockedOffline,
      HomeResetBlock.safeMode => l10n.homeResetBlockedSafeMode,
      HomeResetBlock.moving => l10n.homeResetBlockedMoving,
      HomeResetBlock.jogBusy => l10n.homeResetBlockedJog,
      HomeResetBlock.stopPending => l10n.homeResetBlockedStop,
      HomeResetBlock.notArmed => l10n.errJogNotArmed,
      HomeResetBlock.role => l10n.homeResetBlockedRole,
      HomeResetBlock.noPose => l10n.homeResetBlockedNoPose,
      HomeResetBlock.notSupported => l10n.homeResetNotSupported,
    };
