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
    return RawGestureDetector(
      gestures: {
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(),
          (instance) {
            instance
              ..onStart = _onVerticalStart
              ..onUpdate = _onVerticalUpdate
              ..onEnd = _onVerticalEnd;
          },
        ),
        HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(),
          (instance) {
            instance
              ..onStart = _onHorizontalStart
              ..onUpdate = _onHorizontalUpdate
              ..onEnd = _onHorizontalEnd;
          },
        ),
      },
      child: child,
    );
  }

  // --- Vertical Drag (Minimize/Maximize) ---

  void _onVerticalStart(DragStartDetails details) {
    controller.startDragging(DragMiniStatus.draggingVertical);
  }

  void _onVerticalUpdate(DragUpdateDetails details) {
    const screenHeight = 800.0; // Should be dynamic from MediaQuery
    final delta = details.primaryDelta! / (screenHeight * 0.5);
    controller.updateDragProgress(controller.progress + delta);
  }

  void _onVerticalEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    const spring = SpringDescription(mass: 1, stiffness: 150, damping: 15);
    final progress = controller.progress;

    if (velocity > 500 || progress > 0.5) {
      controller.snapWithPhysics(
        velocity: velocity / 1000,
        targetProgress: 1.0,
        targetStatus: DragMiniStatus.mini,
        spring: spring,
      );
    } else {
      controller.snapWithPhysics(
        velocity: velocity / 1000,
        targetProgress: 0.0,
        targetStatus: DragMiniStatus.full,
      );
    }
  }

  // --- Horizontal Drag (Dismiss Mini) ---

  void _onHorizontalStart(DragStartDetails details) {
    if (controller.status != DragMiniStatus.mini) return;
    controller.startDragging(DragMiniStatus.draggingHorizontal);
  }

  void _onHorizontalUpdate(DragUpdateDetails details) {
    if (controller.status != DragMiniStatus.draggingHorizontal) return;
    // Update X position for dismissal visual
    controller.updateMiniPosition(controller.position + details.delta);
  }

  void _onHorizontalEnd(DragEndDetails details) {
    if (controller.status != DragMiniStatus.draggingHorizontal) return;
    // Snap back or dismiss based on velocity/distance
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity.abs() > 800) {
      controller.dismiss();
    } else {
      controller.minimize(); // Snap back
    }
  }
}
