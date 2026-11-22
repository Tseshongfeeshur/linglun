import 'package:linglun/data/models/window_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/frame/page_info.dart';

import 'package:linglun/ui/widgets/reveal_icon.dart';

/// 侧边抽屉。宽度、阴影、圆角都由布局和动画进度 animationProgress 决定
/// （进度由 Frame 的动画给出）。
class AppDrawer extends StatelessWidget {
  final int pageIndex;
  final List<PageInfo> pages;
  final ValueChanged<int> onSelected;

  final WindowLayout layout;
  final double mediumDrawerWidth;
  final double largeDrawerWidth;
  final bool extended;
  final double animationProgress;
  // Function 声明需要同时声明类型，避免运行时类型不匹配而崩溃。
  // 无参调用表示"切换"，传 true/false 表示指定目标。
  final Function([bool? value]) onTapSwitch;

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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // 阴影只在平板布局出现（展开的抽屉浮在页面之上，随动画进度淡入）；
        // 圆角只在手机布局出现。桌面的抽屉会推开页面，不需要这两样。
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              (48 * (layout == WindowLayout.tablet ? animationProgress : 0))
                  .toInt()
                  .clamp(0, 48),
            ),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(layout == WindowLayout.phone ? 16 : 0),
          bottomRight: Radius.circular(layout == WindowLayout.phone ? 16 : 0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      width: layout == WindowLayout.phone
          ? largeDrawerWidth
          : mediumDrawerWidth +
                (largeDrawerWidth - mediumDrawerWidth) * animationProgress,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 56,
                  width: 56,
                  child: Center(
                    child: IconButton(
                      onPressed: () => onTapSwitch(),
                      icon: RevealIcon(
                        isFilled: extended,
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
              ),
              Expanded(
                child: ListView(
                  children: List.generate(
                    pages.length,
                    (currentIndex) => ListTile(
                      leading: RevealIcon(
                        isFilled: pageIndex == currentIndex,
                        outlineIcon: pages[currentIndex].icon,
                        filledIcon: pages[currentIndex].selectedIcon,
                      ),
                      title: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          pages[currentIndex].title,
                          style: const TextStyle(overflow: TextOverflow.clip),
                          maxLines: 1,
                        ),
                      ),
                      // 非桌面布局下，选了页面后自动收起抽屉。
                      onTap: () {
                        if (layout != WindowLayout.desktop) {
                          onTapSwitch(false);
                        }
                        onSelected(currentIndex);
                      },
                      selected: pageIndex == currentIndex,
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
      ),
    );
  }
}
