import 'package:linglun/data/utils/string.dart';

import 'package:isar/isar.dart';

part 'music_info_model.g.dart';

@collection
class MusicInfo {
  Id id = Isar.autoIncrement;

  String title;
  late String titleInLatin;

  List<String> artists;
  late String artistsInLatin;

  String album;
  late String albumInLatin;

  String path;
  late String pathInLatin;

  int sizeBytes;
  int durationMs;
  int playCount;
  DateTime addTime;
  DateTime editTime;

  MusicInfo({
    this.id = Isar.autoIncrement,
    required this.title,
    required this.artists,
    required this.album,
    required this.path,
    required this.sizeBytes,
    required this.durationMs,
    required this.playCount,
    required this.addTime,
    required this.editTime,
  }) {
    titleInLatin = title.toLatin();
    artistsInLatin = artists.join().toLatin();
    albumInLatin = album.toLatin();
    pathInLatin = path.toLatin();
  }

  // 面向业务的 Duration Getter，Isar 会忽略
  @Ignore()
  Duration get duration => Duration(milliseconds: durationMs);

  // 面向业务的 Duration Setter
  set duration(Duration value) {
    durationMs = value.inMilliseconds;
  }
}
