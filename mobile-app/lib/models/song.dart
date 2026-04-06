enum SongCategory {
  whiteNoise,
  lullaby,
  fairyTale,
}

class Song {
  final String id;
  final String title;
  final SongCategory category;
  final String thumbnailAsset;
  /// Path relative to `assets/` (e.g. `audio/foo.mp3`).
  final String audioAsset;
  final Duration duration;

  Song({
    required this.id,
    required this.title,
    required this.category,
    required this.thumbnailAsset,
    required this.audioAsset,
    required this.duration,
  });
}

