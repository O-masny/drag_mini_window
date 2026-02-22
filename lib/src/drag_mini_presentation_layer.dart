import 'dart:ui';

import 'package:flutter/material.dart';

import 'drag_mini_window_controller.dart';
import 'drag_mini_window_state.dart';
import 'drag_mini_window_style.dart';

/// The actual UI layer that lives inside the Overlay.
/// Responsible for the high-performance Transform (Scale + Translate).
class DragMiniPresentationLayer extends StatelessWidget {
  /// Internal constructor for the presentation layer.
  const DragMiniPresentationLayer({
    super.key,
    required this.controller,
    required this.expandedContent,
    required this.miniContent,
    required this.style,
    this.title,
    this.thumbnail,
  });

  /// The controller managing the window state.
  final DragMiniWindowController controller;

  /// Content shown in full-screen mode.
  final Widget expandedContent;

  /// Content shown in mini-player mode.
  final Widget miniContent;

  /// Visual style configurations.
  final DragMiniWindowStyle style;

  /// Optional title for the mini-player.
  final Widget? title;

  /// Optional thumbnail/preview for the mini-player.
  final Widget? thumbnail;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isDismissed) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = constraints.biggest;
            final progress = controller.progress.clamp(0.0, 1.0);

            // Determine Geometry
            final miniSize = style.mobileMiniSize;
            final fullRect = Offset.zero & screenSize;

            // 1. Ensure a stable miniHome position exists in the controller
            if (controller.position == Offset.zero) {
              final defaultMiniOrigin = Offset(
                lerpDouble(
                  style.edgeSnapMargin,
                  screenSize.width - miniSize.width - style.edgeSnapMargin,
                  (style.defaultMiniAlignment.x + 1) / 2,
                )!,
                lerpDouble(
                  style.edgeSnapMargin,
                  screenSize.height - miniSize.height - style.edgeSnapMargin,
                  (style.defaultMiniAlignment.y + 1) / 2,
                )!,
              );
              // Set initial position once
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.setMiniPosition(defaultMiniOrigin);
              });
            }

            // 2. The target miniRect is based on the CONTROLLER'S stored position
            // (which is updated during dragging and persists after drag ends)
            final miniRect = controller.position & miniSize;

            // 3. Smoothly lerp between full screen and the current mini position
            final currentRect = Rect.lerp(fullRect, miniRect, progress)!;
            final radius = lerpDouble(0.0, style.miniBorderRadius, progress)!;

            // 4. Backdrop logic (only show when expanded/transitioning)
            final showBackdrop = progress < 0.99;

            return Stack(
              children: [
                // Backdrop
                if (showBackdrop)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: progress > 0.05,
                      child: Opacity(
                        opacity:
                            (1.0 - progress) * (style.backdropColor.a / 255.0),
                        child: Container(color: style.backdropColor),
                      ),
                    ),
                  ),

                // Main Window
                Positioned.fromRect(
                  rect: currentRect,
                  child: Container(
                    decoration: BoxDecoration(
                      color: style.windowBackgroundColor,
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: progress > 0.8 ? style.shadows : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildContent(progress),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildContent(double progress) {
    // Direct switch based on progress to avoid GlobalKey collisions
    // which occur during AnimatedSwitcher's cross-fade transition.
    return progress > 0.5 ? miniContent : expandedContent;
  }
}
