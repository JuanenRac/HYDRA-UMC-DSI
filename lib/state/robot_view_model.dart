// =============================================================================
// HYDRA-UMC DSI (Flutter) - state/robot_view_model.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Single ChangeNotifier every screen listens to via Provider - ported from
// HYDRA-UMC-IOS-CONTROL's own state/robot_view_model.dart (same Dart/
// Flutter stack, direct reuse per [[No reference -> reuse, don't invent]]).
// Every write goes through sendAtomicCommand(), which POSTs the real atomic
// POST /api/robot/:id/command endpoint instead of overwriting the whole
// settings tree - see that file's own header comment for the full
// reasoning, unchanged here.
//
// One addition over the iOS version: hydraInfo, a lightweight periodic poll
// of GET /api/hydra-info (hostname/controllerCount/robotCount/uptime) for
// this app's own dedicated Metrics screen (ui/metrics_screen.dart) - the
// iOS/Android apps fold a couple of these numbers into their Dashboard, but
// the DSI spec calls for system metrics as its own catalog entry, so this
// app polls a slightly larger set on its own timer instead of stealing
// dashboard screen space for it.
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../l10n/language_prefs.dart';
import '../models/hydra_state.dart';
import '../models/server_info.dart';
import '../network/auth_prefs.dart';
import '../network/hydra_api_client.dart';
import '../network/hydra_websocket.dart';
import 'hydra_error.dart';

class SystemMetrics {
  final int cpuLoad;
  final int memoryUsage;
  final double temp;
  final int uptime;
  SystemMetrics({required this.cpuLoad, required this.memoryUsage, required this.temp, required this.uptime});
}

class RobotViewModel extends ChangeNotifier {
  final AuthPrefs _authPrefs = AuthPrefs();
  final LanguagePrefs _languagePrefs = LanguagePrefs();

  HydraState state = HydraState();
  HydraApiClient? apiClient;
  HydraWebSocket? _ws;
  Timer? _metricsTimer;

  // Per-command-name debounce for _sendAtomicCommand()'s own network send -
  // a dragged Slider's onChanged fires many times a second (setSpeed's own
  // real caller, ui/control_screen.dart), and until this existed every one
  // of those ticks fired its own real POST /api/robot/:id/command, unlike
  // HYDRA-UMC-ANDROID-CONTROL's own equivalent sendAtomicCommand(), which
  // already debounces setSpeed 300ms for exactly this reason - this port
  // (and HYDRA-UMC-IOS-CONTROL's own, fixed the same way) had the same gap
  // the Android app already closed. Keyed by command name so debouncing
  // 'speed' can never coalesce away or delay an unrelated command (e.g. a
  // jog or E-STOP) that happens to fire during the same debounce window.
  final Map<String, Timer> _debounceTimers = {};
  Timer? _hydraInfoTimer;

  // Per-robot generation counter guarding _sendAtomicCommand()'s own
  // rollback-on-failure below. A held jog button fires a new command
  // roughly every 150ms while the API call it's rolling back from can take
  // up to the 5s network timeout - so several commands for the same robot
  // can be in flight at once. Without this guard, an early command failing
  // AFTER later ones already applied (and possibly already succeeded)
  // would restore its own stale pre-mutation snapshot over top of that
  // newer state, silently erasing real progress the operator already
  // made. Ported from HYDRA-UMC-IOS-CONTROL's own robot_view_model.dart -
  // this file's rollback existed without this guard until now, a real gap
  // vs. that reference (see DISEÑO_SYNC_DELTAS.txt section 1/5c).
  final Map<dynamic, int> _commandGeneration = {};

  ServerInfo? activeServer;
  bool isLoggedIn = false;
  HydraError? lastError;
  String connectionStatus = 'disconnected';
  dynamic selectedRobotId;
  SystemMetrics? metrics;
  Map<String, dynamic>? hydraInfo;

  // Explicit language override (null = follow the OS locale) - persisted
  // via LanguagePrefs, loaded in init(), read by main.dart's own
  // MaterialApp.locale and changed from ui/settings_screen.dart.
  Locale? languageOverride;

  Future<void> setLanguage(String? languageCode) async {
    await _languagePrefs.saveLanguage(languageCode);
    languageOverride = await _languagePrefs.loadLocale();
    notifyListeners();
  }

  Future<void> init() async {
    languageOverride = await _languagePrefs.loadLocale();
    final saved = await _authPrefs.loadConnection();
    final token = await _authPrefs.loadToken();
    if (saved != null) {
      final (host, port) = saved;
      final client = HydraApiClient(host, port);
      client.authToken = token;
      apiClient = client;
      activeServer = ServerInfo(host: host, port: port);
      isLoggedIn = token != null;
    }
    notifyListeners();
    // A restored session needs the same real connect() step login() runs
    // (fetch settings, open the WS, start metrics polling) - without this
    // call the app would land straight on MainScreen with isLoggedIn=true
    // but an empty HydraState and no live connection.
    if (isLoggedIn) await connect();
  }

