import 'package:material_ui/material_ui.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:linglun/data/utils/track_sort.dart';

class ListPageActions extends StatefulWidget {
  final SortConfig sortConfig;
  final ValueChanged<SortConfig> onSortChanged;
  const ListPageActions({
    super.key,
    required this.sortConfig,
    required this.onSortChanged,
  });

  @override
  State<ListPageActions> createState() => _ListPageActionsState();
}

class _ListPageActionsState extends State<ListPageActions> {
  late TextEditingController searchBarController;
  late FocusNode searchBarFocusNode;
  final double searchBarPadding = 8;
  bool isSearchBarExtended = false;

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
    final theme = Theme.of(context);
    final base = 48.0;
    final adj = theme.visualDensity.baseSizeAdjustment;
    final buttonSize = Size(base + adj.dx, base + adj.dy);

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
              child: PopupMenuButton<TrackSort>(
                style: IconButton.styleFrom(
                  minimumSize: buttonSize,
                  maximumSize: buttonSize,
                ),
                popUpAnimationStyle: AnimationStyle(
                  curve: Curves.easeInOutCubic,
                  reverseCurve: Curves.easeInOutCubic,
                  reverseDuration: 140.ms,
                ),
                onSelected: (value) {
                  if (widget.sortConfig.method == value) {
                    widget.onSortChanged(
                      widget.sortConfig.copyWith(
                        descending: !widget.sortConfig.descending,
                      ),
                    );
                  } else {
                    widget.onSortChanged(
                      widget.sortConfig.copyWith(
                        method: value,
                        descending: false,
                      ),
                    );
                  }
                },
                initialValue: widget.sortConfig.method,
                itemBuilder: (context) => [
                  for (final item in TrackSort.values)
                    PopupMenuItem(
                      value: item,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item == widget.sortConfig.method
                                ? (widget.sortConfig.descending
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
                style: IconButton.styleFrom(
                  minimumSize: buttonSize,
                  maximumSize: buttonSize,
                ),
              ),
            ),
            SearchField(
              buttonSize: buttonSize,
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
  final Size buttonSize;
  final TextEditingController controller;
  final FocusNode focusNode;
  final double searchBarPadding;
  final bool extended;
  final double animationProgress;

  const SearchField({
    super.key,
    required this.buttonSize,
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
            widget.buttonSize.width +
            (MediaQuery.sizeOf(context).width >= 600
                    ? 240
                    : (MediaQuery.sizeOf(context).width -
                              widget.searchBarPadding * 2) -
                          widget.buttonSize.width) *
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
              style: IconButton.styleFrom(
                minimumSize: widget.buttonSize,
                maximumSize: widget.buttonSize,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.buttonSize.width,
              ),
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
                    style: IconButton.styleFrom(
                      minimumSize: widget.buttonSize,
                      maximumSize: widget.buttonSize,
                    ),
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
    final visible = MediaQuery.sizeOf(context).width >= 600
        ? 1.0
        : (1 - progress).clamp(0.0, 1.0);
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
