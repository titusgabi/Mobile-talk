import 'package:firebase_auth/firebase_auth.dart';
import 'video_model.dart'; // or use the correct relative path


class AppUser {
  final List<Video> videos;
  final String uid;
  final String email;
  final String username;
  final String profilePic;
  final String bio;
  final String? displayName;
  final String? photoURL;
  final int followers;
  final int following;
  final String thumbnailUrl;

  AppUser({
    this.videos = const [],
    required this.uid,
    required this.email,
    required this.username,
    required this.profilePic,
    required this.bio,
    this.displayName,
    this.photoURL,
    this.followers = 0,
    this.following = 0,
    required this.thumbnailUrl,
  });


  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      profilePic: map['profilePic'] ?? '',
      bio: map['bio'] ?? '',
      followers: map['followers'] ?? 0,
      following: map['following'] ?? 0,
      thumbnailUrl: map['thumbnailUrl'] ?? 0,
    );
  }
}





