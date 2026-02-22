import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Controls the state of a [DragMiniWindow].
///
/// ```dart
/// final controller = DragMiniWindowController();
/// controller.minimize();
/// controller.maximize();
/// controller.setPlaybackProgress(0.5); // YouTube-style progress bar
/// ```
class DragMiniWindowController extends ChangeNotifier {
  bool _isMinimized = false;
  bool _isDismissed = false;
  bool _isDocked = false;
  bool _isTucked = false;
  double _dragProgress = 0.0;
  double _playbackProgress = 0.0;
  Offset? _miniPosition;

  // ── Public state ─────────────────────────────────────────────────────

  /// Whether the window is currently minimized.
  bool get isMinimized => _isMinimized;

  /// Whether the window is currently dismissed (closed).
  bool get isDismissed => _isDismissed;

  /// Whether the mini panel is currently docked at the bottom edge.
  bool get isDocked => _isDocked;

  /// Whether the mini panel is tucked behind the screen edge.
  bool get isTucked => _isTucked;

  /// Normalized progress between expanded (0.0) and minimized (1.0).
  double get dragProgress => _dragProgress;

  /// The free-form position of the mini panel, in screen coordinates.
  Offset? get miniPosition => _miniPosition;

  /// Playback progress (0.0–1.0) shown as a thin progress bar
  /// on the mini panel or docked bar.
  double get playbackProgress => _playbackProgress;

  // ── Internal setters (used by the widget) ────────────────────────────

  @internal
  void setDragProgress(double value) {
    _dragProgress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  @internal
  void setMiniPosition(Offset position) {
    _miniPosition = position;
    notifyListeners();
  }

  @internal
  void confirmMinimize({required Offset landingPosition}) {
    _isMinimized = true;
    _dragProgress = 1.0;
    _miniPosition = landingPosition;
    _isDismissed = false;
    notifyListeners();
  }

  @internal
  void confirmDismiss() {
    _isDismissed = true;
    notifyListeners();
  }

  @internal
  void setDocked(bool docked) {
    if (_isDocked != docked) {
      _isDocked = docked;
      notifyListeners();
    }
  }

  @internal
  void setTucked(bool tucked) {
    if (_isTucked != tucked) {
      _isTucked = tucked;
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
  void maximize() {
    _isDismissed = false;
    _isDocked = false;
    _isTucked = false;
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
    _isTucked = false;
    _isMinimized = true;
    _dragProgress = 1.0;
    notifyListeners();
  }

  /// Programmatically undock back to floating mini.
  void undock() {
    _isDocked = false;
    notifyListeners();
  }

  /// Set the playback progress (0.0–1.0) for the mini bar indicator.
  void setPlaybackProgress(double value) {
    _playbackProgress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Tuck the mini panel behind the screen edge.
  void tuck() {
    _isTucked = true;
    notifyListeners();
  }

  /// Untuck the mini panel from behind the screen edge.
  void untuck() {
    _isTucked = false;
    notifyListeners();
  }

  /// Toggle between minimized and maximized.
  void toggle() => _isMinimized ? maximize() : minimize();
}
