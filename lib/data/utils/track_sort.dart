import 'package:linglun/data/track_scanner/utils/group_key_of.dart';
import 'package:material_ui/material_ui.dart';
import 'package:linglun/data/models/track_info.dart';

enum TrackSort {
  title('标题', Icons.title, true),
  artists('艺术家', Icons.person, true),
  album('专辑', Icons.album, true),

  uri('文件路径', Icons.folder_copy, false),

  sizeBytes('文件体积', Icons.storage, false),
  durationMs('时长', Icons.timer, false),
  playCount('播放次数', Icons.play_circle, false),
  addTime('扫描时间', Icons.add, false),
  editTime('编辑时间', Icons.edit, false);

  const new(this.label, this.icon, this.shouldBeGrouped);

  final String label;
  final IconData icon;
  final bool shouldBeGrouped;

  /// 返回某指定 MusicInfo 的特定字段
  String? groupSource(TrackInfo m) => switch (this) {
    TrackSort.title => m.titleKey.sort,
    TrackSort.artists => m.artistsKeys.first.sort,
    TrackSort.album => m.albumKey.sort,
    _ => null,
  };
}

class SortConfig {
  final TrackSort method;
  final bool descending;
  const new(this.method, this.descending);

  SortConfig copyWith({TrackSort? method, bool? descending}) =>
      SortConfig(method ?? this.method, descending ?? this.descending);
}

List<TrackInfo> sortMusicList(List<TrackInfo> list, SortConfig sortConfig) {
  final result = [...list];
  switch (sortConfig.method) {
    case TrackSort.title:
      result.sort((a, b) => compareKeys(a.titleKey, b.titleKey));
    case TrackSort.artists:
      result.sort(
        (a, b) => compareKeys(a.artistsKeys.first, b.artistsKeys.first),
      );
    case TrackSort.album:
      result.sort((a, b) => compareKeys(a.albumKey, b.albumKey));

    case TrackSort.uri:
      result.sort((a, b) => a.uri.compareTo(b.uri));

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
  var result = <String, List<TrackInfo>>{};
  for (final element in sortedList) {
    final sortSource = sortConfig.method.groupSource(element) ?? '';
    var key = sortSource.isEmpty
        ? '#'
        : sortSource.characters.first.toUpperCase();
    if (!RegExp(r'^[A-Z]$').hasMatch(key)) key = '#';
    (result[key] ??= []).add(element);
  }
  return result;
}
