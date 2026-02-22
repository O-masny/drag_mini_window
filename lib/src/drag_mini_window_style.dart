import 'package:flutter/material.dart';

/// Defines the visual appearance and behavior settings for [DragMiniWindow].
class DragMiniWindowStyle {
  /// Creates a [DragMiniWindowStyle] with the provided configuration.
  const DragMiniWindowStyle({
    this.webMiniSize = const Size(360, 202),
    this.mobileMiniSize = const Size(160, 90),
    this.defaultMiniAlignment = Alignment.bottomRight,
    this.backdropColor = const Color(0xD9000000),
    this.borderRadius = 16.0,
    this.miniBorderRadius = 12.0,
    this.dockedHeight = 64.0,
    this.progressColor = Colors.red,
    this.placeholderColor,
    this.placeholderBorderColor,
    this.edgeSnapMargin = 16.0,
    this.springStiffness = 300.0,
    this.springDamping = 30.0,
    this.shadows = const [
      BoxShadow(color: Colors.black54, blurRadius: 12, spreadRadius: 2),
    ],
  });

  /// Size of the mini window on web or large screens.
  final Size webMiniSize;

  /// Size of the mini window on mobile screens.
  final Size mobileMiniSize;

  /// Default landing corner for the mini panel.
  final Alignment defaultMiniAlignment;

  /// Color of the dimmed background when expanded.
  final Color backdropColor;

  /// Border radius of the expanded view.
  final double borderRadius;

  /// Border radius of the mini floating view.
  final double miniBorderRadius;

  /// Height of the docked bar (top/bottom).
  final double dockedHeight;

  /// Color of the playback progress line.
  final Color progressColor;

  /// Color of the snap zone placeholder fill.
  final Color? placeholderColor;

  /// Color of the snap zone placeholder border.
  final Color? placeholderBorderColor;

  /// Distance from screen edges for snapping.
  final double edgeSnapMargin;

  /// Stiffness of the spring animation.
  final double springStiffness;

  /// Damping of the spring animation.
  final double springDamping;

  /// Shadows applied to the mini window.
  final List<BoxShadow> shadows;

  /// Creates a copy of this style with the given fields replaced.
  DragMiniWindowStyle copyWith({
    Size? webMiniSize,
    Size? mobileMiniSize,
    Alignment? defaultMiniAlignment,
    Color? backdropColor,
    double? borderRadius,
    double? miniBorderRadius,
    double? dockedHeight,
    Color? progressColor,
    Color? placeholderColor,
    Color? placeholderBorderColor,
    double? edgeSnapMargin,
    double? springStiffness,
    double? springDamping,
    List<BoxShadow>? shadows,
  }) {
    return DragMiniWindowStyle(
      webMiniSize: webMiniSize ?? this.webMiniSize,
      mobileMiniSize: mobileMiniSize ?? this.mobileMiniSize,
      defaultMiniAlignment: defaultMiniAlignment ?? this.defaultMiniAlignment,
      backdropColor: backdropColor ?? this.backdropColor,
      borderRadius: borderRadius ?? this.borderRadius,
      miniBorderRadius: miniBorderRadius ?? this.miniBorderRadius,
      dockedHeight: dockedHeight ?? this.dockedHeight,
      progressColor: progressColor ?? this.progressColor,
      placeholderColor: placeholderColor ?? this.placeholderColor,
      placeholderBorderColor:
          placeholderBorderColor ?? this.placeholderBorderColor,
      edgeSnapMargin: edgeSnapMargin ?? this.edgeSnapMargin,
      springStiffness: springStiffness ?? this.springStiffness,
      springDamping: springDamping ?? this.springDamping,
      shadows: shadows ?? this.shadows,
    );
  }
}
