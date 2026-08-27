// =============================================================================
// HYDRA-UMC DSI (Flutter) - main.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0 - see LICENSE
//
// Entry point - ported from HYDRA-UMC-IOS-CONTROL's own main.dart. Same
// dark theme/color seed as the other 2 apps in this ecosystem (a robot
// arm looks the same red/green/cyan whichever client is showing it), same
// login-gated root widget. The window itself starts at a fixed 1280x720
// (see linux/runner/my_application.cc and windows/runner/main.cpp) -
// nothing about layout here needs to react to a different size, since the
// real hardware this ships to never runs at any other resolution.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/robot_view_model.dart';
import 'ui/login_screen.dart';
import 'ui/main_screen.dart';

void main() {
  runApp(const HydraUmcDsiApp());
}

class HydraUmcDsiApp extends StatelessWidget {
  const HydraUmcDsiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RobotViewModel()..init(),
      child: MaterialApp(
        title: 'HYDRA-UMC DSI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF07090C),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00E5FF),
            brightness: Brightness.dark,
            surface: const Color(0xFF12161C),
          ),
          useMaterial3: true,
          // Larger default tap targets ecosystem-wide would be a bigger
          // change than this app needs - individual widgets (JoystickPad,
          // the nav bar, playback buttons) already size themselves for
          // touch directly, see each file's own header comment.
          visualDensity: VisualDensity.standard,
        ),
        home: const _RootGate(),
      ),
    );
  }
}

/// Shows the login screen until a session is active - same gating
/// HYDRA-UMC-IOS-CONTROL's own main.dart uses.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RobotViewModel>();
    return vm.isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}
