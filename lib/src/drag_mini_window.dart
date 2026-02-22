import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'drag_mini_window_controller.dart';
import 'drag_mini_window_style.dart';

/// A premium, YouTube-style draggable mini window for Flutter.
///
/// Features vertical swipe minimization, docking zones with ghost placeholders,
/// edge tucking, and full web/desktop optimizations.
class DragMiniWindow extends StatefulWidget {
  /// Creates a [DragMiniWindow] with the provided configuration.
  const DragMiniWindow({
    super.key,
    required this.controller,
    required this.expandedContent,
    required this.miniContent,
    this.style = const DragMiniWindowStyle(),
    this.title,
    this.thumbnail,
    this.expandedSize,
    this.snapThreshold = 0.3,
    this.snapVelocityThreshold = 800.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.enableHaptics = true,
    this.enableEdgeSnap = true,
    this.enableTuck = true,
    this.onMinimized,
    this.onMaximized,
    this.onDismissed,
    this.onTucked,
    this.closeButton,
  });

  /// Controller managing the state of the window.
  final DragMiniWindowController controller;

  /// Content shown when the window is fully expanded.
  final Widget expandedContent;

  /// Content shown when the window is in mini floating mode.
  final Widget miniContent;

  /// Visual styling configuration.
  final DragMiniWindowStyle style;

  /// Optional widget for the title in docked mode.
  final Widget? title;

  /// Optional widget for the thumbnail in docked mode.
  final Widget? thumbnail;

  /// Custom size for the expanded view. Defaults to adaptive layout.
  final Size? expandedSize;

  /// Drag-progress threshold at which the panel snaps.
  final double snapThreshold;

  /// Drag velocity (px/s) for quick snapping.
  final double snapVelocityThreshold;

  /// Base duration for state animations.
  final Duration animationDuration;

  /// Whether to trigger haptic feedback on state changes.
  final bool enableHaptics;

  /// Whether the mini panel should snap to horizontal edges.
  final bool enableEdgeSnap;

  /// Whether the mini panel can be tucked away into screen edges.
  final bool enableTuck;

  /// Triggered when the window reaches mini state.
  final VoidCallback? onMinimized;

  /// Triggered when the window reaches expanded state.
  final VoidCallback? onMaximized;

  /// Triggered when the window is closed.
  final VoidCallback? onDismissed;

  /// Triggered when the window is tucked away into the edge.
  final VoidCallback? onTucked;

  /// Custom close button shown in expanded view.
  final Widget? closeButton;

  @override
  State<DragMiniWindow> createState() => _DragMiniWindowState();
}

