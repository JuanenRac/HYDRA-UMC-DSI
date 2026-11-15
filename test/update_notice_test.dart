// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/update_notice_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The notice of a newer version: the check applies the rules of the shared package, an unreachable feed is named, the
// switch is off at first and kept, the button appears only while it is on, and the six texts exist in the eight languages.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydra_umc_app_common/hydra_umc_app_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/network/client_prefs.dart';
import 'package:hydra_umc_dsi/ui/widgets/update_notice_tile.dart';
import 'package:hydra_umc_dsi/app_version.dart';
import 'package:hydra_umc_dsi/update/update_notice.dart';

class _Fake implements HttpTransport {
  _Fake(this.status, this.body, {this.fail = false});
  final int status;
  final String body;
  final bool fail;
  final List<HttpRequestData> asked = [];
  bool closed = false;

  @override
  Future<HttpResponseData> send(HttpRequestData request) async {
    asked.add(request);
    if (fail) throw Exception('offline');
    return HttpResponseData(status, body, path: request.path);
  }

  @override
  void close() => closed = true;
}

String _feed(String tag) => jsonEncode({'tag_name': tag, 'html_url': 'https://example.test/releases/tag/$tag', 'assets': []});

Widget host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('checkForNewVersion', () {
    test('asks only for the latest release of this app and names itself', () async {
      final fake = _Fake(200, _feed('v9.0.0'));
      await checkForNewVersion(transport: fake, installed: '1.0.0');
      expect(fake.asked.single.method, 'GET');
      expect(fake.asked.single.url, 'https://api.github.com/repos/JuanenRac/HYDRA-UMC-DSI/releases/latest');
      expect(fake.asked.single.headers['User-Agent'], 'HYDRA-UMC-DSI/1.0.0');
    });

    test('a newer release is available, the same one is up to date', () async {
      expect(await checkForNewVersion(transport: _Fake(200, _feed('v9.0.0')), installed: '1.0.0'), isA<ReleaseAvailable>());
      expect(await checkForNewVersion(transport: _Fake(200, _feed('v1.0.0')), installed: '1.0.0'), isA<ReleaseUpToDate>());
    });

    test('an error status and a failure are the unreachable feed', () async {
      for (final fake in [_Fake(403, '{}'), _Fake(200, '{}', fail: true)]) {
        final result = await checkForNewVersion(transport: fake);
        expect((result as ReleaseFeedFailed).reason, ReleaseFeedProblem.unreachable);
      }
    });

    test('a damaged answer is told apart from an unreachable feed', () async {
      final result = await checkForNewVersion(transport: _Fake(200, 'not json'));
      expect((result as ReleaseFeedFailed).reason, ReleaseFeedProblem.notJson);
    });

    test('the installed version of the app is a stable version', () {
      expect(FeedVersion.parseStable(kAppVersion), isNotNull);
    });
  });

  group('the tile', () {
    testWidgets('off at first, no button, and nothing is read', (tester) async {
      var reads = 0;
      await tester.pumpWidget(host(UpdateNoticeTile(prefs: ClientPrefs(), check: () async {
        reads++;
        return const ReleaseUpToDate();
      })));
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('settings-update-notice'))).value, isFalse);
      expect(find.byKey(const Key('settings-update-check')), findsNothing);
      expect(reads, 0);
    });

    testWidgets('turning it on is kept and shows the button, which reads once per tap', (tester) async {
      var reads = 0;
      await tester.pumpWidget(host(UpdateNoticeTile(prefs: ClientPrefs(), check: () async {
        reads++;
        return ReleaseAvailable(AvailableRelease(
            version: FeedVersion.parseStable('2.0.0')!, name: 'v2.0.0', notes: '', pageUrl: 'https://example.test/r',
            assetName: null, assetUrl: null, signatureUrl: null, digest: null));
      })));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-update-notice')));
      await tester.pumpAndSettle();
      expect(await ClientPrefs().loadUpdateNotice(), isTrue);
      expect(reads, 0);
      await tester.tap(find.byKey(const Key('settings-update-check')));
      await tester.pumpAndSettle();
      expect(reads, 1);
      expect(find.text('Version 2.0.0 is available'), findsOneWidget);
      expect(find.byKey(const Key('settings-update-page')), findsOneWidget);
    });

    testWidgets('says up to date and says when the list could not be read', (tester) async {
      SharedPreferences.setMockInitialValues({'hydra_update_notice': true});
      var answer = _upToDate();
      await tester.pumpWidget(host(UpdateNoticeTile(prefs: ClientPrefs(), check: () async => answer)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-update-check')));
      await tester.pumpAndSettle();
      expect(find.text('This version is up to date'), findsOneWidget);
      answer = const ReleaseFeedFailed(ReleaseFeedProblem.unreachable);
      await tester.tap(find.byKey(const Key('settings-update-check')));
      await tester.pumpAndSettle();
      expect(find.text('The list of releases could not be read'), findsOneWidget);
    });

    testWidgets('turning it off hides the button and the result', (tester) async {
      SharedPreferences.setMockInitialValues({'hydra_update_notice': true});
      await tester.pumpWidget(host(UpdateNoticeTile(prefs: ClientPrefs(), check: () async => const ReleaseUpToDate())));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-update-check')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-update-notice')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-update-check')), findsNothing);
      expect(find.byKey(const Key('settings-update-result')), findsNothing);
      expect(await ClientPrefs().loadUpdateNotice(), isFalse);
    });
  });

  test('the six texts exist in the eight languages and differ from the English one', () {
    final english = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    const keys = [
      'settingsUpdateNotice', 'settingsUpdateNoticeSubtitle', 'settingsUpdateCheckNow',
      'settingsUpdateAvailable', 'settingsUpdateUpToDate', 'settingsUpdateCheckFailed',
    ];
    for (final lang in ['de', 'es', 'fr', 'it', 'ja', 'pt', 'zh']) {
      final arb = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;
      for (final key in keys) {
        expect(arb[key], isA<String>(), reason: '$lang $key');
        expect(arb[key], isNot(english[key]), reason: '$lang $key');
      }
      expect(arb['settingsUpdateAvailable'], contains('{version}'), reason: lang);
    }
  });
}

ReleaseFeedResult _upToDate() => const ReleaseUpToDate();
