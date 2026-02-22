import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'drag_mini_window_controller.dart';

/// iOS/YouTube-style drag-to-place mini window.
///
/// Refined for 2025 standards with vertical swipe minimization,
/// edge tucking, and web-optimized layouts.
class DragMiniWindow extends StatefulWidget {
  const DragMiniWindow({
    super.key,
    required this.controller,
    required this.expandedContent,
    required this.miniContent,
    this.title,
    this.thumbnail,
    this.expandedSize,
    this.miniSize,
    this.webMiniSize = const Size(360, 202),
    this.mobileMiniSize = const Size(160, 90),
    this.defaultMiniAlignment = Alignment.bottomRight,
    this.backdropColor,
    this.snapThreshold = 0.3,
    this.snapVelocityThreshold = 800.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.enableHaptics = true,
    this.enableEdgeSnap = true,
    this.enableTuck = true,
    this.edgeSnapMargin = 16.0,
    this.springStiffness = 300.0,
    this.springDamping = 30.0,
    this.borderRadius = 16.0,
    this.miniBorderRadius = 12.0,
    this.onMinimized,
    this.onMaximized,
    this.onDismissed,
    this.onTucked,
    this.closeButton,
    this.dockedHeight = 64.0,
    this.progressColor = Colors.red,
  });

  /// State controller.
  final DragMiniWindowController controller;

  /// Content shown when fully expanded.
  final Widget expandedContent;

  /// Content shown when minimized in floating mode.
  final Widget miniContent;

  /// Optional title for the docked bar (YouTube style).
  final Widget? title;

  /// Optional thumbnail for the docked bar (YouTube style).
  final Widget? thumbnail;

  /// Size of the expanded overlay.
  final Size? expandedSize;

  /// Custom mini size. If null, uses [webMiniSize] or [mobileMiniSize].
  final Size? miniSize;

  /// Mini size used on web/desktop. Defaults to 16:9 360px width.
  final Size webMiniSize;

  /// Mini size used on mobile. Defaults to 160x90.
  final Size mobileMiniSize;

  /// Corner/alignment used as the default landing position.
  final Alignment defaultMiniAlignment;

  /// Backdrop overlay color.
  final Color? backdropColor;

  /// Drag-progress threshold (0.0–1.0) at which the panel snaps.
  final double snapThreshold;

  /// Drag velocity (px/s) for quick snap.
  final double snapVelocityThreshold;

  /// Duration of animations.
  final Duration animationDuration;

  /// Whether to trigger haptic feedback.
  final bool enableHaptics;

  /// Whether the mini panel should snap to horizontal edges.
  final bool enableEdgeSnap;

  /// Whether the mini panel can be tucked away into the side edge.
  final bool enableTuck;

  /// Margin from screen edge.
  final double edgeSnapMargin;

  /// Spring stiffness for animations.
  final double springStiffness;

  /// Spring damping for animations.
  final double springDamping;

  /// Border radius of the expanded dialog.
  final double borderRadius;

  /// Border radius of the mini panel.
  final double miniBorderRadius;

  /// Callback when minimized.
  final VoidCallback? onMinimized;

  /// Callback when maximized.
  final VoidCallback? onMaximized;

  /// Callback when dismissed.
  final VoidCallback? onDismissed;

  /// Callback when tucked away.
  final VoidCallback? onTucked;

  /// Optional close button widget.
  final Widget? closeButton;

  /// Height of the docked bottom bar.
  final double dockedHeight;

  /// Color of the playback progress bar.
  final Color progressColor;

  @override
  State<DragMiniWindow> createState() => _DragMiniWindowState();
}

