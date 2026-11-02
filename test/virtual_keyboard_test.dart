// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/virtual_keyboard_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The on-screen keyboard and the sign-in screen it serves: it types into the
// field touched last, off by default, and in appliance mode the address is not
// the person's to choose.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydra_umc_dsi/l10n/app_localizations.dart';
import 'package:hydra_umc_dsi/network/auth_prefs.dart';
import 'package:hydra_umc_dsi/services/operator_pin.dart';
import 'package:hydra_umc_dsi/state/robot_view_model.dart';
import 'package:hydra_umc_dsi/ui/login_screen.dart';
import 'package:hydra_umc_dsi/ui/widgets/virtual_keyboard.dart';
import 'package:hydra_umc_dsi/util/panel_config.dart';

class _Backend implements SecureTokenBackend {
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
}

Widget _app(Widget home, {RobotViewModel? vm}) {
  final app = MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
  return vm == null ? app : ChangeNotifierProvider<RobotViewModel>.value(value: vm, child: app);
}

RobotViewModel _vm(PanelConfig config) =>
    RobotViewModel(authPrefs: AuthPrefs(secureBackend: _Backend()), config: config, operatorPin: OperatorPin(backend: _Backend()));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the keyboard', () {
    testWidgets('types, shifts for one letter, deletes and takes the symbols', (tester) async {
      final controller = TextEditingController();
      var entered = 0;
      await tester.pumpWidget(_app(Scaffold(body: Column(children: [const Spacer(), VirtualKeyboard(target: () => controller, onEnter: () => entered++)]))));
      Future<void> tap(String key) async {
        await tester.tap(find.byKey(Key(key)));
        await tester.pump();
      }

      await tap('vk-h');
      await tap('vk-shift');
      await tap('vk-i');
      await tap('vk-i');
      expect(controller.text, 'hIi', reason: 'shift lasts for one letter');
      await tap('vk-back');
      await tap('vk-at');
      await tap('vk-1');
      await tap('vk-dot');
      expect(controller.text, 'hI@1.');
      await tap('vk-layer');
      await tap('vk-!');
      expect(controller.text, 'hI@1.!');
      await tap('vk-space');
      expect(controller.text, 'hI@1.! ');
      await tap('vk-enter');
      expect(entered, 1);
    });

    testWidgets('writes where the cursor is, replaces a selection, and does nothing without a field', (tester) async {
      final controller = TextEditingController(text: 'abcd');
      controller.selection = const TextSelection(baseOffset: 1, extentOffset: 3);
      TextEditingController? target = controller;
      await tester.pumpWidget(_app(Scaffold(body: Column(children: [const Spacer(), VirtualKeyboard(target: () => target)]))));
      await tester.tap(find.byKey(const Key('vk-x')));
      await tester.pump();
      expect(controller.text, 'axd');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
      await tester.tap(find.byKey(const Key('vk-back')));
      await tester.pump();
      expect(controller.text, 'ad');
      target = null;
      await tester.tap(find.byKey(const Key('vk-x')));
      await tester.pump();
      expect(controller.text, 'ad');
    });
  });

  group('the sign-in screen', () {
    testWidgets('by default there is no keyboard and the address can be typed', (tester) async {
      final vm = _vm(PanelConfig.defaults);
      addTearDown(vm.dispose);
      await tester.pumpWidget(_app(const LoginScreen(), vm: vm));
      expect(find.byKey(const Key('virtual-keyboard')), findsNothing);
      expect(find.byType(TextField), findsNWidgets(4));
    });

    testWidgets('with the keyboard on, it types into the field touched last', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final vm = _vm(const PanelConfig(virtualKeyboard: true));
      addTearDown(vm.dispose);
      await tester.pumpWidget(_app(const LoginScreen(), vm: vm));
      expect(find.byKey(const Key('virtual-keyboard')), findsOneWidget);
      final fields = find.byType(TextField);
      // host, port, user, password
      await tester.tap(fields.at(2));
      await tester.pump();
      await tester.tap(find.byKey(const Key('vk-a')));
      await tester.tap(find.byKey(const Key('vk-d')));
      await tester.pump();
      expect(tester.widget<TextField>(fields.at(2)).controller!.text, 'ad');
      await tester.tap(fields.at(3));
      await tester.pump();
      await tester.tap(find.byKey(const Key('vk-7')));
      await tester.pump();
      expect(tester.widget<TextField>(fields.at(3)).controller!.text, '7');
      expect(tester.widget<TextField>(fields.at(2)).controller!.text, 'ad');
    });

    testWidgets('in appliance mode the address is not offered and the screen still fits with the keyboard', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final vm = _vm(const PanelConfig(appliance: true, virtualKeyboard: true));
      addTearDown(vm.dispose);
      await tester.pumpWidget(_app(const LoginScreen(), vm: vm));
      expect(find.byType(TextField), findsNWidgets(2), reason: 'user and password only');
      expect(find.byIcon(Icons.wifi_find), findsNothing, reason: 'no scan: the server is this machine');
      expect(tester.takeException(), isNull);
    });
  });
}
