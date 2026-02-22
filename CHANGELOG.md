## 0.1.0

- Initial release.
- `DragMiniWindow` widget with fully configurable expanded/mini content.
- `DragMiniWindowController` for programmatic minimize / maximize / toggle / dismiss.
- **Single-gesture drag**: drag from expanded → shrinks + places in one motion.
- **Spring physics**: snap animations use `SpringSimulation` for an organic, iOS-like feel.
- **Haptic feedback**: light impact on minimize, medium impact on maximize.
- **Edge snapping**: mini panel slides to the nearest horizontal screen edge after release.
- **Free positioning**: mini panel lands exactly where the finger lifts, then edge-snaps.
- **Tap to maximize**: tap the mini panel to restore full size.
- **Swipe to dismiss**: fast horizontal swipe dismisses the mini panel.
- **Orientation-safe**: re-clamps mini panel position on screen rotation.
- **Adaptive sizing**: landscape-aware expanded size defaults.
- Configurable: sizes, backdrop color, snap threshold, velocity threshold, spring constants, animation duration, border radius, accent border.
