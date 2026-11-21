import 'dart:math' as math;
// import 'dart:nativewrappers/_internal/vm/lib/math_patch.dart';

import 'package:flutter/services.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/ui/pages/track_lib/widgets/letter_index_rail_slot.dart';
import 'package:material_ui/material_ui.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class LetterIndexRail extends StatefulWidget {
  const new({
    super.key,
    required this.groupedTrackList,
    required this.itemScrollController,
    required this.keyIndexList,
  });

  final Map<String, List<TrackInfo>> groupedTrackList;
  final ItemScrollController itemScrollController;
  final List<int> keyIndexList;

  @override
  State<LetterIndexRail> createState() => _LetterIndexRailState();
}

class _LetterIndexRailState extends State<LetterIndexRail> {
  static const double railPadding = 6;
  static const double railOuterPadding = 4;
  static const double slotMaxHeight = 20;
  static const double hinterSize = 52;

  bool isDragging = false;
  double dragPosition = 0;
  List<LetterIndexRailSlot> slotContents = [];
  String letter = '';

  @override
  void initState() {
    super.initState();
    slotContents = buildRailSlots(widget.groupedTrackList, widget.keyIndexList);
  }

  @override
  void didUpdateWidget(covariant LetterIndexRail oldWidget) {
    slotContents = buildRailSlots(widget.groupedTrackList, widget.keyIndexList);

    super.didUpdateWidget(oldWidget);
  }

  // 第 i 个格子对应的字母下标
  int letterIndexOf(int slot, int slotCount) =>
      (slot * slotContents.length / slotCount).floor();

  void onPointer(double y, double slotHeight, int slotCount) {
    final slot = ((y - railPadding) ~/ slotHeight).clamp(0, slotCount - 1);
    final idx = letterIndexOf(slot, slotCount);
    final newLetter = slotContents[idx].display;
    final letterChanged = letter != newLetter;

    setState(() {
      dragPosition = y;
      letter = newLetter;
    });

    if (letterChanged) {
      HapticFeedback.selectionClick();
      widget.itemScrollController.jumpTo(index: slotContents[idx].index);
    }
  }

  double hinterOffset(double y, double slotHeight, int slotCount) {
    final minOffset = -hinterSize / 2;
    final maxOffset = slotHeight * slotCount + railPadding * 2 - hinterSize / 2;

    final offset = y - hinterSize / 2;

    if (offset < minOffset) {
      final d = minOffset - offset;
      return minOffset - 8 * (1 - math.exp(-d / 20));
    } else if (offset > maxOffset) {
      final d = offset - maxOffset;
      return maxOffset + 8 * (1 - math.exp(-d / 20));
    }

    return offset;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (slotContents.isEmpty) return const SizedBox.shrink();

        final railHeight = constraints.maxHeight - railOuterPadding * 2;
        final availableHeight = math.max(0.0, railHeight - railPadding * 2 - 2);

        final slotCount = (availableHeight ~/ 14).clamp(1, slotContents.length);
        final slotHeight = math.min(availableHeight / slotCount, slotMaxHeight);

        final sparse = slotCount < slotContents.length;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            if (isDragging)
              Transform.translate(
                offset: Offset(
                  0,
                  hinterOffset(dragPosition, slotHeight, slotCount),
                ),
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
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
                onPointer(details.localPosition.dy, slotHeight, slotCount);
              },
              onVerticalDragUpdate: (details) {
                isDragging = true;
                onPointer(details.localPosition.dy, slotHeight, slotCount);
              },
              onVerticalDragStart: (details) {
                isDragging = true;
                onPointer(details.localPosition.dy, slotHeight, slotCount);
              },
              onVerticalDragEnd: (_) => setState(() => isDragging = false),
              onVerticalDragCancel: () => setState(() => isDragging = false),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: railPadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(slotCount, (slot) {
                        final showDot = sparse && slot.isOdd;
                        final l = slotContents[letterIndexOf(slot, slotCount)]
                            .display;

                        return SizedBox(
                          height: slotHeight,
                          child: Center(
                            child: showDot
                                ? Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(120),
                                    ),
                                  )
                                : Text(
                                    l,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 12,
                                      height: 1,
                                    ),
                                    maxLines: 1,
                                  ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
