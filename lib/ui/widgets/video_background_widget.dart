import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackgroundWidget extends StatefulWidget {
  final String videoPath;
  final double opacity;
  final Widget? overlay;

  const VideoBackgroundWidget({
    required this.videoPath,
    super.key,
    this.opacity = 0.5,
    this.overlay,
  });

  @override
  State<VideoBackgroundWidget> createState() => _VideoBackgroundWidgetState();
}

class _VideoBackgroundWidgetState extends State<VideoBackgroundWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final file = File(widget.videoPath);
    if (!await file.exists()) {
      debugPrint('[VideoBackground] File not found: ${widget.videoPath}');
      setState(() => _error = true);
      return;
    }

    _controller = VideoPlayerController.file(file);

    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      await _controller.play();
      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      debugPrint('[VideoBackground] Error initializing video: $e');
      if (mounted) {
        setState(() => _error = true);
      }
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        color: const Color(0xFFE3001B), // Fallback Mario Red
        child: widget.overlay,
      );
    }

    if (!_initialized) {
      return Container(
        color: const Color(0xFF161B22), // Loading placeholder
        child: widget.overlay,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Layer
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),

        // Overlay Tint Layer
        Container(
          color: Colors.black.withValues(alpha: 1.0 - widget.opacity),
        ),

        // Content
        if (widget.overlay != null) widget.overlay!,
      ],
    );
  }
}
