import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:linglun/ui/utils/show_letter_selecting_dialog.dart';

class LetterIndexRail extends StatefulWidget {
  const new({
    super.key,
    required this.existLetters,
    required this.itemScrollController,
    required this.keyIndexList,
    required this.descending,
  });

  final List<String> existLetters;
  final ItemScrollController itemScrollController;
  final List<int> keyIndexList;
  final bool descending;

  @override
  State<LetterIndexRail> createState() => _LetterIndexRailState();
}

class _LetterIndexRailState extends State<LetterIndexRail> {
  static const double letterHeight = 12;
  static const double letterSinglePadding = 2;
  static const double railOuterPadding = 6;

  static const double hinterSize = 48;

  bool isDragging = false;
  double dragPosition = 0;
  String letter = '';

  static final List<String> reversedLetters = allLetters.reversed.toList();
  List<String> get letters => widget.descending ? reversedLetters : allLetters;

  void onPointer(double y) {
    setState(() {
      dragPosition = y;
      letter =
          letters[((y - railOuterPadding) ~/
                  (letterHeight + letterSinglePadding * 2))
              .clamp(0, letters.length - 1)];
    });
    final int index = widget.existLetters.indexOf(letter);
    if (index == -1) return;
    widget.itemScrollController.jumpTo(index: widget.keyIndexList[index]);
  }

  double hinterOffset(double y) {
    final double min = -hinterSize / 2;
    final double max =
        (letterHeight + letterSinglePadding * 2) * letters.length +
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
                    color: Theme.of(context).colorScheme.onSecondaryContainer
                        .withAlpha(
                          widget.existLetters.contains(letter) ? 255 : 120,
                        ),
                    fontSize: hinterSize / 2,
                    fontWeight: const FontWeight(600),
                    height: 1,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ),
        GestureDetector(
          // 令内部 padding 响应事件
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            onPointer(details.localPosition.dy);
          },
          onVerticalDragUpdate: (details) {
            isDragging = true;
            onPointer(details.localPosition.dy);
          },
          onVerticalDragStart: (details) {
            isDragging = true;
            onPointer(details.localPosition.dy);
          },
          onVerticalDragEnd: (_) => setState(() => isDragging = false),
          onVerticalDragCancel: () => setState(() => isDragging = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: railOuterPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: letters
                      .map(
                        (letter) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: letterSinglePadding,
                          ),
                          child: Text(
                            letter,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface
                                  .withAlpha(
                                    widget.existLetters.contains(letter)
                                        ? 255
                                        : 120,
                                  ),
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
        ),
      ],
    );
  }
}
