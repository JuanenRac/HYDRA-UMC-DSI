// The backlight control against a made-up sysfs folder: the brightness is a percentage of the range the driver reports, and every failure answers false.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/services/backlight.dart';

void main() {
  late Directory sysfs;

  setUp(() {
    sysfs = Directory.systemTemp.createTempSync('backlight_sysfs_');
  });

  tearDown(() {
    if (sysfs.existsSync()) sysfs.deleteSync(recursive: true);
  });

  Directory device(String name, {String max = '255', String start = '0'}) {
    final dir = Directory('${sysfs.path}/$name')..createSync();
    if (max.isNotEmpty) File('${dir.path}/max_brightness').writeAsStringSync('$max\n');
    File('${dir.path}/brightness').writeAsStringSync(start);
    return dir;
  }

  String written(Directory dir) => File('${dir.path}/brightness').readAsStringSync();

  BacklightControl control() => BacklightControl(basePath: sysfs.path, linuxOnly: true);

  test('the percentage is taken of the range the driver reports, not of 255', () async {
    final wide = device('panel_wide', max: '255');
    expect(await control().setBrightnessPercent(60), isTrue);
    expect(written(wide), '153');
    wide.deleteSync(recursive: true);
    final narrow = device('panel_narrow', max: '31');
    expect(await control().setBrightnessPercent(100), isTrue);
    expect(written(narrow), '31');
    expect(await control().setBrightnessPercent(30), isTrue);
    expect(written(narrow), '9');
  });

  test('a percentage outside 0 to 100 is held at the ends', () async {
    final dir = device('panel');
    final backlight = control();
    expect(await backlight.setBrightnessPercent(250), isTrue);
    expect(written(dir), '255');
    expect(await backlight.setBrightnessPercent(-40), isTrue);
    expect(written(dir), '0');
  });

  test('without a backlight folder, or with an empty one, nothing is written and the answer is false', () async {
    expect(await BacklightControl(basePath: '${sysfs.path}/missing', linuxOnly: true).setBrightnessPercent(50), isFalse);
    expect(await control().setBrightnessPercent(50), isFalse);
  });

  test('on a host that is not Linux the control does nothing', () async {
    final dir = device('panel');
    expect(await BacklightControl(basePath: sysfs.path, linuxOnly: false).setBrightnessPercent(50), isFalse);
    expect(written(dir), '0');
  });

  test('a driver whose range is missing, unreadable or zero is not driven', () async {
    final noMax = device('panel_a', max: '');
    expect(await control().setBrightnessPercent(50), isFalse);
    expect(written(noMax), '0');
    noMax.deleteSync(recursive: true);
    final garbage = device('panel_b', max: 'abc');
    expect(await control().setBrightnessPercent(50), isFalse);
    garbage.deleteSync(recursive: true);
    final zero = device('panel_c', max: '0');
    expect(await control().setBrightnessPercent(50), isFalse);
    expect(written(zero), '0');
  });

  test('a brightness file that cannot be written gives false instead of an error', () async {
    final dir = Directory('${sysfs.path}/panel')..createSync();
    File('${dir.path}/max_brightness').writeAsStringSync('100');
    Directory('${dir.path}/brightness').createSync(); // a folder where the file should be: the write fails
    expect(await control().setBrightnessPercent(50), isFalse);
  });

  test('the device found first is kept for the next calls', () async {
    final dir = device('panel');
    final backlight = control();
    expect(await backlight.setBrightnessPercent(10), isTrue);
    dir.deleteSync(recursive: true);
    device('other', max: '10');
    expect(await backlight.setBrightnessPercent(50), isFalse, reason: 'the cached folder is gone; the control does not hop to another panel');
  });

  test('the schedule gives full light in the working day, less in the evening and least at night', () {
    expect(<int, int>{for (final h in [0, 6, 7, 18, 19, 21, 22, 23]) h: brightnessPercentForHour(h)},
        {0: 30, 6: 30, 7: 100, 18: 100, 19: 60, 21: 60, 22: 30, 23: 30});
  });
}
