import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'drag_mini_window_controller.dart';
import 'drag_mini_window_state.dart';

/// Aggregates gestures and maps them to Controller actions.
class DragMiniGestureHandler extends StatelessWidget {
  /// Creates an internal [DragMiniGestureHandler].
  const DragMiniGestureHandler({
    super.key,
    required this.controller,
    required this.child,
  });

  /// The controller managing the window state.
  final DragMiniWindowController controller;

  /// The child widget that will receive gestures.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: (details) => _onPanUpdate(details, context),
      onPanEnd: (details) => _onPanEnd(details, context),
      child: child,
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (controller.isMinimized) {
      controller.startDragging(DragMiniStatus.draggingHorizontal);
    } else {
      controller.startDragging(DragMiniStatus.draggingVertical);
    }
  }

  void _onPanUpdate(DragUpdateDetails details, BuildContext context) {
    final size = MediaQuery.of(context).size;
    final delta = details.delta;

    if (controller.status == DragMiniStatus.draggingVertical) {
      // Horizontal drag doesn't affect progress in full mode usually,
      // but vertical drag shrinks it toward mini.
      final progressDelta = delta.dy / (size.height * 0.5);
      controller.updateDragProgress(controller.progress + progressDelta);
    } else if (controller.status == DragMiniStatus.draggingHorizontal) {
      // Free form 2D movement in mini mode
      controller.updateMiniPosition(controller.position + delta);
    }
  }

  void _onPanEnd(DragEndDetails details, BuildContext context) {
    final velocity = details.velocity.pixelsPerSecond;
    final progress = controller.progress;

    if (controller.status == DragMiniStatus.draggingVertical) {
      if (velocity.dy > 500 || progress > 0.5) {
        controller.snapWithPhysics(
          velocity: velocity.dy / 1000,
          targetProgress: 1.0,
          targetStatus: DragMiniStatus.mini,
        );
      } else {
        controller.snapWithPhysics(
          velocity: velocity.dy / 1000,
          targetProgress: 0.0,
          targetStatus: DragMiniStatus.full,
        );
      }
    } else if (controller.status == DragMiniStatus.draggingHorizontal) {
      // Logic for snapping mini window to edges or dismissing
      if (velocity.dx.abs() > 1000) {
        controller.dismiss();
      } else {
        // Just keep the new position
        controller.minimize();
      }
    }
  }
}