class _DragMiniWindowState extends State<DragMiniWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  bool _isDraggingExpanded = false;
  Offset _fingerPos = Offset.zero;
  Offset? _miniLanding;
  Size _lastScreen = Size.zero;

  // Repositioning state
  Offset _miniPanStart = Offset.zero;
  double _miniPanDistance = 0.0;
  static const _tapDeadZone = 8.0;

  // Web/Hover state
  bool _isHovered = false;

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
      if ((_anim.value - target).abs() > 0.001) {
        _springTo(target);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screen = MediaQuery.sizeOf(context);
    if (_lastScreen != Size.zero && _lastScreen != screen) {
      final safe = MediaQuery.paddingOf(context);
      final mini = _getMiniSize(screen);
      if (widget.controller.miniPosition != null) {
        widget.controller.setMiniPosition(
          _clamp(widget.controller.miniPosition!, screen, safe, mini),
        );
      }
    }
    _lastScreen = screen;
  }

  @override
  void dispose() {
    _anim.removeListener(_onAnimTick);
    _anim.dispose();
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  Size _getMiniSize(Size screen) {
    if (widget.miniSize != null) return widget.miniSize!;
    return kIsWeb || screen.width > 600
        ? widget.webMiniSize
        : widget.mobileMiniSize;
  }

  Size _expandedSize(Size screen) {
    if (widget.expandedSize != null) return widget.expandedSize!;
    final isLandscape = screen.width > screen.height;
    return isLandscape
        ? Size(screen.width * 0.96, screen.height * 0.92)
        : Size(screen.width * 0.92, screen.height * 0.80);
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
    final margin = widget.edgeSnapMargin;
    final available = Size(
      screen.width - miniSize.width - (margin * 2) - safe.horizontal,
      screen.height - miniSize.height - (margin * 2) - safe.vertical,
    );
    final cx = (alignment.x + 1) / 2;
    final cy = (alignment.y + 1) / 2;
    return Offset(
      margin + safe.left + cx * available.width,
      margin + safe.top + cy * available.height,
    );
  }

  Offset _clamp(Offset pos, Size screen, EdgeInsets safe, Size size) {
    final m = widget.edgeSnapMargin;
    return Offset(
      pos.dx.clamp(m + safe.left, screen.width - size.width - m - safe.right),
      pos.dy.clamp(m + safe.top, screen.height - size.height - m - safe.bottom),
    );
  }

  // YouTube-style vertical swipe logic
  double _progressFromVerticalSwipe(Offset finger, Size screen) {
    final expSize = _expandedSize(screen);
    final startY = (screen.height - expSize.height) / 2;
    // Normalized distance from top of expanded panel to bottom of screen
    final maxSwipe = screen.height - startY - 100;
    final currentSwipe = (finger.dy - startY).clamp(0.0, maxSwipe);
    return (currentSwipe / maxSwipe).clamp(0.0, 1.0);
  }

  void _onExpandedPanStart(DragStartDetails d) {
    _isDraggingExpanded = true;
    _fingerPos = d.globalPosition;
    _anim.stop();
  }

  void _onExpandedPanUpdate(DragUpdateDetails d) {
    _fingerPos = d.globalPosition;
    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final miniSize = _getMiniSize(screen);

    // YouTube style: Progress is mostly vertical
    final progress = _progressFromVerticalSwipe(_fingerPos, screen);

    // Target position lerps towards finger
    final landing = Offset(
      _fingerPos.dx - miniSize.width / 2,
      _fingerPos.dy - miniSize.height / 2,
    );

    widget.controller.setDragProgress(progress);
    _anim.value = progress;
    setState(() => _miniLanding = _clamp(landing, screen, safe, miniSize));
  }

  void _onExpandedPanEnd(DragEndDetails d) {
    _isDraggingExpanded = false;
    final progress = widget.controller.dragProgress;
    final velocity = d.velocity.pixelsPerSecond.dy;

    final toMini = progress > widget.snapThreshold ||
        velocity > widget.snapVelocityThreshold;

    if (toMini) {
      if (widget.enableHaptics && !kIsWeb) HapticFeedback.lightImpact();
      _springTo(1.0, onComplete: () {
        final screen = MediaQuery.sizeOf(context);
        final safe = MediaQuery.paddingOf(context);
        final miniSize = _getMiniSize(screen);
        var landing = _miniLanding ??
            _defaultMiniOrigin(
                screen, safe, miniSize, widget.defaultMiniAlignment);

        if (widget.enableEdgeSnap) {
          landing = _edgeSnap(landing, screen, safe, miniSize);
        }
        widget.controller.confirmMinimize(landingPosition: landing);
        _miniLanding = null;
        widget.onMinimized?.call();
      });
    } else {
      _springTo(0.0, onComplete: () {
        widget.controller.maximize();
        widget.onMaximized?.call();
      });
    }
  }

  void _onMiniPanStart(DragStartDetails d) {
    _miniPanStart = d.globalPosition;
    _miniPanDistance = 0.0;
  }

  void _onMiniPanUpdate(DragUpdateDetails d) {
    _miniPanDistance += (d.globalPosition - _miniPanStart).distance;
    _miniPanStart = d.globalPosition;

    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final miniSize = _getMiniSize(screen);
    final currentPos = widget.controller.miniPosition ??
        _defaultMiniOrigin(screen, safe, miniSize, widget.defaultMiniAlignment);

    final newPos = currentPos + d.delta;

    // Check for "Tuck" (sliding past edges)
    if (widget.enableTuck) {
      final isPastLeft = newPos.dx < safe.left - miniSize.width * 0.5;
      final isPastRight =
          newPos.dx > screen.width - safe.right - miniSize.width * 0.5;
      if (isPastLeft || isPastRight) {
        widget.controller.setTucked(true);
      } else {
        widget.controller.setTucked(false);
      }
    }

    widget.controller.setMiniPosition(newPos);

    // Dock detection (YouTube style bar at bottom)
    final panelBottom = newPos.dy + miniSize.height;
    final screenBottom = screen.height - safe.bottom;
    final nearBottom = (screenBottom - panelBottom) < 40.0;

    if (nearBottom && !widget.controller.isDocked) {
      if (widget.enableHaptics && !kIsWeb) HapticFeedback.selectionClick();
      widget.controller.setDocked(true);
    } else if (!nearBottom && widget.controller.isDocked) {
      widget.controller.setDocked(false);
    }
  }

  void _onMiniPanEnd(DragEndDetails d) {
    if (_miniPanDistance < _tapDeadZone) {
      if (widget.enableHaptics && !kIsWeb) HapticFeedback.mediumImpact();
      _springTo(0.0, onComplete: () {
        widget.controller.maximize();
        widget.onMaximized?.call();
      });
      return;
    }

    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final miniSize = _getMiniSize(screen);
    final pos = widget.controller.miniPosition ?? Offset.zero;

    // 1. Swipe to dismiss
    final velocityX = d.velocity.pixelsPerSecond.dx;
    if (velocityX.abs() > 1000) {
      final targetX =
          velocityX > 0 ? screen.width + 100.0 : -miniSize.width - 100.0;
      widget.controller.setMiniPosition(Offset(targetX, pos.dy));
      widget.controller.confirmDismiss();
      widget.onDismissed?.call();
      return;
    }

    // 2. Handle Tucking
    if (widget.controller.isTucked) {
      final isLeft = pos.dx < screen.width / 2;
      final tuckedX = isLeft
          ? safe.left - miniSize.width + 20.0
          : screen.width - safe.right - 20.0;
      widget.controller.setMiniPosition(Offset(tuckedX, pos.dy));
      widget.onTucked?.call();
      return;
    }

    // 3. Normal Edge Snap
    if (widget.enableEdgeSnap && !widget.controller.isDocked) {
      widget.controller.setMiniPosition(_edgeSnap(pos, screen, safe, miniSize));
    } else if (widget.controller.isDocked) {
      // Snap to bottom center for docked
      widget.controller.setMiniPosition(Offset(
          (screen.width - miniSize.width) / 2,
          screen.height - safe.bottom - miniSize.height));
    }
  }

  Offset _edgeSnap(Offset pos, Size screen, EdgeInsets safe, Size size) {
    final m = widget.edgeSnapMargin;
    final center = pos.dx + size.width / 2;
    final dx = center < screen.width / 2
        ? m + safe.left
        : screen.width - size.width - m - safe.right;
    return Offset(
        dx,
        pos.dy.clamp(
            m + safe.top, screen.height - size.height - m - safe.bottom));
  }

  void _springTo(double target, {VoidCallback? onComplete}) {
    final sim = SpringSimulation(
      SpringDescription(
          mass: 1.0,
          stiffness: widget.springStiffness,
          damping: widget.springDamping),
      _anim.value,
      target,
      0.0,
    );
    _anim.animateWith(sim).whenCompleteOrCancel(onComplete ?? () {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.isDismissed) return const SizedBox.shrink();

        final progress = widget.controller.dragProgress;
        final screen = MediaQuery.sizeOf(context);
        final safe = MediaQuery.paddingOf(context);
        final isDocked = widget.controller.isDocked;
        final miniSize = _getMiniSize(screen);
        final expSize = _expandedSize(screen);

        // ── Keyboard Support ──
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () {
              if (widget.controller.isMinimized) {
                widget.controller.dismiss();
              } else {
                widget.controller.minimize();
              }
            },
          },
          child: Focus(
            autofocus: true,
            child: Stack(
              children: [
                // 1. Backdrop
                if (progress < 0.99)
                  IgnorePointer(
                    ignoring: progress > 0.5,
                    child: Opacity(
                      opacity: (1.0 - progress).clamp(0.0, 1.0) * 0.8,
                      child: GestureDetector(
                        onTap: () => widget.controller.minimize(),
                        child: Container(
                            color: widget.backdropColor ?? Colors.black),
                      ),
                    ),
                  ),

                // 2. Main Window
                _buildWindow(context, progress, screen, safe, miniSize, expSize,
                    isDocked),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWindow(BuildContext context, double progress, Size screen,
      EdgeInsets safe, Size miniSize, Size expSize, bool isDocked) {
    final isMini = progress > 0.95 && !_isDraggingExpanded;
    final expOrigin = _expandedOrigin(screen, expSize);
    final miniOrigin = _miniLanding ??
        widget.controller.miniPosition ??
        _defaultMiniOrigin(screen, safe, miniSize, widget.defaultMiniAlignment);

    // YouTube Docked Transition
    final effectiveMiniOrigin = isDocked && isMini
        ? Offset(0, screen.height - safe.bottom - widget.dockedHeight)
        : miniOrigin;
    final effectiveMiniSize =
        isDocked && isMini ? Size(screen.width, widget.dockedHeight) : miniSize;

    final currentLeft =
        lerpDouble(expOrigin.dx, effectiveMiniOrigin.dx, progress)!;
    final currentTop =
        lerpDouble(expOrigin.dy, effectiveMiniOrigin.dy, progress)!;
    final currentW =
        lerpDouble(expSize.width, effectiveMiniSize.width, progress)!;
    final currentH =
        lerpDouble(expSize.height, effectiveMiniSize.height, progress)!;
    final currentRadius = lerpDouble(
        widget.borderRadius, isDocked ? 0 : widget.miniBorderRadius, progress)!;

    return Positioned(
      left: currentLeft,
      top: currentTop,
      width: currentW,
      height: currentH,
      child: MouseRegion(
        cursor: isMini ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onPanStart: isMini ? _onMiniPanStart : _onExpandedPanStart,
          onPanUpdate: isMini ? _onMiniPanUpdate : _onExpandedPanUpdate,
          onPanEnd: isMini ? _onMiniPanEnd : _onExpandedPanEnd,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(currentRadius),
              boxShadow: isMini
                  ? [
                      BoxShadow(
                          color: Colors.black54,
                          blurRadius: 12,
                          spreadRadius: 2)
                    ]
                  : [],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Content with Cross-fade
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isDocked && isMini
                        ? _buildDockedBar(context)
                        : (progress > 0.8
                            ? KeyedSubtree(
                                key: const ValueKey('mini'),
                                child: widget.miniContent)
                            : KeyedSubtree(
                                key: const ValueKey('exp'),
                                child: widget.expandedContent)),
                  ),
                ),

                // Playback progress bar (Bottom)
                if (isMini || isDocked)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SizedBox(
                      height: 2,
                      child: LinearProgressIndicator(
                        value: widget.controller.playbackProgress,
                        backgroundColor: Colors.white24,
                        color: widget.progressColor,
                      ),
                    ),
                  ),

                // Web Controls / Hover Overlay
                if (isMini && kIsWeb && _isHovered && !isDocked)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => widget.controller.dismiss(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // X Button (Always visible on mobile mini or docked)
                if (isMini && (!kIsWeb || isDocked))
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                        onPressed: () => widget.controller.dismiss(),
                      ),
                    ),
                  ),

                // Close button in expanded view
                if (!isMini && widget.closeButton != null)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => widget.controller.minimize(),
                      child: widget.closeButton!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockedBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          // Thumbnail
          if (widget.thumbnail != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: widget.thumbnail,
                ),
              ),
            ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: widget.title ?? const SizedBox.shrink(),
          ),
          // Controls placeholder (usually provided in title row or separately)
          // For now we just keep the X which is handled in the main stack
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
