// Basic smoke test - confirms the app builds and shows the login screen
// when no session is active, same pattern HYDRA-UMC-IOS-CONTROL's own
// test/widget_test.dart uses (replacing the default Flutter counter
// template `flutter create` generates).

import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/main.dart';

void main() {
  testWidgets('Shows the login screen when not signed in', (WidgetTester tester) async {
    await tester.pumpWidget(const HydraUmcDsiApp());
    await tester.pump();

    expect(find.text('HYDRA-UMC DSI'), findsOneWidget);
    expect(find.text('Server IP'), findsOneWidget);
  });
}
