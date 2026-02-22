# drag_mini_window

[![pub package](https://img.shields.io/pub/v/drag_mini_window.svg)](https://pub.dev/packages/drag_mini_window)
[![likes](https://img.shields.io/pub/likes/drag_mini_window)](https://pub.dev/packages/drag_mini_window/score)

A Flutter widget implementing **iOS/YouTube-style drag-to-place mini window**.

Drag the expanded overlay anywhere on screen — it shrinks as you move the finger and lands as a compact floating panel where you release. Tap the panel to maximize back.

---

## Features

- 🎯 **Single-gesture drag**: drag from expanded → minimizes + places in one motion
- 🌀 **Spring physics**: snap animations use `SpringSimulation` for an organic feel
- 📳 **Haptic feedback**: light impact on minimize, medium impact on maximize
- 🧲 **Edge snapping**: mini panel slides to the nearest horizontal edge after release
- 📌 **Free positioning**: mini panel lands exactly where you lift your finger
- ↔️ **Pan to reposition**: drag the mini panel to any position afterward
- 🔁 **Tap to maximize**: tap on the mini panel to restore full size
- 💨 **Swipe to dismiss**: fast horizontal swipe dismisses the mini panel
- 🔄 **Orientation-safe**: re-clamps panel position on screen rotation
- 📐 **Adaptive sizing**: landscape-aware expanded size defaults
- 🎛️ **Fully configurable**: sizes, backdrop, thresholds, spring constants, borders
- 🧩 **Content-agnostic**: works with video, maps, chat, anything

---

## Usage

```dart
import 'package:drag_mini_window/drag_mini_window.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final _controller = DragMiniWindowController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Your main page content
          const Center(child: Text('Main Content')),

          // The draggable mini window
          DragMiniWindow(
            controller: _controller,
            expandedContent: MyVideoPlayer(),
            miniContent: MiniVideoPlayer(),
          ),
        ],
      ),
    );
  }
}
```

### Programmatic control

```dart
_controller.minimize();
_controller.maximize();
_controller.toggle();
_controller.dismiss();

// Listen to state
ListenableBuilder(
  listenable: _controller,
  builder: (context, _) {
    if (_controller.isDismissed) return const SizedBox.shrink();
    return Text(_controller.isMinimized ? 'Mini' : 'Expanded');
  },
);
```

---

## Parameters

### `DragMiniWindow`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `controller` | `DragMiniWindowController` | required | State controller |
| `expandedContent` | `Widget` | required | Content when expanded |
| `miniContent` | `Widget` | required | Content when minimized |
| `expandedSize` | `Size?` | 88%×75% / 96%×92% | Expanded overlay size (adapts to orientation) |
| `miniSize` | `Size` | `Size(160, 90)` | Mini panel size |
| `defaultMiniAlignment` | `Alignment` | `bottomRight` | Starting mini position |
| `backdropColor` | `Color?` | `black 85%` | Expanded overlay backdrop |
| `snapThreshold` | `double` | `0.3` | Progress needed to snap to mini |
| `snapVelocityThreshold` | `double` | `800.0` | Velocity (px/s) for velocity-snap |
| `animationDuration` | `Duration` | `280ms` | Animation controller duration |
| `animationCurve` | `Curve` | `easeOutCubic` | Fallback curve (spring is primary) |
| `enableHaptics` | `bool` | `true` | Haptic feedback on snap |
| `enableEdgeSnap` | `bool` | `true` | Snap mini panel to nearest edge |
| `edgeSnapMargin` | `double` | `12.0` | Edge snap margin from screen border |
| `springStiffness` | `double` | `350.0` | Spring stiffness (higher = snappier) |
| `springDamping` | `double` | `28.0` | Spring damping ratio |
| `borderRadius` | `double` | `16.0` | Expanded border radius |
| `miniBorderRadius` | `double` | `12.0` | Mini panel border radius |
| `miniBorderColor` | `Color?` | theme primary | Mini panel accent border |
| `miniBorderWidth` | `double` | `2.0` | Accent border width |
| `closeButton` | `Widget?` | — | Optional close button overlay |
| `onMinimized` | `VoidCallback?` | — | Called when fully minimized |
| `onMaximized` | `VoidCallback?` | — | Called when fully maximized |
| `onDismissed` | `VoidCallback?` | — | Called when dismissed |

---

## How it works

When the user **drags the expanded window**:
1. The panel shrinks proportionally to the drag distance (panel-diagonal normalized)
2. The **finger position** is tracked as the target mini-panel landing spot
3. On release: if `dragProgress > snapThreshold` (or velocity is high) → spring-snaps to mini at the nearest edge; otherwise springs back to expanded
4. 📳 Haptic feedback fires at the snap point

When the user **taps or drags the mini panel**:
- Tap (< 8px movement) → maximize with spring animation + haptic
- Pan → freely reposition; on release, edge-snaps to nearest side
- Fast horizontal swipe → dismiss the panel entirely

---

## Example

See the [`example/`](example/) directory for a runnable demo.

---

## License

MIT
