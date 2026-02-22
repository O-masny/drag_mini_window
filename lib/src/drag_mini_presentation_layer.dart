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

  /// Optional title for the mini-player.
  final Widget? title;

  /// Optional thumbnail/preview for the mini-player.
  final Widget? thumbnail;

  /// Optional close button widget shown on the mini-player.
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

            // 1. Calculate the default mini origin (TOP RIGHT by default now)
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

            // 3. Determine current rect based on state
            final Rect currentRect;
            if (isDocked) {
              // DOCKED: full-width bar at the bottom of the screen
              currentRect = Rect.fromLTWH(
                0,
                screenSize.height - style.dockedHeight,
                screenSize.width,
                style.dockedHeight,
              );
            } else {
              final miniRect = stableMiniOrigin & miniSize;
              currentRect = Rect.lerp(fullRect, miniRect, progress)!;
            }

            final radius = isDocked
                ? 0.0
                : lerpDouble(0.0, style.miniBorderRadius, progress)!;

            // 4. Backdrop logic
            final showBackdrop = !isDocked && progress < 0.99;
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

                // Main Window with its own gesture handler
                Positioned.fromRect(
                  rect: currentRect,
                  child: DragMiniGestureHandler(
                    controller: controller,
                    child: Container(
                      decoration: BoxDecoration(
                        color: style.windowBackgroundColor,
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow:
                            (isDocked || progress > 0.8) ? style.shadows : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: isDocked
                          ? _buildDockedContent()
                          : _buildContent(progress),
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
    if (progress <= 0.5) return expandedContent;

    // Mini mode: stack content + optional close button
    if (closeButton == null) return miniContent;
    return Stack(
      children: [
        miniContent,
        Positioned(
          top: 4,
          right: 4,
          child: closeButton!,
        ),
      ],
    );
  }

  /// Docked bar: thumbnail on left, title in center, full width.
  Widget _buildDockedContent() {
    return Row(
      children: [
        // Thumbnail / video preview
        SizedBox(
          width: style.dockedHeight * (16 / 9),
          height: style.dockedHeight,
          child: ClipRRect(borderRadius: BorderRadius.zero, child: miniContent),
        ),
        const SizedBox(width: 12),
        // Title area
        Expanded(
          child: title ??
              const Text(
                'Now Playing',
                style: TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
