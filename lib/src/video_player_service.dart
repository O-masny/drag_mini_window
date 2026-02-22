import 'package:flutter/material.dart';

/// Global service for managing video tutorial state.
/// This service acts as a state holder for the currently playing video.
class VideoPlayerService extends ChangeNotifier {
  /// The singleton instance of [VideoPlayerService].
  static final VideoPlayerService instance = VideoPlayerService._internal();

  /// Returns the singleton instance of [VideoPlayerService].
  factory VideoPlayerService() => instance;

  VideoPlayerService._internal();

  String? _currentVideoUrl;
  String? _currentVideoTitle;
  String? _currentVideoSubtitle;

  /// The URL of the currently playing video.
  String? get currentVideoUrl => _currentVideoUrl;

  /// The title of the currently playing video.
  String? get currentVideoTitle => _currentVideoTitle;

  /// The subtitle of the currently playing video.
  String? get currentVideoSubtitle => _currentVideoSubtitle;

  /// Whether a video is currently being played.
  bool get hasActiveVideo => _currentVideoUrl != null;

  /// Starts a video tutorial.
  void playVideo({
    required String url,
    required String title,
    String subtitle = 'Tutoriál',
  }) {
    _currentVideoUrl = url;
    _currentVideoTitle = title;
    _currentVideoSubtitle = subtitle;
    notifyListeners();
  }

  /// Stops the current video tutorial.
  void stopVideo() {
    _currentVideoUrl = null;
    _currentVideoTitle = null;
    _currentVideoSubtitle = null;
    notifyListeners();
  }
}
