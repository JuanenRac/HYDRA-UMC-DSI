// =============================================================================
// HYDRA-UMC CONTROL (DSI/Flutter) - models/contract_v2.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The second contract of the server, as pure data and rules with no network and
// no widgets:
//   - conditional writes: every robot has a revision (GET /api/robot/:id, and
//     every answer of a command, a reservation or a release). A write that sends
//     it back as If-Match is refused with 412 when the robot changed in between,
//     so this app never overwrites what someone else did to the robot without
//     knowing it. [RevisionTracker] keeps the last revision seen and decides when
//     it is sent;
//   - the `table` command moves the XY table in one request: [tableParams],
//     [tableLimitExceeded] and, for a server that predates it, [tableAsJogs];
//   - the audit record (GET /api/audit, administrators only) is an append-only
//     chain of SHA-256 hashes: [AuditRecord] reads it and checks the chain of the
//     lines it was given.
// =============================================================================

import 'dart:convert';

import 'access.dart';
import 'sha256.dart';

// ---- conditional writes -----------------------------------------------------

/// Which writes carry If-Match. The default is [standard].
enum ConditionalMode {
  /// Nothing is checked.
  off,

  /// Reservations, the table and the one-off commands; the continuous ones (jog, speed) go unchecked.
  standard,

  /// Every command except STOP.
  strict;

  String get key => name;

  static ConditionalMode fromKey(String? key) {
    for (final mode in values) {
      if (mode.name == key) return mode;
    }
    return standard;
  }
}

/// Commands sent many times a second while a control is held: a revision can not follow them.
const Set<String> continuousCommands = {'jog', 'speed', 'jogStep'};

/// Whether a command carries If-Match in a mode. Reservations are `claim` and `release`. STOP never does.
bool isConditional(ConditionalMode mode, String command) {
  if (command == 'stop' || mode == ConditionalMode.off) return false;
  if (mode == ConditionalMode.strict) return true;
  return !continuousCommands.contains(command);
}

final RegExp _revisionPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

/// The revision in the body of an answer (`revision`), or null.
String? revisionOf(Object? body) {
  if (body is! Map) return null;
  final value = body['revision'];
  return value is String && _revisionPattern.hasMatch(value) ? value : null;
}

/// The value of the If-Match header for a revision (quoted, as an ETag is).
String ifMatchHeader(String revision) => '"$revision"';

/// What [RevisionTracker.begin] gives back: the header to send (null for none) and the number of this write.
class RevisionTicket {
  final String? ifMatch;
  final int seq;
  const RevisionTicket(this.ifMatch, this.seq);
}

/// The last revision seen of each robot of one server. Call [begin] before a write and [finish] when it was
/// answered. It sends nothing when no revision is known (the first write learns it), when another write to the
/// same robot is still on its way (its answer is what makes the revision stale, not a change by someone else),
/// or when the mode says the command is not checked.
class RevisionTracker {
  RevisionTracker([ConditionalMode Function()? mode]) : _mode = mode ?? (() => ConditionalMode.standard);

  final ConditionalMode Function() _mode;
  int _counter = 0;
  final Map<String, (String, int)> _known = {};
  final Map<String, int> _inFlight = {};

  RevisionTicket begin(dynamic robotId, String command) {
    final key = '$robotId';
    _counter += 1;
    final seq = _counter;
    final busy = (_inFlight[key] ?? 0) > 0;
    _inFlight[key] = (_inFlight[key] ?? 0) + 1;
    final entry = _known[key];
    final ifMatch = !busy && entry != null && isConditional(_mode(), command) ? ifMatchHeader(entry.$1) : null;
    return RevisionTicket(ifMatch, seq);
  }

  /// The write was answered: keep the revision it carried (when it is the newest answer) and stop counting it.
  void finish(dynamic robotId, int seq, String? revision) {
    final key = '$robotId';
    final left = (_inFlight[key] ?? 1) - 1;
    if (left <= 0) {
      _inFlight.remove(key);
    } else {
      _inFlight[key] = left;
    }
    if (revision == null) {
      // An answer without a revision (a refusal, an older server): what was known may be stale now.
      if (left <= 0) _known.remove(key);
      return;
    }
    final entry = _known[key];
    if (entry == null || seq >= entry.$2) _known[key] = (revision, seq);
  }

