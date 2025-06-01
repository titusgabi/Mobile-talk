import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../auth/auth_service.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _authService.user.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _user = null;
      } else {
        await _fetchUserData(firebaseUser.uid);
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _user = AppUser(
          uid: uid,
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
      } else {
        // Create new user document if doesn't exist
        await _createUserDocument(uid);
      }
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> _createUserDocument(String uid) async {
    final firebaseUser = FirebaseAuth.instance.currentUser!;
    await _firestore.collection('users').doc(uid).set({
      'email': firebaseUser.email,
      'username': firebaseUser.displayName ?? 'User${uid.substring(0, 5)}',
      'profilePic': firebaseUser.photoURL ?? '',
      'followers': 0,
      'following': 0,
      'createdAt': Timestamp.now(),
    });
    await _fetchUserData(uid);
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signInWithEmail(email, password);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String username) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _authService.registerWithEmail(email, password);
      if (user != null) {
        // Update display name
        await user.updateDisplayName(username);
        await _createUserDocument(user.uid);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? username,
    String? profilePicUrl,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (username != null) {
        await FirebaseAuth.instance.currentUser!.updateDisplayName(username);
        await _firestore.collection('users').doc(_user!.uid).update({
          'username': username,
        });
      }

      if (profilePicUrl != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'profilePic': profilePicUrl,
        });
      }

      await _fetchUserData(_user!.uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}