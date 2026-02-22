import 'dart:async';

import 'package:drag_mini_window/drag_mini_window.dart';
import 'package:flutter/material.dart';

void main() => runApp(const App());

/// Root application widget for the drag_mini_window demo.
class App extends StatelessWidget {
  /// Creates the [App].
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'drag_mini_window demo',
      theme: ThemeData.dark(useMaterial3: true),
      home: const DemoPage(),
    );
  }
}

/// Main demo page showing a [DragMiniWindow] with a fake video player.
class DemoPage extends StatefulWidget {
  /// Creates the [DemoPage].
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _controller = DragMiniWindowController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('drag_mini_window'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // ── Main page content ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tap the button to open the player.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _controller.maximize,
                  icon: const Icon(Icons.play_circle_rounded),
                  label: const Text('Open Player'),
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => Text(
                    _controller.isMinimized ? '▶ Minimized' : '◻ Expanded',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // ── DragMiniWindow overlay ──
          DragMiniWindow(
            controller: _controller,
            expandedContent: const _FakePlayer(mini: false),
            miniContent: const _FakePlayer(mini: true),
            onMinimized: () => debugPrint('minimized'),
            onMaximized: () => debugPrint('maximized'),
          ),
        ],
      ),
    );
  }
}

/// A mock player widget for the demo.
class _FakePlayer extends StatefulWidget {
  const _FakePlayer({required this.mini});
  final bool mini;

  @override
  State<_FakePlayer> createState() => _FakePlayerState();
}

class _FakePlayerState extends State<_FakePlayer> {
  bool _playing = false;
  late Timer _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_playing && mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mini) {
      return Container(
        color: const Color(0xFF1A237E),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.movie_rounded, color: Colors.white30, size: 40),
            Positioned(
              bottom: 6,
              right: 8,
              child: Text(
                '${_seconds}s',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }

    // Expanded view
    return Container(
      color: const Color(0xFF0D0D0D),
      child: Column(
        children: [
          // Fake titlebar
          Container(
            color: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Icon(
                  Icons.movie_rounded,
                  color: Colors.white54,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'drag_mini_window demo video',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Drag hint
                Text(
                  '↕ drag to place',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          // Fake video area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.indigo.shade900, Colors.black],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _playing = !_playing),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _playing
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          key: ValueKey(_playing),
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Drag anywhere to minimize',
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
