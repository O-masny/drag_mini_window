import 'dart:ui';

import 'package:flutter/material.dart';

import 'drag_mini_gesture_handler.dart';
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
    this.closeButton,
  });

  /// The controller managing the window state.
  final DragMiniWindowController controller;

  /// Content shown in full-screen mode.
  final Widget expandedContent;

  /// Content shown in mini-player mode.
  final Widget miniContent;

  /// Visual style configurations.
  final DragMiniWindowStyle style;

  /// Optional title widget for the mini-bar.
  final Widget? title;

  /// Optional thumbnail/preview for the mini-bar.
  final Widget? thumbnail;

  /// Optional close button widget for the mini-bar.
  final Widget? closeButton;

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
            final isDocked = controller.status == DragMiniStatus.docked;

            // Determine Geometry
            final miniSize = style.mobileMiniSize;
            final fullRect = Offset.zero & screenSize;

            // 1. Calculate the default mini origin
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

            // 2. Persistent position logic
            if (controller.position == Offset.zero) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.setMiniPosition(defaultMiniOrigin);
              });
            }

            final stableMiniOrigin = controller.position == Offset.zero
                ? defaultMiniOrigin
                : controller.position;

            // 3. Calculate rects based on state
            final Rect targetMiniRect;
            if (isDocked) {
              // Docked: full-width bar at current Y position
              targetMiniRect = Rect.fromLTWH(
                0,
                stableMiniOrigin.dy.clamp(
                  0,
                  screenSize.height - style.dockedHeight,
                ),
                screenSize.width,
                style.dockedHeight,
              );
            } else {
              targetMiniRect = stableMiniOrigin & miniSize;
            }

            // 4. Smoothly lerp between full screen and mini/docked
            final currentRect = Rect.lerp(fullRect, targetMiniRect, progress)!;
            final radius = lerpDouble(0.0, style.miniBorderRadius, progress)!;

            // 5. Backdrop logic
            final showBackdrop = progress < 0.99;
            final backdropInteractive = progress < 0.1;

            return Stack(
              children: [
                // Backdrop
                if (showBackdrop)
                  Positioned.fill(
                    child: backdropInteractive
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => controller.minimize(),
                            child: Opacity(
                              opacity: (1.0 - progress) *
                                  (style.backdropColor.a / 255.0),
                              child: Container(color: style.backdropColor),
                            ),
                          )
                        : IgnorePointer(
                            child: Opacity(
                              opacity: (1.0 - progress) *
                                  (style.backdropColor.a / 255.0),
                              child: Container(color: style.backdropColor),
                            ),
                          ),
                  ),

                // Main Window with gesture handler
                Positioned.fromRect(
                  rect: currentRect,
                  child: DragMiniGestureHandler(
                    controller: controller,
                    child: Container(
                      decoration: BoxDecoration(
                        color: style.windowBackgroundColor,
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: progress > 0.8 ? style.shadows : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildContent(progress, isDocked),
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

  Widget _buildContent(double progress, bool isDocked) {
    // Expanded mode: show full content
    if (progress <= 0.5 && !isDocked) {
      return expandedContent;
    }

    // Mini or Docked mode: show mini content with optional bar UI
    if (title != null || closeButton != null) {
      return Row(
        children: [
          // Video thumbnail area
          AspectRatio(
            aspectRatio: 16 / 9,
            child: miniContent,
          ),
          // Title area
          if (title != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: title!,
              ),
            ),
          // Close button
          if (closeButton != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: closeButton!,
            ),
        ],
      );
    }

    // Fallback: just the mini content
    return miniContent;
  }
}
