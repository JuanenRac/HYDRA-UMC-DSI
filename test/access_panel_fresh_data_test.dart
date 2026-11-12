// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/access_panel_fresh_data_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The reservation panel of the control screen reads many fields of the view
// model (who holds the robot, whether a request is on the wire, the limits of
// the model, the jog arming and its countdown, the list of reservations and the
// conditional-write mode). This is a safety screen: whatever the screen does to
// redraw less, the panel must never show a value that was true a moment ago.
// Every field is changed after the panel is drawn and the new value must be on
// the screen at once; the same checks guard a later move of the panel to
// selectors.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/models/access.dart';
import 'package:hydra_umc_dsi/models/contract_v2.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/services/operator_pin.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/widgets/access_panel.dart';
import 'package:hydra_umc_dsi/util/panel_config.dart';

class _Backend implements SecureTokenBackend {
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
}

class _Vm extends RobotViewModel {
  _Vm()
    : super(
        authPrefs: AuthPrefs(secureBackend: _Backend()),
        config: PanelConfig.defaults,
        operatorPin: OperatorPin(backend: _Backend()),
      );
  void poke() => notifyListeners();
}

final DateTime _now = DateTime.utc(2030, 1, 1, 12);

ClaimInfo _claim({
  String owner = 'bob',
  String? controller = 'another-device',
}) => ClaimInfo(
  robotId: 1,
  robotName: 'ARM-1',
  ownerUsername: owner,
  controllerId: controller,
  expiresAt: 0,
);

RobotSafety _safety({bool armRequired = true, DateTime? armedUntil}) =>
    RobotSafety(
      robotId: 1,
      jog: const JogLimits(10, 100),
      bedMaxC: 0,
      armRequired: armRequired,
      armTtlMs: 60000,
      jogArmedUntil: armedUntil?.millisecondsSinceEpoch,
    );

/// The panel drawn the way the control screen draws it: it is rebuilt whenever the view model notifies.
Future<_Vm> _pump(WidgetTester tester) async {
  final vm = _Vm();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ListenableBuilder(
            listenable: vm,
            builder: (context, _) => AccessPanel(vm: vm, robotId: 1, now: _now),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return vm;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(AccessPanel)))!;

bool _enabled(WidgetTester tester, String key) {
  final button = tester.widget<ButtonStyleButton>(find.byKey(ValueKey(key)));
  return button.onPressed != null;
}