  Future<bool> login(ServerInfo server) async {
    // Close out any previous session's client before replacing it - each
    // HydraApiClient owns its own http.Client (its own connection pool).
    apiClient?.close();
    final client = HydraApiClient(server.host, server.port);
    apiClient = client;
    try {
      final resp = await client.login(server.username, server.password);
      final token = resp['token'] as String?;
      if (resp['success'] != true || token == null) {
        lastError = const HydraError(HydraErrorKind.loginFailed);
        notifyListeners();
        return false;
      }
      client.authToken = token;
      isLoggedIn = true;
      activeServer = server;
      await _authPrefs.saveConnection(server.host, server.port);
      await _authPrefs.saveToken(token, server.username);
      lastError = null;
      notifyListeners();
      await connect();
      return true;
    } catch (e) {
      lastError = HydraError(HydraErrorKind.loginError, {'error': '$e'});
      notifyListeners();
      return false;
    }
  }

  void logout() {
    isLoggedIn = false;
    _ws?.disconnect();
    _metricsTimer?.cancel();
    _hydraInfoTimer?.cancel();
    unawaited(_authPrefs.clearToken());
    notifyListeners();
  }

  Future<void> connect() async {
    final server = activeServer;
    final client = apiClient;
    if (server == null || client == null) return;
    connectionStatus = 'connecting';
    notifyListeners();

    try {
      final settings = await client.getSettings();
      state = HydraState(settings);
      _ensureSelectedRobot();
      notifyListeners();
    } catch (e) {
      lastError = HydraError(HydraErrorKind.fetchFailed, {'error': '$e'});
      connectionStatus = 'error';
      // A restored session (see init()) can reach here with a token the
      // server no longer accepts (expired/revoked while the app was
      // closed) - same 401/403 -> logout rule _sendAtomicCommand and the
      // WS onError callback below already apply.
      if (e.toString().contains('401') || e.toString().contains('403')) {
        isLoggedIn = false;
      }
      notifyListeners();
    }

    _setupWebSocket(server, client.authToken);
    _startMetricsLoop(client);
    _startHydraInfoLoop(client);
  }

  void _setupWebSocket(ServerInfo server, String? token) {
    _ws?.disconnect();
    _ws = HydraWebSocket(
      host: server.host,
      port: server.port,
      token: token,
      onStatus: (status) {
        connectionStatus = switch (status) {
          WsStatus.connecting => 'connecting',
          WsStatus.connected => 'connected',
          WsStatus.disconnected => 'disconnected',
        };
        notifyListeners();
      },
      onSettings: (payload) {
        state = HydraState(payload);
        _ensureSelectedRobot();
        notifyListeners();
      },
      onDelta: _applyRobotDelta,
      onError: (error) {
        lastError = error;
        // Only a server-relayed message ever carries the real
        // "denied"/"token" auth-rejection text - a client-side connection
        // failure (wsConnectionLost/wsConnectFailed) is a generic
        // connectivity problem, never an auth one.
        if (error.kind == HydraErrorKind.serverMessage) {
          final message = error.params['message'] ?? '';
          if (message.contains('denied') || message.contains('token')) {
            isLoggedIn = false;
            connectionStatus = 'disconnected';
            _ws?.disconnect();
          }
        }
        notifyListeners();
      },
    )..connect();
  }

