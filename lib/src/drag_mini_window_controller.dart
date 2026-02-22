import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

import 'drag_mini_window_state.dart';

/// A production-ready controller that manages a formal state machine
/// and physics-based snapping for a YouTube-like experience.
class DragMiniWindowController extends ChangeNotifier {
  /// Creates a [DragMiniWindowController] with an optional [initialStatus].
  DragMiniWindowController({
    DragMiniStatus initialStatus = DragMiniStatus.full,
  }) : _status = initialStatus {
    if (_status == DragMiniStatus.mini || _status == DragMiniStatus.docked) {
      _progress = 1.0;
    }
  }

  // --- State ---
  DragMiniStatus _status = DragMiniStatus.full;
  double _progress = 0.0;
  Offset _position = Offset.zero;

  // --- Animation Physics ---
  Ticker? _ticker;
  Simulation? _simulation;

  /// Current status of the window state machine.
  DragMiniStatus get status => _status;

  /// Normalized progress of the window (0.0 = full, 1.0 = mini).
  double get progress => _progress;

  /// Current logical position of the window.
  Offset get position => _position;

  /// Returns true if the window is currently dismissed.
  bool get isDismissed => _status == DragMiniStatus.dismissed;

  /// Returns true if the window is in a minimized/docked state.
  bool get isMinimized =>
      _status == DragMiniStatus.mini || _status == DragMiniStatus.docked;

  /// Returns true if the window is currently being dragged.
  bool get isDragging =>
      _status == DragMiniStatus.draggingVertical ||
      _status == DragMiniStatus.draggingHorizontal;

  /// Shim for legacy/internal compatibility; same as [progress].
  double get dragProgress => _progress;

  /// Shim for legacy/internal compatibility; same as [position].
  Offset? get miniPosition => _position;

  final ValueNotifier<double> _playbackProgress = ValueNotifier<double>(0.0);

  /// Listenable for the video playback progress.
  ValueListenable<double> get playbackProgressListenable => _playbackProgress;

  // --- Public API ---

  /// Animates the window to the maximized (full) state.
  void maximize() {
    snapWithPhysics(
      velocity: -1.0,
      targetProgress: 0.0,
      targetStatus: DragMiniStatus.full,
    );
  }

  /// Animates the window to the minimized (mini) state.
  void minimize() {
    snapWithPhysics(
      velocity: 1.0,
      targetProgress: 1.0,
      targetStatus: DragMiniStatus.mini,
    );
  }

  /// Animates the window to the dismissed (closed) state.
  void dismiss() {
    _stopAnimation();
    _status = DragMiniStatus.dismissed;
    notifyListeners();
  }

  /// Transitions the window to the docked (full-width bar) state.
  void dock() {
    _stopAnimation();
    _status = DragMiniStatus.docked;
    _progress = 1.0;
    notifyListeners();
  }

  /// Toggles between minimized and maximized states.
  void toggle() => isMinimized ? maximize() : minimize();

  /// Sets the video playback progress (0.0 to 1.0).
  void setPlaybackProgress(double value) {
    _playbackProgress.value = value.clamp(0.0, 1.0);
  }

  // --- Internal State Machine Logic ---

  /// Updates the internal path (position) of the mini window.
  @internal
  void updateInternalPath(Offset pos) {
    _position = pos;
    notifyListeners();
  }

  /// Sets the window to a dragging state.
  @internal
  void startDragging(DragMiniStatus type) {
    _stopAnimation();
    _status = type;
    notifyListeners();
  }

  /// Updates the drag progress during an active gesture.
  @internal
  void updateDragProgress(double progress) {
    _progress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Sets the explicit mini position (used for 2D dragging).
  @internal
  void setMiniPosition(Offset pos) {
    _position = pos;
    notifyListeners();
  }

  /// Snaps the window to a target progress using physics simulations.
  @internal
  void snapWithPhysics({
    required double velocity,
    required double targetProgress,
    required DragMiniStatus targetStatus,
    SpringDescription spring = const SpringDescription(
      mass: 1.0,
      stiffness: 700.0,
      damping: 40.0,
    ),
  }) {
    _stopAnimation();
    _simulation = SpringSimulation(spring, _progress, targetProgress, velocity);
    _ticker ??= Ticker(_onTick);
    _ticker!.start();
  }

  void _onTick(Duration elapsed) {
    if (_simulation == null) return;
    final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _progress = _simulation!.x(t).clamp(0.0, 1.0);

    if (_simulation!.isDone(t)) {
      final isMini = _progress > 0.5;
      _status = isMini ? DragMiniStatus.mini : DragMiniStatus.full;
      _progress = isMini ? 1.0 : 0.0;
      _stopAnimation();
    }
    notifyListeners();
  }

  void _stopAnimation() {
    _ticker?.stop();
    _simulation = null;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _playbackProgress.dispose();
    super.dispose();
  }
}
