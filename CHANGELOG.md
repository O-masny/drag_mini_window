## 0.2.0

- **YouTube Pro UX Update**: Massive rewrite for premium video player feel.
- **Vertical Swipe Minimization**: Replaced radial drag with YouTube-style vertical swipe logic.
- **Docked Bottom Bar**: Mini window can now dock into a full-width bottom bar.
- **Title & Thumbnail Support**: Integrated slots for video metadata in docked/mini modes.
- **Playback Progress Bar**: Added a thin, customizable progress bar on mini/docked views.
- **Edge Tucking**: Mini panel can now be tucked away behind the screen edge.
- **Web/Desktop Optimizations**: 
  - Adaptive default sizes for web (360px width).
  - Hover overlays and cursors for desktop.
  - Keyboard shortcut (ESC) for status changes.
- **Animated Transitions**: Added `AnimatedSwitcher` for smooth expanded-to-mini content swapping.

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
