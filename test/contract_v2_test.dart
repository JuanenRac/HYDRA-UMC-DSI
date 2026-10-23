// =============================================================================
// HYDRA-UMC DSI (Flutter) - test/contract_v2_test.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// Conditional writes, the atomic table move and the audit record: pure rules.
// =============================================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:hydra_umc_dsi/models/access.dart';
import 'package:hydra_umc_dsi/models/contract_v2.dart';
import 'package:hydra_umc_dsi/models/sha256.dart';

const String _genesis = '0000000000000000000000000000000000000000000000000000000000000000';

/// Lines written the way the server writes them: compact JSON, the hash of the line without `hash`, which is added last.
List<String> _chain(int count, {int start = 1, String username = 'ana'}) {
  final lines = <String>[];
  var prev = _genesis;
  for (var i = 0; i < count; i++) {
    final body =
        '{"seq":${start + i},"ts":"2030-01-01T00:00:0$i.000Z","type":"claim","outcome":"ok","username":"$username","controllerId":"w1","ip":"10.0.0.5","robotId":1,"detail":{"ttlMs":60000,"note":"a } and a ] and a \\" inside"},"prev":"$prev"}';
    final digest = sha256Hex(utf8.encode(body));
    lines.add('${body.substring(0, body.length - 1)},"hash":"$digest"}');
    prev = digest;
  }
  return lines;
}

String _answer(List<String> lines, [String extra = '']) => '{"enabled":true,"lockedOff":false,"entries":[${lines.join(',')}]$extra}';

