import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/video_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Operations
  Future<void> createUserDocument(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'username': user.username,
      'profilePic': user.profilePic,
      'bio': user.bio,
      'followers': user.followers,
      'following': user.following,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUser?> getUser(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? AppUser.fromMap(doc.data() as Map<String, dynamic>) : null;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    await _firestore.collection('users').doc(uid).update(updates);
  }

  // Video Operations
  Future<String> createVideo(Video video) async {
    DocumentReference docRef = await _firestore.collection('videos').add({
      'userId': video.userId,
      'videoUrl': video.videoUrl,
      'thumbnailUrl': video.thumbnailUrl,
      'caption': video.caption,
      'songName': video.songName,
      'likes': video.likes,
      'comments': video.comments,
      'shares': video.shares,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Stream<List<Video>> getVideos() {
    return _firestore
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Video.fromMap(doc.data(), doc.id))
        .toList());
  }

  Stream<List<Video>> getUserVideos(String userId) {
    return _firestore
        .collection('videos')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Video.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> likeVideo(String videoId, String userId) async {
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
  }

  // Follow System
  Future<void> followUser(String followerId, String followingId) async {
    final batch = _firestore.batch();

    // Add to follower's following list
    final followingRef = _firestore
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(followingId);

    // Add to following user's followers list
    final followerRef = _firestore
        .collection('users')
        .doc(followingId)
        .collection('followers')
        .doc(followerId);

    batch.set(followingRef, {
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.set(followerRef, {
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update counts
    batch.update(_firestore.collection('users').doc(followerId), {
      'followingCount': FieldValue.increment(1),
    });

    batch.update(_firestore.collection('users').doc(followingId), {
      'followerCount': FieldValue.increment(1),
    });

    await batch.commit();
  }
}