class _DragMiniWindowState extends State<DragMiniWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  // Gesture status
  bool _isDraggingExpanded = false;
  Offset _fingerPos = Offset.zero;
  Offset? _miniLanding;
  Size _lastScreen = Size.zero;

  // Mini Repositioning
  Offset _miniPanStart = Offset.zero;
  double _miniPanDistance = 0.0;
  static const _tapDeadZone = 8.0;

  // Docking status
  bool _isDockingCandidateTop = false;
  bool _isDockingCandidateBottom = false;
  bool _isDockedAtTop = false;

  // Hover status
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

  @override
  void dispose() {
    _anim.removeListener(_onAnimTick);
    _anim.dispose();
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screen = MediaQuery.sizeOf(context);
    if (_lastScreen != Size.zero && _lastScreen != screen) {
      final safe = MediaQuery.paddingOf(context);
      final mini = _currentMiniSize;
      if (widget.controller.miniPosition != null) {
        widget.controller.setMiniPosition(
          _clampToSafe(widget.controller.miniPosition!, screen, safe, mini),
        );
      }
    }
    _lastScreen = screen;
  }

  // --- Logic Separation: Geometry ---

  Size get _currentMiniSize {
    final screen = MediaQuery.sizeOf(context);
    return kIsWeb || screen.width > 600
        ? widget.style.webMiniSize
        : widget.style.mobileMiniSize;
  }

  Size _getExpandedSize(Size screen) {
    if (widget.expandedSize != null) return widget.expandedSize!;
    final isLandscape = screen.width > screen.height;
    return isLandscape
        ? Size(screen.width * 0.96, screen.height * 0.92)
        : Size(screen.width * 0.92, screen.height * 0.80);
  }

  Offset _getExpandedOrigin(Size screen, Size expSize) => Offset(
        (screen.width - expSize.width) / 2,
        (screen.height - expSize.height) / 2,
      );

  Offset _getDefaultMiniOrigin(
    Size screen,
    EdgeInsets safe,
    Size miniSize,
    Alignment alignment,
  ) {
    final m = widget.style.edgeSnapMargin;
    final available = Size(
      screen.width - miniSize.width - (m * 2) - safe.horizontal,
      screen.height - miniSize.height - (m * 2) - safe.vertical,
    );
    final cx = (alignment.x + 1) / 2;
    final cy = (alignment.y + 1) / 2;
    return Offset(
      m + safe.left + cx * available.width,
      m + safe.top + cy * available.height,
    );
  }

  Offset _clampToSafe(Offset pos, Size screen, EdgeInsets safe, Size size) {
    final m = widget.style.edgeSnapMargin;
    return Offset(
      pos.dx.clamp(m + safe.left, screen.width - size.width - m - safe.right),
      pos.dy.clamp(m + safe.top, screen.height - size.height - m - safe.bottom),
    );
  }

  // --- Internal Handlers ---

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

  void _springTo(double target, {VoidCallback? onComplete}) {
    final sim = SpringSimulation(
      SpringDescription(
        mass: 1.0,
        stiffness: widget.style.springStiffness,
        damping: widget.style.springDamping,
      ),
      _anim.value,
      target,
      0.0,
    );
    _anim.animateWith(sim).whenCompleteOrCancel(onComplete ?? () {});
  }

  // --- Gesture Handlers ---

  void _onExpandedPanUpdate(DragUpdateDetails d) {
    _fingerPos = d.globalPosition;
    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final miniSize = _currentMiniSize;

    // YouTube style: Progress based on vertical distance
    final expSize = _getExpandedSize(screen);
    final startY = (screen.height - expSize.height) / 2;
    final maxSwipe = screen.height - startY - 100;
    final currentSwipe = (_fingerPos.dy - startY).clamp(0.0, maxSwipe);
    final progress = (currentSwipe / maxSwipe).clamp(0.0, 1.0);

    final landing = Offset(
      _fingerPos.dx - miniSize.width / 2,
      _fingerPos.dy - miniSize.height / 2,
    );

    widget.controller.setDragProgress(progress);
    _anim.value = progress;
    _isDraggingExpanded = true;
    setState(
        () => _miniLanding = _clampToSafe(landing, screen, safe, miniSize));
  }

  void _onExpandedPanEnd(DragEndDetails d) {
    _isDraggingExpanded = false;
    final progress = widget.controller.dragProgress;
    final velocity = d.velocity.pixelsPerSecond.dy;

    if (progress > widget.snapThreshold ||
        velocity > widget.snapVelocityThreshold) {
      if (widget.enableHaptics && !kIsWeb) HapticFeedback.lightImpact();
      _springTo(1.0, onComplete: () {
        final screen = MediaQuery.sizeOf(context);
        final safe = MediaQuery.paddingOf(context);
        final miniSize = _currentMiniSize;
        var landing = _miniLanding ??
            _getDefaultMiniOrigin(
                screen, safe, miniSize, widget.style.defaultMiniAlignment);

        if (widget.enableEdgeSnap) {
          final center = landing.dx + miniSize.width / 2;
          final m = widget.style.edgeSnapMargin;
          final dx = center < screen.width / 2
              ? m + safe.left
              : screen.width - miniSize.width - m - safe.right;
          landing = Offset(
              dx,
              landing.dy.clamp(m + safe.top,
                  screen.height - miniSize.height - m - safe.bottom));
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

  void _onMiniPanUpdate(DragUpdateDetails d) {
    _miniPanDistance += (d.globalPosition - _miniPanStart).distance;
    _miniPanStart = d.globalPosition;

    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final miniSize = _currentMiniSize;
    Offset currentPos = widget.controller.miniPosition ??
        _getDefaultMiniOrigin(
            screen, safe, miniSize, widget.style.defaultMiniAlignment);

    // DOCK BREAK LOGIC: If we are docked and start dragging, "break" the dock
    // and snap the player back to the finger position.
    if (widget.controller.isDocked) {
      if (_miniPanDistance > _tapDeadZone) {
        widget.controller.setDocked(false);
        // Position the mini window centered under the finger
        currentPos = Offset(
          d.globalPosition.dx - miniSize.width / 2,
          d.globalPosition.dy - miniSize.height / 2,
        );
      } else {
        // Still in deadzone, don't move yet
        return;
      }
    }

    final newPos = currentPos + d.delta;

    // Detect Snap Zones
    final centerX = newPos.dx + miniSize.width / 2;
    final isInCenterZone =
        centerX > screen.width * 0.3 && centerX < screen.width * 0.7;
    final distFromTop = newPos.dy + safe.top;
    final distFromBottom =
        screen.height - (newPos.dy + miniSize.height) - safe.bottom;

    final isTopCandidate = isInCenterZone && distFromTop < 60.0;
    final isBottomCandidate = isInCenterZone && distFromBottom < 60.0;

    if (isTopCandidate != _isDockingCandidateTop ||
        isBottomCandidate != _isDockingCandidateBottom) {
      if ((isTopCandidate || isBottomCandidate) &&
          widget.enableHaptics &&
          !kIsWeb) {
        HapticFeedback.selectionClick();
      }
      setState(() {
        _isDockingCandidateTop = isTopCandidate;
        _isDockingCandidateBottom = isBottomCandidate;
      });
    }

    // Tuck logic
    if (widget.enableTuck && !isTopCandidate && !isBottomCandidate) {
      final isPastLeft = newPos.dx < safe.left - miniSize.width * 0.5;
      final isPastRight =
          newPos.dx > screen.width - safe.right - miniSize.width * 0.5;
      widget.controller.setTucked(isPastLeft || isPastRight);
    } else {
      widget.controller.setTucked(false);
    }

    widget.controller.setMiniPosition(newPos);
  }

  void _onMiniPanEnd(DragEndDetails d) {
    if (_miniPanDistance < _tapDeadZone) {
      if (widget.enableHaptics && !kIsWeb) HapticFeedback.mediumImpact();
      widget.controller.maximize();
      widget.onMaximized?.call();
      return;
    }

    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final miniSize = _currentMiniSize;
    final pos = widget.controller.miniPosition ?? Offset.zero;

    if (_isDockingCandidateTop || _isDockingCandidateBottom) {
      setState(() {
        _isDockedAtTop = _isDockingCandidateTop;
        _isDockingCandidateTop = _isDockingCandidateBottom = false;
      });
      widget.controller.setDocked(true);
      return;
    }

    final velocityX = d.velocity.pixelsPerSecond.dx;
    if (velocityX.abs() > 1000) {
      final targetX =
          velocityX > 0 ? screen.width + 100.0 : -miniSize.width - 100.0;
      widget.controller.setMiniPosition(Offset(targetX, pos.dy));
      widget.controller.confirmDismiss();
      widget.onDismissed?.call();
      return;
    }

    if (widget.controller.isTucked) {
      final isLeft = pos.dx < screen.width / 2;
      final x = isLeft
          ? safe.left - miniSize.width + 20.0
          : screen.width - safe.right - 20.0;
      widget.controller.setMiniPosition(Offset(x, pos.dy));
      widget.onTucked?.call();
      return;
    }

    if (widget.enableEdgeSnap) {
      widget.controller.setDocked(false);
      final center = pos.dx + miniSize.width / 2;
      final m = widget.style.edgeSnapMargin;
      final dx = center < screen.width / 2
          ? m + safe.left
          : screen.width - miniSize.width - m - safe.right;
      widget.controller.setMiniPosition(Offset(
          dx,
          pos.dy.clamp(m + safe.top,
              screen.height - miniSize.height - m - safe.bottom)));
    }
  }

  // --- Build Modular Methods ---

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.isDismissed) return const SizedBox.shrink();

        final screen = MediaQuery.sizeOf(context);
        final safe = MediaQuery.paddingOf(context);
        final progress = widget.controller.dragProgress;

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                widget.controller.toggle(),
          },
          child: Focus(
            autofocus: true,
            child: Stack(
              children: [
                _buildBackdrop(progress),
                if (_isDockingCandidateTop)
                  _buildPlaceholder(safe, screen, true),
                if (_isDockingCandidateBottom)
                  _buildPlaceholder(safe, screen, false),
                _buildWindowFrame(screen, safe, progress),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackdrop(double progress) {
    if (progress >= 0.99) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: progress > 0.5,
        child: Opacity(
          opacity: (1.0 - progress).clamp(0.0, 1.0) *
              (widget.style.backdropColor.a / 255.0),
          child: GestureDetector(
            onTap: () => widget.controller.minimize(),
            child: Container(color: widget.style.backdropColor),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(EdgeInsets safe, Size screen, bool isTop) {
    return Positioned(
      left: 8,
      right: 8,
      top: isTop
          ? safe.top
          : screen.height - safe.bottom - widget.style.dockedHeight,
      height: widget.style.dockedHeight,
      child: Container(
        decoration: BoxDecoration(
          color: widget.style.placeholderColor ??
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.style.placeholderBorderColor ??
                Theme.of(context).primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildWindowFrame(Size screen, EdgeInsets safe, double progress) {
    final isMini = progress > 0.95 && !_isDraggingExpanded;
    final isDocked = widget.controller.isDocked;
    final miniSize = _currentMiniSize;
    final expSize = _getExpandedSize(screen);

    final expOrigin = _getExpandedOrigin(screen, expSize);
    final miniOrigin = _miniLanding ??
        widget.controller.miniPosition ??
        _getDefaultMiniOrigin(
            screen, safe, miniSize, widget.style.defaultMiniAlignment);

    Offset targetOrigin = miniOrigin;
    Size targetSize = miniSize;
    double targetRadius = widget.style.miniBorderRadius;

    if (isDocked && isMini) {
      targetOrigin = Offset(
          0,
          _isDockedAtTop
              ? safe.top
              : screen.height - safe.bottom - widget.style.dockedHeight);
      targetSize = Size(screen.width, widget.style.dockedHeight);
      targetRadius = 0.0;
    }

    final L = lerpDouble(expOrigin.dx, targetOrigin.dx, progress)!;
    final T = lerpDouble(expOrigin.dy, targetOrigin.dy, progress)!;
    final W = lerpDouble(expSize.width, targetSize.width, progress)!;
    final H = lerpDouble(expSize.height, targetSize.height, progress)!;
    final R = lerpDouble(widget.style.borderRadius, targetRadius, progress)!;

    return Positioned(
      left: L,
      top: T,
      width: W,
      height: H,
      child: MouseRegion(
        cursor: isMini ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onPanStart: (d) {
            _miniPanStart = d.globalPosition;
            _miniPanDistance = 0;
            if (!isMini) _anim.stop();
          },
          onPanUpdate: isMini ? _onMiniPanUpdate : _onExpandedPanUpdate,
          onPanEnd: (d) {
            _isDraggingExpanded = false;
            if (isMini) {
              _onMiniPanEnd(d);
            } else {
              _onExpandedPanEnd(d);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(R),
              boxShadow: isMini && !isDocked ? widget.style.shadows : [],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                _buildContent(isMini, isDocked, progress),
                _buildProgressBar(isMini, isDocked),
                _buildControls(isMini, isDocked),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isMini, bool isDocked, double progress) {
    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isDocked && isMini
            ? _buildDockedBar()
            : (progress > 0.8
                ? KeyedSubtree(
                    key: const ValueKey('mini'), child: widget.miniContent)
                : KeyedSubtree(
                    key: const ValueKey('exp'), child: widget.expandedContent)),
      ),
    );
  }

  Widget _buildProgressBar(bool isMini, bool isDocked) {
    if (!isMini && !isDocked) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 2,
      child: LinearProgressIndicator(
        value: widget.controller.playbackProgress,
        backgroundColor: Colors.white12,
        color: widget.style.progressColor,
      ),
    );
  }

  Widget _buildControls(bool isMini, bool isDocked) {
    if (isMini) {
      final showX = (!kIsWeb) || (kIsWeb && _isHovered);
      if (!showX) return const SizedBox.shrink();
      return Positioned(
        right: 4,
        top: 0,
        bottom: 0,
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 20),
          onPressed: () => widget.controller.dismiss(),
        ),
      );
    }

    if (widget.closeButton != null) {
      return Positioned(
        top: 16,
        right: 16,
        child: GestureDetector(
          onTap: () => widget.controller.minimize(),
          child: widget.closeButton!,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDockedBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
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
          Expanded(child: widget.title ?? const SizedBox.shrink()),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}
