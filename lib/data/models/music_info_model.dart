import 'package:linglun/data/utils/string.dart';

import 'package:isar/isar.dart';

part 'music_info_model.g.dart';

@collection
class MusicInfo {
  Id id = Isar.autoIncrement;

  String title;
  String titleInLatin;

  List<String> artists;
  String artistsInLatin;

  String album;
  String albumInLatin;

  String path;
  String pathInLatin;

  int sizeBytes;
  int durationMs;
  int playCount;
  DateTime addTime;
  DateTime editTime;

  MusicInfo({
    this.id = Isar.autoIncrement,
    required this.title,
    required this.titleInLatin,
    required this.artists,
    required this.artistsInLatin,
    required this.album,
    required this.albumInLatin,
    required this.path,
    required this.pathInLatin,
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