  void _startMetricsLoop(HydraApiClient client) {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final m = await client.getSystemMetrics();
        metrics = SystemMetrics(
          cpuLoad: (m['cpu_load'] ?? 0) as int,
          memoryUsage: (m['memory_usage'] ?? 0) as int,
          temp: ((m['temp'] ?? 0) as num).toDouble(),
          uptime: (m['uptime'] ?? 0) as int,
        );
        notifyListeners();
      } catch (_) {
        // best-effort background poll - a miss doesn't clear the last known reading
      }
    });
    // Fire once immediately rather than waiting a full 5s for the first
    // reading - the Metrics screen would otherwise show empty tiles for up
    // to 5 seconds after every login.
    unawaited(client.getSystemMetrics().then((m) {
      metrics = SystemMetrics(
        cpuLoad: (m['cpu_load'] ?? 0) as int,
        memoryUsage: (m['memory_usage'] ?? 0) as int,
        temp: ((m['temp'] ?? 0) as num).toDouble(),
        uptime: (m['uptime'] ?? 0) as int,
      );
      notifyListeners();
    }).catchError((_) {}));
  }

  void _startHydraInfoLoop(HydraApiClient client) {
    _hydraInfoTimer?.cancel();
    Future<void> poll() async {
      final info = await client.getHydraInfo();
      if (info != null) {
        hydraInfo = info;
        notifyListeners();
      }
    }

    unawaited(poll());
    _hydraInfoTimer = Timer.periodic(const Duration(seconds: 10), (_) => poll());
  }

  /// Applies one {controllerId, robotId, patch, cameraId?, cameraPatch?}
  /// delta in place onto state.raw's own nested Maps - ported from
  /// HYDRA-UMC-IOS-CONTROL's own robot_view_model.dart. Looks the robot up
  /// by controllerId + robotId directly rather than via
  /// HydraState.robotById() (which only searches activeController) - a
  /// delta can legitimately target a robot in a non-active controller in a
  /// multi-controller swarm. Validates the robot exists locally BEFORE
  /// touching anything: if it doesn't, the delta is discarded and a full
  /// reload is forced instead of ever creating a "ghost" robot from a
  /// partial patch - DISEÑO_SYNC_DELTAS.txt section 5b mitigation (b),
  /// non-optional.
  void _applyRobotDelta(Map<String, dynamic> msg) {
    final controllerId = msg['controllerId'];
    final robotId = msg['robotId'];
    final patch = msg['patch'];
    if (controllerId is! String || patch is! Map) return;
    Map<String, dynamic>? targetRobot;
    Map<String, dynamic>? targetCamera;
    for (final c in (state.raw['controllers'] as List? ?? const [])) {
      if (c is! Map || c['id'] != controllerId) continue;
      for (final r in (c['robots'] as List? ?? const [])) {
        if (r is Map && r['id'] == robotId) {
          targetRobot = r as Map<String, dynamic>;
          break;
        }
      }
      final cameraId = msg['cameraId'];
      if (cameraId != null) {
        for (final cam in (c['cameras'] as List? ?? const [])) {
          if (cam is Map && cam['id'] == cameraId) {
            targetCamera = cam as Map<String, dynamic>;
            break;
          }
        }
      }
      break;
    }
    if (targetRobot == null) {
      final client = apiClient;
      if (client != null) {
        unawaited(client.getSettings().then((settings) {
          state = HydraState(settings);
          _ensureSelectedRobot();
          notifyListeners();
        }).catchError((_) {}));
      }
      return;
    }
    targetRobot.addAll(patch.cast<String, dynamic>());
    final cameraPatch = msg['cameraPatch'];
    if (targetCamera != null && cameraPatch is Map) {
      targetCamera.addAll(cameraPatch.cast<String, dynamic>());
    }
    notifyListeners();
  }

  void _ensureSelectedRobot() {
    final robots = state.activeController?.robots ?? const [];
    if (selectedRobotId == null || robots.every((r) => r.id != selectedRobotId)) {
      selectedRobotId = robots.isNotEmpty ? robots.first.id : null;
    }
  }

  RobotView? get selectedRobot => selectedRobotId == null ? null : state.robotById(selectedRobotId);
  List<RobotView> get robots => state.activeController?.robots ?? const [];

  void selectRobot(dynamic robotId) {
    selectedRobotId = robotId;
    notifyListeners();
  }

  /// Applies [command]/[params] to [robotId] (defaults to the selected
  /// robot) and, when [propagateToCombined] is true, its own combinedWith
  /// siblings too - locally for instant UI feedback via [localMutate], then
  /// via the real atomic endpoint.
  Future<void> _sendAtomicCommand(
    String command, {
    Map<String, dynamic>? params,
    bool propagateToCombined = false,
    dynamic robotIdOverride,
    Duration debounce = Duration.zero,
    required void Function(RobotView) localMutate,
  }) async {
    final robotId = robotIdOverride ?? selectedRobotId;
    if (robotId == null) return;
    final target = state.robotById(robotId);
    if (target == null) {
      lastError = const HydraError(HydraErrorKind.robotNotFound);
      notifyListeners();
      return;
    }

    final client = apiClient;
    if (client == null) {
      lastError = const HydraError(HydraErrorKind.notConnected);
      notifyListeners();
      return;
    }

    final affectedIds = <dynamic>[robotId];
    if (propagateToCombined) affectedIds.addAll(target.combinedWith);

    // Deep-copy snapshot of every affected robot's raw state before
    // mutating, so a failed write can roll back cleanly (see
    // HYDRA-UMC-IOS-CONTROL's own header comment for why a shallow copy
    // wouldn't work here). Applied unconditionally, even when `debounce`
    // delays the actual network send below - a dragged Slider still needs
    // instant per-tick visual feedback (see setSpeed's own comment); only
    // the real POST round-trip is worth coalescing away.
    final snapshots = <dynamic, Map<String, dynamic>>{};
    final myGeneration = <dynamic, int>{};
    for (final id in affectedIds) {
      final r = state.robotById(id);
      if (r != null) {
        snapshots[id] = jsonDecode(jsonEncode(r.raw)) as Map<String, dynamic>;
        localMutate(r);
        myGeneration[id] = _commandGeneration[id] = (_commandGeneration[id] ?? 0) + 1;
      }
    }
    notifyListeners();

    final payload = <String, dynamic>{'command': command};
    if (params != null) payload['params'] = params;

    Future<void> send() async {
      try {
        await client.postRobotCommand(robotId, payload);
        lastError = null;
      } catch (e) {
        // Catches everything, not just HydraApiException - a plain network
        // failure must still roll back the optimistic mutation and surface
        // the error, especially critical for a touchscreen jog pendant/E-STOP
        // (see control_screen.dart) where a silently-failed STOP is
        // dangerous.
        for (final entry in snapshots.entries) {
          // Skip the rollback if a newer command for this same robot has
          // already started since this one's snapshot was taken (see
          // _commandGeneration's own header comment) - this failure is stale,
          // and restoring its snapshot now would overwrite whatever that
          // newer command already applied.
          if (_commandGeneration[entry.key] != myGeneration[entry.key]) continue;
          final r = state.robotById(entry.key);
          if (r != null) {
            r.raw
              ..clear()
              ..addAll(entry.value);
          }
        }
        lastError = HydraError(HydraErrorKind.txError, {'command': command, 'error': '$e'});
        if (e.toString().contains('401') || e.toString().contains('403')) {
          isLoggedIn = false;
          connectionStatus = 'disconnected';
          _ws?.disconnect();
        }
        notifyListeners();
      }
    }

    // Debounced (same real mechanism as HYDRA-UMC-ANDROID-CONTROL's own
    // sendAtomicCommand): cancel any still-pending send for this exact
    // command name, then schedule a new one after `debounce` - a rapid
    // burst of calls for the same command (e.g. every Slider drag frame)
    // collapses into exactly one real POST once the drag settles, instead
    // of one POST per frame.
    _debounceTimers.remove(command)?.cancel();
    if (debounce > Duration.zero) {
      _debounceTimers[command] = Timer(debounce, send);
    } else {
      await send();
    }
  }

  void sendCommand(String command) {
    switch (command) {
      case 'play':
        _sendAtomicCommand(command, propagateToCombined: true, localMutate: (r) => r.setPlaying(true));
      case 'pause':
        _sendAtomicCommand(command, propagateToCombined: true, localMutate: (r) => r.togglePaused());
      case 'stop':
        _sendAtomicCommand(command, propagateToCombined: true, localMutate: (r) => r.stop());
      default:
        lastError = HydraError(HydraErrorKind.unknownCommand, {'command': command});
        notifyListeners();
    }
  }

  void jog(String target, String axis, double amount) {
    final params = {'axis': axis, 'amount': amount, 'target': target};
    _sendAtomicCommand(
      'jog',
      params: params,
      localMutate: (r) {
        if (target == 'robot') {
          r.setPosAxis(axis, r.posAxis(axis) + amount);
        } else if (target == 'xytable') {
          r.setXyTableAxis(axis, (r.xyTablePos[axis] ?? 0.0) + amount);
        }
      },
    );
  }

  void toggleValve(int index) {
    final r = selectedRobot;
    if (r == null) return;
    final newState = !((r.valves[index] ?? false) as bool);
    _sendAtomicCommand('valve', params: {'index': index, 'state': newState}, localMutate: (r) => r.setValve(index, newState));
  }

  void togglePump(int index) {
    final r = selectedRobot;
    if (r == null) return;
    final newState = !((r.pumps[index] ?? false) as bool);
    _sendAtomicCommand('pump', params: {'index': index, 'state': newState}, localMutate: (r) => r.setPump(index, newState));
  }

  /// Debounced (300ms, matching HYDRA-UMC-ANDROID-CONTROL's own setSpeed) -
  /// a dragged Slider's onChanged (ui/control_screen.dart) fires this many
  /// times a second.
  void setSpeed(double speed, double acceleration) {
    _sendAtomicCommand(
      'speed',
      params: {'speed': speed, 'acceleration': acceleration},
      debounce: const Duration(milliseconds: 300),
      localMutate: (r) {
        r.setSpeed(speed);
        r.setAcceleration(acceleration);
      },
    );
  }

  /// Toggles a robot's vision system on/off from the Camera screen. Takes
  /// an explicit robotId since the camera being browsed isn't necessarily
  /// the globally selected control robot.
  void setVisionEnabled(dynamic robotId, bool enabled) {
    _sendAtomicCommand(
      'vision',
      params: {'enabled': enabled},
      robotIdOverride: robotId,
      localMutate: (r) => r.raw['visionEnabled'] = enabled,
    );
  }

  @override
  void dispose() {
    _ws?.disconnect();
    _metricsTimer?.cancel();
    _hydraInfoTimer?.cancel();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    apiClient?.close();
    super.dispose();
  }
}
