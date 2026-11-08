import 'package:material_ui/material_ui.dart';
import 'package:linglun/data/models/music_info_model.dart';

enum MusicSort {
  titleInLatin('标题', Icons.title, true),
  artistsInLatin('艺术家', Icons.person, true),
  albumInLatin('专辑', Icons.album, true),

  path('文件路径', Icons.folder_copy, false),

  sizeBytes('文件体积', Icons.storage, false),
  durationMs('时长', Icons.timer, false),
  playCount('播放次数', Icons.play_circle, false),
  addTime('扫描时间', Icons.add, false),
  editTime('编辑时间', Icons.edit, false);

  const MusicSort(this.label, this.icon, this.shouldBeGrouped);

  final String label;
  final IconData icon;
  final bool shouldBeGrouped;

  /// 返回某指定 MusicInfo 的特定字段
  String? groupSource(MusicInfo m) => switch (this) {
    MusicSort.titleInLatin => m.titleInLatin,
    MusicSort.artistsInLatin => m.artistsInLatin,
    MusicSort.albumInLatin => m.albumInLatin,
    _ => null,
  };
}

class SortConfig {
  final MusicSort method;
  final bool descending;
  const SortConfig(this.method, this.descending);

  SortConfig copyWith({MusicSort? method, bool? descending}) =>
      SortConfig(method ?? this.method, descending ?? this.descending);
}

List<MusicInfo> sortMusicList(List<MusicInfo> list, SortConfig sortConfig) {
  final result = [...list];
  switch (sortConfig.method) {
    case MusicSort.titleInLatin:
      result.sort((a, b) => a.titleInLatin.compareTo(b.titleInLatin));
    case MusicSort.artistsInLatin:
      result.sort((a, b) => a.artistsInLatin.compareTo(b.artistsInLatin));
    case MusicSort.albumInLatin:
      result.sort((a, b) => a.albumInLatin.compareTo(b.albumInLatin));

    case MusicSort.path:
      result.sort((a, b) => a.path.compareTo(b.path));

    case MusicSort.sizeBytes:
      result.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
    case MusicSort.durationMs:
      result.sort((a, b) => a.durationMs.compareTo(b.durationMs));
    case MusicSort.playCount:
      result.sort((a, b) => a.playCount.compareTo(b.playCount));
    case MusicSort.addTime:
      result.sort((a, b) => a.addTime.compareTo(b.addTime));
    case MusicSort.editTime:
      result.sort((a, b) => a.editTime.compareTo(b.editTime));
  }

  return sortConfig.descending ? result.reversed.toList() : result;
}

Map<String, List<MusicInfo>> groupMusicList(
  List<MusicInfo> sortedList,
  SortConfig sortConfig,
) {
  if (!sortConfig.method.shouldBeGrouped) {
    return {'default': sortedList};
  }
  Map<String, List<MusicInfo>> result = {};
  for (final element in sortedList) {
    final sortSource = sortConfig.method.groupSource(element) ?? '';
    String key = sortSource.isEmpty
        ? '#'
        : sortSource.characters.first.toUpperCase();
    if (!RegExp(r'^[A-Z]$').hasMatch(key)) key = '#';
    (result[key] ??= []).add(element);
  }
  return result;
}
