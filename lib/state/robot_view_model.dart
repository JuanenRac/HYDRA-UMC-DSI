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

import 'package:flutter/foundation.dart';

import '../models/hydra_state.dart';
import '../models/server_info.dart';
import '../network/auth_prefs.dart';
import '../network/hydra_api_client.dart';
import '../network/hydra_websocket.dart';

class SystemMetrics {
  final int cpuLoad;
  final int memoryUsage;
  final double temp;
  final int uptime;
  SystemMetrics({required this.cpuLoad, required this.memoryUsage, required this.temp, required this.uptime});
}

class RobotViewModel extends ChangeNotifier {
  final AuthPrefs _authPrefs = AuthPrefs();

  HydraState state = HydraState();
  HydraApiClient? apiClient;
  HydraWebSocket? _ws;
  Timer? _metricsTimer;
  Timer? _hydraInfoTimer;

  ServerInfo? activeServer;
  bool isLoggedIn = false;
  String lastError = '';
  String connectionStatus = 'disconnected';
  dynamic selectedRobotId;
  SystemMetrics? metrics;
  Map<String, dynamic>? hydraInfo;

  Future<void> init() async {
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
        lastError = 'Login failed: server rejected credentials';
        notifyListeners();
        return false;
      }
      client.authToken = token;
      isLoggedIn = true;
      activeServer = server;
      await _authPrefs.saveConnection(server.host, server.port);
      await _authPrefs.saveToken(token, server.username);
      lastError = '';
      notifyListeners();
      await connect();
      return true;
    } catch (e) {
      lastError = 'Login error: $e';
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
      lastError = 'Initial fetch failed: $e';
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
      onError: (message) {
        lastError = message;
        if (message.contains('denied') || message.contains('token')) {
          isLoggedIn = false;
          connectionStatus = 'disconnected';
          _ws?.disconnect();
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
    required void Function(RobotView) localMutate,
  }) async {
    final robotId = robotIdOverride ?? selectedRobotId;
    if (robotId == null) return;
    final target = state.robotById(robotId);
    if (target == null) {
      lastError = 'Robot not found';
      notifyListeners();
      return;
    }

    final client = apiClient;
    if (client == null) {
      lastError = 'Not connected to a server';
      notifyListeners();
      return;
    }

    final affectedIds = <dynamic>[robotId];
    if (propagateToCombined) affectedIds.addAll(target.combinedWith);

    // Deep-copy snapshot of every affected robot's raw state before
    // mutating, so a failed write can roll back cleanly (see
    // HYDRA-UMC-IOS-CONTROL's own header comment for why a shallow copy
    // wouldn't work here).
    final snapshots = <dynamic, Map<String, dynamic>>{};
    for (final id in affectedIds) {
      final r = state.robotById(id);
      if (r != null) {
        snapshots[id] = jsonDecode(jsonEncode(r.raw)) as Map<String, dynamic>;
        localMutate(r);
      }
    }
    notifyListeners();

    final payload = <String, dynamic>{'command': command};
    if (params != null) payload['params'] = params;

    try {
      await client.postRobotCommand(robotId, payload);
      lastError = '';
    } catch (e) {
      // Catches everything, not just HydraApiException - a plain network
      // failure must still roll back the optimistic mutation and surface
      // the error, especially critical for a touchscreen jog pendant/E-STOP
      // (see control_screen.dart) where a silently-failed STOP is
      // dangerous.
      for (final entry in snapshots.entries) {
        final r = state.robotById(entry.key);
        if (r != null) {
          r.raw
            ..clear()
            ..addAll(entry.value);
        }
      }
      lastError = 'TX error [$command]: $e';
      if (e.toString().contains('401') || e.toString().contains('403')) {
        isLoggedIn = false;
        connectionStatus = 'disconnected';
        _ws?.disconnect();
      }
      notifyListeners();
    }
  }

  void sendCommand(String command) {
    switch (command) {
      case 'enable':
        _sendAtomicCommand(command, propagateToCombined: true, localMutate: (r) => r.setOnline(true));
      case 'disable':
        _sendAtomicCommand(command, propagateToCombined: true, localMutate: (r) => r.setOnline(false));
      case 'play':
        _sendAtomicCommand(command, propagateToCombined: true, localMutate: (r) => r.setPlaying(true));
      case 'pause':
        _sendAtomicCommand(command, propagateToCombined: true, localMutate: (r) => r.togglePaused());
      case 'stop':
        _sendAtomicCommand(command, propagateToCombined: true, localMutate: (r) => r.stop());
      default:
        lastError = 'Unknown command: $command';
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

  void setSpeed(double speed, double acceleration) {
    _sendAtomicCommand(
      'speed',
      params: {'speed': speed, 'acceleration': acceleration},
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
    apiClient?.close();
    super.dispose();
  }
}
