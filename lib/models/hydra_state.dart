// =============================================================================
// HYDRA-UMC DSI (Flutter) - models/hydra_state.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Thin, mutation-friendly views over the raw settings.json tree - copied
// verbatim from HYDRA-UMC-IOS-CONTROL's own models/hydra_state.dart (same
// Dart/Flutter stack, direct reuse per [[No reference -> reuse, don't
// invent]]), which itself mirrors HYDRA-UMC-ANDROID-CONTROL's own
// model/HydraState.kt and HYDRA-UMC-SUITE's own hydra_suite/models.py: NOT
// a strict schema that (de)serializes every field HYDRA-UMC-STUDIO's own
// store.tsx defines, only the handful this app actually reads/writes.
// Every field this class doesn't expose an accessor for still passes
// through untouched.
// =============================================================================

/// Thin, mutation-friendly view over one entry of controllers[].robots[].
class RobotView {
  final Map<String, dynamic> raw;
  RobotView(this.raw);

  dynamic get id => raw['id'];
  String get name => (raw['name'] ?? 'Robot $id') as String;
  bool get online => (raw['online'] ?? false) as bool;
  String get model => (raw['model'] ?? 'Generic (6-DOF)') as String;
  String get role => (raw['role'] ?? 'Idle') as String;
  String get tool => (raw['tool'] ?? 'None') as String;
  bool get hasXYTable => (raw['hasXYTable'] ?? false) as bool;

  String get manufacturer {
    final m = model;
    if (m.contains('Parol6') || m.contains('Faze4')) return 'Source Robotics';
    if (m.contains('AR3') || m.contains('AR4')) return 'Annin Robotics';
    if (m.contains('UR') || m.contains('Universal')) return 'Universal Robots';
    if (m.contains('xArm') || m.contains('Lite 6')) return 'UFACTORY';
    if (m.contains('Gen3') || m.contains('Gen2')) return 'Kinova';
    if (m.contains('ViperX') || m.contains('WidowX')) return 'Trossen Robotics';
    if (m.contains('e.DO')) return 'Comau';
    if (m.contains('Z1')) return 'Unitree';
    if (m.contains('PiPER')) return 'AgileX';
    return 'Generic';
  }

  bool _moduleEnabled(String key) => (raw[key]?['enabled'] ?? false) as bool;
  bool get hasPnP => _moduleEnabled('juanenPnP') || _moduleEnabled('lumenPnP');
  bool get hasCNC => _moduleEnabled('juanenCNC');
  bool get hasLaser => _moduleEnabled('juanenLaser');
  bool get hasHeatedBed => _moduleEnabled('heatedBed');
  bool get hasVacuumTable => _moduleEnabled('vacuumTable');
  // Real signal is visionEnabled or the paired camera's own connected flag -
  // NOT mere presence of a "camera"/"cameraView" key. Matches the same fix
  // in HYDRA-UMC-STUDIO's own Dashboard Overview and both Android/iOS.
  bool get hasCamera => (raw['visionEnabled'] ?? false) as bool || ((raw['camera']?['connected']) ?? false) as bool;
  bool get hasAtc => raw.containsKey('atc');
  bool get hasRack => _moduleEnabled('rackSystem');

  List<int> get combinedWith {
    final arr = raw['combinedWith'];
    if (arr is List) return arr.map((e) => e as int).toList();
    return const [];
  }

  void setOnline(bool value) => raw['online'] = value;
  void setTool(String value) => raw['tool'] = value;

  List<dynamic> get valves => (raw['valves'] ??= [false, false]) as List<dynamic>;
  void setValve(int index, bool state) => valves[index] = state;

  List<dynamic> get pumps => (raw['pumps'] ??= [false, false]) as List<dynamic>;
  void setPump(int index, bool state) => pumps[index] = state;

  Map<String, dynamic> get joints => (raw['joints'] ??= <String, dynamic>{}) as Map<String, dynamic>;
  void setJoint(String joint, double value) => joints[joint] = value;

  Map<String, dynamic> get pos => (raw['pos'] ??= <String, dynamic>{}) as Map<String, dynamic>;
  double posAxis(String axis) => ((pos[axis] ?? 0.0) as num).toDouble();
  void setPosAxis(String axis, double value) => pos[axis] = value;

  Map<String, dynamic> get xyTable => (raw['xyTable'] ??= <String, dynamic>{}) as Map<String, dynamic>;
  Map<String, dynamic> get xyTablePos => (xyTable['pos'] ??= <String, dynamic>{}) as Map<String, dynamic>;
  void setXyTableAxis(String axis, double value) {
    xyTablePos[axis] = value;
    if (axis == 'x') pos['tx'] = value;
    if (axis == 'y') pos['ty'] = value;
  }

