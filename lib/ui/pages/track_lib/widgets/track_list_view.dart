import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/cover_thumbnail/cover_result.dart';
import 'package:linglun/data/utils/track_sort.dart';
import 'package:linglun/states/cover_cache_provider.dart';
import 'package:linglun/ui/pages/track_lib/widgets/letter_index_rail.dart';
import 'package:linglun/data/cover_thumbnail/cover_thumbnail_cache.dart';
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
  final List<TrackListItemType> groupedTracks;
  final SortConfig sortConfig;

  const new({super.key, required this.groupedTracks, required this.sortConfig});

  @override
  State<TrackListView> createState() => _TrackListViewState();
}

class _TrackListViewState extends State<TrackListView> {
  final ItemScrollController itemScrollController = ItemScrollController();

  @override
  Widget build(BuildContext context) {
    final items = widget.groupedTracks;
    final hasGroups = widget.sortConfig.method.shouldBeGrouped;

    final keyIndexList = items
        .whereType<TrackListGroupHead>()
        .map((item) => item.index)
        .toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        ScrollConfiguration(
          // 分组模式下关闭系统滚动条（右侧由字母索引栏代替）。
          behavior: hasGroups
              ? ScrollConfiguration.of(context).copyWith(scrollbars: false)
              : ScrollConfiguration.of(context),
          // TODO: 待办"排序变化时列表项以动画移动位置"：需要给每项稳定的 key
          // （如 ValueKey(track.sourceKey)）；而 ScrollablePositionedList 本身没有
          // 重排动画能力，多半得换方案（如自己实现，或改用别的列表）——复杂度不小，
          // 建议先做小实验。
          child: ScrollablePositionedList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              switch (items[index]) {
                case TrackListItem trackListItem:
                  return _TrackListItem(trackInfo: trackListItem.track);
                case TrackListGroupHead trackListGroupHead:
                  return _TrackListGroupHead(
                    letter: trackListGroupHead.group,
                    onTap: () async {
                      var selectedLetter = await showLetterSelectingDialog(
                        context,
                        items,
                        trackListGroupHead.group,
                      );
                      if (selectedLetter == null) return;

                      itemScrollController.scrollTo(
                        index: (items.firstWhere((item) {
                          if (item is! TrackListGroupHead) return false;
                          return item.group == selectedLetter;
                        }) as TrackListGroupHead).index,
                        duration: 400.ms,
                        curve: Curves.easeInOutCubic,
                      );
                    },
                  );
              }
            },
            itemScrollController: itemScrollController,
          ),
        ),
        // 字母索引栏，叠在列表右侧。
        if (hasGroups)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: Align(
              alignment: Alignment.centerRight,
              child: LetterIndexRail(
                groupedTrackList: items,
                itemScrollController: itemScrollController,
                keyIndexList: keyIndexList,
              ),
            ),
          ),
      ],
    );
  }
}

/// 组头。点击后弹出分组选择框，选中后跳转到该组。
class _TrackListGroupHead extends StatelessWidget {
  final String letter;
  final Function() onTap;

  const new({required this.letter, required this.onTap});

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
      onTap: onTap,
    );
  }
}

/// 一首歌的列表项。已被标记 removed（磁盘上找不到）的半透明显示。
class _TrackListItem extends StatelessWidget {
  const new({required this.trackInfo});

  final TrackInfo trackInfo;
  final coverSize = 46.0;

