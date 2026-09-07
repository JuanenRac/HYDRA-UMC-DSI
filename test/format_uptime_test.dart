// Confirms dashboard_screen.dart's formatUptime() matches
// ui/metrics_screen.dart's own private _formatUptime() and
// HYDRA-UMC-ANDROID-CONTROL's own DashboardScreen.kt formatUptime()
// algorithm exactly.

import 'package:flutter_test/flutter_test.dart';
import 'package:hydra_umc_dsi/ui/dashboard_screen.dart';

void main() {
  test('formats under a minute as 0m', () {
    expect(formatUptime(45), '0m');
  });

  test('formats minutes only, no leading hour', () {
    expect(formatUptime(15 * 60), '15m');
  });

  test('formats hours and minutes, no leading day', () {
    expect(formatUptime(2 * 3600 + 5 * 60), '2h 5m');
  });

  test('formats days, hours and minutes', () {
    expect(formatUptime(2 * 86400 + 4 * 3600 + 15 * 60), '2d 4h 15m');
  });

  test('drops the day component when it is exactly zero days', () {
    expect(formatUptime(23 * 3600 + 59 * 60), '23h 59m');
  });
}
