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
      behavior: HitTestBehavior.opaque, // Ensure gestures are captured reliably
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
    if (controller.status == DragMiniStatus.mini) {
      controller.startDragging(DragMiniStatus.draggingHorizontal);
    } else {
      controller.startDragging(DragMiniStatus.draggingVertical);
    }
  }

  void _onPanUpdate(DragUpdateDetails details, BuildContext context) {
    final size = MediaQuery.of(context).size;
    final delta = details.delta;

    if (controller.status == DragMiniStatus.draggingVertical) {
      // Scale based on vertical movement relative to screen height
      final progressDelta = delta.dy / (size.height * 0.7);
      controller.updateDragProgress(controller.progress + progressDelta);
    } else if (controller.status == DragMiniStatus.draggingHorizontal) {
      // Free form 2D movement in mini mode
      controller.setMiniPosition(controller.position + delta);
    }
  }

  void _onPanEnd(DragEndDetails details, BuildContext context) {
    final velocity = details.velocity.pixelsPerSecond;
    final progress = controller.progress;

    if (controller.status == DragMiniStatus.draggingVertical) {
      // Snap to full or mini based on velocity and position
      if (velocity.dy > 500 || progress > 0.4) {
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
      // Update status to mini (saves position definitively) or dismiss
      if (velocity.dx.abs() > 1000) {
        controller.dismiss();
      } else {
        // Just revert status from dragging to mini
        controller.minimize();
      }
    }
  }
}