  Map<String, dynamic> get playbackState => (raw['playbackState'] ??= <String, dynamic>{}) as Map<String, dynamic>;
  bool get isPlaying => (playbackState['isPlaying'] ?? playbackState['playing'] ?? false) as bool;
  bool get isPaused => (playbackState['isPaused'] ?? playbackState['paused'] ?? false) as bool;
  double get speed => ((playbackState['speed'] ?? 100.0) as num).toDouble();
  double get acceleration => ((playbackState['acceleration'] ?? 100.0) as num).toDouble();

  void setPlaying(bool playing) {
    final pb = playbackState;
    pb['isPlaying'] = playing;
    pb['playing'] = playing;
    pb['requestStop'] = !playing;
    if (playing) {
      pb['activeStep'] = 0;
      pb['isFinished'] = false;
      pb['finished'] = false;
      pb['isPaused'] = false;
      pb['paused'] = false;
      pb['requestPause'] = false;
    } else {
      pb['activeStep'] = -1;
      pb['isFinished'] = false;
      pb['finished'] = false;
    }
  }

  void togglePaused() {
    final newVal = !isPaused;
    final pb = playbackState;
    pb['isPaused'] = newVal;
    pb['paused'] = newVal;
    pb['requestPause'] = newVal;
    pb['isPlaying'] = true;
    pb['playing'] = true;
    pb['isFinished'] = false;
    pb['finished'] = false;
  }

  void stop() {
    final pb = playbackState;
    pb['isPlaying'] = false;
    pb['playing'] = false;
    pb['requestStop'] = true;
    pb['isPaused'] = false;
    pb['paused'] = false;
    pb['requestPause'] = false;
    pb['activeStep'] = -1;
  }

  void setSpeed(double value) => playbackState['speed'] = value;
  void setAcceleration(double value) => playbackState['acceleration'] = value;

  Map<String, dynamic>? get controllerBoard => raw['controllerBoard'] as Map<String, dynamic>?;
  Map<String, dynamic>? get urtcHead => raw['urtcHead'] as Map<String, dynamic>?;
  Map<String, dynamic>? get urtcExpansion => raw['urtcExpansion'] as Map<String, dynamic>?;

  @override
  String toString() => 'RobotView(id=$id, name=$name, online=$online)';
}

/// Thin view over one entry of the top-level controllers[] array.
class ControllerView {
  final Map<String, dynamic> raw;
  ControllerView(this.raw);

  String get id => (raw['id'] ?? '') as String;
  String get name => (raw['name'] ?? id) as String;
  String get ip => (raw['ip'] ?? '') as String;

  List<RobotView> get robots {
    final arr = raw['robots'];
    if (arr is List) return arr.map((r) => RobotView(r as Map<String, dynamic>)).toList();
    return const [];
  }

  RobotView? robotById(dynamic robotId) {
    for (final r in robots) {
      if (r.id == robotId) return r;
    }
    return null;
  }

  List<Map<String, dynamic>> get cameras {
    final arr = raw['cameras'];
    if (arr is List) return arr.cast<Map<String, dynamic>>();
    return const [];
  }
}

/// Root wrapper over the full settings.json tree - {settings, controllers,
/// activeControllerId, ...}.
class HydraState {
  final Map<String, dynamic> raw;
  HydraState([Map<String, dynamic>? raw]) : raw = raw ?? <String, dynamic>{};

  List<ControllerView> get controllers {
    final arr = raw['controllers'];
    if (arr is List) return arr.map((c) => ControllerView(c as Map<String, dynamic>)).toList();
    return const [];
  }

  String get activeControllerId => (raw['activeControllerId'] ?? '') as String;

  ControllerView? get activeController {
    final cid = activeControllerId;
    for (final c in controllers) {
      if (c.id == cid) return c;
    }
    final all = controllers;
    return all.isNotEmpty ? all.first : null;
  }

  RobotView? robotById(dynamic robotId) => activeController?.robotById(robotId);

  /// Shallow merge of an incoming delta/settings payload into this state's
  /// own raw tree. See HYDRA-UMC-IOS-CONTROL's own equivalent method for
  /// the full reasoning (a WS payload is always the full tree, so a full
  /// replace is correct here too, not a partial merge).
  void merge(Map<String, dynamic> other) {
    raw.addAll(other);
  }

  Map<String, dynamic> toJson() => raw;
}
