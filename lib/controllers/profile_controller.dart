import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/video_model.dart';

class ProfileController with ChangeNotifier {
  List<Video> _likedVideos = [];
  List<Video> get likedVideos => _likedVideos;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser? _currentUser;
  AppUser? _viewedUser;
  List<Video> _userVideos = [];
  bool _isFollowing = false;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  AppUser? get viewedUser => _viewedUser;
  List<Video> get userVideos => _userVideos;
  bool get isFollowing => _isFollowing;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        _currentUser = AppUser(
          uid: doc.id,
          email: doc['email'],
          username: doc['username'],
          profilePic: doc['profilePic'],
          bio: doc['bio'],
          displayName: doc['username'],
          photoURL: doc['profilePic'],
          followers: doc['followers'],
          following: doc['following'],
          thumbnailUrl: doc['thumbnailUrl'],
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProfile(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch user data
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        _viewedUser = AppUser(
          uid: userDoc.id,
          email: userDoc['email'],
          username: userDoc['username'],
          profilePic: userDoc['profilePic'],
          bio: userDoc['bio'],
          displayName: userDoc['username'],
          photoURL: userDoc['profilePic'],
          followers: userDoc['followers'],
          following: userDoc['following'],
          thumbnailUrl: userDoc['thumbnailUrl'],
        );
      }

      // Check if current user is following this user
      if (_auth.currentUser != null && userId != _auth.currentUser!.uid) {
        DocumentSnapshot followDoc = await _firestore
            .collection('followers')
            .doc(userId)
            .collection('userFollowers')
            .doc(_auth.currentUser!.uid)
            .get();

        _isFollowing = followDoc.exists;
      }

      // Fetch user videos
      QuerySnapshot videosSnapshot = await _firestore
          .collection('videos')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _userVideos = videosSnapshot.docs.map((doc) {
        return Video.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> followUser(String userId) async {
    try {
      if (_auth.currentUser == null) return;

      final currentUserId = _auth.currentUser!.uid;
      final batch = _firestore.batch();

      // Add to followers collection
      final followerRef = _firestore
          .collection('followers')
          .doc(userId)
          .collection('userFollowers')
          .doc(currentUserId);

      final followingRef = _firestore
          .collection('following')
          .doc(currentUserId)
          .collection('userFollowing')
          .doc(userId);

      if (_isFollowing) {
        batch.delete(followerRef);
        batch.delete(followingRef);
        batch.update(_firestore.collection('users').doc(userId), {
          'followers': FieldValue.increment(-1),
        });
        batch.update(_firestore.collection('users').doc(currentUserId), {
          'following': FieldValue.increment(-1),
        });
      } else {
        batch.set(followerRef, {
          'followedAt': Timestamp.now(),
        });
        batch.set(followingRef, {
          'followedAt': Timestamp.now(),
        });
        batch.update(_firestore.collection('users').doc(userId), {
          'followers': FieldValue.increment(1),
        });
        batch.update(_firestore.collection('users').doc(currentUserId), {
          'following': FieldValue.increment(1),
        });
      }

      await batch.commit();

      _isFollowing = !_isFollowing;
      notifyListeners();

      // Update user counts in local state
      if (_viewedUser != null) {
        _viewedUser = AppUser(
          uid: _viewedUser!.uid,
          email: _viewedUser!.email,
          username: _viewedUser!.username,
          profilePic: _viewedUser!.profilePic,
          bio: _viewedUser!.bio,
          displayName: _viewedUser!.displayName,
          photoURL: _viewedUser!.photoURL,
          followers: _isFollowing
              ? _viewedUser!.followers + 1
              : _viewedUser!.followers - 1,
          following: _viewedUser!.following,
          thumbnailUrl: _viewedUser!.thumbnailUrl,
          videos: _viewedUser!.videos,
        );
      }

      if (_currentUser != null && userId == _currentUser!.uid) {
        _currentUser = AppUser(
          uid: _currentUser!.uid,
          email: _currentUser!.email,
          username: _currentUser!.username,
          profilePic: _currentUser!.profilePic,
          bio: _currentUser!.bio,
          displayName: _currentUser!.displayName,
          photoURL: _currentUser!.photoURL,
          followers: _currentUser!.followers,
          following: _isFollowing
              ? _currentUser!.following + 1
              : _currentUser!.following - 1,
          thumbnailUrl: _currentUser!.thumbnailUrl,
          videos: _currentUser!.videos,
        );
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? username,
    String? profilePicUrl,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final Map<String, dynamic> updates = {};

      if (username != null && username != _currentUser?.displayName) {
        updates['username'] = username;
        await currentUser.updateDisplayName(username);
      }

      if (profilePicUrl != null && profilePicUrl != _currentUser?.photoURL) {
        updates['profilePic'] = profilePicUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update(updates);

        // Update local state
        _currentUser = AppUser(
          uid: _currentUser!.uid,
          email: _currentUser!.email,
          username: username ?? _currentUser!.username,
          profilePic: profilePicUrl ?? _currentUser!.profilePic,
          bio: _currentUser!.bio,
          displayName: username ?? _currentUser!.displayName,
          photoURL: profilePicUrl ?? _currentUser!.photoURL,
          followers: _currentUser!.followers,
          following: _currentUser!.following,
          thumbnailUrl: _currentUser!.thumbnailUrl,
          videos: _currentUser!.videos,
        );


        if (_viewedUser != null && _viewedUser!.uid == currentUser.uid) {
          _viewedUser = AppUser(
            uid: _viewedUser!.uid,
            email: _viewedUser!.email,
            username: username ?? _viewedUser!.username,
            profilePic: profilePicUrl ?? _viewedUser!.profilePic,
            bio: _viewedUser!.bio,
            displayName: username ?? _viewedUser!.displayName,
            photoURL: profilePicUrl ?? _viewedUser!.photoURL,
            followers: _viewedUser!.followers,
            following: _viewedUser!.following,
            thumbnailUrl: _viewedUser!.thumbnailUrl,
            videos: _viewedUser!.videos,
          );

        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}