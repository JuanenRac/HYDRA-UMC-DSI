// =============================================================================
// HYDRA-UMC DSI (Flutter) - models/contract_v2.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The second contract of the server (conditional writes, the `table` command, the audit chain).
// The code lives in the shared package of the SDK (clients/dart_app_common).
// =============================================================================

export 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show ConditionalMode, continuousCommands, isConditional, revisionOf, ifMatchHeader, RevisionTicket, RevisionTracker, RobotRead, tableParams, tableLimitExceeded, tableAsJogs, isUnknownCommandAnswer, AuditLine, AuditVerdict, AuditRead, ChainCheck, AuditRecord;
