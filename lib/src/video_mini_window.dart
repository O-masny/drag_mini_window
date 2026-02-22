import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'drag_mini_window.dart';
import 'drag_mini_window_controller.dart';
import 'drag_mini_window_state.dart';

/// A high-level, "Plug & Play" video tutorial window that supports
/// YouTube-style dragging, scaling, and professional aesthetics.
class VideoMiniWindow extends StatefulWidget {
  /// Creates a [VideoMiniWindow].
  const VideoMiniWindow({
    super.key,
    required this.url,
    required this.title,
    this.subtitle = 'Tutoriál',
    this.initialMinimized = false,
    this.autoPlay = true,
    this.onClose,
  });

  /// The URL of the video to play.
  final String url;

  /// The main title shown in the expanded view.
  final String title;

  /// The subtitle shown in the expanded view.
  final String subtitle;

  /// Whether to start in the minimized (mini-player) state.
  final bool initialMinimized;

  /// Whether to start playback automatically.
  final bool autoPlay;

  /// Callback when the window is closed/stopped.
  final VoidCallback? onClose;

  @override
  State<VideoMiniWindow> createState() => _VideoMiniWindowState();
}

class _VideoMiniWindowState extends State<VideoMiniWindow> {
  late DragMiniWindowController _dmw;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  final GlobalKey _videoFrameKey = GlobalKey();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _dmw = DragMiniWindowController(
      initialStatus:
          widget.initialMinimized ? DragMiniStatus.mini : DragMiniStatus.full,
    );
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final uri = Uri.parse(widget.url);
    final controller = VideoPlayerController.networkUrl(uri);
    _videoController = controller;

    try {
      await controller.initialize();
      if (_isDisposed) return;

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: widget.autoPlay,
        looping: false,
        aspectRatio: controller.value.aspectRatio,
        showControls: true,
        allowFullScreen: false,
        placeholder: Container(color: Colors.black),
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _dmw.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragMiniWindow(
      controller: _dmw,
      expandedContent: _VideoExpandedContent(
        title: widget.title,
        subtitle: widget.subtitle,
        dmw: _dmw,
        chewieController: _chewieController,
        videoController: _videoController,
        videoFrameKey: _videoFrameKey,
        onClose: widget.onClose,
      ),
      closeButton: widget.onClose != null
          ? IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 28),
              onPressed: widget.onClose,
            )
          : null,
      miniContent: _VideoMiniContent(
        videoFrameKey: _videoFrameKey,
        chewieController: _chewieController,
      ),
    );
  }
}

class _VideoFrame extends StatelessWidget {
  const _VideoFrame({
    super.key,
    required this.chewieController,
    this.isMini = false,
  });

  final ChewieController? chewieController;
  final bool isMini;

  @override
  Widget build(BuildContext context) {
    if (chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      );
    }

    // Standard layout. Chewie handles its own internal scaling of the video texture.
    // By letting it fill the container, we preserve logical pixel sizes for controls.
    return Container(
      color: Colors.black,
      child: Center(
        child: Chewie(controller: chewieController!),
      ),
    );
  }
}

class _VideoExpandedContent extends StatelessWidget {
  const _VideoExpandedContent({
    required this.title,
    required this.subtitle,
    required this.dmw,
    required this.chewieController,
    required this.videoController,
    required this.videoFrameKey,
    this.onClose,
  });

  final String title;
  final String subtitle;
  final DragMiniWindowController dmw;
  final ChewieController? chewieController;
  final VideoPlayerController? videoController;
  final GlobalKey videoFrameKey;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dmw,
      builder: (context, _) {
        final progress = dmw.progress;
        final contentOpacity = (1.0 - (progress * 3.0)).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // Header / AppBar
              Opacity(
                opacity: contentOpacity,
                child: Padding(
                  padding:
                      EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white, size: 32),
                          onPressed: () => dmw.minimize(),
                        ),
                        const Spacer(),
                        if (onClose != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: onClose,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Video Section
              Expanded(
                child: Center(
                  child: AspectRatio(
                    key: videoFrameKey,
                    aspectRatio: chewieController?.aspectRatio ?? 16 / 9,
                    child: _VideoFrame(
                      chewieController: chewieController,
                      isMini: false,
                    ),
                  ),
                ),
              ),

              // Info Section
              Opacity(
                opacity: contentOpacity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(height: 2, width: 40, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'V tomto tutoriálu se dozvíte vše potřebné pro efektivní práci se systémem ShopIO.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VideoMiniContent extends StatelessWidget {
  const _VideoMiniContent({
    required this.videoFrameKey,
    required this.chewieController,
  });

  final GlobalKey videoFrameKey;
  final ChewieController? chewieController;

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: IgnorePointer ensures that mini video controls don't
    // swallow gestures (taps/drags) meant for the DragMiniWindow.
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _VideoFrame(
            key: videoFrameKey,
            chewieController: chewieController,
            isMini: true,
          ),

          // Mini decoration (overlay)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
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
