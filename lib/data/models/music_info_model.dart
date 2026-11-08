class MusicInfo {
  // Id id = ;

  String title;
  String titleInLatin;

  List<String> artists;
  String artistsInLatin;

  String album;
  String albumInLatin;

  String path;

  int sizeBytes;
  int durationMs;
  int playCount;
  DateTime addTime;
  DateTime editTime;

  MusicInfo({
    required this.title,
    required this.titleInLatin,
    required this.artists,
    required this.artistsInLatin,
    required this.album,
    required this.albumInLatin,
    required this.path,
    required this.sizeBytes,
    required this.durationMs,
    required this.playCount,
    required this.addTime,
    required this.editTime,
  });
}
