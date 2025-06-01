import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../controllers/video_controller.dart';
import 'dart:io';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _songController = TextEditingController();
  VideoPlayerController? _videoController;
  String? _videoPath;

  @override
  void dispose() {
    _captionController.dispose();
    _songController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoPath = pickedFile.path;
        _videoController = VideoPlayerController.file(File(_videoPath!))
          ..initialize().then((_) {
            setState(() {});
            _videoController!.play();
          });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoController = Provider.of<VideoController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Video'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _videoPath == null
                ? null
                : () async {
              await videoController.uploadVideo(
                videoPath: _videoPath!,
                caption: _captionController.text,
                songName: _songController.text,
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
          GestureDetector(
          onTap: _pickVideo,
          child: Container(
            height: 300,
            color: Colors.grey[800],
            child: _videoController != null
                ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
            )
                    : Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(Icons.video_library, size: 50),
            SizedBox(height: 10),
            Text('Select a video to upload'),
            ],
          ),
        ),
      ),
    ),
    Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    children: [
    TextFormField(
    controller: _captionController,
    decoration: InputDecoration(
    labelText: 'Caption',
    border: OutlineInputBorder(),
    ),
    maxLines: 3,
    ),
    SizedBox(height: 20),
    TextField(
    controller: _songController,
    decoration: InputDecoration(
    labelText: 'Song Name',
    border: OutlineInputBorder(),
    ),
    ),
    ],
    ),
    ),
    if (videoController.isLoading)
    Padding(
    padding: const EdgeInsets.all(20.0),
    child: CircularProgressIndicator(),
    ),
    if (videoController.error != null)
    Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
    videoController.error!,
    style: TextStyle(color: Colors.red),
    ),
    ),
    ],
    ),
    ),
    );
  }
}