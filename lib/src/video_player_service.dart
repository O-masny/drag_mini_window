import 'package:flutter/material.dart';

/// Global service for managing video tutorial state.
/// This service acts as a state holder for the currently playing video.
class VideoPlayerService extends ChangeNotifier {
  static final VideoPlayerService instance = VideoPlayerService._internal();
  factory VideoPlayerService() => instance;
  VideoPlayerService._internal();

  String? _currentVideoUrl;
  String? _currentVideoTitle;
  String? _currentVideoSubtitle;

  String? get currentVideoUrl => _currentVideoUrl;
  String? get currentVideoTitle => _currentVideoTitle;
  String? get currentVideoSubtitle => _currentVideoSubtitle;
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
