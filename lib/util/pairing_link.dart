// =============================================================================
// HYDRA-UMC DSI (Flutter) - util/pairing_link.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The code lives in the shared package of the SDK (clients/dart_app_common): the reading of the link the admin page of
// the server puts in its QR code (host, port, SHA-256 fingerprint of the certificate and a name). The fingerprint is
// required: there is no "pair anyway" mode.
// =============================================================================

export 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show PairingLimits, PairingLink, PairingOffer, PairingProblem, PairingResult;
