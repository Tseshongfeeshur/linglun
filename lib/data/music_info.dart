import 'package:isar/isar.dart';

part 'music_info.g.dart';

@collection
class MusicInfo {
  final Id id = Isar.autoIncrement;
  final String title;
  final List<String> artists;
  final String album;
  final String path;
  final int size;
  final int duration;
  final int frequency;
  final int addTime;

  const MusicInfo({
    required this.title,
    required this.artists,
    required this.album,
    required this.path,
    required this.size,
    required this.duration,
    required this.frequency,
    required this.addTime,
  });
}
