import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/video_player_item.dart';
import '../models/video_model.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pageIdx = 0;
  final PageController _pageController = PageController();

  // Sample video URLs - replace with your actual video URLs
  final List<String> _videoUrls = [
    'https://example.com/video1.mp4',
    'https://example.com/video2.mp4',
    'https://example.com/video3.mp4',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videoUrls.length,
        onPageChanged: (index) {
          setState(() {
            _pageIdx = index;
          });
        },
        itemBuilder: (context, index) {
          return VideoPlayerItem(
            video: Video(
              id: 'video${index + 1}',
              videoUrl: _videoUrls[index],
              userId: 'user${index + 1}',
              caption: 'Sample video ${index + 1}',
              songName: 'Sample song',
              thumbnailUrl: 'https://your-thumbnail-url.com/image${index + 1}.jpg', // 🔧 Add this line
              likes: [],
              shares: [],
              comments: [],
            ),
          showControls: true,
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        pageIdx: _pageIdx,
        onTap: (index) {
          setState(() {
            _pageIdx = index;
            _pageController.jumpToPage(index);
          });
        },
      ),
    );
  }
}