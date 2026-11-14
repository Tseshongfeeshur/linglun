import 'package:linglun/data/models/window_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/frame/page_info.dart';

import 'package:linglun/ui/widgets/reveal_icon.dart';

class AppDrawer extends StatefulWidget {
  final int pageIndex;
  final List<PageInfo> pages;
  final Function onSelected;

  final WindowLayout layout;
  final double mediumDrawerWidth;
  final double largeDrawerWidth;
  final bool extended;
  final double animationProgress;
  final Function onTapSwitch;

  const new({
    super.key,
    required this.pageIndex,
    required this.pages,
    required this.onSelected,

    required this.layout,
    required this.mediumDrawerWidth,
    required this.largeDrawerWidth,
    required this.extended,
    required this.animationProgress,
    required this.onTapSwitch,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              (48 *
                      (widget.layout == WindowLayout.tablet
                          ? widget.animationProgress
                          : 0))
                  .toInt()
                  .clamp(0, 48),
            ),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(
            widget.layout == WindowLayout.phone ? 16 : 0,
          ),
          bottomRight: Radius.circular(
            widget.layout == WindowLayout.phone ? 16 : 0,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      width: widget.layout == WindowLayout.phone
          ? widget.largeDrawerWidth
          : widget.mediumDrawerWidth +
                (widget.largeDrawerWidth - widget.mediumDrawerWidth) *
                    widget.animationProgress,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  onPressed: () => widget.onTapSwitch(),
                  icon: RevealIcon(
                    isFilled: widget.extended,
                    outlineIcon: Icons.menu,
                    filledIcon: Icons.menu_open,
                    outlineIconColor: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                    filledIconColor: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: List.generate(
                  widget.pages.length,
                  (currentIndex) => ListTile(
                    leading: RevealIcon(
                      isFilled: widget.pageIndex == currentIndex,
                      outlineIcon: widget.pages[currentIndex].icon,
                      filledIcon: widget.pages[currentIndex].selectedIcon,
                    ),
                    title: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        widget.pages[currentIndex].title,
                        style: const TextStyle(overflow: TextOverflow.clip),
                        maxLines: 1,
                      ),
                    ),
                    onTap: () {
                      if (widget.layout != WindowLayout.desktop) {
                        widget.onTapSwitch(false);
                      }
                      widget.onSelected(currentIndex);
                    },
                    selected: widget.pageIndex == currentIndex,
                    selectedTileColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHigh,
                    contentPadding: const EdgeInsets.only(left: 16),
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
