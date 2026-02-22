import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Controls the state of a [DragMiniWindow].
///
/// Extend or listen to this via [ListenableBuilder] or [AnimatedBuilder].
///
/// ```dart
/// final controller = DragMiniWindowController();
/// controller.minimize();
/// controller.maximize();
/// ```
class DragMiniWindowController extends ChangeNotifier {
  bool _isMinimized = false;
  bool _isDismissed = false;
  bool _isDocked = false;

  /// Current drag/animation progress.
  /// 0.0 = fully expanded, 1.0 = fully minimized.
  double _dragProgress = 0.0;

  /// Current free-form position of the mini panel.
  /// `null` means "use [DragMiniWindow.defaultMiniAlignment]".
  Offset? _miniPosition;

  // ── Public state ─────────────────────────────────────────────────────

  /// Whether the window is currently minimized.
  bool get isMinimized => _isMinimized;

  /// Whether the window is currently dismissed (closed).
  bool get isDismissed => _isDismissed;

  /// Whether the mini panel is currently docked at the bottom edge.
  bool get isDocked => _isDocked;

  /// Normalized progress between expanded (0.0) and minimized (1.0).
  /// Useful for building custom interpolated effects.
  double get dragProgress => _dragProgress;

  /// The free-form position of the mini panel, in screen coordinates.
  /// `null` when using the default alignment.
  Offset? get miniPosition => _miniPosition;

  // ── Internal setters (used by the widget) ────────────────────────────

  /// Called by the widget during drag gestures.
  @internal
  void setDragProgress(double value) {
    _dragProgress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Called by the widget when the mini panel is repositioned via pan.
  @internal
  void setMiniPosition(Offset position) {
    _miniPosition = position;
    notifyListeners();
  }

  /// Called by the widget when full minimization is confirmed.
  @internal
  void confirmMinimize({required Offset landingPosition}) {
    _isMinimized = true;
    _dragProgress = 1.0;
    _miniPosition = landingPosition;
    _isDismissed = false;
    notifyListeners();
  }

  /// Called by the widget when the panel is dismissed.
  @internal
  void confirmDismiss() {
    _isDismissed = true;
    notifyListeners();
  }

  /// Called by the widget when the panel enters/exits the dock zone.
  @internal
  void setDocked(bool docked) {
    if (_isDocked != docked) {
      _isDocked = docked;
      notifyListeners();
    }
  }

  // ── Public API ───────────────────────────────────────────────────────

  /// Programmatically minimize the window.
  void minimize() {
    _isDismissed = false;
    _isMinimized = true;
    _dragProgress = 1.0;
    notifyListeners();
  }

  /// Programmatically maximize the window.
  ///
  /// Clears the stored [miniPosition] so the next minimize cycle starts from
  /// [DragMiniWindow.defaultMiniAlignment] rather than the previous landing spot.
  void maximize() {
    _isDismissed = false;
    _isDocked = false;
    _isMinimized = false;
    _dragProgress = 0.0;
    _miniPosition = null;
    notifyListeners();
  }

  /// Programmatically dismiss (close) the window.
  void dismiss() {
    _isDismissed = true;
    notifyListeners();
  }

  /// Programmatically dock the mini panel at the bottom edge.
  void dock() {
    _isDocked = true;
    _isMinimized = true;
    _dragProgress = 1.0;
    notifyListeners();
  }

  /// Programmatically undock back to floating mini.
  void undock() {
    _isDocked = false;
    notifyListeners();
  }

  /// Toggle between minimized and maximized.
  void toggle() => _isMinimized ? maximize() : minimize();
}
