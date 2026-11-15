import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:linglun/ui/utils/show_music_info_bottom_sheet.dart';
import 'package:linglun/ui/utils/show_letter_selecting_dialog.dart';

import 'package:linglun/data/models/track_info.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TrackListView extends StatefulWidget {
  final Map<String, List<TrackInfo>> groupedMusicList;
  final bool hasGroups;

  const new({
    super.key,
    required this.groupedMusicList,
    required this.hasGroups,
  });

  @override
  State<TrackListView> createState() => _TrackListViewState();
}

class _TrackListViewState extends State<TrackListView> {
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

      return Stack(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: false),
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
          Positioned(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _LetterIndexRail(
                  existLetters: widget.groupedMusicList.keys.toList(),
                  itemScrollController: itemScrollController,
                  keyIndexList: keyIndexList,
                ),
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

class _LetterIndexRail extends StatefulWidget {
  const new({
    required this.existLetters,
    required this.itemScrollController,
    required this.keyIndexList,
  });

  final List<String> existLetters;
  final ItemScrollController itemScrollController;
  final List<int> keyIndexList;

  @override
  State<_LetterIndexRail> createState() => _LetterIndexRailState();
}

class _LetterIndexRailState extends State<_LetterIndexRail> {
  static const double letterHeight = 12;
  static const double letterSinglePadding = 2;
  static const double railOuterPadding = 6;

  static const double hinterSize = 36;

  bool isDragging = false;
  double dragPosition = 0;
  String letter = '#';

  void onDraging(double y) {
    setState(() {
      dragPosition = y;
      isDragging = true;
    });
    letter =
        allLetters[((y - railOuterPadding) ~/
                (letterHeight + letterSinglePadding * 2))
            .clamp(0, allLetters.length - 1)];
    final int index = widget.existLetters.indexOf(letter);
    if (index == -1) return;
    widget.itemScrollController.jumpTo(index: widget.keyIndexList[index]);
  }

  double hinterOffset(double y) {
    final double min = -hinterSize / 2;
    final double max =
        (letterHeight + letterSinglePadding * 2) * allLetters.length +
        railOuterPadding * 2 -
        hinterSize / 2;

    final double offset = y - hinterSize / 2;

    if (offset < min) {
      final double d = min - offset;
      return min - 8 * (1 - math.exp(-d / 20));
    } else if (offset > max) {
      final double d = offset - max;
      return max + 8 * (1 - math.exp(-d / 20));
    }

    return offset;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (isDragging)
          Transform.translate(
            offset: Offset(0, hinterOffset(dragPosition)),
            child: Container(
              width: hinterSize,
              height: hinterSize,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: const FontWeight(600),
                    height: 1,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            border: Border.all(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: GestureDetector(
            onVerticalDragUpdate: (details) =>
                onDraging(details.localPosition.dy),
            onVerticalDragStart: (details) =>
                onDraging(details.localPosition.dy),
            onVerticalDragEnd: (_) => setState(() => isDragging = false),
            onVerticalDragCancel: () => setState(() => isDragging = false),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: railOuterPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: allLetters
                    .map(
                      (letter) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: letterSinglePadding,
                        ),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: letterHeight,
                            height: 1,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
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