  /// A revision learned some other way (the 412 answer, GET /api/robot/:id).
  void learn(dynamic robotId, String? revision) {
    final key = '$robotId';
    if (revision == null) {
      _known.remove(key);
      return;
    }
    _counter += 1;
    _known[key] = (revision, _counter);
  }

  void forget([dynamic robotId]) {
    if (robotId == null) {
      _known.clear();
    } else {
      _known.remove('$robotId');
    }
  }

  String? known(dynamic robotId) => _known['$robotId']?.$1;
}

/// One robot as GET /api/robot/:id gives it, with its revision (null from a server that predates revisions).
class RobotRead {
  final Map<String, dynamic> robot;
  final String? revision;
  const RobotRead(this.robot, this.revision);
}

// ---- the atomic move of the XY table ----------------------------------------

bool _finite(num value) => !value.isNaN && !value.isInfinite;

/// The parameters of a table move, or null when they are not numbers. [mode] is `absolute` or `relative`.
Map<String, dynamic>? tableParams(double x, double y, String mode, {double? rz}) {
  if (!_finite(x) || !_finite(y) || (rz != null && !_finite(rz)) || (mode != 'absolute' && mode != 'relative')) return null;
  return {'x': x, 'y': y, 'mode': mode, 'rz': ?rz};
}

/// The limit a table move exceeds, or null when it is within [limits] (or the limits are not known: the server
/// then decides). Every number of a relative move is bounded by the largest jog, every number of an absolute move
/// by the largest position, and the position a relative move ends in by the largest position too.
double? tableLimitExceeded(Map<String, dynamic> params, JogLimits? limits, {double currentX = 0, double currentY = 0}) {
  if (limits == null) return null;
  final relative = params['mode'] == 'relative';
  final limit = relative ? limits.maxAmount : limits.maxAbsolute;
  double number(Object? v) => v is num ? v.toDouble() : double.nan;
  final x = number(params['x']);
  final y = number(params['y']);
  final values = [x, y, if (params.containsKey('rz')) number(params['rz'])];
  for (final value in values) {
    if (!_finite(value) || value.abs() > limit) return limit;
  }
  if (relative && ((currentX + x).abs() > limits.maxAbsolute || (currentY + y).abs() > limits.maxAbsolute)) {
    return limits.maxAbsolute;
  }
  return null;
}

/// The jogs that did the same on a server without the table command (one per axis that moves; no rotation).
List<Map<String, dynamic>> tableAsJogs(Map<String, dynamic> params) {
  final absolute = params['mode'] != 'relative';
  final jogs = <Map<String, dynamic>>[];
  for (final axis in const ['x', 'y']) {
    final amount = params[axis];
    if (amount is! num || !_finite(amount)) continue;
    if (!absolute && amount == 0) continue;
    jogs.add({'axis': axis, 'amount': amount, 'target': 'xytable', if (absolute) 'absolute': true});
  }
  return jogs;
}

/// An older server answers 400 "unknown command" to a command it does not have.
bool isUnknownCommandAnswer(int? statusCode, String? code, String? serverMessage) =>
    statusCode == 400 && code == null && (serverMessage ?? '').toLowerCase().contains('unknown command');

// ---- the audit record --------------------------------------------------------

/// One line of the audit record.
class AuditLine {
  final int seq;
  final String ts;
  final String type;
  final String outcome;
  final String? username;
  final String? controllerId;
  final String? ip;
  final int? robotId;

  /// The detail as `key=value` pairs, in key order.
  final String detail;
  final String prev;
  final String hash;

  /// The SHA-256 of the line as the server wrote it, without its hash; null when the line could not be re-read byte for byte.
  final String? hashed;

  const AuditLine({
    required this.seq,
    required this.ts,
    required this.type,
    required this.outcome,
    required this.username,
    required this.controllerId,
    required this.ip,
    required this.robotId,
    required this.detail,
    required this.prev,
    required this.hash,
    required this.hashed,
  });
}

