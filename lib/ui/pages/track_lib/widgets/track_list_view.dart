import 'package:linglun/ui/pages/track_lib/widgets/letter_index_rail.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:linglun/ui/utils/show_track_info_bottom_sheet.dart';
import 'package:linglun/ui/utils/show_letter_selecting_dialog.dart';

import 'package:linglun/data/models/track_info.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// 曲库列表。分组模式下把 {组名: 曲目们} 压平成一维列表
/// [组头(String), 曲目, 曲目, ..., 组头, 曲目, ...]，交给 ScrollablePositionedList
/// 渲染，右侧叠一个字母索引栏；不分组时用普通 ListView。
class TrackListView extends StatefulWidget {
  final Map<String, List<TrackInfo>> groupedTrackList;
  final bool hasGroups;
  // TODO: descending 在本文件里没有被使用，要么删掉，要么用上。
  final bool descending;

  const new({
    super.key,
    required this.groupedTrackList,
    required this.hasGroups,
    required this.descending,
  });

  @override
  State<TrackListView> createState() => _TrackListViewState();
}

class _TrackListViewState extends State<TrackListView> {
  final ItemScrollController itemScrollController = ItemScrollController();

  @override
  Widget build(BuildContext context) {
    if (widget.hasGroups) {
      // 把分组压平成一维列表，同时记下每个组头在一维列表里的下标
      // （keyIndexList[i] 对应 groupedTrackList 的第 i 个组，用于跳转）。
      // TODO: items 与 keyIndexList 是并行的两个结构，且每次 build 都重新压平；
      // 字母索引栏、组头又各自靠"遍历 groupedTrackList 的顺序与 keyIndexList 一致"
      // 来对应，一旦错位就跳错位置。可引入 TrackGroup{key, startIndex, tracks}
      // 之类的结构，一次算好、各处共用。
      final entries = widget.groupedTrackList.entries;

      final items = <Object>[];
      final keyIndexList = <int>[];

      var index = 0;

      for (final entry in entries) {
        keyIndexList.add(index);
        items.add(entry.key);

        index++;

        items.addAll(entry.value);
        index += entry.value.length;
      }

      return Stack(
        children: [
          ScrollConfiguration(
            // 分组模式下关闭系统滚动条（右侧由字母索引栏代替）。
            // TODO: 这个分支里 hasGroups 恒为 true，`!widget.hasGroups` 就是 false，
            // 下面的 `if (widget.hasGroups)` 也是多余的，可直接写 false / 去掉 if。
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: !widget.hasGroups),
            // TODO: 待办"排序变化时列表项以动画移动位置"：需要给每项稳定的 key
            // （如 ValueKey(track.sourceKey)）；而 ScrollablePositionedList 本身没有
            // 重排动画能力，多半得换方案（如自己实现，或改用别的列表）——复杂度不小，
            // 建议先做小实验。
            child: ScrollablePositionedList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                switch (items[index]) {
                  case TrackInfo trackInfo:
                    return _TrackListItem(trackInfo: trackInfo);
                  case String letter:
                    return _TrackListGroupHead(
                      letter: letter,
                      groupedTrackList: widget.groupedTrackList,
                      itemScrollController: itemScrollController,
                      keyIndexList: keyIndexList,
                    );
                }
                // items 是 List<Object>，switch 无法穷尽（Object 不是 sealed），需要兜底。
                return const SizedBox.shrink();
              },
              itemScrollController: itemScrollController,
            ),
          ),
          // 字母索引栏，叠在列表右侧。
          if (widget.hasGroups)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: LetterIndexRail(
                  groupedTrackList: widget.groupedTrackList,
                  itemScrollController: itemScrollController,
                  keyIndexList: keyIndexList,
                ),
              ),
            ),
        ],
      );
    } else {
      return ListView.builder(
        itemCount: widget.groupedTrackList['default']!.length,
        itemBuilder: (context, index) => _TrackListItem(
          trackInfo: widget.groupedTrackList['default']![index],
        ),
      );
    }
  }
}

/// 组头。点击后弹出分组选择框，选中后跳转到该组。
// TODO: 这里把整个 groupedTrackList、itemScrollController、keyIndexList 都传进来，
// 只为在 onTap 里做一次跳转。让上层传一个 onTap 回调，组头只管显示更干净。
class _TrackListGroupHead extends StatelessWidget {
  final String letter;
  final Map<String, List<TrackInfo>> groupedTrackList;
  final ItemScrollController itemScrollController;
  final List<int> keyIndexList;

  const new({
    required this.letter,
    required this.groupedTrackList,
    required this.itemScrollController,
    required this.keyIndexList,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 0,
      minVerticalPadding: 0,
      title: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          letter,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
          ),
        ),
      ),
      // 注意：keyIndexList 必须与 groupedTrackList.keys 同序（都由 TrackListView
      // 的 build 生成）。selectedLetter 来自弹窗，必在 keys 里，indexOf 不会是 -1。
      onTap: () async {
        var selectedLetter = await showLetterSelectingDialog(
          context,
          groupedTrackList,
          letter,
        );
        if (selectedLetter == null) return;

        final index = groupedTrackList.keys.toList().indexOf(selectedLetter);
        itemScrollController.scrollTo(
          index: keyIndexList[index],
          duration: 400.ms,
          curve: Curves.easeInOutCubic,
        );
      },
    );
  }
}

/// 一首歌的列表项。已被标记 removed（磁盘上找不到）的半透明显示。
class _TrackListItem extends StatelessWidget {
  const new({required this.trackInfo});

  final TrackInfo trackInfo;

  @override
  Widget build(BuildContext context) {
    var removed = trackInfo.removed;
    return Opacity(
      opacity: removed ? 0.6 : 1,
      child: ListTile(
        // TODO: 占位封面（圆形 + 音符），之后换成真实专辑封面。
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Center(
            child: Icon(
              Icons.music_note,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
        title: Text(
          trackInfo.title,
          maxLines: 1,
          style: const TextStyle(overflow: TextOverflow.ellipsis),
        ),
        subtitle: Text(
          // TODO: 使用富文本，淡化斜杠
          trackInfo.artists?.join('/') ?? '未知艺术家',
          maxLines: 1,
          style: const TextStyle(overflow: TextOverflow.ellipsis),
        ),
        // TODO: 目前点击弹出的是调试用的信息面板；接入播放器后点击应改为播放，
        // 信息面板挪到长按/菜单里。
        onTap: () {
          showTrackInfoBottomSheet(context, trackInfo);
        },
      ),
    );
  }
}
