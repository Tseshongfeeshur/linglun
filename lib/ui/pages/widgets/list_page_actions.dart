import 'package:material_ui/material_ui.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:linglun/ui/utils/window_info.dart';
import 'package:linglun/ui/pages/music_lib/music_sort.dart';

class ListPageActions extends StatefulWidget {
  const ListPageActions({super.key});

  @override
  State<ListPageActions> createState() => _ListPageActionsState();
}

class _ListPageActionsState extends State<ListPageActions> {
  late TextEditingController searchBarController;
  late FocusNode searchBarFocusNode;
  final double searchBarPadding = 8;
  bool isSearchBarExtended = false;

  MusicSort _sortSelected = MusicSort.titleInLatin;
  bool _sortInDescending = false;

  void updateExtendedState() => setState(
    () => isSearchBarExtended =
        searchBarFocusNode.hasFocus || searchBarController.text.isNotEmpty,
  );

  @override
  void initState() {
    super.initState();
    searchBarController = TextEditingController();
    searchBarController.addListener(updateExtendedState);
    searchBarFocusNode = FocusNode();
    searchBarFocusNode.addListener(updateExtendedState);
  }

  @override
  void dispose() {
    searchBarFocusNode.removeListener(updateExtendedState);
    searchBarFocusNode.dispose();
    searchBarController.removeListener(updateExtendedState);
    searchBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(target: isSearchBarExtended ? 1 : 0).custom(
      duration: 200.ms,
      curve: Curves.easeInOutCubic,
      builder: (context, animationProgress, child) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: (searchBarPadding * animationProgress).clamp(
            0,
            searchBarPadding,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Collapsible(
              progress: animationProgress,
              child: PopupMenuButton<MusicSort>(
                popUpAnimationStyle: AnimationStyle(
                  curve: Curves.easeInOutCubic,
                  reverseCurve: Curves.easeInOutCubic,
                  reverseDuration: 140.ms,
                ),
                onSelected: (value) => setState(() {
                  if (_sortSelected == value) {
                    _sortInDescending = !_sortInDescending;
                  } else {
                    _sortInDescending = false;
                    _sortSelected = value;
                  }
                }),
                initialValue: _sortSelected,
                itemBuilder: (context) => [
                  for (final item in MusicSort.values)
                    PopupMenuItem(
                      value: item,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item == _sortSelected
                                ? (_sortInDescending
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward)
                                : item.icon,
                          ),
                          const SizedBox(width: 12),
                          Text(item.label),
                        ],
                      ),
                    ),
                ],
                tooltip: '排序依据',
                icon: const Icon(Icons.sort),
              ),
            ),
            Collapsible(
              progress: animationProgress,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.check_box_outlined),
              ),
            ),
            SearchField(
              controller: searchBarController,
              focusNode: searchBarFocusNode,
              searchBarPadding: searchBarPadding,
              extended: isSearchBarExtended,
              animationProgress: animationProgress,
            ),
          ],
        ),
      ),
    );
  }
}

class SearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double searchBarPadding;
  final bool extended;
  final double animationProgress;

  const SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.searchBarPadding,
    required this.extended,
    required this.animationProgress,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _groupId = Object();

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _groupId,
      child: Container(
        width:
            40 +
            (context.isTablet
                    ? 240
                    : (context.windowSize.width - widget.searchBarPadding * 2) -
                          40) *
                widget.animationProgress,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer.withAlpha(
            (255 * widget.animationProgress).toInt().clamp(0, 255),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            IconButton(
              onPressed: () => widget.focusNode.requestFocus(),
              icon: Icon(Icons.search),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                groupId: _groupId,
                controller: widget.controller,
                focusNode: widget.focusNode,
                onTapOutside: (_) => widget.focusNode.unfocus(),
                decoration: InputDecoration(
                  hintText: '搜索',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface
                        .withAlpha((160 * widget.animationProgress).toInt()),
                    fontSize: 16,
                    overflow: TextOverflow.ellipsis,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Opacity(
                opacity: ((widget.animationProgress - 0.5) / 0.5).clamp(0, 1),
                child: IgnorePointer(
                  ignoring: widget.animationProgress < 0.5,
                  child: IconButton(
                    onPressed: () {
                      if (widget.controller.text.isEmpty) {
                        widget.focusNode.unfocus();
                      } else {
                        widget.controller.clear();
                        widget.focusNode.requestFocus();
                      }
                    },
                    icon: Icon(Icons.clear),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Collapsible extends StatelessWidget {
  final Widget child;
  final double progress;

  const Collapsible({super.key, required this.child, required this.progress});

  @override
  Widget build(BuildContext context) {
    final visible = context.isTablet ? 1.0 : (1 - progress).clamp(0.0, 1.0);
    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: visible,
        child: Opacity(
          opacity: visible,
          child: IgnorePointer(ignoring: visible < 0.5, child: child),
        ),
      ),
    );
  }
}
