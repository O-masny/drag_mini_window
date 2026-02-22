import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'drag_mini_window_controller.dart';

/// iOS/YouTube-style drag-to-place mini window.
///
/// The user drags the [expandedContent] panel — it shrinks proportionally
/// as the finger moves and lands as a compact [miniContent] panel wherever
/// the finger is released. Tap the mini panel to maximize.
///
/// ```dart
/// DragMiniWindow(
///   controller: _controller,
///   expandedContent: MyVideoPlayer(),
///   miniContent: MiniPlayer(),
/// )
/// ```
class DragMiniWindow extends StatefulWidget {
  /// Creates a [DragMiniWindow] overlay.
  const DragMiniWindow({
    super.key,
    required this.controller,
    required this.expandedContent,
    required this.miniContent,
    this.expandedSize,
    this.miniSize = const Size(160, 90),
    this.defaultMiniAlignment = Alignment.bottomRight,
    this.backdropColor,
    this.snapThreshold = 0.3,
    this.snapVelocityThreshold = 800.0,
    this.animationDuration = const Duration(milliseconds: 280),
    this.animationCurve = Curves.easeOutCubic,
    this.borderRadius = 16.0,
    this.miniBorderRadius = 12.0,
    this.miniBorderColor,
    this.miniBorderWidth = 2.0,
    this.onMinimized,
    this.onMaximized,
    this.onDismissed,
    this.closeButton,
  });

  /// State controller. Provide a [DragMiniWindowController] and call
  /// [DragMiniWindowController.minimize] / [maximize] / [toggle] from outside.
  final DragMiniWindowController controller;

  /// Content shown when fully expanded.
  final Widget expandedContent;

  /// Content shown when minimized (mini panel).
  final Widget miniContent;

  /// Size of the expanded overlay.
  /// Defaults to 88% width × 75% height of the screen.
  final Size? expandedSize;

  /// Size of the mini floating panel. Defaults to `Size(160, 90)`.
  final Size miniSize;

  /// Corner/alignment used as the default landing position for the mini panel
  /// before the user has dragged it anywhere. Defaults to [Alignment.bottomRight].
  final Alignment defaultMiniAlignment;

  /// Backdrop overlay color. Defaults to `Colors.black` at 85% opacity.
  final Color? backdropColor;

  /// Drag-progress threshold (0.0–1.0) at which the panel snaps to minimized.
  /// Defaults to `0.3`.
  final double snapThreshold;

  /// Drag velocity (px/s) at which the panel always snaps regardless of
  /// [snapThreshold]. Defaults to `800.0`.
  final double snapVelocityThreshold;

  /// Duration of the snap-to-mini and snap-to-expanded animations.
  final Duration animationDuration;

  /// Curve used for snap animations.
  final Curve animationCurve;

  /// Border radius of the expanded dialog. Defaults to `16.0`.
  final double borderRadius;

  /// Border radius of the mini panel. Defaults to `12.0`.
  final double miniBorderRadius;

  /// Accent border color drawn around the mini panel. Defaults to the
  /// theme's primary color.
  final Color? miniBorderColor;

  /// Width of the mini panel accent border. Defaults to `2.0`.
  final double miniBorderWidth;

  /// Called once when the panel is fully minimized (animation complete).
  final VoidCallback? onMinimized;

  /// Called once when the panel is fully maximized (animation complete).
  final VoidCallback? onMaximized;

  /// Called once when the panel is fully dismissed.
  final VoidCallback? onDismissed;

  /// Optional close button widget. If provided, it will be shown in the
  /// expanded view.
  final Widget? closeButton;

  @override
  State<DragMiniWindow> createState() => _DragMiniWindowState();
}

// ─────────────────────────────────────────────────────────────────────────────

