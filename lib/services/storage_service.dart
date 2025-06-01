import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload Video
  Future<String> uploadVideo(File videoFile, String userId) async {
    try {
      String fileName = 'videos/$userId/${DateTime.now().millisecondsSinceEpoch}${path.extension(videoFile.path)}';
      Reference storageRef = _storage.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(videoFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload video: ${e.toString()}';
    }
  }

  // Upload Thumbnail
  Future<String> uploadThumbnail(File thumbnailFile, String userId) async {
    try {
      String fileName = 'thumbnails/$userId/${DateTime.now().millisecondsSinceEpoch}${path.extension(thumbnailFile.path)}';
      Reference storageRef = _storage.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(thumbnailFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload thumbnail: ${e.toString()}';
    }
  }

  // Upload Profile Picture
  Future<String> uploadProfilePicture(File imageFile, String userId) async {
    try {
      String fileName = 'profile_pictures/$userId${path.extension(imageFile.path)}';
      Reference storageRef = _storage.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload profile picture: ${e.toString()}';
    }
  }

  // Delete File
  Future<void> deleteFile(String fileUrl) async {
    try {
      Reference storageRef = _storage.refFromURL(fileUrl);
      await storageRef.delete();
    } catch (e) {
      throw 'Failed to delete file: ${e.toString()}';
    }
  }

  // Generate Thumbnail (placeholder - you'll need a proper implementation)
  Future<File> generateThumbnail(String videoPath) async {
    // In a real app, you would use a package like video_thumbnail
    // This is just a placeholder
    return File(videoPath);
  }
}