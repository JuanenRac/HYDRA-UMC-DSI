// =============================================================================
// HYDRA-UMC DSI (Flutter) - models/access.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Reservations, safety limits and jog arming of the server (contract v2, block 1).
// The code lives in the shared package of the SDK (clients/dart_app_common); only the
// prefix of the controller id of this app (dsi-) is its own.
// =============================================================================

import 'dart:math';

import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' as common;

export 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show ClaimInfo, ClaimStanding, claimStanding, canTakeOverRobot, jwtRole, isValidControllerId, JogLimits, RobotSafety, jogLimitExceeded, formatLimit;

/// A new controller id for this installation, e.g. `dsi-3fa9c1d27b40`.
String generateControllerId([Random? random]) => common.generateControllerId(random, 'dsi');
