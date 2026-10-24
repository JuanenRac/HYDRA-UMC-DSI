// =============================================================================
// HYDRA-UMC DSI (Flutter) - util/play_confirmation.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// When PLAY asks first. It asks when the person left the option on (it is on
// until they turn it off) and the robot is not already playing: a robot that
// is playing or paused is resumed from the console it is already on, there is
// no new trajectory to confirm.
// =============================================================================

/// Whether PLAY must show the confirmation.
bool playNeedsConfirmation({required bool askBeforePlay, required bool robotIsPlaying}) => askBeforePlay && !robotIsPlaying;

/// The speed of the robot as a whole percent for the summary; a value that is
/// not a number or is negative is 0.
int playSpeedPercent(double speed) => speed.isNaN || speed.isInfinite || speed < 0 ? 0 : speed.round();

/// The number of recorded points of a robot (0 when the state has none or has damaged data).
int recordedPointsCount(Map<String, dynamic> raw) {
  final points = raw['recordedPoints'];
  return points is List ? points.length : 0;
}