class _DragMiniWindowState extends State<DragMiniWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  // ── Drag-from-expanded state ──────────────────────────────────────────

  /// True during a finger-down gesture on the expanded panel.
  bool _isDraggingExpanded = false;

  /// The finger's current screen position during an expanded drag.
  /// Used to derive both [_dragProgress] and the landing [_miniLanding].
  Offset _fingerPos = Offset.zero;

  /// Target mini-panel position derived live during the drag.
  /// On release this becomes the confirmed position.
  Offset? _miniLanding;

  /// Last known screen size — used to detect orientation changes and
  /// re-clamp the mini panel so it stays on screen after rotation.
  Size _lastScreen = Size.zero;

  // ── Mini panel repositioning ──────────────────────────────────────────

  Offset _miniPanStart = Offset.zero;
  double _miniPanDistance = 0.0;
  static const _tapDeadZone = 8.0;

  // ─────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: widget.controller.dragProgress,
    );
    _anim.addListener(_onAnimTick);
    widget.controller.addListener(_onControllerChange);
  }

  void _onAnimTick() {
    if (!_isDraggingExpanded) {
      widget.controller.setDragProgress(_anim.value);
    }
  }

  void _onControllerChange() {
    if (!_isDraggingExpanded) {
      final target = widget.controller.isMinimized ? 1.0 : 0.0;
      if ((_anim.value - target).abs() > 0.01) {
        _anim.animateTo(target, curve: widget.animationCurve);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screen = MediaQuery.sizeOf(context);
    if (_lastScreen != Size.zero && _lastScreen != screen) {
      // Orientation changed — re-clamp mini panel and stored landing position
      // so the widget never ends up off-screen after rotation.
      final safe = MediaQuery.paddingOf(context);
      final mini = widget.miniSize;
      if (widget.controller.miniPosition != null) {
        widget.controller.setMiniPosition(
          _clamp(widget.controller.miniPosition!, screen, safe, mini),
        );
      }
      if (_miniLanding != null) {
        _miniLanding = _clamp(_miniLanding!, screen, safe, mini);
      }
    }
    _lastScreen = screen;
  }

  @override
  void didUpdateWidget(DragMiniWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationDuration != widget.animationDuration) {
      _anim.duration = widget.animationDuration;
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    _anim.removeListener(_onAnimTick);
    _anim.dispose();
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  // ── Geometry helpers ─────────────────────────────────────────────────

  /// Returns the expanded panel size, automatically adapting to orientation.
  ///
  /// In landscape (`width > height`) the panel fills more of the short axis
  /// (92% height, 96% width) so it feels natural without cropping.
  Size _expandedSize(Size screen) {
    if (widget.expandedSize != null) return widget.expandedSize!;
    final isLandscape = screen.width > screen.height;
    return isLandscape
        ? Size(screen.width * 0.96, screen.height * 0.92)
        : Size(screen.width * 0.88, screen.height * 0.75);
  }

  Offset _expandedOrigin(Size screen, Size expSize) => Offset(
        (screen.width - expSize.width) / 2,
        (screen.height - expSize.height) / 2,
      );

  Offset _defaultMiniOrigin(
    Size screen,
    EdgeInsets safe,
    Size miniSize,
    Alignment alignment,
  ) {
    final available = Size(
      screen.width - miniSize.width - 16 - safe.right,
      screen.height - miniSize.height - 16 - safe.bottom,
    );
    final cx = (alignment.x + 1) / 2; // -1..1 → 0..1
    final cy = (alignment.y + 1) / 2;
    return Offset(
      8 + safe.left + cx * available.width,
      8 + safe.top + cy * available.height,
    );
  }

  /// Clamps [pos] so the panel (of [size]) stays fully on-screen,
  /// respecting safe-area insets on all sides.
  Offset _clamp(Offset pos, Size screen, EdgeInsets safe, Size size) => Offset(
        pos.dx
            .clamp(8.0 + safe.left, screen.width - size.width - 8 - safe.right),
        pos.dy.clamp(
            8.0 + safe.top, screen.height - size.height - 8 - safe.bottom),
      );

  /// Normalized distance of [finger] from the expanded panel center.
  /// Using the half-diagonal of the expanded panel as max-distance gives a
  /// stable 0→1 range that is independent of aspect-ratio / orientation.
  double _progressFromFinger(Offset finger, Size screen) {
    final expSize = _expandedSize(screen);
    final center = Offset(screen.width / 2, screen.height / 2);
    final maxDist = math.sqrt(
      math.pow(expSize.width / 2, 2) + math.pow(expSize.height / 2, 2),
    );
    final dist = (finger - center).distance;
    return (dist / maxDist).clamp(0.0, 1.0);
  }

  /// Maps the current finger position to a clamped mini-panel origin.
  Offset _miniOriginFromFinger(
      Offset finger, Size screen, EdgeInsets safe, Size miniSize) {
    return _clamp(
      Offset(finger.dx - miniSize.width / 2, finger.dy - miniSize.height / 2),
      screen,
      safe,
      miniSize,
    );
  }

  // ── Expanded-panel drag handlers ─────────────────────────────────────

  void _onExpandedPanStart(DragStartDetails d) {
    _isDraggingExpanded = true;
    _fingerPos = d.globalPosition;
    _anim.stop();
  }

  void _onExpandedPanUpdate(DragUpdateDetails d) {
    _fingerPos = d.globalPosition;
    final safe = MediaQuery.paddingOf(context);
    final screen = MediaQuery.sizeOf(context);
    final progress = _progressFromFinger(_fingerPos, screen);
    final landing =
        _miniOriginFromFinger(_fingerPos, screen, safe, widget.miniSize);

    widget.controller.setDragProgress(progress);
    _anim.value = progress;
    setState(() => _miniLanding = landing);
  }

  void _onExpandedPanEnd(DragEndDetails d) {
    _isDraggingExpanded = false;
    final speed = d.velocity.pixelsPerSecond.distance;
    final progress = widget.controller.dragProgress;

    // Determine whether to snap to mini or snap back.
    final toMini =
        progress > widget.snapThreshold || speed > widget.snapVelocityThreshold;

    if (toMini) {
      _snapTo(
        1.0,
        onComplete: () {
          final screen = MediaQuery.sizeOf(context);
          final safe = MediaQuery.paddingOf(context);
          final landing = _miniLanding ??
              _defaultMiniOrigin(
                screen,
                safe,
                widget.miniSize,
                widget.defaultMiniAlignment,
              );
          widget.controller.confirmMinimize(landingPosition: landing);
          widget.onMinimized?.call();
        },
      );
    } else {
      _snapTo(
        0.0,
        onComplete: () {
          widget.controller.maximize();
        },
      );
    }
  }

  // ── Mini-panel pan handlers ───────────────────────────────────────────

  void _onMiniPanStart(DragStartDetails d) {
    _miniPanStart = d.globalPosition;
    _miniPanDistance = 0.0;
  }

  void _onMiniPanUpdate(DragUpdateDetails d) {
    _miniPanDistance += (d.globalPosition - _miniPanStart).distance;
    _miniPanStart = d.globalPosition;

    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final currentPos = widget.controller.miniPosition ??
        _defaultMiniOrigin(
          screen,
          safe,
          widget.miniSize,
          widget.defaultMiniAlignment,
        );

    widget.controller.setMiniPosition(
      _clamp(currentPos + d.delta, screen, safe, widget.miniSize),
    );
  }

  void _onMiniPanEnd(DragEndDetails d) {
    final speed = d.velocity.pixelsPerSecond.dx.abs();
    final dist = (d.velocity.pixelsPerSecond.dx * 0.2)
        .abs(); // Simple heuristic for flick distance

    if (speed > 1000 || dist > 100) {
      // Swipe to dismiss
      final screen = MediaQuery.sizeOf(context);
      final currentPos = widget.controller.miniPosition ?? Offset.zero;
      final targetX = d.velocity.pixelsPerSecond.dx > 0
          ? screen.width + 50.0
          : -widget.miniSize.width - 50.0;

      widget.controller.setMiniPosition(Offset(targetX, currentPos.dy));
      widget.controller.confirmDismiss();
      widget.onDismissed?.call();
    } else if (_miniPanDistance < _tapDeadZone) {
      // Treat as tap → maximize
      _snapTo(
        0.0,
        onComplete: () {
          widget.controller.maximize();
          widget.onMaximized?.call();
        },
      );
    }
  }

  // ── Animation snap ────────────────────────────────────────────────────

  void _snapTo(double target, {VoidCallback? onComplete}) {
    _anim
        .animateTo(target, curve: widget.animationCurve)
        .whenCompleteOrCancel(onComplete ?? () {});
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.isDismissed) return const SizedBox.shrink();

        final progress = widget.controller.dragProgress;
        final screen = MediaQuery.sizeOf(context);
        final safe = MediaQuery.paddingOf(context);

        final expSize = _expandedSize(screen);
        final miniSize = widget.miniSize;

        final currentWidth = lerpDouble(
          expSize.width,
          miniSize.width,
          progress,
        )!;
        final currentHeight = lerpDouble(
          expSize.height,
          miniSize.height,
          progress,
        )!;

        // Position lerp: center → mini landing
        final expOrigin = _expandedOrigin(screen, expSize);
        final miniOrigin = _miniLanding ??
            widget.controller.miniPosition ??
            _defaultMiniOrigin(
              screen,
              safe,
              miniSize,
              widget.defaultMiniAlignment,
            );

        final currentLeft = lerpDouble(expOrigin.dx, miniOrigin.dx, progress)!;
        final currentTop = lerpDouble(expOrigin.dy, miniOrigin.dy, progress)!;

        final baseOpacity = widget.backdropColor != null
            ? widget.backdropColor!.a / 255.0
            : 0.85;
        final backdropOpacity = (baseOpacity * (1.0 - progress)).clamp(
          0.0,
          1.0,
        );

        final currentRadius = lerpDouble(
          widget.borderRadius,
          widget.miniBorderRadius,
          progress,
        )!;
        final currentElevation = lerpDouble(24, 8, progress)!;

        final isMini = progress > 0.9 && !_isDraggingExpanded;
        final accentColor =
            widget.miniBorderColor ?? Theme.of(context).colorScheme.primary;

        return SizedBox.expand(
          child: Stack(
            children: [
              // Backdrop
              if (backdropOpacity > 0.01)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: isMini,
                    child: GestureDetector(
                      onTap: isMini
                          ? null
                          : () {
                              _snapTo(
                                1.0,
                                onComplete: () {
                                  widget.controller.minimize();
                                  widget.onMinimized?.call();
                                },
                              );
                            },
                      child: AnimatedOpacity(
                        opacity: backdropOpacity,
                        duration: const Duration(milliseconds: 50),
                        child: ColoredBox(
                          color: widget.backdropColor ?? Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

              // Floating panel
              Positioned(
                left: currentLeft,
                top: currentTop,
                child: GestureDetector(
                  // Pan gesture is shared — dispatch based on current mode.
                  onPanStart: isMini ? _onMiniPanStart : _onExpandedPanStart,
                  onPanUpdate: isMini ? _onMiniPanUpdate : _onExpandedPanUpdate,
                  onPanEnd: isMini ? _onMiniPanEnd : _onExpandedPanEnd,

                  child: Material(
                    elevation: currentElevation,
                    borderRadius: BorderRadius.circular(currentRadius),
                    color: Colors.transparent,
                    child: Container(
                      width: currentWidth,
                      height: currentHeight,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(currentRadius),
                        border: isMini
                            ? Border.all(
                                color: accentColor,
                                width: widget.miniBorderWidth,
                              )
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(currentRadius - 1),
                        child: Stack(
                          children: [
                            isMini
                                ? widget.miniContent
                                : widget.expandedContent,
                            if (!isMini && widget.closeButton != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    _snapTo(
                                      1.0,
                                      onComplete: () {
                                        widget.controller.minimize();
                                        widget.onMinimized?.call();
                                      },
                                    );
                                  },
                                  child: widget.closeButton!,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
