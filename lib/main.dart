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

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'state/robot_view_model.dart';
import 'ui/login_screen.dart';
import 'ui/main_screen.dart';

/// Attached to MaterialApp's scaffoldMessengerKey: the only way an error caught
/// outside Flutter's build/layout/paint pipeline (no BuildContext of its own)
/// can still put something on screen. debugPrint alone is invisible in a
/// release build, and a panel next to a robot has no debugger attached.
final GlobalKey<ScaffoldMessengerState> _rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

void _surfaceAsyncError(Object error) {
  final context = _rootMessengerKey.currentContext;
  final message = context != null ? AppLocalizations.of(context)?.errorUnexpected('$error') : null;
  _rootMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message ?? 'Unexpected error: $error'),
      backgroundColor: const Color(0xFFB91C1C),
      duration: const Duration(seconds: 6),
    ),
  );
}

void main() {
  // Without these, an uncaught exception either shows Flutter's blank grey
  // box (a widget failing to build: the whole Control tab with STOP in it) or
  // leaves an async error with no sign anything went wrong at all.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Uncaught Flutter error: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error\n$stack');
    _surfaceAsyncError(error);
    return true; // handled - don't crash the isolate over it
  };
  ErrorWidget.builder = (details) => _CrashScreen(details: details);
  runZonedGuarded(
    () => runApp(const HydraUmcDsiApp()),
    (error, stack) {
      debugPrint('Uncaught zone error: $error\n$stack');
      _surfaceAsyncError(error);
    },
  );
}

/// Replaces a widget that failed to build, with a way to get the details out
/// of the device (the on-screen text is debug-only).
class _CrashScreen extends StatefulWidget {
  final FlutterErrorDetails details;
  const _CrashScreen({required this.details});

  @override
  State<_CrashScreen> createState() => _CrashScreenState();
}

class _CrashScreenState extends State<_CrashScreen> {
  bool _copied = false;

  Future<void> _copyDetails() async {
    final text = '${widget.details.exceptionAsString()}\n\n${widget.details.stack ?? ''}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    // AppLocalizations may not be resolvable if this renders before the app's
    // delegates are ready: fall back to English instead of crashing the crash screen.
    final l10n = AppLocalizations.of(context);
    return Container(
      color: const Color(0xFF07090C),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E), size: 48),
          const SizedBox(height: 12),
          Text(
            l10n?.crashMessage ?? 'Something went wrong displaying this screen.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Text(
              widget.details.exceptionAsString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          Material(
            type: MaterialType.transparency,
            child: TextButton.icon(
              onPressed: _copyDetails,
              icon: Icon(_copied ? Icons.check : Icons.copy, size: 16, color: _copied ? const Color(0xFF10B981) : Colors.white70),
              label: Text(
                _copied ? (l10n?.crashCopied ?? 'Copied') : (l10n?.crashCopyDetails ?? 'Copy error details'),
                style: TextStyle(color: _copied ? const Color(0xFF10B981) : Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HydraUmcDsiApp extends StatelessWidget {
  const HydraUmcDsiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RobotViewModel()..init(),
      child: Consumer<RobotViewModel>(
        builder: (context, vm, _) => MaterialApp(
          title: 'HYDRA-UMC DSI',
          scaffoldMessengerKey: _rootMessengerKey,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          // null lets Flutter resolve the OS locale itself against
          // supportedLocales (falling back to English) - only set once the
          // user has made an explicit choice in ui/settings_screen.dart,
          // see state/robot_view_model.dart's own languageOverride.
          locale: vm.languageOverride,
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
