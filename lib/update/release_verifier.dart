// =============================================================================
// HYDRA-UMC DSI (Flutter) - update/release_verifier.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// What the app checks about a downloaded release asset (its digest and, behind
// the switch, its Ed25519 signature) lives in the shared app package of the
// SDK, with the Ed25519 and SHA-512 code it uses; this file only names it for
// the app.
// =============================================================================

export 'package:hydra_umc_app_common/hydra_umc_app_common.dart'
    show ReleaseCheck, pinnedReleaseKeyHex, decodeSignatureFile, verifyDownloadedRelease, sha256FileMatches;
