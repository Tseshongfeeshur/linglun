import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:linglun/ui/utils/show_music_info_bottom_sheet.dart';
import 'package:linglun/ui/utils/show_letter_selecting_dialog.dart';

import 'package:linglun/data/models/track_info_model.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MusicListView extends StatefulWidget {
  final Map<String, List<TrackInfo>> groupedMusicList;
  final bool hasGroups;

  const MusicListView({
    super.key,
    required this.groupedMusicList,
    required this.hasGroups,
  });

  @override
  State<MusicListView> createState() => _MusicListViewState();
}

class _MusicListViewState extends State<MusicListView> {
  final ItemScrollController itemScrollController = ItemScrollController();

  @override
  Widget build(BuildContext context) {
    if (widget.hasGroups) {
      final List<String> keys = widget.groupedMusicList.keys.toList();
      List<List<TrackInfo>> valuesList = widget.groupedMusicList.values
          .toList();

      List<int> keyIndexList = [];
      List<Object> items = [];
      for (int i = 0; i < keys.length; i++) {
        items.add(keys[i]);
        items.addAll(valuesList[i]);
        keyIndexList.add(
          i == 0 ? 0 : keyIndexList.last + valuesList[i - 1].length + 1,
        );
      }

      return ScrollablePositionedList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          switch (items[index]) {
            case TrackInfo musicInfo:
              return MusicListItem(musicInfo: musicInfo);
            case String letter:
              return MusicListGroupHead(
                letter: letter,
                groupedMusicList: widget.groupedMusicList,
                itemScrollController: itemScrollController,
                keyIndexList: keyIndexList,
              );
          }
          return SizedBox.shrink();
        },
        itemScrollController: itemScrollController,
      );
    } else {
      return ListView.builder(
        itemCount: widget.groupedMusicList['default']!.length,
        itemBuilder: (context, index) => MusicListItem(
          musicInfo: widget.groupedMusicList['default']![index],
        ),
      );
    }
  }
}

class MusicListGroupHead extends StatelessWidget {
  final String letter;
  final Map<String, List<TrackInfo>> groupedMusicList;
  final ItemScrollController itemScrollController;
  final List<int> keyIndexList;

  const MusicListGroupHead({
    super.key,
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
        String? selectedLetter = await showLetterSelectingDialog(
          context,
          groupedMusicList,
          letter,
        );
        if (selectedLetter == null) return;

        final int index = groupedMusicList.keys.toList().indexOf(
          selectedLetter,
        );
        itemScrollController.scrollTo(
          index: keyIndexList[index],
          duration: 400.ms,
          curve: Curves.easeInOutCubic,
        );
      },
    );
  }
}

class MusicListItem extends StatelessWidget {
  const MusicListItem({super.key, required this.musicInfo});

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
        style: TextStyle(overflow: TextOverflow.ellipsis),
      ),
      subtitle: Text(
        musicInfo.titleInLatin,
        maxLines: 1,
        style: TextStyle(overflow: TextOverflow.ellipsis),
      ),
      onTap: () {
        showTrackInfoBottomSheet(context, musicInfo);
      },
    );
  }
}