  @override
  Widget build(BuildContext context) {
    var removed = trackInfo.removed;

    return ListTile(
      leading: Container(
        width: coverSize,
        height: coverSize,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: Opacity(
          opacity: removed ? 0.4 : 1,
          child: CoverImage(track: trackInfo),
        ),
      ),
      title: Text(
        trackInfo.title,
        maxLines: 1,
        style: TextStyle(
          overflow: TextOverflow.ellipsis,
          color: Theme.of(context).colorScheme.onSurface
              .withAlpha(removed ? 120 : 255),
          decoration: removed ? TextDecoration.lineThrough : null,
          decorationColor: Theme.of(context).colorScheme.onSurface
              .withAlpha(160),
        ),
      ),
      subtitle: trackInfo.artists == null
          ? const Text('未知艺术家')
          : RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSecondaryContainer
                      .withAlpha(removed ? 120 : 255),
                  decoration: removed ? TextDecoration.lineThrough : null,
                  decorationColor: Theme.of(context)
                      .colorScheme
                      .onSecondaryContainer
                      .withAlpha(160),
                ),
                children: [
                  for (var i = 0; i < trackInfo.artists!.length; i++)
                    TextSpan(
                      children: [
                        if (i != 0)
                          TextSpan(
                            text: ' / ',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface
                                  .withAlpha(removed ? 60 : 120),
                            ),
                          ),
                        TextSpan(text: trackInfo.artists![i]),
                      ],
                    ),
                  if (trackInfo.album != null)
                    TextSpan(
                      children: [
                        TextSpan(
                          text: ' - ',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface
                                .withAlpha(removed ? 60 : 120),
                          ),
                        ),
                        TextSpan(text: trackInfo.album),
                      ],
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      // TODO: 目前点击弹出的是调试用的信息面板；接入播放器后点击应改为播放，
      // 信息面板挪到长按/菜单里。
      onTap: () {
        showTrackInfoBottomSheet(context, trackInfo);
      },
    );
  }
}

class CoverImage extends ConsumerStatefulWidget {
  const new({super.key, required this.track});

  final TrackInfo track;

  @override
  ConsumerState<CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends ConsumerState<CoverImage> {
  late CoverThumbnailCache cache;
  CoverResult? coverResult;

  Future<void> _load() async {
    final track = widget.track;
    // 先尝试命中内存
    coverResult = cache.peekCoverThumbnail(track);
    if (coverResult == null) {
      // 内存中没有则找缓存和源文件
      try {
        final result = await cache.getCoverThumbnail(track);
        // 检查组件是否还在，要显示的歌曲是否没变
        if (mounted &&
            cache.coverThumbnailKeyOf(widget.track) ==
                cache.coverThumbnailKeyOf(track)) {
          setState(() => coverResult = result);
        }
      } catch (e) {
        if (mounted &&
            cache.coverThumbnailKeyOf(widget.track) ==
                cache.coverThumbnailKeyOf(track)) {
          setState(() => coverResult = CoverFailed());
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    cache = ref.read(coverCacheProvider);
    _load();
  }

  @override
  void didUpdateWidget(CoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 同一个 State 被复用来显示另一首歌时，才重新请求
    if (cache.coverThumbnailKeyOf(oldWidget.track) !=
        cache.coverThumbnailKeyOf(widget.track)) {
      _load();
    }
  }

  Widget buildIcon(BuildContext context, {bool loading = false}) => Padding(
    // 防止上层抗锯齿混色
    padding: const EdgeInsets.all(1),
    child: Container(
      decoration: BoxDecoration(
        color: loading
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Icon(
          Icons.music_note,
          color: loading
              ? Theme.of(context).colorScheme.onSurface.withAlpha(120)
              : Theme.of(context).colorScheme.surface,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    switch (coverResult) {
      case CoverFound found:
        return Image.file(
          found.file,
          frameBuilder: (context, child, frame, sync) {
            if (sync) return child;
            return Stack(
              fit: StackFit.expand,
              children: [
                buildIcon(context, loading: true),
                AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: 100.ms,
                  child: child,
                ),
              ],
            );
          },
          errorBuilder: (context, error, stackTrace) => buildIcon(context),
          fit: BoxFit.cover,
        );
      case CoverNone() || CoverFailed():
        return buildIcon(context);

      case null:
        return buildIcon(context, loading: true);
    }
  }
}
