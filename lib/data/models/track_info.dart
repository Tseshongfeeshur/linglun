class TrackInfo {
  // Id id = ;

  final String title;
  final String titleInLatin;

  final List<String>? artists;
  final String artistsInLatin;

  final String? album;
  final String albumInLatin;

  final String path;
  final String fileName;

  final int sizeBytes;
  final int durationMs;
  final DateTime editTime;
  final bool trackGainUpdated;

  final int playCount;
  final DateTime addTime;
  final bool removed;

  new({
    required this.title,
    required this.titleInLatin,
    this.artists,
    required this.artistsInLatin,
    this.album,
    required this.albumInLatin,
    required this.path,
    required this.fileName,
    required this.sizeBytes,
    required this.durationMs,
    required this.editTime,
    required this.trackGainUpdated,
    required this.playCount,
    required this.addTime,
    required this.removed,
  });

  TrackInfo copyWith({
    String? title,
    String? titleInLatin,
    List<String>? artists,
    String? artistsInLatin,
    String? album,
    String? albumInLatin,
    String? path,
    String? fileName,
    int? sizeBytes,
    int? durationMs,
    DateTime? editTime,
    bool? trackGainUpdated,
    int? playCount,
    DateTime? addTime,
    bool? removed,
  }) {
    return TrackInfo(
      title: title ?? this.title,
      titleInLatin: titleInLatin ?? this.titleInLatin,
      artists: artists ?? this.artists,
      artistsInLatin: artistsInLatin ?? this.artistsInLatin,
      album: album ?? this.album,
      albumInLatin: albumInLatin ?? this.albumInLatin,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      durationMs: durationMs ?? this.durationMs,
      editTime: editTime ?? this.editTime,
      trackGainUpdated: trackGainUpdated ?? this.trackGainUpdated,
      playCount: playCount ?? this.playCount,
      addTime: addTime ?? this.addTime,
      removed: removed ?? this.removed,
    );
  }
}
