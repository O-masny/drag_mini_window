# drag_mini_window

A Flutter widget implementing **iOS/YouTube-style drag-to-place mini window**.

Drag the expanded overlay anywhere on screen — it shrinks as you move the finger and lands as a compact floating panel where you release. Tap the panel to maximize back.

---

## Features

- 🎯 **Single-gesture drag**: drag from expanded → minimizes + places in one motion
- 📌 **Free positioning**: mini panel lands exactly where you lift your finger
- ↔️ **Pan to reposition**: drag the mini panel to any corner afterward
- 🔁 **Tap to maximize**: tap on the mini panel to restore full size
- 🎛️ **Fully configurable**: sizes, backdrop, snap threshold, animation duration
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

// Listen to state
ListenableBuilder(
  listenable: _controller,
  builder: (context, _) {
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
| `expandedSize` | `Size?` | 88%×75% screen | Expanded overlay size |
| `miniSize` | `Size?` | `Size(160, 90)` | Mini panel size |
| `defaultMiniAlignment` | `Alignment` | `bottomRight` | Starting mini position |
| `backdropColor` | `Color` | `black 85%` | Expanded overlay background |
| `snapThreshold` | `double` | `0.3` | Progress needed to snap to mini |
| `snapVelocityThreshold` | `double` | `800.0` | Velocity (px/s) for velocity-snap |
| `animationDuration` | `Duration` | `280ms` | Snap animation duration |
| `animationCurve` | `Curve` | `easeOutCubic` | Snap animation curve |
| `borderRadius` | `double` | `16.0` | Expanded border radius |
| `miniBorderRadius` | `double` | `12.0` | Mini panel border radius |
| `onMinimized` | `VoidCallback?` | — | Called when fully minimized |
| `onMaximized` | `VoidCallback?` | — | Called when fully maximized |

---

## How it works

When the user **drags the expanded window**:
1. The panel shrinks proportionally to the drag distance (screen-diagonal normalized)
2. The **finger position** is tracked as the target mini-panel landing spot
3. On release: if `dragProgress > snapThreshold` (or velocity is high) → snaps to mini at the landing position; otherwise snaps back to expanded

When the user **taps or drags the mini panel**:
- Tap (< 8px movement) → maximize with animation
- Pan → freely reposition the mini panel

---

## Example

See the [`example/`](example/) directory for a runnable demo.

---

## License

MIT
