class Video {
  final String id;
  final String? userId;
  final String videoUrl;
  final String thumbnailUrl;
  final String? caption;
  final String songName;
  final List<dynamic> likes;
  final List comments;
  final List shares;

  Video({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.songName,
    required this.likes,
    required this.comments,
    required this.shares,
  });

  factory Video.fromMap(Map<String, dynamic> map, String id) {
    return Video(
      id: id,
      userId: map['userId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      caption: map['caption'] ?? '',
      songName: map['songName'] ?? '',
      likes: List.from(map['likes'] ?? []),
      comments: (map['comments'] ?? 0),
      shares: (map['shares'] ?? 0),
    );
  }
}
