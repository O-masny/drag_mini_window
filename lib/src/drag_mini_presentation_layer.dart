import 'dart:ui';

import 'package:flutter/material.dart';

import 'drag_mini_window_controller.dart';
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
            final screen = constraints.biggest;
            final progress = controller.progress.clamp(0.0, 1.0);

            // Determine Geometry
            final miniSize = style.mobileMiniSize;
            final expSize = screen;

            // Calculate default mini position (bottom right) if not yet set
            // or if we just transitioned to mini for the first time
            var miniOrigin = controller.position;
            if (miniOrigin == Offset.zero) {
              miniOrigin = Offset(
                screen.width - miniSize.width - style.edgeSnapMargin,
                screen.height - miniSize.height - style.edgeSnapMargin,
              );
              // Update controller so it knows its "mini" home
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.updateInternalGeometry(
                  position: miniOrigin,
                  size: miniSize,
                );
              });
            }

            // Sync controller size regardless of mode
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.updateInternalGeometry(
                position: controller.position,
                size: progress > 0.5 ? miniSize : expSize,
              );
            });

            // Compute Transform
            final scaleX =
                lerpDouble(1.0, miniSize.width / expSize.width, progress)!;
            final scaleY =
                lerpDouble(1.0, miniSize.height / expSize.height, progress)!;

            // In full mode (progress 0), translateX/Y must be 0
            // In mini mode (progress 1), translateX/Y must be miniOrigin
            final translateX = lerpDouble(0.0, miniOrigin.dx, progress)!;
            final translateY = lerpDouble(0.0, miniOrigin.dy, progress)!;

            final radius = lerpDouble(0.0, style.miniBorderRadius, progress)!;

            return Stack(
              children: [
                // Backdrop
                if (progress < 0.99)
                  Positioned.fill(
                    child: Opacity(
                      opacity:
                          (1.0 - progress) * (style.backdropColor.a / 255.0),
                      child: Container(color: style.backdropColor),
                    ),
                  ),

                // Main Window
                Positioned(
                  left: 0,
                  top: 0,
                  width: expSize.width,
                  height: expSize.height,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..translate(translateX, translateY)
                      ..scale(scaleX, scaleY),
                    alignment: Alignment.topLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: style.windowBackgroundColor,
                        borderRadius: BorderRadius.circular(radius / scaleX),
                        boxShadow: progress > 0.8 ? style.shadows : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildContent(progress),
                    ),
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
