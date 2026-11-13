class TrackInfo {
  // Id id = ;

  final String title;
  final String titleInLatin;

  final List<String>? artists;
  final String artistsInLatin;

  final String? album;
  final String albumInLatin;

  final String path;

  final int sizeBytes;
  final int durationMs;
  final DateTime editTime;
  final bool trackGainUpdated;

  final int playCount;
  final DateTime addTime;

  new({
    required this.title,
    required this.titleInLatin,
    this.artists,
    required this.artistsInLatin,
    this.album,
    required this.albumInLatin,
    required this.path,
    required this.sizeBytes,
    required this.durationMs,
    required this.editTime,
    required this.trackGainUpdated,
    required this.playCount,
    required this.addTime,
  });
}
