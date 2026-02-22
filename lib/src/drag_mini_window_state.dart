import 'dart:ui';

/// Formal states for the Draggable Mini Window state machine.
/// Formalized states for the YouTube-like mini window interactions.
enum DragMiniStatus {
  /// Window is fully expanded, covering the intended area.
  full,

  /// Window is in mini floating mode at a specific position.
  /// Window is minimized to a small floating panel.
  mini,

  /// Window is docked at top or bottom as a bar.
  docked,

  /// Window is hidden/closed.
  dismissed,

  /// Window is currently being moved vertically (minimizing/maximizing).
  draggingVertical,

  /// Window is currently being moved horizontally (dismissing).
  draggingHorizontal,

  /// Window is tucked into a screen edge.
  tucked,
}

/// A snapshot of the window's geometry and state.
class DragMiniState {
  const DragMiniState({
    required this.status,
    required this.progress,
    required this.position,
    required this.size,
  });

  /// Current machine status.
  final DragMiniStatus status;

  /// Normalized progress (0.0 = full, 1.0 = mini/docked).
  final double progress;

  /// Logical position of the window.
  final Offset position;

  /// Logical size of the window.
  final Size size;

  /// Creates a copy of this state with the given fields replaced.
  DragMiniState copyWith({
    DragMiniStatus? status,
    double? progress,
    Offset? position,
    Size? size,
  }) {
    return DragMiniState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      position: position ?? this.position,
      size: size ?? this.size,
    );
  }
}
