import 'dart:ui';

/// Formalized states for the YouTube-like mini window interactions.
enum DragMiniStatus {
  /// Window is fully expanded, covering the intended area.
  full,

  /// Window is minimized to a small floating panel.
  mini,

  /// Window is docked as a full-width bar.
  docked,

  /// Window is hidden/closed.
  dismissed,

  /// Window is currently being moved vertically (minimizing/maximizing).
  draggingVertical,

  /// Window is currently being moved horizontally (repositioning/dismissing).
  draggingHorizontal,
}

/// A snapshot of the window's geometry and state.
class DragMiniState {
  /// Creates a [DragMiniState] snapshot.
  const DragMiniState({
    required this.status,
    required this.progress,
    required this.position,
  });

  /// Current machine status.
  final DragMiniStatus status;

  /// Normalized progress (0.0 = full, 1.0 = mini/docked).
  final double progress;

  /// Logical position of the window.
  final Offset position;

  /// Creates a copy of this state with the given fields replaced.
  DragMiniState copyWith({
    DragMiniStatus? status,
    double? progress,
    Offset? position,
  }) {
    return DragMiniState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      position: position ?? this.position,
    );
  }
}
