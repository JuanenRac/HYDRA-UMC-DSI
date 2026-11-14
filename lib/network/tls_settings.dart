// =============================================================================
// HYDRA-UMC-DSI - network/tls_settings.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// How this app reaches the server, and what it trusts: HTTPS first, plain HTTP only
// when the person allowed it, a self-signed server trusted by its SHA-256
// fingerprint (confirmed once), or a custom CA. The rules, the pinned and the
// custom-CA clients and the reading of a certificate live in the shared package of
// the SDK (clients/dart_app_common); this file only fills its storage seam with the
// preferences of the display.
// =============================================================================

import 'package:hydra_umc_app_common/hydra_umc_app_common.dart' show TlsPrefsCore, TlsSettings;

import 'shared_preferences_store.dart';

export 'package:hydra_umc_app_common/hydra_umc_app_common.dart'
    show
        ServerCertificate,
        TlsFingerprint,
        TlsPem,
        TlsPolicy,
        TlsProblem,
        TlsSettings,
        TlsSettingsStore,
        createClient,
        createDiscoveryClient,
        createHttpClient,
        fetchServerCertificate,
        isCertificateRejection,
        isTlsFailure,
        pinMatches;

/// Loads and saves [TlsSettings] in the preferences of the display. Nothing stored
/// means the defaults: HTTPS only, no fingerprint, no CA.
class TlsPrefs {
  final TlsPrefsCore _core = TlsPrefsCore(SharedPreferencesPrefsStore());

  Future<TlsSettings> load() => _core.load();

  Future<void> save(TlsSettings settings) => _core.save(settings);
}
