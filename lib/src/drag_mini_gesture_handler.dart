import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'drag_mini_window_controller.dart';
import 'drag_mini_window_state.dart';

/// Aggregates gestures and maps them to Controller actions.
///
/// Three modes:
/// - **From MAX**: Any drag direction shrinks the player. The mini-player
///   target follows the finger in 2D so it lands exactly where you release.
/// - **From MINI**: Free-form 2D repositioning. Tap to maximize.
///   A fast horizontal flick dismisses the player.
/// - **Docking**: If the user holds the mini-player stationary for 500ms+
///   during a drag, the player adaptively expands to a docked bottom bar.
class DragMiniGestureHandler extends StatefulWidget {
  /// Creates an internal [DragMiniGestureHandler].
  const DragMiniGestureHandler({
    super.key,
    required this.controller,
    required this.child,
    this.dockHoldDuration = const Duration(milliseconds: 500),
  });

  /// The controller managing the window state.
  final DragMiniWindowController controller;

  /// The child widget that will receive gestures.
  final Widget child;

  /// How long the user must hold stationary before docking triggers.
  final Duration dockHoldDuration;

  @override
  State<DragMiniGestureHandler> createState() => _DragMiniGestureHandlerState();
}

class _DragMiniGestureHandlerState extends State<DragMiniGestureHandler> {
  // Track accumulated drag distance from the start point
  Offset _dragAccumulator = Offset.zero;

  // --- Docking hold detection ---
  Timer? _dockTimer;

  /// Movement threshold below which we consider the finger "stationary".
  static const double _stationaryThreshold = 2.0;

  DragMiniWindowController get controller => widget.controller;

  @override
  void dispose() {
    _cancelDockTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      onPanStart: _onPanStart,
      onPanUpdate: (details) => _onPanUpdate(details, context),
      onPanEnd: (details) => _onPanEnd(details, context),
      child: widget.child,
    );
  }

  void _onTap() {
    if (controller.isMinimized) {
      controller.maximize();
    }
  }

  void _onPanStart(DragStartDetails details) {
    _dragAccumulator = Offset.zero;
    _cancelDockTimer();

    if (controller.status == DragMiniStatus.docked) {
      // Dragging from docked undocks first
      controller.undock();
      controller.startDragging(DragMiniStatus.draggingHorizontal);
    } else if (controller.status == DragMiniStatus.mini) {
      controller.startDragging(DragMiniStatus.draggingHorizontal);
    } else {
      controller.startDragging(DragMiniStatus.draggingVertical);
    }
  }

  void _onPanUpdate(DragUpdateDetails details, BuildContext context) {
    final size = MediaQuery.of(context).size;
    final delta = details.delta;
    _dragAccumulator += delta;

    if (controller.status == DragMiniStatus.draggingVertical) {
      // --- FROM MAX MODE: Shrink towards the finger ---

      // 1. Progress = how far the finger has moved from the start point.
      //    Use the MAXIMUM of abs(dx) and abs(dy) so ANY direction works.
      final maxDragDistance =
          size.height * 0.5; // half screen = fully minimized
      final dragMagnitude = max(
        _dragAccumulator.dx.abs(),
        _dragAccumulator.dy.abs(),
      );
      final newProgress = (dragMagnitude / maxDragDistance).clamp(0.0, 1.0);
      controller.updateDragProgress(newProgress);

      // 2. Update the mini target position to follow the finger (both axes).
      final fingerGlobal = details.globalPosition;
      const miniW = 160.0;
      const miniH = 90.0;
      final newDx = (fingerGlobal.dx - miniW / 2).clamp(
        0.0,
        size.width - miniW,
      );
      final newDy = (fingerGlobal.dy - miniH / 2).clamp(
        0.0,
        size.height - miniH,
      );
      controller.setMiniPosition(Offset(newDx, newDy));
    } else if (controller.status == DragMiniStatus.draggingHorizontal) {
      // --- FROM MINI MODE: Free-form 2D repositioning ---
      controller.setMiniPosition(controller.position + delta);

      // --- Docking hold detection ---
      // If the finger is barely moving, start/restart the dock timer.
      if (delta.distance < _stationaryThreshold) {
        _startDockTimerIfNeeded();
      } else {
        _cancelDockTimer();
      }
    }
  }

  void _onPanEnd(DragEndDetails details, BuildContext context) {
    _cancelDockTimer();

    final velocity = details.velocity.pixelsPerSecond;
    final progress = controller.progress;
    final speed = max(velocity.dx.abs(), velocity.dy.abs());

    if (controller.status == DragMiniStatus.draggingVertical) {
      // Snap to mini if dragged far enough OR flicked fast enough
      if (speed > 500 || progress > 0.3) {
        controller.snapWithPhysics(
          velocity: speed / 1000,
          targetProgress: 1.0,
          targetStatus: DragMiniStatus.mini,
        );
      } else {
        // Snap back to full
        controller.snapWithPhysics(
          velocity: speed / 1000,
          targetProgress: 0.0,
          targetStatus: DragMiniStatus.full,
        );
      }
    } else if (controller.status == DragMiniStatus.draggingHorizontal) {
      // Dismiss on fast horizontal flick, otherwise keep position
      if (velocity.dx.abs() > 1000) {
        controller.dismiss();
      } else {
        controller.minimize();
      }
    }
  }

  // --- Dock timer helpers ---

  void _startDockTimerIfNeeded() {
    if (_dockTimer != null) return; // Already running
    _dockTimer = Timer(widget.dockHoldDuration, () {
      if (mounted && controller.isDragging) {
        HapticFeedback.mediumImpact();
        controller.dock();
      }
    });
  }

  void _cancelDockTimer() {
    _dockTimer?.cancel();
    _dockTimer = null;
  }
}
