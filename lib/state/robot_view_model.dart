// =============================================================================
// HYDRA-UMC DSI (Flutter) - state/robot_view_model.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
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
import '../models/access.dart';
import '../models/hydra_state.dart';
import '../models/server_info.dart';
import '../models/stop_all_result.dart';
import '../network/auth_prefs.dart';
import '../network/client_prefs.dart';
import '../network/hydra_api_client.dart';
import '../network/hydra_websocket.dart';
import 'hydra_error.dart';

class SystemMetrics {
  final int cpuLoad;
  final int memoryUsage;
  final double temp;
  final int uptime;
  /// False when the host has no temperature sensor: the server then reports
  /// a made-up 45-55 degrees (temp_is_real: false) that must not be shown as
  /// a reading or coloured with the alarm thresholds.
  final bool tempIsReal;
  SystemMetrics({
    required this.cpuLoad,
    required this.memoryUsage,
    required this.temp,
    required this.uptime,
    this.tempIsReal = true,
  });
}

class RobotViewModel extends ChangeNotifier {
  // injectable for real test coverage of the login/_attemptTokenRefresh/
  // logout() lifecycle - same DI pattern this app already uses for
  // HydraApiClient's own {http.Client? client} and AuthPrefs' own
  // {SecureTokenBackend? secureBackend}. Defaults to a real AuthPrefs()
  // (backed by real platform secure storage) for every actual screen.
  final AuthPrefs _authPrefs;
  final ClientPrefs _clientPrefs = ClientPrefs();
  final LanguagePrefs _languagePrefs = LanguagePrefs();

  RobotViewModel({AuthPrefs? authPrefs}) : _authPrefs = authPrefs ?? AuthPrefs();

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
  // vs. that reference (see the delta-sync design).
  final Map<dynamic, int> _commandGeneration = {};

  // Jog commands on the wire, per robot. A held button repeats every 150 ms;
  // on a slow link the POSTs used to pile up and still be applied after the
  // button was released. While one is in flight the next tick is dropped.
  final Map<dynamic, int> _jogsInFlight = {};

  // One session renewal at a time, however many requests and socket events
  // notice the expired token together: the refresh token is single-use, so a
  // second parallel refresh would be refused and end a session that was fine.
  Future<bool>? _renewalInFlight;
  bool _handlingWsAuthFailure = false;

  // The sign-out in progress: a login that starts meanwhile waits for it, or
  // its fresh token would be erased by the logout still running.
  Future<void>? _pendingLogout;

  bool _disposed = false;

