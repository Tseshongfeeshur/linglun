import 'package:linglun/ui/pages/track_lib/widgets/letter_index_rail.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:linglun/ui/utils/show_music_info_bottom_sheet.dart';
import 'package:linglun/ui/utils/show_letter_selecting_dialog.dart';

import 'package:linglun/data/models/track_info.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TrackListView extends StatefulWidget {
  final Map<String, List<TrackInfo>> groupedMusicList;
  final bool hasGroups;
  final bool descending;

  const new({
    super.key,
    required this.groupedMusicList,
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
      final entries = widget.groupedMusicList.entries;

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
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: !widget.hasGroups),
            child: ScrollablePositionedList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                switch (items[index]) {
                  case TrackInfo musicInfo:
                    return _MusicListItem(musicInfo: musicInfo);
                  case String letter:
                    return _MusicListGroupHead(
                      letter: letter,
                      groupedMusicList: widget.groupedMusicList,
                      itemScrollController: itemScrollController,
                      keyIndexList: keyIndexList,
                    );
                }
                return const SizedBox.shrink();
              },
              itemScrollController: itemScrollController,
            ),
          ),
          if (widget.hasGroups)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: LetterIndexRail(
                  existLetters: widget.groupedMusicList.keys.toList(),
                  itemScrollController: itemScrollController,
                  keyIndexList: keyIndexList,
                  descending: widget.descending,
                ),
              ),
            ),
        ],
      );
    } else {
      return ListView.builder(
        itemCount: widget.groupedMusicList['default']!.length,
        itemBuilder: (context, index) => _MusicListItem(
          musicInfo: widget.groupedMusicList['default']![index],
        ),
      );
    }
  }
}

class _MusicListGroupHead extends StatelessWidget {
  final String letter;
  final Map<String, List<TrackInfo>> groupedMusicList;
  final ItemScrollController itemScrollController;
  final List<int> keyIndexList;

  const new({
    required this.letter,
    required this.groupedMusicList,
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
      onTap: () async {
        var selectedLetter = await showLetterSelectingDialog(
          context,
          groupedMusicList,
          letter,
        );
        if (selectedLetter == null) return;

        final index = groupedMusicList.keys.toList().indexOf(selectedLetter);
        itemScrollController.scrollTo(
          index: keyIndexList[index],
          duration: 400.ms,
          curve: Curves.easeInOutCubic,
        );
      },
    );
  }
}

class _MusicListItem extends StatelessWidget {
  const new({required this.musicInfo});

  final TrackInfo musicInfo;

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
        musicInfo.title,
        maxLines: 1,
        style: const TextStyle(overflow: TextOverflow.ellipsis),
      ),
      subtitle: Text(
        // TODO: 使用富文本，淡化斜杠
        musicInfo.artists?.join('/') ?? '未知艺术家',
        maxLines: 1,
        style: const TextStyle(overflow: TextOverflow.ellipsis),
      ),
      onTap: () {
        showTrackInfoBottomSheet(context, musicInfo);
      },
    );
  }
}
