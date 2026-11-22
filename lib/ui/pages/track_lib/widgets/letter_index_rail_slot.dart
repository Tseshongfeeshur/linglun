import 'package:linglun/data/utils/group_key_of.dart';
import 'package:linglun/data/utils/track_sort.dart';

/// 索引栏上的一个条目：display 是栏上显示的字符，
/// index 是点击后要跳转到的一维列表下标。
class LetterIndexRailSlot {
  final String display;
  final int index;
  new({required this.display, required this.index});
}

/// 生成索引栏条目。策略：曲目最多的那种文字系统（如拉丁 A-Z）逐组展开，
/// 其余文字系统各折叠成一个代表字符（假名→'あ'，韩文→'가'，西里尔→'Я'，其他→'#'），
/// 点击代表字符跳到该文字系统的第一个组——避免稀有文字把索引栏撑得太长。
List<LetterIndexRailSlot> buildRailSlots(
  List<TrackListItemType> groupedTrackList,
  List<int> keyIndexList,
) {
  if (groupedTrackList.isEmpty) return [];

  // 统计各文字系统的曲目数（按曲目数，不是按分组数）。
  // 依赖 groupedTrackList 的遍历顺序与 keyIndexList 一一对应。
  var scriptCounts = <Script, int>{};

  Script script;
  for (var i = 0; i < groupedTrackList.length; i++) {
    final item = groupedTrackList[i];
    if (item is TrackListGroupHead) {
      final group = item.group;
      script = scriptOf(group.runes.first);

      var count = 1;
      for (
        ;
        i + count < groupedTrackList.length &&
            groupedTrackList[i + count] is TrackListItem;
        count++
      ) {}

      scriptCounts[script] = (scriptCounts[script] ?? 0) + count;
    }
  }

  var expandedScript = Script.latin;
  var maxCount = 0;
  for (final e in scriptCounts.entries) {
    if (e.value > maxCount) {
      maxCount = e.value;
      expandedScript = e.key;
    }
  }

  var result = <LetterIndexRailSlot>[];
  final sampleOfScript = {
    Script.cyrillic: 'Я',
    // han 不会作为分组出现（汉字归入拼音首字母 A-Z），这一项只是让 Map 完整。
    Script.han: 'A',
    Script.hangul: '가',
    Script.kana: 'あ',
    Script.latin: 'A',
    Script.other: '#',
  };
  // 同一文字系统的多个组在列表里是连续的（groupRank 保证，降序时也连续），
  // 所以折叠时只需与上一个被折叠的文字系统比较。
  Script? lastFoldedScript;
  for (var i = 0; i < groupedTrackList.length; i++) {
    final item = groupedTrackList[i];
    if (item is! TrackListGroupHead) continue;

    final group = item.group; // 分组名
    final target = item.index; // 这个分组在一维列表里的位置
    final script = scriptOf(group.runes.first);

    if (script == expandedScript) {
      result.add(LetterIndexRailSlot(display: group, index: target));
    } else {
      if (lastFoldedScript != null && script == lastFoldedScript) {
        continue;
      }
      lastFoldedScript = script;
      result.add(
        LetterIndexRailSlot(
          display: sampleOfScript[script] ?? '#',
          index: target,
        ),
      );
    }
  }

  return result;
}
