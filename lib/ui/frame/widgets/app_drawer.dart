import 'package:linglun/data/models/window_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/frame/page_info.dart';

import 'package:linglun/ui/widgets/reveal_icon.dart';

/// 侧边抽屉。宽度、阴影、圆角都由布局和动画进度 animationProgress 决定
/// （进度由 Frame 的动画给出）。
// TODO: 这个 State 里没有任何状态，可以改成 StatelessWidget。
class AppDrawer extends StatefulWidget {
  final int pageIndex;
  final List<PageInfo> pages;
  // TODO: 裸的 `Function` 丢掉了类型检查（传错参数数量/类型也能编译，运行时才炸）。
  // 改成 ValueChanged<int>。
  final Function onSelected;

  final WindowLayout layout;
  final double mediumDrawerWidth;
  final double largeDrawerWidth;
  final bool extended;
  final double animationProgress;
  // TODO: 同上，应为 void Function([bool? value])。
  // 无参调用表示"切换"，传 true/false 表示指定目标（见 Frame 里的实现）。
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
        // 阴影只在平板布局出现（展开的抽屉浮在页面之上，随动画进度淡入）；
        // 圆角只在手机布局出现。桌面的抽屉会推开页面，不需要这两样。
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
        child: SafeArea(
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
                      // 非桌面布局下，选了页面后自动收起抽屉。
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
      ),
    );
  }
}
