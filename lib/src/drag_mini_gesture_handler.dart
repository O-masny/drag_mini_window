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
      onTap: _onTap,
      onPanStart: _onPanStart,
      onPanUpdate: (details) => _onPanUpdate(details, context),
      onPanEnd: (details) => _onPanEnd(details, context),
      child: child,
    );
  }

  void _onTap() {
    if (controller.isMinimized) {
      controller.maximize();
    }
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
      // Scale based on vertical movement
      final progressDelta = delta.dy / (size.height * 0.8);
      controller.updateDragProgress(controller.progress + progressDelta);
    } else if (controller.status == DragMiniStatus.draggingHorizontal) {
      // Free form 2D movement.
      // If the controller doesn't have a valid position yet, we initialize it
      // to the "natural" mini position before adding the delta.
      var currentPos = controller.position;
      if (currentPos == Offset.zero) {
        // For now, we assume bottom right as the most common home
        currentPos = Offset(
          size.width - 160 - 16,
          size.height - 90 - 16,
        );
      }
      controller.setMiniPosition(currentPos + delta);
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