void main() {
  group('SHA-256', () {
    test('known vectors', () {
      expect(sha256Hex(utf8.encode('')), 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
      expect(sha256Hex(utf8.encode('abc')), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
      expect(
        sha256Hex(utf8.encode('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq')),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
      expect(sha256Hex(utf8.encode('a' * 1000)), '41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3');
    });

    test('text with accents is hashed as UTF-8', () {
      expect(sha256Hex(utf8.encode('ñ')), sha256Hex([0xc3, 0xb1]));
    });
  });

  group('which commands carry If-Match', () {
    test('STOP never does, whatever the mode', () {
      for (final mode in ConditionalMode.values) {
        expect(isConditional(mode, 'stop'), isFalse, reason: mode.name);
      }
    });

    test('standard leaves out the commands that repeat many times a second', () {
      expect(isConditional(ConditionalMode.standard, 'jog'), isFalse);
      expect(isConditional(ConditionalMode.standard, 'speed'), isFalse);
      expect(isConditional(ConditionalMode.standard, 'table'), isTrue);
      expect(isConditional(ConditionalMode.standard, 'claim'), isTrue);
      expect(isConditional(ConditionalMode.standard, 'play'), isTrue);
    });

    test('strict checks everything but STOP and off checks nothing', () {
      expect(isConditional(ConditionalMode.strict, 'jog'), isTrue);
      expect(isConditional(ConditionalMode.off, 'table'), isFalse);
    });

    test('the mode is read from its key and falls back to standard', () {
      expect(ConditionalMode.fromKey('strict'), ConditionalMode.strict);
      expect(ConditionalMode.fromKey('off'), ConditionalMode.off);
      expect(ConditionalMode.fromKey('nonsense'), ConditionalMode.standard);
      expect(ConditionalMode.fromKey(null), ConditionalMode.standard);
    });
  });

  group('the revision', () {
    test('is read from a body and nothing else', () {
      expect(revisionOf({'revision': 'abc123'}), 'abc123');
      expect(revisionOf({'revision': 12}), isNull);
      expect(revisionOf({'revision': 'has space'}), isNull);
      expect(revisionOf({'revision': null}), isNull);
      expect(revisionOf(null), isNull);
      expect(revisionOf('text'), isNull);
      expect(ifMatchHeader('abc'), '"abc"');
    });

    test('a reservation carries when the jog of its robot is armed', () {
      expect(ClaimInfo.listFromJson({'claims': [{'robotId': 1, 'jogArmedUntil': 5000}]}).single.jogArmedUntil, 5000);
      expect(ClaimInfo.listFromJson({'claims': [{'robotId': 1, 'jogArmedUntil': null}]}).single.jogArmedUntil, isNull);
    });
  });

  group('the tracker', () {
    test('nothing is sent until a revision is known and then the last one', () {
      final tracker = RevisionTracker();
      final first = tracker.begin(1, 'play');
      expect(first.ifMatch, isNull);
      tracker.finish(1, first.seq, 'r1');
      expect(tracker.known(1), 'r1');
      expect(tracker.begin(1, 'play').ifMatch, '"r1"');
    });

    test('nothing is sent while another write to the same robot is on its way', () {
      final tracker = RevisionTracker(() => ConditionalMode.strict);
      tracker.learn(1, 'r1');
      final a = tracker.begin(1, 'table');
      final b = tracker.begin(1, 'table');
      expect(a.ifMatch, '"r1"');
      expect(b.ifMatch, isNull);
      tracker.finish(1, a.seq, 'r2');
      tracker.finish(1, b.seq, 'r3');
      expect(tracker.known(1), 'r3');
    });

    test('answers that come back out of order keep the newest revision', () {
      final tracker = RevisionTracker(() => ConditionalMode.strict);
      final a = tracker.begin(1, 'play');
      final b = tracker.begin(1, 'play');
      tracker.finish(1, b.seq, 'newer');
      tracker.finish(1, a.seq, 'older');
      expect(tracker.known(1), 'newer');
    });

    test('an answer without a revision forgets what was known', () {
      final tracker = RevisionTracker();
      tracker.learn(1, 'r1');
      final t = tracker.begin(1, 'play');
      tracker.finish(1, t.seq, null);
      expect(tracker.known(1), isNull);
    });

    test('robots are independent, a robot is the same as a number or as text, and the mode is read each time', () {
      var mode = ConditionalMode.standard;
      final tracker = RevisionTracker(() => mode);
      tracker.learn(1, 'r1');
      expect(tracker.begin(2, 'play').ifMatch, isNull);
      expect(tracker.known('1'), 'r1');
      expect(tracker.begin(1, 'play').ifMatch, '"r1"');
      tracker.finish(1, 1, 'r1');
      mode = ConditionalMode.off;
      expect(tracker.begin(1, 'play').ifMatch, isNull);
      tracker.forget();
      expect(tracker.known(1), isNull);
    });
  });

  group('the table move', () {
    test('parameters need numbers and a known mode', () {
      final params = tableParams(10, 20, 'absolute')!;
      expect(params, {'x': 10.0, 'y': 20.0, 'mode': 'absolute'});
      expect(tableParams(1, 2, 'relative', rz: 5)!['rz'], 5.0);
      expect(tableParams(double.nan, 1, 'absolute'), isNull);
      expect(tableParams(1, double.infinity, 'absolute'), isNull);
      expect(tableParams(1, 2, 'sideways'), isNull);
    });

    test('a relative move is bounded by the largest jog and an absolute one by the largest position', () {
      const limits = JogLimits(100, 1000);
      expect(tableLimitExceeded(tableParams(100, 0, 'relative')!, limits), isNull);
      expect(tableLimitExceeded(tableParams(0, -101, 'relative')!, limits), 100);
      expect(tableLimitExceeded(tableParams(1000, -1000, 'absolute')!, limits), isNull);
      expect(tableLimitExceeded(tableParams(1001, 0, 'absolute')!, limits), 1000);
    });

    test('a relative move is also bounded by where it ends, and unknown limits decide nothing', () {
      const limits = JogLimits(100, 1000);
      expect(tableLimitExceeded(tableParams(50, 0, 'relative')!, limits, currentX: 980), 1000);
      expect(tableLimitExceeded(tableParams(50, 0, 'relative')!, limits, currentX: 900), isNull);
      expect(tableLimitExceeded(tableParams(5000, 0, 'absolute')!, null), isNull);
    });

    test('an older server is recognised by its answer', () {
      expect(isUnknownCommandAnswer(400, null, 'unknown command'), isTrue);
      expect(isUnknownCommandAnswer(400, 'table-invalid', 'x and y must be finite numbers'), isFalse);
      expect(isUnknownCommandAnswer(500, null, 'unknown command'), isFalse);
    });

    test('the move turned into the jogs it did before', () {
      final absolute = tableAsJogs(tableParams(10, 20, 'absolute')!);
      expect(absolute.length, 2);
      expect(absolute.first, {'axis': 'x', 'amount': 10.0, 'target': 'xytable', 'absolute': true});
      final relative = tableAsJogs(tableParams(2, 0, 'relative')!);
      expect(relative, [
        {'axis': 'x', 'amount': 2.0, 'target': 'xytable'},
      ]);
    });
  });

  group('the audit record', () {
    test('the lines are split exactly as the server wrote them, even with braces and quotes inside strings', () {
      final lines = _chain(3);
      expect(AuditRecord.splitEntries(_answer(lines, ',"verification":{"ok":true,"entries":3}')), lines);
      expect(AuditRecord.splitEntries('{"enabled":true,"entries":[]}'), isEmpty);
      expect(AuditRecord.splitEntries('not json'), isEmpty);
    });

    test('an entries key inside a string or a nested object is not the list', () {
      const body = r'{"note":"\"entries\":[{\"x\":1}]","nested":{"entries":[{"y":2}]},"entries":[{"seq":1}]}';
      expect(AuditRecord.splitEntries(body), ['{"seq":1}']);
    });

    test('the answer is read with its fields and the verdict of the server', () {
      final read = AuditRecord.parse(_answer(_chain(2), ',"verification":{"ok":false,"entries":2,"brokenAtSeq":2,"reason":"a line was changed"}'));
      expect(read.enabled, isTrue);
      expect(read.lines.length, 2);
      expect(read.lines.first.username, 'ana');
      expect(read.lines.first.robotId, 1);
      expect(read.lines.first.detail, contains('ttlMs=60000'));
      expect(read.lines.first.hashed, isNotNull);
      expect(read.verification!.ok, isFalse);
      expect(read.verification!.brokenAtSeq, 2);
      expect(read.verification!.reason, 'a line was changed');
      final off = AuditRecord.parse('{"enabled":false,"lockedOff":true,"entries":[]}');
      expect(off.enabled, isFalse);
      expect(off.lockedOff, isTrue);
      expect(AuditRecord.parse('not json').lines, isEmpty);
    });

    test('an intact chain passes, and a window in the middle of the record too', () {
      final check = AuditRecord.checkChain(AuditRecord.parse(_answer(_chain(5))).lines);
      expect(check.ok, isTrue);
      expect(check.checked, 5);
      expect(check.links, 4);
      expect(check.gaps, 0);
      expect(AuditRecord.checkChain(AuditRecord.parse(_answer(_chain(4, start: 100))).lines).ok, isTrue);
    });

    test('a changed line is found', () {
      final lines = _chain(4);
      lines[2] = lines[2].replaceFirst('"username":"ana"', '"username":"mallory"');
      final check = AuditRecord.checkChain(AuditRecord.parse(_answer(lines)).lines);
      expect(check.ok, isFalse);
      expect(check.brokenAtSeq, 3);
      expect(check.reason, 'changed');
    });

    test('a replaced line whose successor still names the old one is found', () {
      final lines = _chain(3);
      final body = '${lines[1].substring(0, lines[1].indexOf(',"hash":"'))}}'.replaceFirst('"username":"ana"', '"username":"someone-else"');
      final replaced = '${body.substring(0, body.length - 1)},"hash":"${sha256Hex(utf8.encode(body))}"}';
      final check = AuditRecord.checkChain(AuditRecord.parse(_answer([lines[0], replaced, lines[2]])).lines);
      expect(check.ok, isFalse);
      expect(check.brokenAtSeq, 3);
      expect(check.reason, 'link');
    });

    test('a filtered view is not called broken, its holes are only counted', () {
      final lines = _chain(6);
      final check = AuditRecord.checkChain(AuditRecord.parse(_answer([lines[0], lines[2], lines[5]])).lines);
      expect(check.ok, isTrue);
      expect(check.links, 0);
      expect(check.gaps, 2);
    });

    test('a line that cannot be re-read byte for byte is counted, not called broken', () {
      final pretty = _chain(1)[0].replaceAll('","', '",\n"');
      final check = AuditRecord.checkChain(AuditRecord.parse(_answer([pretty])).lines);
      expect(check.ok, isTrue);
      expect(check.unreadable, 1);
    });

    test('the query string keeps the limit in range and only known types', () {
      expect(AuditRecord.query(), '');
      expect(AuditRecord.query(limit: 5000, type: 'claim', robotId: 2, verify: true), '?limit=1000&type=claim&robotId=2&verify=1');
      expect(AuditRecord.query(limit: 0), '?limit=1');
      expect(AuditRecord.query(limit: 100, type: 'no-such-type'), '?limit=100');
      expect(AuditRecord.query(limit: 10, format: 'jsonl'), '?limit=10&format=jsonl');
    });
  });
}
