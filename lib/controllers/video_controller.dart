import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video_model.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';



class VideoController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  List<Video> _videos = [];
  List<Video> _userVideos = [];
  List<Video> _likedVideos = [];
  bool _isLoading = false;
  String? _error;

  List<Video> get videos => _videos;
  List<Video> get userVideos => _userVideos;
  List<Video> get likedVideos => _likedVideos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchVideos() async {
    try {
      _isLoading = true;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('videos')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      _videos = snapshot.docs.map((doc) {
        return Video.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserVideos(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('videos')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _userVideos = snapshot.docs.map((doc) {
        return Video.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLikedVideos() async {
    try {
      _isLoading = true;
      notifyListeners();

      // First get the list of video IDs the user has liked
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      List<String> likedVideoIds = List<String>.from(userDoc['likedVideos'] ?? []);

      if (likedVideoIds.isEmpty) {
        _likedVideos = [];
        return;
      }

      // Fetch all liked videos in a single query
      QuerySnapshot snapshot = await _firestore
          .collection('videos')
          .where('id', whereIn: likedVideoIds)
          .get();

      _likedVideos = snapshot.docs.map((doc) {
        return Video.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadVideo({
    required String videoPath,
    required String caption,
    required String songName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Upload video to storage
      String videoId = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('videos/$videoId.mp4');
      await ref.putFile(File(videoPath));
      String videoUrl = await ref.getDownloadURL();
      String thumbnailUrl = await _generateThumbnail(videoPath);
      // Save video info to Firestore
      await _firestore.collection('videos').doc(videoId).set({
        'id': videoId,
        'userId': _auth.currentUser!.uid,
        'videoUrl': videoUrl,
        'caption': caption,
        'songName': songName,
        'likes': [],
        'comments': 0,
        'shares': 0,
        'createdAt': Timestamp.now(),
        'thumbnailUrl': thumbnailUrl,
      });

      // Add to local list
      _videos.insert(0, Video(
        id: videoId,
        userId: _auth.currentUser!.uid,
        videoUrl: videoUrl,
        caption: caption,
        songName: songName,
        likes: [],
        comments: [],
        shares: [],
        thumbnailUrl: thumbnailUrl,
      ));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> likeVideo(String videoId) async {
    try {
      String userId = _auth.currentUser!.uid;

      // Update video likes
      await _firestore.runTransaction((transaction) async {
        DocumentReference videoRef = _firestore.collection('videos').doc(videoId);
        DocumentSnapshot snapshot = await transaction.get(videoRef);

        if (!snapshot.exists) return;

        List<dynamic> likes = snapshot['likes'] ?? [];
        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }

        transaction.update(videoRef, {'likes': likes});
      });

      // Update user's liked videos
      await _firestore.runTransaction((transaction) async {
        DocumentReference userRef = _firestore.collection('users').doc(userId);
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) return;

        List<dynamic> likedVideos = snapshot['likedVideos'] ?? [];
        if (likedVideos.contains(videoId)) {
          likedVideos.remove(videoId);
        } else {
          likedVideos.add(videoId);
        }

        transaction.update(userRef, {'likedVideos': likedVideos});
      });

      // Update local state
      _updateLocalLikes(videoId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _updateLocalLikes(String videoId, String userId) {
    // Update main videos list
    int videoIndex = _videos.indexWhere((v) => v.id == videoId);
    if (videoIndex != -1) {
      List<String> likes = List.from(_videos[videoIndex].likes);
      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }
      _videos[videoIndex] = Video(
        id: _videos[videoIndex].id,
        userId: _videos[videoIndex].userId,
        videoUrl: _videos[videoIndex].videoUrl,
        thumbnailUrl: _videos[videoIndex].thumbnailUrl,
        caption: _videos[videoIndex].caption,
        songName: _videos[videoIndex].songName,
        likes: likes,
        comments: _videos[videoIndex].comments,
        shares: _videos[videoIndex].shares,
      );

    }

    // Update user videos list
    int userVideoIndex = _userVideos.indexWhere((v) => v.id == videoId);
    if (userVideoIndex != -1) {
      List<String> likes = List.from(_userVideos[userVideoIndex].likes);
      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }
      _userVideos[userVideoIndex] = Video(
        id: _videos[videoIndex].id,
        userId: _videos[videoIndex].userId,
        videoUrl: _videos[videoIndex].videoUrl,
        thumbnailUrl: _videos[videoIndex].thumbnailUrl,
        caption: _videos[videoIndex].caption,
        songName: _videos[videoIndex].songName,
        likes: likes,
        comments: _videos[videoIndex].comments,
        shares: _videos[videoIndex].shares,
      );

    }

    notifyListeners();
  }

  Future<void> addComment(String videoId, String comment) async {
    try {
      await _firestore.collection('videos').doc(videoId).update({
        'comments': FieldValue.increment(1),
      });

      await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .add({
        'userId': _auth.currentUser!.uid,
        'comment': comment,
        'createdAt': Timestamp.now(),
      });

      // Update local state
      int index = _videos.indexWhere((v) => v.id == videoId);
      if (index != -1) {
        _videos[index] = Video(
          id: _videos[index].id,
          userId: _videos[index].userId,
          videoUrl: _videos[index].videoUrl,
          thumbnailUrl: _videos[index].thumbnailUrl,
          caption: _videos[index].caption,
          songName: _videos[index].songName,
          likes: _videos[index].likes,
          comments: _videos[index].comments,
          shares: _videos[index].shares,
        );

      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }

  }

  Future<String> _generateThumbnail(String videoPath) async {
    final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 128, // or any desired size
      quality: 25,
    );

    if (thumbnailPath == null) {
      throw Exception("Thumbnail generation failed");
    }

    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference ref = _storage.ref().child('thumbnails/$fileName');
    await ref.putFile(File(thumbnailPath));
    return await ref.getDownloadURL();
  }
}