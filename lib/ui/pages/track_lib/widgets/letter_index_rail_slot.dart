import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/data/utils/group_key_of.dart';

class LetterIndexRailSlot {
  final String display;
  final int index;
  new({required this.display, required this.index});
}

List<LetterIndexRailSlot> buildRailSlots(
  Map<String, List<TrackInfo>> groupedTrackList,
  List<int> keyIndexList,
) {
  if (groupedTrackList.isEmpty) return [];

  var scriptCounts = <Script, int>{};

  for (final entry in groupedTrackList.entries) {
    final group = entry.key;
    final script = scriptOf(group.runes.first);
    final count = entry.value.length;

    scriptCounts[script] = (scriptCounts[script] ?? 0) + count;
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
    Script.han: 'A',
    Script.hangul: '가',
    Script.kana: 'あ',
    Script.latin: 'A',
    Script.other: '#',
  };
  Script? lastFoldedScript;
  for (final (i, entry) in groupedTrackList.entries.indexed) {
    final group = entry.key; // 分组名
    final target = keyIndexList[i]; // 这个分组在一维列表里的位置
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
