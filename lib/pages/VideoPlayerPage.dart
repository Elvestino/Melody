// ignore_for_file: library_private_types_in_public_api, file_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:test1/common/color_extension.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final List<File> videos;
  final int initialIndex;

  const VideoPlayerPage({
    super.key,
    required this.videos,
    this.initialIndex = 0,
  });

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  double _currentSliderValue = 0.0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initializePlayer();
  }

  void _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.file(widget.videos[_currentIndex]);
    await _videoPlayerController.initialize();
    _videoPlayerController.addListener(_videoPlayerListener);
    _videoPlayerController.play();
  }

  void _videoPlayerListener() {
    if (_videoPlayerController.value.isPlaying &&
        _videoPlayerController.value.position >= _videoPlayerController.value.duration) {
      // Video playback is complete, proceed to the next video
      _playNextVideo();
    }
    setState(() {
      _currentSliderValue = _videoPlayerController.value.position.inMilliseconds.toDouble();
    });
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_videoPlayerListener);
    _videoPlayerController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    setState(() {
      _currentSliderValue = value;
      _videoPlayerController.seekTo(Duration(milliseconds: value.toInt()));
    });
  }

  void _playPauseVideo() {
    setState(() {
      if (_videoPlayerController.value.isPlaying) {
        _videoPlayerController.pause();
      } else {
        _videoPlayerController.play();
      }
    });
  }

  void _playNextVideo() {
    if (_currentIndex < widget.videos.length - 1) {
      setState(() {
        _currentIndex++;
        _videoPlayerController = VideoPlayerController.file(widget.videos[_currentIndex]);
        _initializePlayer();
      });
    } else {
      // Optionally loop back to the beginning of the playlist
      // Uncomment the following line to loop the playlist:
      // _currentIndex = 0;
    }
  }

  void _playPreviousVideo() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _videoPlayerController = VideoPlayerController.file(widget.videos[_currentIndex]);
        _initializePlayer();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.bg,
        title: const Text('Lecture Vidéo', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: TColor.bg,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.videos[_currentIndex].path.split('/').last,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: _videoPlayerController.value.isInitialized
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoPlayerController.value.aspectRatio,
                        child: VideoPlayer(_videoPlayerController),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentSliderValue.toInt()),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              _formatDuration(_videoPlayerController.value.duration.inMilliseconds),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Slider(
                        value: _currentSliderValue,
                        thumbColor: TColor.focus,
                        min: 0,
                        max: _videoPlayerController.value.duration.inMilliseconds.toDouble(),
                        onChanged: _onSliderChanged,
                        activeColor: TColor.focus,
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _playPreviousVideo,
            backgroundColor: TColor.focus,
            child: const Icon(Icons.skip_previous, color: Colors.white),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            onPressed: _playPauseVideo,
            backgroundColor: TColor.focus,
            child: Icon(
              _videoPlayerController.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            onPressed: _playNextVideo,
            backgroundColor: TColor.focus,
            child: const Icon(Icons.skip_next, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    Duration duration = Duration(milliseconds: milliseconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}