  @override
  void notifyListeners() {
    // A request still on the wire can finish after the model was disposed.
    if (_disposed) return;
    super.notifyListeners();
  }

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
    // The controller id of this installation: made once, kept, and adopted here.
    final storedControllerId = await _clientPrefs.loadControllerId();
    if (isValidControllerId(storedControllerId)) {
      HydraApiClient.controllerId = storedControllerId!;
    } else {
      await _clientPrefs.saveControllerId(HydraApiClient.controllerId);
    }
    final saved = await _authPrefs.loadConnection();
    final token = await _authPrefs.loadToken();
    if (saved != null) {
      final (host, port) = saved;
      // The scheme this server was last seen on: one that answered TLS is not
      // probed over plain http again at start-up.
      final useTls = await _authPrefs.loadUseTls();
      final client = HydraApiClient(host, port, useTls: useTls);
      client.authToken = token;
      apiClient = client;
      activeServer = ServerInfo(host: host, port: port, useTls: useTls);
      isLoggedIn = token != null;
    }
    notifyListeners();
    // A restored session needs the same connect() step login() runs (fetch
    // settings, open the WS, start the polling).
    if (isLoggedIn) await connect();
  }

  Future<bool> login(ServerInfo server) async {
    _myUsername = null;
    // A sign-out still erasing the previous session must finish first.
    await _pendingLogout;
    // Close out any previous session's client before replacing it - each
    // HydraApiClient owns its own http.Client.
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
      // login() resolves the scheme itself, so the server we are now signed in
      // to carries the scheme it really uses.
      activeServer = server.copyWith(useTls: client.usesTls);
      await _authPrefs.saveConnection(server.host, server.port);
      await _authPrefs.saveUseTls(client.usesTls);
      // A login REPLACES the stored refresh token: a server without refresh
      // tokens leaves none behind from the previous account.
      final refreshToken = resp['refreshToken'] as String?;
      await _authPrefs.saveToken(token, server.username, refreshToken: refreshToken, replaceRefreshToken: true);
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
    _myUsername = null;
    claims = const [];
    safetyByRobot.clear();
    jogArmedUntil.clear();
    isLoggedIn = false;
    _ws?.disconnect();
    _metricsTimer?.cancel();
    _hydraInfoTimer?.cancel();
    // A pending debounced command (a speed change) would otherwise be sent
    // after sign-out, with no token, and answer with a 401.
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _jogsInFlight.clear();
    stopAllResult = null;
    stopAllUnconfirmed = false;
    // The bearer token also leaves the live client, not just the stored copy.
    final client = apiClient;
    client?.authToken = null;
    _pendingLogout = _finishLogout(client);
    notifyListeners();
  }

  // Strictly in order: read the refresh token, revoke it on the server
  // (best-effort), then erase the stored session.
  Future<void> _finishLogout(HydraApiClient? client) async {
    try {
      final refreshToken = await _authPrefs.loadRefreshToken();
      if (client != null && refreshToken != null) await client.logoutRemote(refreshToken);
    } finally {
      await _authPrefs.clearToken();
    }
  }

  // The session is over for good (the token is dead and could not be
  // renewed): tell the user and sign out completely - socket, polling, timers
  // and stored tokens - not just flip the flag.
  void _forceLogout() {
    if (!isLoggedIn) return;
    lastError = const HydraError(HydraErrorKind.wsAuthRejected);
    connectionStatus = 'disconnected';
    logout();
  }

  Future<bool> _attemptTokenRefresh() async {
    final client = apiClient;
    final server = activeServer;
    if (client == null || server == null) return false;
    final refreshToken = await _authPrefs.loadRefreshToken();
    if (refreshToken == null) return false;
    try {
      final resp = await client.refresh(refreshToken);
      final newToken = resp['token'] as String?;
      if (resp['success'] != true || newToken == null) return false;
      client.authToken = newToken;
      final username = await _authPrefs.loadUsername() ?? server.username;
      await _authPrefs.saveToken(newToken, username, refreshToken: resp['refreshToken'] as String?);
      lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // The single entry to renewing the session: callers that arrive while a
  // renewal is running share its result instead of starting their own.
  Future<bool> _renewSession() {
    final inFlight = _renewalInFlight;
    if (inFlight != null) return inFlight;
    final renewal = _attemptTokenRefresh().whenComplete(() => _renewalInFlight = null);
    _renewalInFlight = renewal;
    return renewal;
  }

  // Runs [call] with the session's token. An expired or invalid token (a 403
  // TOKEN_EXPIRED / TOKEN_INVALID, or a 401) renews the session once and
  // repeats the call; any other answer, or a failed renewal, reaches the
  // caller as it came.
  Future<T> _authed<T>(Future<T> Function(HydraApiClient client) call) async {
    final client = apiClient;
    if (client == null) throw HydraApiException('Not connected');
    try {
      return await call(client);
    } on HydraApiException catch (e) {
      if (!e.isSessionProblem) rethrow;
      if (!await _renewSession()) rethrow;
      return await call(apiClient ?? client);
    }
  }

  // The server closed (or announced it would close) the socket because the
  // token is dead: the error frame and the 1008 close that follows it about
  // 100 ms later are ONE event. Renew once and reopen the socket with the new
  // token; only a failed renewal signs the user out.
  Future<void> _onWsAuthFailure(ServerInfo server) async {
    if (_handlingWsAuthFailure) return;
    _handlingWsAuthFailure = true;
    try {
      if (await _renewSession()) {
        final client = apiClient;
        if (client != null && isLoggedIn) _setupWebSocket(server, client.authToken, client.usesTls);
      } else {
        _forceLogout();
      }
    } finally {
      _handlingWsAuthFailure = false;
    }
  }

  Future<void> connect() async {
    final server = activeServer;
    final client = apiClient;
    if (server == null || client == null) return;
    connectionStatus = 'connecting';
    notifyListeners();

    try {
      // Through _authed(): a token that expired while the panel was off is
      // renewed with the refresh token instead of ending the session.
      final settings = await _authed((c) => c.getSettings());
      state = HydraState(settings);
      _ensureSelectedRobot();
      if (client.usesTls) unawaited(_authPrefs.saveUseTls(true));
      notifyListeners();
    } catch (e) {
      lastError = HydraError(HydraErrorKind.fetchFailed, {'error': '$e'});
      connectionStatus = 'error';
      if (e is HydraApiException && e.isSessionProblem) {
        // The token is dead and could not be renewed. Sign out for real and
        // stop here: the socket and the polling for a session that no longer
        // exists only kept running behind the login screen.
        _forceLogout();
        return;
      }
      notifyListeners();
    }

    _setupWebSocket(server, client.authToken, client.usesTls);
    _startMetricsLoop(client);
    _startHydraInfoLoop(client);
  }

  void _setupWebSocket(ServerInfo server, String? token, bool useTls) {
    _ws?.disconnect();
    _ws = HydraWebSocket(
      host: server.host,
      port: server.port,
      useTls: useTls,
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
        // The server's "Access denied" frame and the 1008 close that follows
        // it (the WS layer's wsAuthRejected) mean the same thing: this token
        // is dead. A client-side connection failure is never an auth one.
        final isAuthFailure = error.kind == HydraErrorKind.wsAuthRejected ||
            (error.kind == HydraErrorKind.serverMessage &&
                ((error.params['message'] ?? '').contains('denied') ||
                    (error.params['message'] ?? '').contains('token')));
        if (isAuthFailure) unawaited(_onWsAuthFailure(server));
        notifyListeners();
      },
    )..connect();
  }

  static int _asInt(dynamic v) => v is num ? v.toInt() : 0;

  SystemMetrics _metricsFrom(Map<String, dynamic> m) => SystemMetrics(
        cpuLoad: _asInt(m['cpu_load']),
        memoryUsage: _asInt(m['memory_usage']),
        temp: m['temp'] is num ? (m['temp'] as num).toDouble() : 0.0,
        uptime: _asInt(m['uptime']),
        tempIsReal: m['temp_is_real'] != false,
      );

  void _startMetricsLoop(HydraApiClient client) {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        // Carries the bearer token: a server run with
        // HYDRA_UMC_INFO_AUTH=required answers 401 to the open read.
        metrics = _metricsFrom(await client.getSystemMetrics());
        notifyListeners();
      } catch (_) {
        // best-effort background poll - a miss doesn't clear the last known reading
      }
    });
    // First reading right away instead of after the first 5 s.
    unawaited(client.getSystemMetrics().then((m) {
      metrics = _metricsFrom(m);
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
  /// partial patch - the delta-sync design mitigation (b),
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

  /// The camera that shows [robot]: the one whose assignedRobotId is this
  /// robot, else the robot's own id. The server indexes its streams by camera id.
  dynamic cameraIdFor(RobotView robot) {
    for (final cam in state.activeController?.cameras ?? const <Map<String, dynamic>>[]) {
      if (cam['assignedRobotId'] == robot.id && cam['id'] != null) return cam['id'];
    }
    return robot.id;
  }

  /// The base address of the server as the client has learned it (http or https).
  String? get serverBaseUrl => apiClient?.baseUrl ?? activeServer?.baseUrl;

  /// The error was shown to the user: forget it, so the same kind of error
  /// (the const ones are identical objects) is shown again if it happens again.
  void acknowledgeError() {
    lastError = null;
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
      // Nothing to roll back yet (no mutation applied below) - but this was
      // previously a silent no-op with zero feedback, so a stray command
      // fired while disconnected just vanished with no sign anything was
      // wrong.
      lastError = const HydraError(HydraErrorKind.notConnected);
      notifyListeners();
      return;
    }

    // A jog the server requires to be armed and that is not, or one above the
    // limit it holds for this robot's model, is not sent at all (the server
    // checks both again). Checked before the optimistic change, like the client above.
    if (command == 'jog') {
      if (jogNeedsArming(robotId)) {
        lastError = const HydraError(HydraErrorKind.jogNotArmed);
        notifyListeners();
        return;
      }
      final amount = params?['amount'];
      final exceeded = jogLimitExceeded(
        amount is num ? amount.toDouble() : 0.0,
        safetyByRobot[robotId]?.jog,
        absolute: params?['absolute'] == true,
      );
      if (exceeded != null) {
        lastError = HydraError(HydraErrorKind.jogOverLimit, {'limit': formatLimit(exceeded)});
        notifyListeners();
        return;
      }
    }

    final affectedIds = <dynamic>[robotId];
    if (propagateToCombined) affectedIds.addAll(target.combinedWith);

    // Deep-copy snapshot of every affected robot's raw state before
    // mutating: localMutate() writes straight into raw's own nested
    // maps/lists in place, so a shallow copy could not undo anything.
    //
    // Applied unconditionally here, even when `debounce` delays the actual
    // network send below - a dragged Slider still needs instant per-tick
    // visual feedback; only the real POST round-trip is worth coalescing.
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

    void rollback() {
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
    }

    final isStop = command == 'stop';
    final isJog = command == 'jog';

    Future<void> send() async {
      if (isJog) _jogsInFlight[robotId] = (_jogsInFlight[robotId] ?? 0) + 1;
      try {
        final answer = await _postWithRetry(robotId, payload, urgent: isStop);
        final warnings = _commandWarnings(answer);
        if (warnings != null) {
          // The server answered 200 but applied nothing (a speed outside its
          // range, a malformed jog): the same as a failure.
          rollback();
          lastError = HydraError(HydraErrorKind.commandNotApplied, {'command': command, 'reason': warnings});
          notifyListeners();
          return;
        }
        lastError = null;
        // The server disarms the jog on a stop.
        if (isStop) jogArmedUntil.remove(robotId);
        notifyListeners();
      } catch (e) {
        // Catches everything, not just HydraApiException: a plain network
        // failure (timeout, connection refused, DNS failure) throws
        // TimeoutException/SocketException/http's own ClientException, none
        // of which is a HydraApiException. Roll back to the pre-mutation
        // snapshot and surface the failure (see ui/main_screen.dart's own
        // lastError listener) instead of leaving the UI showing a command
        // that never reached the robot.
        rollback();
        lastError = _commandError(command, e);
        // The arming ended (it times out, or a stop cleared it): the screen offers to arm again.
        if (e is HydraApiException && e.isJogNotArmed) jogArmedUntil.remove(robotId);
        if (e is HydraApiException && e.isSessionProblem) {
          // The renewal inside _authed() already failed: the session is over.
          _forceLogout();
        }
        notifyListeners();
      } finally {
        if (isJog) {
          final left = (_jogsInFlight[robotId] ?? 1) - 1;
          if (left <= 0) {
            _jogsInFlight.remove(robotId);
          } else {
            _jogsInFlight[robotId] = left;
          }
        }
      }
    }

    // Debounced (same real mechanism as HYDRA-UMC-ANDROID-CONTROL's own
    // sendAtomicCommand): cancel any still-pending send for this exact
    // command name, then schedule a new one after `debounce` - a rapid
    // burst of calls for the same command (e.g. every Slider drag frame)
    // collapses into exactly one real POST once the drag settles.
    _debounceTimers.remove(command)?.cancel();
    if (debounce > Duration.zero) {
      _debounceTimers[command] = Timer(debounce, send);
    } else {
      await send();
    }
  }

  // A STOP is posted with short timeouts and, when nobody answers (a network
  // failure, not a refusal), sent again up to 3 times in about a second. An
  // answer from the server, of any kind, is final.
  Future<Map<String, dynamic>> _postWithRetry(dynamic robotId, Map<String, dynamic> payload, {required bool urgent}) async {
    var attempt = 0;
    while (true) {
      try {
        return await _authed(
          (c) => c.postRobotCommand(
            robotId,
            payload,
            timeout: urgent ? const Duration(seconds: 2) : const Duration(seconds: 5),
          ),
        );
      } on HydraApiException {
        rethrow; // the server answered: not a delivery problem
      } catch (_) {
        if (!urgent || attempt >= 2) rethrow;
      }
      attempt++;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  // The `warnings` of a 200 answer (the server applied nothing), joined; null when there are none.
  String? _commandWarnings(Map<String, dynamic> answer) {
    final warnings = answer['warnings'];
    if (warnings is! List || warnings.isEmpty) return null;
    return warnings.map((w) => w is Map && w['message'] is String ? w['message'] as String : '$w').join('; ');
  }

  // The user-facing error for a command that failed, by what the server said.
  HydraError _commandError(String command, Object e) {
    if (e is HydraApiException) {
      if (e.isJogNotArmed) return const HydraError(HydraErrorKind.jogNotArmed);
      if (e.isOtherController) return HydraError(HydraErrorKind.claimOtherController, {'detail': e.serverMessage ?? ''});
      if (e.isControllerIdRequired) return HydraError(HydraErrorKind.claimControllerRequired, {'detail': e.serverMessage ?? ''});
      if (e.isReservedByAnother) {
        return HydraError(HydraErrorKind.robotReserved, {'owner': e.serverMessage ?? ''});
      }
      if (e.isPermissionDenied) return const HydraError(HydraErrorKind.permissionDenied);
      if (e.isRejectedCommand) {
        return HydraError(HydraErrorKind.commandRejected, {'command': command, 'reason': e.serverMessage ?? ''});
      }
      if (e.isSessionProblem) return const HydraError(HydraErrorKind.wsAuthRejected);
    } else if (command == 'stop') {
      return const HydraError(HydraErrorKind.stopNotConfirmed);
    }
    return HydraError(HydraErrorKind.txError, {'command': command, 'error': '$e'});
  }

  void sendCommand(String command) {
    switch (command) {
      case 'play':
        _sendAtomicCommand(command, propagateToCombined: true, localMutate: (r) => r.setPlaying(true));
      case 'pause':
        // Sent as an explicit desired state, computed once from the selected
        // robot and applied identically to its combined group. Toggling each
        // member from its own local state let a pair drift in opposite
        // directions, while the server resolves one desired state.
        final paused = !(selectedRobot?.isPaused ?? false);
        _sendAtomicCommand(command, params: {'paused': paused}, propagateToCombined: true, localMutate: (r) => r.setPaused(paused));
      case 'stop':
        _sendAtomicCommand(command, propagateToCombined: true, localMutate: (r) => r.stop());
      default:
        // (There is no "enable"/"disable": the server has no such command and
        // answers 400.)
        lastError = HydraError(HydraErrorKind.unknownCommand, {'command': command});
        notifyListeners();
    }
  }

  // ---- Global STOP -------------------------------------------------------
  //
  // One tap, no confirmation, every robot: POST /api/stop-all. It does not
  // wait for any roster refresh and a reservation held by another account
  // never blocks it.

  /// The newest answer of the global STOP, shown until the user closes it.
  StopAllResult? stopAllResult;

  /// True after a STOP that never got an answer (and until a later one does):
  /// the robots may still be moving, so the app keeps saying so.
  bool stopAllUnconfirmed = false;

  /// Global STOPs on the wire right now.
  int _stopAllInFlight = 0;
  bool get stopAllInFlight => _stopAllInFlight > 0;

  void dismissStopAllResult() {
    if (stopAllResult == null) return;
    stopAllResult = null;
    notifyListeners();
  }

  /// Stops every robot at once. Never throws.
  Future<void> stopAll() async {
    _stopAllInFlight++;
    notifyListeners();
    try {
      StopAllResult? result;
      Object? failure;
      try {
        result = StopAllResult.fromJson(await _postStopAllWithRetry());
      } on HydraApiException catch (e) {
        if (e.isRateLimited || e.isNotFound) {
          // Over the global route's rate limit, or an older server without
          // it: stop the robots one by one instead.
          result = await _stopEachRobot();
        } else {
          failure = e;
        }
      } catch (e) {
        failure = e;
      }

      if (result == null) {
        stopAllUnconfirmed = true;
        lastError = const HydraError(HydraErrorKind.stopNotConfirmed);
        if (failure is HydraApiException && failure.isSessionProblem) {
          // The renewal inside _authed() already failed: the session is over.
          _forceLogout();
        }
        notifyListeners();
        return;
      }

      stopAllUnconfirmed = false;
      jogArmedUntil.clear(); // the server disarms every jog on a global stop
      stopAllResult = result;
      for (final entry in result.robots) {
        if (!entry.stopped) continue;
        for (final c in state.controllers) {
          if (entry.controllerId != null && c.id != entry.controllerId) continue;
          c.robotById(entry.robotId)?.stop();
        }
      }
      notifyListeners();
      _refreshAfterStopAll();
    } finally {
      _stopAllInFlight--;
      notifyListeners();
    }
  }

  // A network failure (not an answer of the server) is tried once more after a
  // short pause; an answer of any kind is final.
  Future<Map<String, dynamic>> _postStopAllWithRetry() async {
    try {
      return await _authed((c) => c.postStopAll());
    } on HydraApiException {
      rethrow;
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return await _authed((c) => c.postStopAll());
    }
  }

  // The per-robot "stop" for every robot of every controller, all at once.
  Future<StopAllResult> _stopEachRobot() async {
    final targets = <(String, RobotView)>[
      for (final c in state.controllers)
        for (final r in c.robots) (c.id, r),
    ];
    final entries = await Future.wait(targets.map((t) async {
      final (controllerId, robot) = t;
      try {
        await _authed((c) => c.postRobotCommand(robot.id, {'command': 'stop'}, timeout: const Duration(seconds: 2)));
        return StopAllRobot(robotId: robot.id, controllerId: controllerId, name: robot.name, stopped: true);
      } catch (e) {
        return StopAllRobot(robotId: robot.id, controllerId: controllerId, name: robot.name, stopped: false, error: '$e');
      }
    }));
    return StopAllResult.fromRobots(entries, viaFallback: true);
  }

  // Reads the state again after a STOP (the WebSocket deltas usually got there
  // first); a failure is ignored, the socket keeps the picture up to date.
  void _refreshAfterStopAll() {
    if (apiClient == null) return;
    unawaited(
      _authed((c) => c.getSettings())
          .then((settings) {
            state = HydraState(settings);
            _ensureSelectedRobot();
            notifyListeners();
          })
          .catchError((_) {}),
    );
  }

  // ---- Reservations, safety limits and jog arming (contract v2, block 1) ----
  //
  // Reservations are optional: a robot nobody reserved is commanded as before.
  // The controller id (HydraApiClient.controllerId) is sent with every reserve,
  // release, jog-arm and command, so a reservation belongs to the account AND
  // to this installation.

  /// Every active reservation, as of the last refresh (GET /api/claims).
  List<ClaimInfo> claims = const [];

  /// The limits of each robot's model the server told this app about, by robot id.
  final Map<dynamic, RobotSafety> safetyByRobot = {};

  /// Until when (this device's clock) the jog of each robot is armed from this app.
  final Map<dynamic, DateTime> jogArmedUntil = {};

  /// True while a reservation or arming request is on the wire.
  bool accessBusy = false;

  String get controllerId => HydraApiClient.controllerId;

  /// The reservation of [robotId], if any.
  ClaimInfo? claimOf(dynamic robotId) {
    for (final c in claims) {
      if (c.robotId == robotId) return c;
    }
    return null;
  }

  /// Where [robotId] stands for this installation, from the last list of reservations.
  ClaimStanding claimStandingOf(dynamic robotId) =>
      claimStanding(claimOf(robotId), _myUsername ?? activeServer?.username ?? '', controllerId);

  // The account name of this session: a restored session has no password and
  // so no username on the server entry; the saved one is read once.
  String? _myUsername;

  /// True when the server requires the jog of [robotId] to be armed and it is
  /// not (this app's view of it).
  bool jogNeedsArming(dynamic robotId, [DateTime? now]) {
    final safety = safetyByRobot[robotId];
    if (safety == null || !safety.armRequired) return false;
    final until = jogArmedUntil[robotId];
    return until == null || !until.isAfter(now ?? DateTime.now());
  }

  /// Reads the reservations and the limits of the selected robot's model from
  /// the server. Called when the control screen opens, when the robot changes
  /// and now and then while it is open; it never raises an error on the screen
  /// (the server may simply be an older one).
  Future<void> refreshAccess() async {
    if (apiClient == null) return;
    final robotId = selectedRobotId;
    if (_myUsername == null) {
      final named = activeServer?.username ?? '';
      _myUsername = named.isNotEmpty ? named : await _authPrefs.loadUsername();
    }
    try {
      claims = await _authed((c) => c.getClaims());
    } catch (e) {
      if (e is HydraApiException && e.isSessionProblem) _forceLogout();
    }
    if (robotId != null) {
      try {
        final safety = await _authed((c) => c.getRobotSafety(robotId));
        if (safety != null) {
          safetyByRobot[robotId] = safety;
          final until = safety.jogArmedUntil;
          final now = DateTime.now();
          // The server clock and this device clock may differ: the arming is
          // shown as ending no later than its length allows.
          if (until != null && until > now.millisecondsSinceEpoch) {
            final byServer = DateTime.fromMillisecondsSinceEpoch(until);
            final byLength = now.add(Duration(milliseconds: safety.armTtlMs));
            jogArmedUntil[robotId] = byServer.isBefore(byLength) ? byServer : byLength;
          } else {
            jogArmedUntil.remove(robotId);
          }
        }
      } catch (e) {
        if (e is HydraApiException && e.isSessionProblem) _forceLogout();
      }
    }
    notifyListeners();
  }

  /// Reserves the selected robot for this account on this installation.
  Future<void> claimSelectedRobot() => _runAccessRequest('claim', (c, id) => c.postClaim(id));

  /// Whether this session is an administrator's (the role in its token; the server checks it again).
  bool get isAdmin => jwtRole(apiClient?.authToken) == 'admin';

  /// Whether the take-over button applies to [robotId]: an administrator, and someone else holds it.
  bool canTakeOver(dynamic robotId) => canTakeOverRobot(jwtRole(apiClient?.authToken), claimStandingOf(robotId));

  /// Takes the selected robot over from whoever holds it (`force: true`; the server accepts it from administrators
  /// only). The screen asks the operator to confirm first; nothing is sent when it does not apply.
  Future<void> takeOverSelectedRobot() {
    if (!canTakeOver(selectedRobotId)) return Future.value();
    return _runAccessRequest('claim', (c, id) => c.postClaim(id, force: true));
  }

  /// Releases the selected robot's reservation. Also ends the arming of its jog, as the server does.
  Future<void> releaseSelectedRobot() => _runAccessRequest('release', (c, id) async {
        final answer = await c.postRelease(id);
        jogArmedUntil.remove(id);
        return answer;
      });

  /// Arms or disarms the jog of the selected robot (only needed when the server requires it).
  Future<void> setJogArmed(bool armed) => _runAccessRequest('jog-arm', (c, id) async {
        final answer = await c.postJogArm(id, armed);
        if (armed) {
          final ttl = answer['ttlMs'] is num ? (answer['ttlMs'] as num).toInt() : (safetyByRobot[id]?.armTtlMs ?? 60000);
          jogArmedUntil[id] = DateTime.now().add(Duration(milliseconds: ttl));
        } else {
          jogArmedUntil.remove(id);
        }
        return answer;
      });

  Future<void> _runAccessRequest(String what, Future<Map<String, dynamic>> Function(HydraApiClient, dynamic) call) async {
    final robotId = selectedRobotId;
    if (robotId == null) return;
    if (apiClient == null) {
      lastError = const HydraError(HydraErrorKind.notConnected);
      notifyListeners();
      return;
    }
    accessBusy = true;
    notifyListeners();
    try {
      await _authed((c) => call(c, robotId));
      lastError = null;
    } catch (e) {
      lastError = _commandError(what, e);
      if (e is HydraApiException && e.isSessionProblem) _forceLogout();
    } finally {
      accessBusy = false;
    }
    notifyListeners();
    await refreshAccess();
  }

  /// True while a jog should not be sent: the previous tick is still on the
  /// wire, or the robot is running a trajectory (the server's playback and a
  /// jog would both write the same setpoint).
  bool jogBlocked([dynamic robotId]) {
    final id = robotId ?? selectedRobotId;
    if (id == null) return true;
    if ((_jogsInFlight[id] ?? 0) > 0) return true;
    final robot = state.robotById(id);
    if (robot == null) return true;
    return robot.isPlaying && !robot.isPaused;
  }

  /// One tick of a held jog button: up to three axes in one go, dropped as a
  /// whole while the previous tick is still on the wire.
  void jogXYZ(String target, int dx, int dy, int dz, double step) {
    if (jogBlocked()) return;
    if (dx != 0) jog(target, 'x', dx * step);
    if (dy != 0) jog(target, 'y', dy * step);
    if (dz != 0) jog('robot', 'z', dz * step);
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
    _disposed = true;
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
