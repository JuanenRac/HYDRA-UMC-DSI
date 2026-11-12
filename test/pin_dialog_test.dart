// =============================================================================
// HYDRA-UMC-DSI - test/pin_dialog_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The dialogs of the operator PIN on the pad: asking for one PIN, checking the current one with the
// counted tries, and setting a new one (typed twice, with the length and digits checked).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/l10n/app_localizations_en.dart';
import 'package:hydra_umc_dsi/services/operator_pin.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/widgets/pin_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _en = AppLocalizationsEn();

/// Pumps an app with one button that runs [action] with a context under the localizations; the result lands in [result].
Future<void> _open<T>(WidgetTester tester, Future<T> Function(BuildContext) action, List<T?> result) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(onPressed: () async => result.add(await action(context)), child: const Text('open')),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.byKey(Key('pin-key-$digit')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('pin-key-ok')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('askPin shows the title, the hint and the error, and returns the digits typed', (tester) async {
    final result = <String?>[];
    await _open<String?>(tester, (context) => askPin(context, 'Title here', hint: 'a hint', error: 'an error'), result);
    expect(find.text('Title here'), findsOneWidget);
    expect(find.text('a hint'), findsOneWidget);
    expect(find.text('an error'), findsOneWidget);
    await _type(tester, '2468');
    expect(result, ['2468']);
  });

  testWidgets('askPin returns null when the person cancels', (tester) async {
    final result = <String?>[];
    await _open<String?>(tester, (context) => askPin(context, 'Title here'), result);
    expect(find.text('a hint'), findsNothing);
    await tester.tap(find.text(_en.playConfirmCancel));
    await tester.pumpAndSettle();
    expect(result, [null]);
  });

  testWidgets('setNewPin refuses a PIN that is too short with the length in the message and asks nothing more', (tester) async {
    final vm = RobotViewModel();
    final result = <String?>[];
    await _open<String?>(tester, (context) => setNewPin(context, vm), result);
    expect(find.text(_en.pinNewTitle), findsOneWidget);
    await _type(tester, '12');
    expect(result, [_en.pinTooShort(vm.panelConfig.pinMinLength)]);
    expect(find.text(_en.pinRepeatTitle), findsNothing);
  });

  testWidgets('setNewPin refuses two different entries and keeps no PIN', (tester) async {
    final vm = RobotViewModel();
    final result = <String?>[];
    await _open<String?>(tester, (context) => setNewPin(context, vm), result);
    await _type(tester, '1234');
    expect(find.text(_en.pinRepeatTitle), findsOneWidget);
    await _type(tester, '4321');
    expect(result, [_en.pinMismatch]);
    expect(vm.pin.check('1234'), PinCheck.notSet);
  });

  testWidgets('setNewPin keeps the PIN after two equal entries and says it was saved', (tester) async {
    final vm = RobotViewModel();
    final result = <String?>[];
    await _open<String?>(tester, (context) => setNewPin(context, vm), result);
    await _type(tester, '1234');
    await _type(tester, '1234');
    expect(result.single, anyOf(_en.pinSaved, _en.pinMemoryOnly));
    expect(vm.pin.check('1234'), PinCheck.accepted);
    expect(vm.pin.check('9999'), PinCheck.wrong);
  });

  testWidgets('setNewPin gives up silently when cancelled on the first pad', (tester) async {
    final vm = RobotViewModel();
    final result = <String?>[];
    await _open<String?>(tester, (context) => setNewPin(context, vm), result);
    await tester.tap(find.text(_en.playConfirmCancel));
    await tester.pumpAndSettle();
    expect(result, [null]);
    expect(vm.pin.check('1234'), PinCheck.notSet);
  });

  testWidgets('confirmCurrentPin accepts the right PIN', (tester) async {
    final vm = RobotViewModel();
    await vm.setOperatorPin('1234');
    final result = <bool?>[];
    await _open<bool>(tester, (context) => confirmCurrentPin(context, vm), result);
    expect(find.text(_en.pinCurrentTitle), findsOneWidget);
    await _type(tester, '1234');
    expect(result, [true]);
  });

  testWidgets('confirmCurrentPin shows the tries left after a wrong PIN and keeps asking until it is right', (tester) async {
    final vm = RobotViewModel();
    await vm.setOperatorPin('1234');
    final result = <bool?>[];
    await _open<bool>(tester, (context) => confirmCurrentPin(context, vm), result);
    await _type(tester, '0000');
    expect(result, isEmpty);
    expect(find.text(_en.lockWrongPin(vm.pin.attemptsLeft)), findsOneWidget);
    await _type(tester, '1234');
    expect(result, [true]);
  });

  testWidgets('confirmCurrentPin returns false when cancelled', (tester) async {
    final vm = RobotViewModel();
    await vm.setOperatorPin('1234');
    final result = <bool?>[];
    await _open<bool>(tester, (context) => confirmCurrentPin(context, vm), result);
    await tester.tap(find.text(_en.playConfirmCancel));
    await tester.pumpAndSettle();
    expect(result, [false]);
  });

  testWidgets('confirmCurrentPin accepts at once when no PIN is set', (tester) async {
    final vm = RobotViewModel();
    final result = <bool?>[];
    await _open<bool>(tester, (context) => confirmCurrentPin(context, vm), result);
    await _type(tester, '5555');
    expect(result, [true]);
  });
}