void main() {
  testWidgets('the standing of the robot follows the list of reservations', (
    tester,
  ) async {
    final vm = await _pump(tester);
    expect(find.text(_l10n(tester).accessFree), findsOneWidget);
    expect(_enabled(tester, 'access-reserve'), isTrue);
    expect(_enabled(tester, 'access-release'), isFalse);

    vm.claims = [_claim(owner: 'bob')];
    vm.poke();
    await tester.pump();
    expect(find.text(_l10n(tester).accessOther('bob')), findsOneWidget);
    expect(find.text(_l10n(tester).accessFree), findsNothing);
    expect(_enabled(tester, 'access-reserve'), isFalse);

    vm.claims = [_claim(owner: 'carol')];
    vm.poke();
    await tester.pump();
    expect(find.text(_l10n(tester).accessOther('carol')), findsOneWidget);
    expect(find.text(_l10n(tester).accessOther('bob')), findsNothing);

    vm.claims = [_claim(owner: 'bob', controller: vm.controllerId)];
    vm.poke();
    await tester.pump();
    expect(find.text(_l10n(tester).accessMineHere), findsOneWidget);
    expect(_enabled(tester, 'access-release'), isTrue);
    expect(_enabled(tester, 'access-reserve'), isFalse);

    vm.claims = const [];
    vm.poke();
    await tester.pump();
    expect(find.text(_l10n(tester).accessFree), findsOneWidget);
    expect(_enabled(tester, 'access-reserve'), isTrue);
    expect(_enabled(tester, 'access-release'), isFalse);
  });

  testWidgets(
    'a request on the wire disables the buttons at once and enables them again when it ends',
    (tester) async {
      final vm = await _pump(tester);
      expect(_enabled(tester, 'access-reserve'), isTrue);
      vm.accessBusy = true;
      vm.poke();
      await tester.pump();
      expect(_enabled(tester, 'access-reserve'), isFalse);
      vm.accessBusy = false;
      vm.poke();
      await tester.pump();
      expect(_enabled(tester, 'access-reserve'), isTrue);

      vm.claims = [_claim(owner: 'bob', controller: vm.controllerId)];
      vm.accessBusy = true;
      vm.poke();
      await tester.pump();
      expect(_enabled(tester, 'access-release'), isFalse);
    },
  );

  testWidgets(
    'the list shows the reservations as they are now and the conditional mode that is set now',
    (tester) async {
      final vm = await _pump(tester);
      expect(find.text(_l10n(tester).accessListEmpty), findsNothing);
      await tester.tap(find.byKey(const ValueKey('access-list')));
      await tester.pump();
      expect(find.text(_l10n(tester).accessListEmpty), findsOneWidget);

      vm.claims = [_claim(owner: 'bob')];
      vm.poke();
      await tester.pump();
      expect(find.text(_l10n(tester).accessListEmpty), findsNothing);
      expect(
        find.text(_l10n(tester).accessListItem('ARM-1', 'bob')),
        findsOneWidget,
      );

      vm.claims = [
        _claim(owner: 'bob'),
        ClaimInfo(
          robotId: 2,
          robotName: '',
          ownerUsername: 'dave',
          controllerId: null,
          expiresAt: 0,
        ),
      ];
      vm.poke();
      await tester.pump();
      expect(
        find.text(_l10n(tester).accessListItem('#2', 'dave')),
        findsOneWidget,
      );

      SegmentedButton<ConditionalMode> mode() =>
          tester.widget(find.byKey(const ValueKey('access-conditional')));
      expect(mode().selected, {vm.conditionalMode});
      vm.conditionalMode = ConditionalMode.strict;
      vm.poke();
      await tester.pump();
      expect(mode().selected, {ConditionalMode.strict});
      vm.conditionalMode = ConditionalMode.off;
      vm.poke();
      await tester.pump();
      expect(mode().selected, {ConditionalMode.off});
    },
  );

  testWidgets(
    'the jog arming appears only when the server requires it and follows the countdown',
    (tester) async {
      final vm = await _pump(tester);
      expect(find.byKey(const ValueKey('access-arm')), findsNothing);

      vm.safetyByRobot[1] = _safety(armRequired: false);
      vm.poke();
      await tester.pump();
      expect(find.byKey(const ValueKey('access-arm')), findsNothing);

      vm.safetyByRobot[1] = _safety();
      vm.poke();
      await tester.pump();
      expect(find.byKey(const ValueKey('access-arm')), findsOneWidget);
      expect(find.text(_l10n(tester).jogNotArmed), findsOneWidget);
      expect(find.text(_l10n(tester).jogArm), findsOneWidget);

      vm.jogArmedUntil[1] = _now.add(const Duration(seconds: 30));
      vm.poke();
      await tester.pump();
      expect(find.text(_l10n(tester).jogArmed(30)), findsOneWidget);
      expect(find.text(_l10n(tester).jogNotArmed), findsNothing);
      expect(find.text(_l10n(tester).jogDisarm), findsOneWidget);

      vm.jogArmedUntil[1] = _now.add(
        const Duration(seconds: 7, milliseconds: 200),
      );
      vm.poke();
      await tester.pump();
      expect(find.text(_l10n(tester).jogArmed(8)), findsOneWidget);

      // an arming that has run out is not shown as armed
      vm.jogArmedUntil[1] = _now.subtract(const Duration(seconds: 1));
      vm.poke();
      await tester.pump();
      expect(find.text(_l10n(tester).jogNotArmed), findsOneWidget);
      expect(find.text(_l10n(tester).jogArm), findsOneWidget);

      vm.jogArmedUntil.remove(1);
      vm.safetyByRobot.remove(1);
      vm.poke();
      await tester.pump();
      expect(find.byKey(const ValueKey('access-arm')), findsNothing);
    },
  );

  testWidgets('a clock that moves redraws the countdown of the arming', (
    tester,
  ) async {
    final vm = _Vm();
    vm.safetyByRobot[1] = _safety();
    vm.jogArmedUntil[1] = _now.add(const Duration(seconds: 10));
    var now = _now;
    late StateSetter tick;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                tick = setState;
                return AccessPanel(vm: vm, robotId: 1, now: now);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(_l10n(tester).jogArmed(10)), findsOneWidget);
    tick(() => now = _now.add(const Duration(seconds: 4)));
    await tester.pump();
    expect(find.text(_l10n(tester).jogArmed(6)), findsOneWidget);
    tick(() => now = _now.add(const Duration(seconds: 11)));
    await tester.pump();
    expect(find.text(_l10n(tester).jogNotArmed), findsOneWidget);
  });
}
