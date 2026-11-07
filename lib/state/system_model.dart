// =============================================================================
// HYDRA-UMC DSI (Flutter) - state/system_model.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The state of the System tab, kept apart from RobotViewModel on purpose: the
// safety verdict is read every couple of seconds and the ecosystem every ten,
// and none of that should redraw the control screen. Only the widgets that
// show it listen to this model.
//
//  * The safety verdict (HYDRA-UMC-SAFETY-ZONES) is read while signed in, if
//    the settings file turns the safety panel on.
//  * The ecosystem status is read only while the System tab is the one shown.
//  * The restart actions of the tab. Each one checks the role first, asks the
//    server only what the server itself allows, leaves a line in the audit
//    trail (also written to the journal of the service), and none of them
//    restarts the whole Compute Module unless the settings file says so on
//    purpose (util/panel_config.dart).
// =============================================================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/access.dart';
import '../models/system_status.dart';
import '../models/tool_arms.dart';
import '../network/hydra_api_client.dart';
import '../network/safety_zones_client.dart';
import '../util/panel_config.dart';
import 'robot_view_model.dart';

/// What came of a restart action. [ok] carries nothing; the others say why not.
enum SystemActionResult { ok, roleDenied, adminOnly, notAllowed, notSupervised, notLocal, failed }

class SystemModel extends ChangeNotifier {
  SystemModel({
    required this.vm,
    SafetyZonesClient Function(PanelConfig config)? safetyClientFactory,
    void Function()? screenRestarter,
    bool? supervised,
    DateTime Function()? clock,
  })  : _safetyClientFactory = safetyClientFactory ?? _defaultSafetyClient,
        _screenRestarter = screenRestarter ?? _exitForSupervisor,
        supervised = supervised ?? Platform.environment.containsKey('INVOCATION_ID'),
        _clock = clock ?? DateTime.now {
    vm.addListener(_sync);
    _sync();
  }

  final RobotViewModel vm;
  final SafetyZonesClient Function(PanelConfig config) _safetyClientFactory;
  final void Function() _screenRestarter;
  final DateTime Function() _clock;

  /// True when a service supervisor (systemd) will start the app again after it closes. Without one, closing the
  /// panel to "restart" it would just close it.
  final bool supervised;

  static SafetyZonesClient _defaultSafetyClient(PanelConfig c) => SafetyZonesClient(host: c.safetyHost, port: c.safetyPort, token: c.safetyToken);

  static void _exitForSupervisor() => exit(0);

  // ---- safety ---------------------------------------------------------------
  SafetyStatus? safety;
  SafetyFailure? safetyFailure;
  Timer? _safetyTimer;
  SafetyZonesClient? _safetyClient;
  bool _safetyReading = false;

  /// The state to show now: not confirmed whenever the verdict is missing, stale or unreadable.
  SafetyLevel get safetyLevel {
    final s = safety;
    if (s == null || safetyFailure != null || s.noVerdictYet) return SafetyLevel.unknown;
    if (s.isStale(_clock(), Duration(seconds: vm.panelConfig.safetyStaleSeconds))) return SafetyLevel.unknown;
    return s.level;
  }

  Future<void> readSafety() async {
    if (_safetyReading) return;
    final client = _safetyClient;
    if (client == null) return;
    _safetyReading = true;
    try {
      safety = await client.read();
      safetyFailure = null;
    } on SafetyZonesException catch (e) {
      safetyFailure = e.failure;
    } catch (_) {
      safetyFailure = SafetyFailure.other;
    } finally {
      _safetyReading = false;
    }
    notifyListeners();
  }

  // ---- ecosystem ------------------------------------------------------------
  EcosystemStatus? ecosystem;
  bool ecosystemFailed = false;
  Timer? _ecosystemTimer;
  bool _ecosystemReading = false;
  bool _visible = false;

