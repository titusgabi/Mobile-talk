import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/video_player_item.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;

  const ProfileScreen({this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final profileController = Provider.of<ProfileController>(context);
    final isCurrentUser = userId == null || userId == authController.user?.uid;

    if (isCurrentUser && authController.user != null) {
      profileController.fetchCurrentUser();
    } else if (userId != null) {
      profileController.fetchUserProfile(userId!);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 300,
                floating: true,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        isCurrentUser
                            ? authController.user?.photoURL ?? ''
                            : profileController.viewedUser?.photoURL ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              //Colors.black.withOpacity(0.7),
                              Colors.black.withAlpha((0.5 * 255).toInt())

                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildProfileHeader(context),
              ),
              SliverPersistentHeader(
                delegate: _TabBarDelegate(),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildVideosGrid(profileController),
              _buildLikedVideos(profileController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final authController = Provider.of<AuthController>(context, listen: false);
    final profileController = Provider.of<ProfileController>(context);
    final isCurrentUser = userId == null || userId == authController.user?.uid;
    final user = isCurrentUser ? authController.user : profileController.viewedUser;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(user?.photoURL ?? ''),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('Posts', user?.videos?.length ?? 0),
                    _buildStatColumn('Followers', user?.followers ?? 0),
                    _buildStatColumn('Following', user?.following ?? 0),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            user?.displayName ?? 'Username',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            user?.email ?? 'user@example.com',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          if (isCurrentUser)
            _buildEditProfileButton()
          else
            _buildFollowButton(profileController),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          // Navigate to edit profile screen
        },
        child: Text('Edit Profile'),
      ),
    );
  }

  Widget _buildFollowButton(ProfileController profileController) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: profileController.isFollowing ? Colors.grey : Colors.blue,
        ),
        onPressed: () {
          if (userId != null) {
            profileController.followUser(userId!);
          }
        },
        child: Text(
          profileController.isFollowing ? 'Following' : 'Follow',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildVideosGrid(ProfileController profileController) {
    if (profileController.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (profileController.userVideos.isEmpty) {
      return Center(child: Text('No videos yet'));
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: profileController.userVideos.length,
      itemBuilder: (context, index) {
        final video = profileController.userVideos[index];
        return GestureDetector(
          onTap: () {
            // Navigate to video detail or play in full screen
          },
          child: VideoPlayerItem(
            video: video,
            showControls: false,
          ),
        );
      },
    );
  }

  Widget _buildLikedVideos(ProfileController profileController) {
    if (profileController.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (profileController.likedVideos.isEmpty) {
      return Center(child: Text('No liked videos'));
    }

    return ListView.builder(
      itemCount: profileController.likedVideos.length,
      itemBuilder: (context, index) {
        final video = profileController.likedVideos[index];
        return ListTile(
          leading: SizedBox(
            height: 60,
            width: 60,
            child: VideoPlayerItem(
            video : video,
            showControls: false,
            ),

          ),
          title: Text(video.caption ?? 'No caption'),
          subtitle: Text('@${(video.userId ?? "unknown_user").substring(0, 8) } '),
          trailing: Icon(Icons.favorite, color: Colors.red),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        indicatorColor: Theme.of(context).primaryColor,
        tabs: [
          Tab(icon: Icon(Icons.grid_on)),
          Tab(icon: Icon(Icons.favorite)),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}