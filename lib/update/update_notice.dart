// =============================================================================
// HYDRA-UMC DSI (Flutter) - update/update_notice.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The notice of a newer version: reads the public list of releases of this app when the person asks and applies the trust
// decisions of the shared app package (stable tag, newer than the installed version, HTTPS). It downloads and installs
// nothing: this app publishes no installable file, so it only tells the person that a newer version exists.
// =============================================================================

import 'package:http/http.dart' as http;
import 'package:hydra_umc_app_common/hydra_umc_app_common.dart'
    show HttpRequestData, HttpTransport, ReleaseFeedFailed, ReleaseFeedProblem, ReleaseFeedResult, evaluateReleaseFeed;

import '../app_version.dart';
import '../network/package_http_transport.dart';

/// The repository whose latest release is read.
const String kReleaseRepository = 'JuanenRac/HYDRA-UMC-DSI';

/// Address of the latest stable release of [repository] (drafts and pre-releases are never returned by it).
String latestReleaseUrl([String repository = kReleaseRepository]) => 'https://api.github.com/repos/$repository/releases/latest';

/// Asks for the latest release and applies the rules. A feed that cannot be reached, or answers with an error, is
/// [ReleaseFeedProblem.unreachable]; the transport is the one of the app unless a test gives another.
Future<ReleaseFeedResult> checkForNewVersion({
  HttpTransport? transport,
  String installed = kAppVersion,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final own = transport == null;
  final t = transport ?? PackageHttpTransport(http.Client());
  try {
    final answer = await t
        .send(HttpRequestData('GET', latestReleaseUrl(), headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'HYDRA-UMC-DSI/$installed',
        }))
        .timeout(timeout);
    if (answer.statusCode != 200) return const ReleaseFeedFailed(ReleaseFeedProblem.unreachable);
    return evaluateReleaseFeed(answer.body, installed, null);
  } catch (_) {
    return const ReleaseFeedFailed(ReleaseFeedProblem.unreachable);
  } finally {
    if (own) t.close();
  }
}
