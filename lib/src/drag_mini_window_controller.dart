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

  /// Current drag/animation progress.
  /// 0.0 = fully expanded, 1.0 = fully minimized.
  double _dragProgress = 0.0;

  /// Current free-form position of the mini panel.
  /// `null` means "use [DragMiniWindow.defaultMiniAlignment]".
  Offset? _miniPosition;

  // ── Public state ─────────────────────────────────────────────────────

  /// Whether the window is currently minimized.
  bool get isMinimized => _isMinimized;

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
    notifyListeners();
  }

  // ── Public API ───────────────────────────────────────────────────────

  /// Programmatically minimize the window.
  void minimize() {
    _isMinimized = true;
    _dragProgress = 1.0;
    notifyListeners();
  }

  /// Programmatically maximize the window.
  void maximize() {
    _isMinimized = false;
    _dragProgress = 0.0;
    notifyListeners();
  }

  /// Toggle between minimized and maximized.
  void toggle() => _isMinimized ? maximize() : minimize();
}