/// What the server says about the whole record when asked (`?verify=1`).
class AuditVerdict {
  final bool ok;
  final int entries;
  final int? brokenAtSeq;
  final String? reason;
  const AuditVerdict(this.ok, this.entries, this.brokenAtSeq, this.reason);
}

class AuditRead {
  final bool enabled;
  final bool lockedOff;
  final List<AuditLine> lines;
  final AuditVerdict? verification;
  const AuditRead(this.enabled, this.lockedOff, this.lines, this.verification);
}

/// The outcome of checking the lines this app was given. [reason] is `changed` or `link` when the chain is broken.
class ChainCheck {
  final bool ok;
  final int checked;
  final int links;
  final int gaps;
  final int unreadable;
  final int? brokenAtSeq;
  final String? reason;
  const ChainCheck({
    required this.ok,
    required this.checked,
    required this.links,
    required this.gaps,
    this.unreadable = 0,
    this.brokenAtSeq,
    this.reason,
  });
}

class AuditRecord {
  AuditRecord._();

  /// The types of line the server writes (the filter of the screen).
  static const List<String> types = ['claim', 'force-claim', 'release', 'force-release', 'jog-arm', 'safety-limits', 'stop-all'];

  /// The sizes of the window of lines the screen offers (the server gives 1 to 1000).
  static const List<int> limits = [50, 100, 250, 1000];

  static final RegExp _hashSuffix = RegExp(r',"hash":"([0-9a-f]{64})"\}$');

  /// The raw text of each object of the top-level `entries` array, exactly as the server sent them: the hash of a
  /// line is the SHA-256 of that text without its `hash` (the last key), so the text must not be re-serialised.
  static List<String> splitEntries(String body) {
    var i = 0;
    final n = body.length;
    var depth = 0;
    String? lastKey;
    var arrayStart = -1;
    while (i < n && arrayStart < 0) {
      final c = body[i];
      if (c == '"') {
        final (text, end) = _readString(body, i);
        var j = end;
        while (j < n && _isSpace(body[j])) {
          j++;
        }
        if (depth == 1 && j < n && body[j] == ':') lastKey = text;
        i = end;
        continue;
      }
      if (c == '{') {
        depth++;
      } else if (c == '[') {
        if (depth == 1 && lastKey == 'entries') {
          arrayStart = i;
        } else {
          depth++;
        }
      } else if (c == '}' || c == ']') {
        depth--;
      }
      i++;
    }
    if (arrayStart < 0) return const [];
    final out = <String>[];
    i = arrayStart + 1;
    var objectDepth = 0;
    var objectStart = -1;
    while (i < n) {
      final c = body[i];
      if (c == '"') {
        i = _readString(body, i).$2;
        continue;
      }
      if (c == '{') {
        if (objectDepth == 0) objectStart = i;
        objectDepth++;
      } else if (c == '}') {
        objectDepth--;
        if (objectDepth == 0 && objectStart >= 0) {
          out.add(body.substring(objectStart, i + 1));
          objectStart = -1;
        }
      } else if (c == '[') {
        objectDepth++;
      } else if (c == ']') {
        if (objectDepth == 0) return out;
        objectDepth--;
      }
      i++;
    }
    return out;
  }

  static bool _isSpace(String c) => c == ' ' || c == '\n' || c == '\r' || c == '\t';

  /// Reads the JSON string that starts at [start] (a quote); gives its text and the index just after it.
  static (String, int) _readString(String body, int start) {
    final sb = StringBuffer();
    var i = start + 1;
    while (i < body.length) {
      final c = body[i];
      if (c == '\\' && i + 1 < body.length) {
        sb.write(body[i + 1]);
        i += 2;
        continue;
      }
      if (c == '"') return (sb.toString(), i + 1);
      sb.write(c);
      i++;
    }
    return (sb.toString(), body.length);
  }

  static String _text(Object? v) => v is String ? v : '';

