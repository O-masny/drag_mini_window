import 'package:flutter/material.dart';

import 'drag_mini_presentation_layer.dart';
import 'drag_mini_window_controller.dart';
import 'drag_mini_window_style.dart';

/// The top-level manager for the YouTube-style mini window.
/// Responsible for OverlayEntry management and child state persistence.
class DragMiniWindow extends StatefulWidget {
  /// Creates a [DragMiniWindow].
  const DragMiniWindow({
    super.key,
    required this.controller,
    required this.expandedContent,
    required this.miniContent,
    this.style = const DragMiniWindowStyle(),
    this.title,
    this.thumbnail,
    this.closeButton,
  });

  /// The controller managing the window state machine.
  final DragMiniWindowController controller;

  /// Content shown when the window is in full-screen mode.
  final Widget expandedContent;

  /// Content shown when the window is in mini-player mode.
  final Widget miniContent;

  /// Visual style configurations.
  final DragMiniWindowStyle style;

  /// Optional title for the mini-player area.
  final Widget? title;

  /// Optional thumbnail shown in the mini-player.
  final Widget? thumbnail;

  /// Optional close button widget.
  final Widget? closeButton;

  @override
  State<DragMiniWindow> createState() => _DragMiniWindowState();
}

class _DragMiniWindowState extends State<DragMiniWindow> {
  // GlobalKeys ensure the child widget state is preserved when
  // switching between expanded and mini modes in the presentation layer.
  final GlobalKey _expandedKey = GlobalKey();
  final GlobalKey _miniKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(DragMiniWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    // We only need to rebuild if state machine moves
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.isDismissed) return const SizedBox.shrink();

    return DragMiniPresentationLayer(
      controller: widget.controller,
      style: widget.style,
      title: widget.title,
      thumbnail: widget.thumbnail,
      closeButton: widget.closeButton,
      expandedContent:
          KeyedSubtree(key: _expandedKey, child: widget.expandedContent),
      miniContent: KeyedSubtree(key: _miniKey, child: widget.miniContent),
    );
  }
}
