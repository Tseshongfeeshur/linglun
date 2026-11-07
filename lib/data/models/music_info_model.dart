import 'package:isar/isar.dart';

part 'music_info_model.g.dart';

@collection
class MusicInfo {
  Id id = Isar.autoIncrement;

  String title;
  @Index()
  String titleInLatin;

  List<String> artists;
  @Index()
  String artistsInLatin;

  String album;
  @Index()
  String albumInLatin;

  @Index()
  String path;

  @Index()
  int sizeBytes;
  @Index()
  int durationMs;
  @Index()
  int playCount;
  @Index()
  DateTime addTime;
  @Index()
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

  // 面向业务的 Duration Getter，Isar 会忽略
  @Ignore()
  Duration get duration => Duration(milliseconds: durationMs);

  // 面向业务的 Duration Setter
  set duration(Duration value) {
    durationMs = value.inMilliseconds;
  }
}
