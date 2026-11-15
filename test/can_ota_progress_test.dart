// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/can_ota_progress_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The live progress of a CAN flash cycle: an unknown phase leaves what is shown as it was in the view model, and the card shows the phase, the percent,
// the pages and the reason in the language chosen. The delivery through the socket is in can_ota_socket_test.dart (a file without the widget binding,
// which answers every HTTP request with 400).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/models/can_ota_progress.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/dashboard_screen.dart';

class _FakeSecureBackend implements SecureTokenBackend {
  final Map<String, String> store = {};
  @override
  Future<void> write(String key, String value) async => store[key] = value;
  @override
  Future<String?> read(String key) async => store[key];
  @override
  Future<void> delete(String key) async => store.remove(key);
}

Map<String, dynamic> _message(Map<String, Object?> payload) => {'type': 'canota_progress', 'payload': payload};

Widget _card(CanOtaProgress progress, Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: CanOtaProgressCard(progress: progress)),
    );

void main() {
  group('the view model', () {
    test('keeps the last progress, ignores a phase it does not know and starts empty', () async {
      SharedPreferences.setMockInitialValues({});
      final vm = RobotViewModel(authPrefs: AuthPrefs(secureBackend: _FakeSecureBackend()));
      addTearDown(vm.dispose);
      expect(vm.canOtaProgressListenable.value, isNull);
      vm.applyCanOtaProgress(_message({'phase': 'erasing_fram'}));
      expect(vm.canOtaProgressListenable.value?.phase, CanOtaPhase.erasingFram);
      vm.applyCanOtaProgress(_message({'phase': 'dancing'}));
      expect(vm.canOtaProgressListenable.value?.phase, CanOtaPhase.erasingFram, reason: 'an unknown phase changes nothing');
      vm.applyCanOtaProgress({'type': 'canota_progress'});
      expect(vm.canOtaProgressListenable.value?.phase, CanOtaPhase.erasingFram, reason: 'a message with no payload changes nothing');
      vm.applyCanOtaProgress(_message({'phase': 'done', 'percent': 100}));
      expect(vm.canOtaProgressListenable.value?.finished, isTrue);
    });
  });

  group('the card', () {
    testWidgets('shows the phase, the percent and the pages while the image is sent', (tester) async {
      await tester.pumpWidget(_card(const CanOtaProgress(phase: CanOtaPhase.transferring, percent: 40, pagesSent: 8, pagesTotal: 20), const Locale('en')));
      await tester.pump();
      expect(find.text('CAN flash'), findsOneWidget);
      expect(find.text('Sending the image'), findsOneWidget);
      expect(find.text('40 %'), findsOneWidget);
      expect(find.text('8 of 20 pages'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows no bar and no pages when the server sent no numbers, and the reason of a failure', (tester) async {
      await tester.pumpWidget(_card(const CanOtaProgress(phase: CanOtaPhase.error, error: 'verify failed'), const Locale('en')));
      await tester.pump();
      expect(find.text('Flash failed'), findsOneWidget);
      expect(find.text('Reason: verify failed'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('pages'), findsNothing);
    });

    testWidgets('does not show the pages outside the transfer', (tester) async {
      await tester.pumpWidget(_card(const CanOtaProgress(phase: CanOtaPhase.verifying, percent: 90, pagesSent: 20, pagesTotal: 20), const Locale('en')));
      await tester.pump();
      expect(find.text('Verifying the image'), findsOneWidget);
      expect(find.textContaining('pages'), findsNothing);
    });

    testWidgets('has a text for every phase in all eight languages', (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        late AppLocalizations l10n;
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          }),
        ));
        await tester.pump();
        final texts = CanOtaPhase.values.map((phase) => canOtaPhaseText(l10n, phase)).toSet();
        expect(texts.length, CanOtaPhase.values.length, reason: 'every phase has its own text in ${locale.languageCode}');
        expect(texts.every((t) => t.trim().isNotEmpty), isTrue);
        expect(l10n.canOtaPages(3, 9), contains('3'));
        expect(l10n.canOtaError('x'), contains('x'));
      }
    });
  });
}
