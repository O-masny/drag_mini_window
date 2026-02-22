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
  final GlobalKey _videoFullKey = GlobalKey();
  final GlobalKey _videoMiniKey = GlobalKey();
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
        videoFrameKey: _videoFullKey,
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
        title: widget.title,
        videoController: _videoController,
        chewieController: _chewieController,
        videoFrameKey: _videoMiniKey,
      ),
    );
  }
}

class _VideoFrame extends StatelessWidget {
  const _VideoFrame({
    super.key,
    required this.chewieController,
    required this.videoController,
    required this.isMini,
  });

  final ChewieController? chewieController;
  final VideoPlayerController? videoController;
  final bool isMini;

  @override
  Widget build(BuildContext context) {
    if (isMini) {
      if (videoController == null || !videoController!.value.isInitialized) {
        return Container(color: Colors.black);
      }
      return VideoPlayer(videoController!);
    } else {
      if (chewieController == null) {
        return const Center(
            child: CircularProgressIndicator(color: Colors.white24));
      }
      return Chewie(controller: chewieController!);
    }
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
        final progress = dmw.dragProgress;
        return Container(
          color: const Color(0xFF0F0F0F),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Video Frame
                  AspectRatio(
                    aspectRatio: chewieController
                            ?.videoPlayerController.value.aspectRatio ??
                        16 / 9,
                    child: _VideoFrame(
                      key: videoFrameKey,
                      chewieController: chewieController,
                      videoController: videoController,
                      isMini: false,
                    ),
                  ),

                  // Metadata & Controls
                  AnimatedOpacity(
                    opacity: (1.0 - progress * 4).clamp(0.0, 1.0),
                    duration: const Duration(milliseconds: 50),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VideoMiniContent extends StatelessWidget {
  const _VideoMiniContent({
    required this.title,
    required this.videoController,
    required this.chewieController,
    required this.videoFrameKey,
  });

  final String title;
  final VideoPlayerController? videoController;
  final ChewieController? chewieController;
  final GlobalKey videoFrameKey;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _VideoFrame(
          key: videoFrameKey,
          chewieController: chewieController,
          videoController: videoController,
          isMini: true,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
        Positioned(
          left: 6,
          right: 6,
          bottom: 6,
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
