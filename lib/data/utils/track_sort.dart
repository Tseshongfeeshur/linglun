import 'package:linglun/data/track_scanner/utils/collation_of.dart';
import 'package:material_ui/material_ui.dart';
import 'package:linglun/data/models/track_info.dart';

/// 曲库的排序依据。shouldBeGrouped 为 true 的前三项会按首字母分组
/// （并显示分组头和字母索引栏），其余按数值/路径排序，不分组。
enum TrackSort {
  title('标题', Icons.title, true),
  artists('艺术家', Icons.person, true),
  album('专辑', Icons.album, true),

  sourceKey('文件路径', Icons.folder_copy, false),

  sizeBytes('文件体积', Icons.storage, false),
  durationMs('时长', Icons.timer, false),
  playCount('播放次数', Icons.play_circle, false),
  addTime('扫描时间', Icons.add, false),
  editTime('编辑时间', Icons.edit, false);

  const new(this.label, this.icon, this.shouldBeGrouped);

  final String label;
  final IconData icon;
  final bool shouldBeGrouped;

  /// 返回该曲目在当前排序依据下的分组键（TextKey.group），歌手只取第一位。
  /// 不分组的排序依据返回 null。
  String? groupSource(TrackInfo m) => switch (this) {
    TrackSort.title => m.titleCollation.group,
    TrackSort.artists => m.artistCollation.group,
    TrackSort.album => m.albumCollation.group,
    _ => null,
  };
}

/// 排序依据 + 是否降序。合成一个值在页面与控件之间传递（只用一个回调回写）。
@immutable
class SortConfig {
  final TrackSort method;
  final bool descending;
  const new(this.method, this.descending);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SortConfig &&
        method == other.method &&
        descending == other.descending;
  }

  SortConfig copyWith({TrackSort? method, bool? descending}) =>
      SortConfig(method ?? this.method, descending ?? this.descending);

  @override
  int get hashCode => Object.hash(method, descending);
}

/// 返回排好序的新列表（不修改入参）。
// TODO: Dart 的 List.sort 不保证稳定。按艺术家/专辑/播放次数/时长等排序时
// 会有大量"相等"的项，它们的相对顺序不确定，重新排序后可能乱跳。
// 建议给每种排序加二级、三级键（例如 艺术家 → 专辑 → 标题 → sourceKey）。
List<TrackInfo> sortTrackList(List<TrackInfo> list, SortConfig sortConfig) {
  final result = [...list];
  switch (sortConfig.method) {
    case TrackSort.title:
      result.sort(
        (a, b) => compareCollations(a.titleCollation, b.titleCollation),
      );
    case TrackSort.artists:
      result.sort(
        (a, b) => compareCollations(a.artistCollation, b.artistCollation),
      );
    case TrackSort.album:
      result.sort(
        (a, b) => compareCollations(a.albumCollation, b.albumCollation),
      );

    case TrackSort.sourceKey:
      result.sort((a, b) => a.sourceKey.compareTo(b.sourceKey));

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

sealed class TrackListItemType {}

class TrackListGroupHead extends TrackListItemType {
  final String group;
  final int index;

  new({required this.group, required this.index});
}

class TrackListItem extends TrackListItemType {
  final TrackInfo track;

  new({required this.track});
}

/// 把已排好序的列表按分组键切成若干组。要求同组元素在 sortedList 里连续
/// （排序保证了这一点）。返回的 Map 保持插入顺序，也就是各组在列表里的先后。
List<TrackListItemType> groupTrackList(
  List<TrackInfo> sortedList,
  SortConfig sortConfig,
) {
  var result = <TrackListItemType>[
    for (final t in sortedList) TrackListItem(track: t),
  ];
  if (!sortConfig.method.shouldBeGrouped) {
    return result;
  }
  var lastGroup = '';
  for (var i = 0; i < result.length; i++) {
    final current = result[i];
    if (current is! TrackListItem) continue;

    final group = sortConfig.method.groupSource(current.track) ?? '#';
    if (lastGroup == group) continue;

    result.insert(i, TrackListGroupHead(group: group, index: i));
    i++;
    lastGroup = group;
  }
  return result;
}