  static AuditLine? _parseLine(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;
    final hash = _text(decoded['hash']);
    final prev = _text(decoded['prev']);
    final seq = decoded['seq'];
    if (hash.isEmpty || prev.isEmpty || seq is! num) return null;
    final trimmed = raw.trim();
    final match = _hashSuffix.firstMatch(trimmed);
    final String? hashed = match != null && !trimmed.contains('\n')
        ? sha256Hex(utf8.encode('${trimmed.substring(0, match.start)}}'))
        : null;
    final detail = decoded['detail'];
    var detailText = '';
    if (detail is Map) {
      final keys = detail.keys.map((k) => '$k').toList()..sort();
      detailText = keys.map((k) => '$k=${detail[k]}').join(' ');
      if (detailText.length > 120) detailText = '${detailText.substring(0, 117)}...';
    }
    final robotId = decoded['robotId'];
    final username = _text(decoded['username']);
    final controllerId = _text(decoded['controllerId']);
    final ip = _text(decoded['ip']);
    return AuditLine(
      seq: seq.toInt(),
      ts: _text(decoded['ts']),
      type: _text(decoded['type']),
      outcome: decoded['outcome'] is String ? decoded['outcome'] as String : 'ok',
      username: username.isEmpty ? null : username,
      controllerId: controllerId.isEmpty ? null : controllerId,
      ip: ip.isEmpty ? null : ip,
      robotId: robotId is num ? robotId.toInt() : null,
      detail: detailText,
      prev: prev,
      hash: hash,
      hashed: hashed,
    );
  }

  /// Reads the answer of GET /api/audit: the lines (oldest first, as the server sends them) and what it says of the record.
  static AuditRead parse(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return const AuditRead(true, false, [], null);
    }
    if (decoded is! Map) return const AuditRead(true, false, [], null);
    final v = decoded['verification'];
    final verdict = v is Map
        ? AuditVerdict(
            v['ok'] == true,
            v['entries'] is num ? (v['entries'] as num).toInt() : 0,
            v['brokenAtSeq'] is num ? (v['brokenAtSeq'] as num).toInt() : null,
            v['reason'] is String && (v['reason'] as String).isNotEmpty ? v['reason'] as String : null,
          )
        : null;
    return AuditRead(
      decoded['enabled'] != false,
      decoded['lockedOff'] == true,
      splitEntries(body).map(_parseLine).whereType<AuditLine>().toList(),
      verdict,
    );
  }

  /// Checks the hash of every line and the link between lines that are neighbours (sequence numbers one apart).
  static ChainCheck checkChain(List<AuditLine> lines) {
    var links = 0;
    var gaps = 0;
    var unreadable = 0;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final hashed = line.hashed;
      if (hashed == null) {
        unreadable++;
      } else if (hashed != line.hash) {
        return ChainCheck(ok: false, checked: index, links: links, gaps: gaps, unreadable: unreadable, brokenAtSeq: line.seq, reason: 'changed');
      }
      if (index == 0) continue;
      final before = lines[index - 1];
      if (line.seq == before.seq + 1) {
        links++;
        if (line.prev != before.hash) {
          return ChainCheck(ok: false, checked: index + 1, links: links, gaps: gaps, unreadable: unreadable, brokenAtSeq: line.seq, reason: 'link');
        }
      } else {
        gaps++;
      }
    }
    return ChainCheck(ok: true, checked: lines.length, links: links, gaps: gaps, unreadable: unreadable);
  }

  /// The query string of GET /api/audit for a filter (limit 1 to 1000).
  static String query({int? limit, String? type, Object? robotId, bool verify = false, String? format}) {
    final pairs = <String>[];
    if (limit != null) pairs.add('limit=${limit.clamp(1, 1000)}');
    if (type != null && types.contains(type)) pairs.add('type=$type');
    if (robotId != null) pairs.add('robotId=${Uri.encodeQueryComponent('$robotId')}');
    if (verify) pairs.add('verify=1');
    if (format != null && format.isNotEmpty) pairs.add('format=$format');
    return pairs.isEmpty ? '' : '?${pairs.join('&')}';
  }
}
