// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/stop_guard_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// With any dialog or menu open, one press on the global STOP reaches the
// server and the window stays open; no dialog reaches the corner of the STOP.
// Before the guard the barrier of the window took the press.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/main.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/widgets/stop_guard.dart';

class _Backend implements SecureTokenBackend {
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
}

class _CountingModel extends RobotViewModel {
  _CountingModel() : super(authPrefs: AuthPrefs(secureBackend: _Backend()));

  int stops = 0;

  @override
  Future<void> stopAll() async => stops++;
}

const _stop = Key('stop-guard');

class _Harness {
  final _CountingModel vm = _CountingModel();
  final StopGuardObserver observer = StopGuardObserver();
  final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();

  Future<void> pump(WidgetTester tester, {bool signedIn = true}) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(vm.dispose);
    vm.isLoggedIn = signedIn;
    await tester.pumpWidget(
      ChangeNotifierProvider<RobotViewModel>.value(
        value: vm,
        child: MaterialApp(
          navigatorKey: navigator,
          navigatorObservers: [observer],
          theme: ThemeData(dialogTheme: const DialogThemeData(insetPadding: stopGuardDialogInsets)),
          builder: (context, child) => StopGuard(observer: observer, child: child!),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
  }

  BuildContext get context => navigator.currentContext!;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('with a dialog of any size open, one press stops and the dialog stays', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    expect(find.byKey(_stop), findsNothing);

    for (final dismissible in [true, false]) {
      for (final huge in [false, true]) {
        showDialog<void>(
          context: harness.context,
          barrierDismissible: dismissible,
          builder: (_) => AlertDialog(
            title: const Text('question'),
            content: SizedBox(width: huge ? 3000 : 200, height: huge ? 3000 : 40),
          ),
        );
        await tester.pumpAndSettle();
        final window = tester.getRect(find.descendant(of: find.byType(Dialog), matching: find.byType(Material)).first);
        expect(window.overlaps(tester.getRect(find.byKey(_stop))), isFalse, reason: 'dismissible=$dismissible huge=$huge');

        final before = harness.vm.stops;
        await tester.tap(find.byKey(_stop));
        await tester.pumpAndSettle();
        expect(harness.vm.stops, before + 1, reason: 'dismissible=$dismissible huge=$huge');
        expect(find.text('question'), findsOneWidget);

        harness.navigator.currentState!.pop();
        await tester.pumpAndSettle();
        expect(find.byKey(_stop), findsNothing);
      }
    }
  });

  testWidgets('with two dialogs the STOP stays until the last one is closed', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    for (var i = 0; i < 2; i++) {
      showDialog<void>(context: harness.context, builder: (_) => const AlertDialog(title: Text('question')));
      await tester.pumpAndSettle();
    }
    harness.navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_stop));
    await tester.pumpAndSettle();
    expect(harness.vm.stops, 1);
    harness.navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_stop), findsNothing);
  });

  testWidgets('with a menu open, one press stops', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    showMenu<int>(
      context: harness.context,
      position: const RelativeRect.fromLTRB(1200, 0, 0, 0),
      items: const [PopupMenuItem<int>(value: 1, child: Text('entry'))],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_stop));
    await tester.pumpAndSettle();
    expect(harness.vm.stops, 1);
    expect(find.text('entry'), findsOneWidget);
  });

  testWidgets('before sign-in no STOP is added over a dialog', (tester) async {
    final harness = _Harness();
    await harness.pump(tester, signedIn: false);
    showDialog<void>(context: harness.context, builder: (_) => const AlertDialog(title: Text('question')));
    await tester.pumpAndSettle();
    expect(find.byKey(_stop), findsNothing);
  });

  testWidgets('the app itself carries the guard', (tester) async {
    await tester.pumpWidget(const HydraUmcDsiApp());
    await tester.pump();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.navigatorObservers!.whereType<StopGuardObserver>(), hasLength(1));
    expect(app.theme!.dialogTheme.insetPadding, stopGuardDialogInsets);
    expect(find.byType(StopGuard), findsOneWidget);
  });
}
