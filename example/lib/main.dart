import 'dart:async';

import 'package:drag_mini_window/drag_mini_window.dart';
import 'package:flutter/material.dart';

void main() => runApp(const App());

/// Main application widget for the example.
class App extends StatelessWidget {
  /// Creates the [App].
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Style Mini Window',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
      ),
      home: const DemoPage(),
    );
  }
}

/// A demo page showcasing the [DragMiniWindow] functionality.
class DemoPage extends StatefulWidget {
  /// Creates the [DemoPage].
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _controller = DragMiniWindowController();
  double _progress = 0.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _progress = (_progress + 0.005) % 1.0;
      _controller.setPlaybackProgress(_progress);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('YouTube UX Pro'),
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Content
          ListView.builder(
            itemCount: 20,
            itemBuilder: (context, index) => ListTile(
              leading: Container(width: 100, height: 60, color: Colors.white12),
              title: Text('Video Recommendation #$index'),
              subtitle: const Text('YouTube Channel • 1.2M views'),
            ),
          ),

          // The DragMiniWindow
          DragMiniWindow(
            controller: _controller,
            style: DragMiniWindowStyle(
              progressColor: Colors.red,
              backdropColor: Colors.black.withValues(alpha: 0.8),
            ),
            expandedContent:
                _VideoPlayer(isMini: false, controller: _controller),
            miniContent: _VideoPlayer(isMini: true, controller: _controller),
            title: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Building a Pro Flutter Package',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Antigravity Dev',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
            thumbnail: Image.network(
              'https://picsum.photos/seed/flutter/320/180',
              fit: BoxFit.cover,
            ),
            closeButton: const Icon(Icons.keyboard_arrow_down, size: 30),
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (!_controller.isDismissed) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _controller.maximize(),
            child: const Icon(Icons.play_arrow),
          );
        },
      ),
    );
  }
}

class _VideoPlayer extends StatelessWidget {
  const _VideoPlayer({required this.isMini, required this.controller});
  final bool isMini;
  final DragMiniWindowController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hideOverlays = controller.isDragging || isMini;
        return Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fake Video Content
              Image.network(
                'https://picsum.photos/seed/flutter/1280/720',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              if (!hideOverlays)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                        Colors.black54
                      ],
                    ),
                  ),
                ),
              if (!hideOverlays)
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_fill, size: 80, color: Colors.white),
                    SizedBox(height: 20),
                    Text('04:20 / 12:00',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              if (isMini)
                const Positioned(
                  child: Icon(Icons.pause, size: 30, color: Colors.white),
                ),
            ],
          ),
        );
      },
    );
  }
}
