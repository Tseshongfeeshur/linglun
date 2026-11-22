import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:linglun/data/models/track_info.dart';
import 'package:linglun/ui/pages/track_lib/widgets/letter_index_rail_slot.dart';
import 'package:material_ui/material_ui.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// 列表右侧的字母索引栏：点击或上下拖动定位到对应分组，拖动时在左侧显示气泡。
/// 栏被切成若干"格子"（slot）：高度够时一格一个分组；不够时一格对应多个分组，
/// 间隔的格子画成圆点表示被省略的分组。
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
  // 栏内部上下内边距。
  static const double railPadding = 6;
  // 栏上下外侧的留白。TODO: 它只从可用高度里扣掉了，并没有真的画出来
  // （靠 Align 居中才形成留白），命名和实现不太对应。
  static const double railOuterPadding = 4;
  // 每个格子的最大高度。
  static const double slotMaxHeight = 20;
  // 拖动时气泡的直径。
  static const double hinterSize = 52;

  bool isDragging = false;
  double dragPosition = 0;
  List<LetterIndexRailSlot> slotContents = [];
  // 当前指向的字符，用来保证只在字母变化时才触发震动和跳转。
  String letter = '';

  @override
  void initState() {
    super.initState();
    slotContents = buildRailSlots(widget.groupedTrackList, widget.keyIndexList);
  }

  @override
  void didUpdateWidget(covariant LetterIndexRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 每次父级重建都重算一遍（只是 O(分组数)，很便宜）。
    // 也可以只在 groupedTrackList/keyIndexList 真正变化时才重算。
    slotContents = buildRailSlots(widget.groupedTrackList, widget.keyIndexList);
  }

  // 第 i 个格子对应的字母下标
  // 把 slotCount 个格子均匀映射到 slotContents.length 个条目：
  // 格子比条目少时，一个格子对应多个条目（中间的会被跳过）。
  int letterIndexOf(int slot, int slotCount) =>
      (slot * slotContents.length / slotCount).floor();

  // y 是手指相对索引栏顶部的纵坐标 → 格子 → 条目 → 更新气泡并跳转。
  // 这里没有把栏边框（上下各 1px）算进去，偏差可以忽略。
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

  // 气泡的纵向位置：跟随手指；超出栏两端时用指数衰减做"橡皮筋"式阻尼，
  // 越界距离趋近但不超过 8px。
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

        // 可用高度 = 总高 - 外侧留白 - 内边距 - 边框（上下各 1px）。
        // 每格至少 14px 高，据此算出能放几个格子（最多等于条目数）；
        // 格子高度不超过 slotMaxHeight。
        final railHeight = constraints.maxHeight - railOuterPadding * 2;
        final availableHeight = math.max(0.0, railHeight - railPadding * 2 - 2);

        final slotCount = (availableHeight ~/ 14).clamp(1, slotContents.length);
        final slotHeight = math.min(availableHeight / slotCount, slotMaxHeight);

        // sparse：格子比条目少，奇数格画圆点，偶数格显示字符。
        final sparse = slotCount < slotContents.length;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          // 气泡与索引栏之间的间距。
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
                letter = '';
              },
              // 注意：这三个回调里先直接改 isDragging，再由 onPointer 里的 setState
              // 一起刷新（所以没有单独包 setState）；onTapUp 不设置 isDragging，所以点按没有气泡。
              onVerticalDragUpdate: (details) {
                isDragging = true;
                onPointer(details.localPosition.dy, slotHeight, slotCount);
              },
              onVerticalDragStart: (details) {
                isDragging = true;
                onPointer(details.localPosition.dy, slotHeight, slotCount);
              },
              onVerticalDragEnd: (_) {
                setState(() => isDragging = false);
                letter = '';
              },
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
