import 'package:linglun/data/utils/group_key_of.dart';
import 'package:material_ui/material_ui.dart';
import 'package:linglun/data/models/track_info.dart';

/// 曲库的排序依据。shouldBeGrouped 为 true 的前三项会按首字母分组
/// （并显示分组头和字母索引栏），其余按数值/路径排序，不分组。
enum TrackSort {
  title('标题', Icons.title, true),
  artists('艺术家', Icons.person, true),
  album('专辑', Icons.album, true),

  // TODO: Android 上 uri 是 content://，按它排序并不等于按"路径"排序，
  // 和这个"文件路径"的标签也对不上。可考虑改用 sourceKey
  // （Android 是 "primary:Music/a/b.mp3" 这样的路径形式）。
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

  /// 返回该曲目在当前排序依据下的分组键（TextKey.group），歌手只取第一位。
  /// 不分组的排序依据返回 null。
  String? groupSource(TrackInfo m) => switch (this) {
    TrackSort.title => m.titleKey.group,
    TrackSort.artists => m.artistsKeys.first.group,
    TrackSort.album => m.albumKey.group,
    _ => null,
  };
}

/// 排序依据 + 是否降序。合成一个值在页面与控件之间传递（只用一个回调回写）。
class SortConfig {
  final TrackSort method;
  final bool descending;
  const new(this.method, this.descending);

  SortConfig copyWith({TrackSort? method, bool? descending}) =>
      SortConfig(method ?? this.method, descending ?? this.descending);
}

/// 返回排好序的新列表（不修改入参）。
// TODO: Dart 的 List.sort 不保证稳定。按艺术家/专辑/播放次数/时长等排序时
// 会有大量"相等"的项，它们的相对顺序不确定，重新排序后可能乱跳。
// 建议给每种排序加二级、三级键（例如 艺术家 → 专辑 → 标题 → sourceKey）。
List<TrackInfo> sortTrackList(List<TrackInfo> list, SortConfig sortConfig) {
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

  // TODO: 降序是把整个升序结果倒过来：'#' 组和"未知艺术家/专辑"（sort 为 \uffff）
  // 会跑到最前面，二级顺序也一并倒转。是否希望降序时仍把"未知"放最后，需要决定。
  return sortConfig.descending ? result.reversed.toList() : result;
}

/// 把已排好序的列表按分组键切成若干组。要求同组元素在 sortedList 里连续
/// （排序保证了这一点）。返回的 Map 保持插入顺序，也就是各组在列表里的先后。
Map<String, List<TrackInfo>> groupTrackList(
  List<TrackInfo> sortedList,
  SortConfig sortConfig,
) {
  if (!sortConfig.method.shouldBeGrouped) {
    // TODO: 一个 Map 同时表示"分组"和"不分组"两种形态，靠魔法键 'default'
    // 区分，TrackLib 还得用 keys.contains('default') 反推 hasGroups，耦合很脆弱。
    // 可以返回 sealed class / record（如 分组: List<TrackGroup>? 与 平铺: List<TrackInfo>），
    // 或者不分组时让调用方根本不调用本函数。
    // TODO: 'default' 作为键是否需要修改
    return {'default': sortedList};
  }
  var result = <String, List<TrackInfo>>{};
  for (final element in sortedList) {
    // 分组依据的 shouldBeGrouped 为 true 时 groupSource 必有值，'#' 只是兜底。
    final groupSource = sortConfig.method.groupSource(element) ?? '#';
    (result[groupSource] ??= []).add(element);
  }
  return result;
}
