import 'package:material_ui/material_ui.dart';
import 'package:linglun/data/models/track_info_model.dart';

enum TrackSort {
  titleInLatin('标题', Icons.title, true),
  artistsInLatin('艺术家', Icons.person, true),
  albumInLatin('专辑', Icons.album, true),

  path('文件路径', Icons.folder_copy, false),

  sizeBytes('文件体积', Icons.storage, false),
  durationMs('时长', Icons.timer, false),
  playCount('播放次数', Icons.play_circle, false),
  addTime('扫描时间', Icons.add, false),
  editTime('编辑时间', Icons.edit, false);

  const TrackSort(this.label, this.icon, this.shouldBeGrouped);

  final String label;
  final IconData icon;
  final bool shouldBeGrouped;

  /// 返回某指定 MusicInfo 的特定字段
  String? groupSource(TrackInfo m) => switch (this) {
    TrackSort.titleInLatin => m.titleInLatin,
    TrackSort.artistsInLatin => m.artistsInLatin,
    TrackSort.albumInLatin => m.albumInLatin,
    _ => null,
  };
}

class SortConfig {
  final TrackSort method;
  final bool descending;
  const SortConfig(this.method, this.descending);

  SortConfig copyWith({TrackSort? method, bool? descending}) =>
      SortConfig(method ?? this.method, descending ?? this.descending);
}

List<TrackInfo> sortMusicList(List<TrackInfo> list, SortConfig sortConfig) {
  final result = [...list];
  switch (sortConfig.method) {
    case TrackSort.titleInLatin:
      result.sort((a, b) => a.titleInLatin.compareTo(b.titleInLatin));
    case TrackSort.artistsInLatin:
      result.sort((a, b) => a.artistsInLatin.compareTo(b.artistsInLatin));
    case TrackSort.albumInLatin:
      result.sort((a, b) => a.albumInLatin.compareTo(b.albumInLatin));

    case TrackSort.path:
      result.sort((a, b) => a.path.compareTo(b.path));

    case TrackSort.sizeBytes:
      result.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
    case TrackSort.durationMs:
      result.sort((a, b) => a.durationMs.compareTo(b.durationMs));
    case TrackSort.playCount:
      result.sort((a, b) => a.playCount.compareTo(b.playCount));
    case TrackSort.addTime:
      result.sort((a, b) => a.addTime.compareTo(b.addTime));
    case TrackSort.editTime:
      result.sort((a, b) => a.editTime.compareTo(b.editTime));
  }

  return sortConfig.descending ? result.reversed.toList() : result;
}

Map<String, List<TrackInfo>> groupMusicList(
  List<TrackInfo> sortedList,
  SortConfig sortConfig,
) {
  if (!sortConfig.method.shouldBeGrouped) {
    // TODO: 'default' 作为键是否需要修改
    return {'default': sortedList};
  }
  Map<String, List<TrackInfo>> result = {};
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
