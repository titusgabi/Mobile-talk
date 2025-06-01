import 'package:flip_talk3/models/video_model.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerItem extends StatefulWidget {

  final Video video;
  final bool showControls;
  const VideoPlayerItem({Key? Key, required this.video,required this.showControls}) : super(key: Key);

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.network(widget.video.videoUrl)
      ..initialize().then((_) {
        _videoController.setLooping(true);
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController.value.isPlaying) {
        _videoController.pause();
        _isPlaying = false;
      } else {
        _videoController.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
      GestureDetector(
      onTap: _togglePlayPause,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: _videoController.value.isInitialized
            ? AspectRatio(
            aspectRatio: _videoController.value.aspectRatio,
            child: VideoPlayer(_videoController),
        )
                : const Center(
            child: CircularProgressIndicator(),
      ),
    ),
    ),
    if (!_isPlaying)
    Center(
    child: Icon(
    Icons.play_arrow,
    size: 60,
    color: Colors.white.withOpacity(0.7),
    ),
    ),
    // Video info overlay
    Positioned(
    bottom: 80,
    left: 10,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text(
    '@username',
    style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 18,
    ),
    ),
    const SizedBox(height: 8),
    const Text(
    'This is an awesome TikTok video! #flutter #tiktok',
    style: TextStyle(
    color: Colors.white,
    fontSize: 15,
    ),
    ),
    const SizedBox(height: 8),
    Row(
    children: const [
    Icon(Icons.music_note, color: Colors.white, size: 15),
    SizedBox(width: 5),
    Text(
    'Original Sound',
    style: TextStyle(
    color: Colors.white,
    fontSize: 15,
    ),
    ),
    ],
    ),
    ],
    ),
    ),
    // Right side action buttons
    Positioned(
    bottom: 100,
    right: 10,
    child: Column(
    children: [
    _buildActionButton(Icons.favorite, '24.5K'),
    const SizedBox(height: 20),
    _buildActionButton(Icons.comment, '1.2K'),
    const SizedBox(height: 20),
    _buildActionButton(Icons.share, 'Share'),
    const SizedBox(height: 20),
    _buildProfileButton(),
    ],
    ),
    ),
    ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 35),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileButton() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage('https://example.com/profile.jpg'),
      ),
    );
  }
}