  /// The System tab is the one shown: the ecosystem is read only then.
  void setVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    _sync();
  }

  Future<void> readEcosystem() async {
    if (_ecosystemReading || !vm.isLoggedIn) return;
    _ecosystemReading = true;
    try {
      final raw = await vm.runAuthed((c) => c.getEcosystemStatus());
      ecosystem = EcosystemStatus.parse(raw);
      ecosystemFailed = false;
    } catch (_) {
      ecosystemFailed = true;
    } finally {
      _ecosystemReading = false;
    }
    notifyListeners();
  }

  // ---- tool arms --------------------------------------------------------------
  /// The last good reading, or null. A reading that fails drops it: a list that could not be refreshed is never kept as if it were current.
  ToolArmsReport? toolArms;
  ToolArmsFailure? toolArmsFailure;
  Timer? _toolArmsTimer;
  bool _toolArmsReading = false;

  /// Reads the arm state of the tools (read only). 404 = the server is old, 502/503/504 = not available there, 401/403 = not allowed.
  Future<void> readToolArms() async {
    if (_toolArmsReading || !vm.isLoggedIn) return;
    _toolArmsReading = true;
    try {
      final raw = await vm.runAuthed((c) => c.getToolArms());
      final report = ToolArmsReport.parse(raw, _clock());
      toolArms = report;
      toolArmsFailure = report == null ? ToolArmsFailure.shape : null;
    } on HydraApiException catch (e) {
      toolArms = null;
      final status = e.statusCode;
      toolArmsFailure = status == 404
          ? ToolArmsFailure.unsupported
          : status == 502 || status == 503 || status == 504
              ? ToolArmsFailure.unavailable
              : status == 401 || status == 403
                  ? ToolArmsFailure.forbidden
                  : status == null
                      ? ToolArmsFailure.shape
                      : ToolArmsFailure.other;
    } catch (_) {
      toolArms = null;
      toolArmsFailure = ToolArmsFailure.network;
    } finally {
      _toolArmsReading = false;
    }
    notifyListeners();
  }

  // ---- timers follow the session and the settings -----------------------------
  bool _safetyRunning = false;
  bool _ecosystemRunning = false;
  bool _toolArmsRunning = false;
  PanelConfig? _configSeen;

  void _sync() {
    final config = vm.panelConfig;
    final wantSafety = vm.isLoggedIn && config.safetyPanel;
    final wantEcosystem = vm.isLoggedIn && config.ecosystemView && _visible;
    final wantToolArms = vm.isLoggedIn && config.toolArmsPanel && _visible;
    final changedConfig = !identical(_configSeen, config);
    _configSeen = config;

    if (wantSafety && (!_safetyRunning || changedConfig)) {
      _safetyTimer?.cancel();
      _safetyClient?.close();
      _safetyClient = _safetyClientFactory(config);
      _safetyRunning = true;
      unawaited(readSafety());
      _safetyTimer = Timer.periodic(Duration(seconds: config.safetyPollSeconds), (_) => readSafety());
    } else if (!wantSafety && _safetyRunning) {
      _safetyTimer?.cancel();
      _safetyClient?.close();
      _safetyClient = null;
      _safetyRunning = false;
      safety = null;
      safetyFailure = null;
      notifyListeners();
    }

    if (wantEcosystem && (!_ecosystemRunning || changedConfig)) {
      _ecosystemTimer?.cancel();
      _ecosystemRunning = true;
      unawaited(readEcosystem());
      _ecosystemTimer = Timer.periodic(Duration(seconds: config.ecosystemPollSeconds), (_) => readEcosystem());
    } else if (!wantEcosystem && _ecosystemRunning) {
      _ecosystemTimer?.cancel();
      _ecosystemRunning = false;
    }

    if (wantToolArms && (!_toolArmsRunning || changedConfig)) {
      _toolArmsTimer?.cancel();
      _toolArmsRunning = true;
      unawaited(readToolArms());
      _toolArmsTimer = Timer.periodic(Duration(seconds: config.toolArmsPollSeconds), (_) => readToolArms());
    } else if (!wantToolArms && _toolArmsRunning) {
      _toolArmsTimer?.cancel();
      _toolArmsRunning = false;
      toolArms = null;
      toolArmsFailure = null;
      notifyListeners();
    }
  }

  // ---- restart actions --------------------------------------------------------
  /// The lines of what was asked from this tab, newest last (also written to the journal of the service).
  final List<String> auditTrail = [];

  String? get _role => jwtRole(vm.apiClient?.authToken);

  /// Operators and administrators may restart; a viewer or a role that cannot be read may not.
  bool get roleMayRestart => _role == 'admin' || _role == 'operator';

  void _audit(String what, SystemActionResult result) {
    final user = _role ?? '?';
    final line = '${_clock().toIso8601String()} role=$user action=$what result=${result.name}';
    auditTrail.add(line);
    if (auditTrail.length > 50) auditTrail.removeAt(0);
    try {
      stderr.writeln('[hydra-dsi] $line');
    } catch (_) {
      // No stderr (a test host, a detached run): the in-memory trail is all there is.
    }
  }

  SystemActionResult _done(String what, SystemActionResult result) {
    _audit(what, result);
    return result;
  }

  /// Closes this screen so the supervisor of the service starts it again. Robots and servers are not touched.
  SystemActionResult restartScreen() {
    if (!roleMayRestart) return _done('restart-screen', SystemActionResult.roleDenied);
    if (!supervised) return _done('restart-screen', SystemActionResult.notSupervised);
    _done('restart-screen', SystemActionResult.ok);
    _screenRestarter();
    return SystemActionResult.ok;
  }

  /// Asks the server to close so its supervisor starts it again (administrators only, the server checks too).
  Future<SystemActionResult> restartServices() async {
    if (!roleMayRestart) return _done('restart-services', SystemActionResult.roleDenied);
    if (_role != 'admin') return _done('restart-services', SystemActionResult.adminOnly);
    try {
      await vm.runAuthed((c) => c.postAdminRestart());
      return _done('restart-services', SystemActionResult.ok);
    } catch (e) {
      return _done('restart-services', e is HydraApiException && e.isPermissionDenied ? SystemActionResult.adminOnly : SystemActionResult.failed);
    }
  }

  /// The whole Compute Module. Only when the settings file chose it on purpose, and only from the panel that runs on it.
  Future<SystemActionResult> restartHost() async {
    if (!roleMayRestart) return _done('restart-host', SystemActionResult.roleDenied);
    if (!vm.panelConfig.hostRebootOffered) return _done('restart-host', SystemActionResult.notAllowed);
    final host = vm.activeServer?.host ?? '';
    if (host != '127.0.0.1' && host != 'localhost' && host != '::1') return _done('restart-host', SystemActionResult.notLocal);
    try {
      await vm.runAuthed((c) => c.postSystemReboot());
      return _done('restart-host', SystemActionResult.ok);
    } catch (_) {
      return _done('restart-host', SystemActionResult.failed);
    }
  }

  String? _busyUnit;

  /// The unit an action is running on, or null.
  String? get busyUnit => _busyUnit;

  /// Starts, stops or restarts one service of the ecosystem (administrators only).
  Future<SystemActionResult> serviceAction(String unit, String action) async {
    final what = 'service-$action:$unit';
    if (_role != 'admin') return _done(what, _role == null || _role == 'viewer' ? SystemActionResult.roleDenied : SystemActionResult.adminOnly);
    _busyUnit = unit;
    notifyListeners();
    try {
      await vm.runAuthed((c) => c.postEcosystemService(unit, action));
      _audit(what, SystemActionResult.ok);
      unawaited(readEcosystem());
      return SystemActionResult.ok;
    } catch (_) {
      return _done(what, SystemActionResult.failed);
    } finally {
      _busyUnit = null;
      notifyListeners();
    }
  }

  bool _disposed = false;

  @override
  void notifyListeners() {
    // A reading still on the wire can finish after the model was disposed.
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    vm.removeListener(_sync);
    _safetyTimer?.cancel();
    _ecosystemTimer?.cancel();
    _toolArmsTimer?.cancel();
    _safetyClient?.close();
    super.dispose();
  }
}
