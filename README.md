# drag_mini_window

[![pub package](https://img.shields.io/pub/v/drag_mini_window.svg)](https://pub.dev/packages/drag_mini_window)

A high-performance Flutter widget for creating **YouTube/iOS-style draggable mini windows**. Refined for 2025 with pro-level UX patterns, vertical swipe gestures, and full web/desktop support.

---

## 🚀 Pro Features (YouTube Style)

- 🎬 **Vertical Swipe Minimization**: Smooth vertical swipe down to minimize (YouTube-style) with a linear progress model.
- 🎯 **Docked Bottom Bar**: Transition into a fixed bottom bar with support for **Thumbnail**, **Title**, and controls.
- 📊 **Playback Progress Bar**: Thin video progress indicator on the bottom edge of the mini window or bar.
- 📌 **Edge Tucking**: Ability to "tuck" the mini window behind the screen edge (hide-to-edge).
- 🖥️ **Web & Desktop Optimized**: 
  - Larger default size for desktop (16:9 360px).
  - **Hover state** with overlay controls.
  - Cursors (pointer/grab) and Esc keyboard shortcut support.
- 🌀 **Spring Physics**: Organic animations using `SpringSimulation`.
- 📳 **Smart Haptics**: Adaptive vibrations on snap points or docking (disabled on web).
- 🧲 **Edge Snapping**: Automatic snapping to horizontal edges.
- 🔄 **Animated Cross-fade**: Smooth visual switching between expanded and mini content.

---

## Usage

```dart
import 'package:drag_mini_window/drag_mini_window.dart';

// ...
DragMiniWindow(
  controller: _controller,
  expandedContent: LargeVideoPlayer(),
  miniContent: SmallVideoPlayer(),
  title: Text('My Video Title'),
  thumbnail: Image.asset('thumb.png'),
  onMinimized: () => print('Mini!'),
)
```

### Controlling Progress
```dart
_controller.setPlaybackProgress(0.42); // Updates the red line at the bottom
```

---

## 📐 Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `controller` | `DragMiniWindowController` | required | State controller |
| `expandedContent` | `Widget` | required | Content when expanded |
| `miniContent` | `Widget` | required | Content when minimized |
| `title` | `Widget?` | — | Title widget for the docked bottom bar |
| `thumbnail` | `Widget?` | — | Thumbnail widget for the docked bottom bar |
| `webMiniSize` | `Size` | `360x202` | Mini size for web/desktop devices |
| `mobileMiniSize` | `Size` | `160x90` | Mini size for mobile devices |
| `enableTuck` | `bool` | `true` | Allow hiding the mini window into the side edge |
| `progressColor` | `Color` | `red` | Color of the playback progress line |

---

## License

MIT
