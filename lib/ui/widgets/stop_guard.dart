// =============================================================================
// HYDRA-UMC DSI (Flutter) - ui/widgets/stop_guard.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The global STOP stays pressable while a dialog or a menu is open. A modal
// window of Flutter lays a barrier over the whole screen, the top bar and its
// STOP included: the first press only closed the window, or did nothing.
//
//  * StopGuardObserver knows whether a popup (dialog, menu, sheet) is up.
//  * StopGuard sits above the navigator (MaterialApp.builder) and, while one is,
//    draws the global STOP above everything, where the one of the top bar is,
//    and what the STOP did at the bottom.
//  * stopGuardDialogInsets keeps every dialog out of the corner of that STOP.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../state/robot_view_model.dart';
import 'stop_all.dart';

/// The margin of every dialog: wide enough at the sides that no dialog reaches the STOP of the top right corner.
const EdgeInsets stopGuardDialogInsets = EdgeInsets.symmetric(horizontal: 140, vertical: 24);

/// Knows whether something modal covers the screen. Give it to MaterialApp.navigatorObservers.
class StopGuardObserver extends NavigatorObserver {
  /// True while at least one popup route is on the navigator.
  final ValueNotifier<bool> covered = ValueNotifier<bool>(false);

  final Set<Route<dynamic>> _popups = <Route<dynamic>>{};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _change(add: route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _change(remove: route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _change(remove: route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _change(add: newRoute, remove: oldRoute);

  void _change({Route<dynamic>? add, Route<dynamic>? remove}) {
    if (remove != null) _popups.remove(remove);
    if (add is PopupRoute) _popups.add(add);
    // The navigator may call this while the frame is being built: the listeners are then told after it.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => covered.value = _popups.isNotEmpty);
    } else {
      covered.value = _popups.isNotEmpty;
    }
  }
}

/// Draws the global STOP above [child] (the navigator) while a popup covers it. Nothing is drawn before sign-in.
class StopGuard extends StatelessWidget {
  const StopGuard({super.key, required this.observer, required this.child});

  final StopGuardObserver observer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<RobotViewModel, bool>((vm) => vm.isLoggedIn);
    return Stack(
      children: [
        Positioned.fill(child: child),
        ValueListenableBuilder<bool>(
          valueListenable: observer.covered,
          builder: (context, covered, _) => covered && signedIn ? const Positioned.fill(child: _StopLayer()) : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// An overlay of its own (the tooltips need one above them); a touch outside its two widgets goes through.
class _StopLayer extends StatelessWidget {
  const _StopLayer();

  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => const Stack(
            children: [
              Positioned(top: 10, right: 8, child: StopAllButton(key: Key('stop-guard'))),
              Positioned(left: 0, right: 0, bottom: 0, child: Material(type: MaterialType.transparency, child: StopAllBanner())),
            ],
          ),
        ),
      ],
    );
  }
}
