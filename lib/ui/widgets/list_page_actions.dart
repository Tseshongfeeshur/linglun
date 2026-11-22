import 'package:linglun/data/models/window_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:linglun/data/utils/track_sort.dart';

/// AppBar 右侧的列表操作区：排序菜单、多选按钮、可展开的搜索框。
/// 搜索框获得焦点或有文字时展开；窄屏展开时其他按钮折叠让位。
/// 三者由同一个动画进度 progress（0~1）统一驱动。
class ListPageActions extends StatefulWidget {
  final SortConfig sortConfig;
  final ValueChanged<SortConfig> onSortChanged;
  const new({super.key, required this.sortConfig, required this.onSortChanged});

  @override
  State<ListPageActions> createState() => _ListPageActionsState();
}

class _ListPageActionsState extends State<ListPageActions> {
  // TODO: 搜索文本目前只用来控制"展开/收起"，没有回传给页面做过滤
  // （待办：搜索接入过滤逻辑）。接入时通过回调把 controller.text 传出去，
  // 数据量大时考虑防抖。
  late TextEditingController searchBarController;
  late FocusNode searchBarFocusNode;
  final double searchBarPadding = 8;
  bool isSearchBarExtended = false;

  // 展开条件：有焦点，或已输入文字（有文字时即使失焦也保持展开，
  // 提示"当前列表正在被过滤"）。
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
      builder: (context, progress, child) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: (searchBarPadding * progress).clamp(0, searchBarPadding),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Collapsible(
              progress: progress,
              child: _SortButton(
                sortConfig: widget.sortConfig,
                onSortChanged: widget.onSortChanged,
              ),
            ),
            _Collapsible(progress: progress, child: _CheckButton()),
            _SearchField(
              controller: searchBarController,
              focusNode: searchBarFocusNode,
              searchBarPadding: searchBarPadding,
              extended: isSearchBarExtended,
              progress: progress,
            ),
          ],
        ),
      ),
    );
  }
}

/// 窄屏时随搜索框展开而收起的按钮（宽度→0 + 渐隐 + 不再响应点击）；宽屏始终显示。
class _Collapsible extends StatelessWidget {
  final Widget child;
  final double progress;

  const new({required this.child, required this.progress});

  @override
  Widget build(BuildContext context) {
    final visible = context.layout != WindowLayout.phone
        ? 1.0
        : (1 - progress).clamp(0.0, 1.0);
    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: visible,
        heightFactor: 1,
        child: Opacity(
          opacity: visible,
          child: IgnorePointer(ignoring: visible < 0.5, child: child),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final SortConfig sortConfig;
  final ValueChanged<SortConfig> onSortChanged;

  const new({required this.sortConfig, required this.onSortChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TrackSort>(
      popUpAnimationStyle: AnimationStyle(
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInOutCubic,
        reverseDuration: 140.ms,
      ),
      // 点已选中的项 = 翻转升降序；点别的项 = 切换依据，并重置为升序。
      onSelected: (value) {
        if (sortConfig.method == value) {
          onSortChanged(
            sortConfig.copyWith(descending: !sortConfig.descending),
          );
        } else {
          onSortChanged(sortConfig.copyWith(method: value, descending: false));
        }
      },
      initialValue: sortConfig.method,
      itemBuilder: (context) => [
        for (final item in TrackSort.values)
          PopupMenuItem(
            value: item,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item == sortConfig.method
                      ? (sortConfig.descending
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
      icon: Stack(
        children: [
          const Icon(Icons.sort),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(sortConfig.method.icon, size: 12),
          ),
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      // TODO: 多选模式尚未实现（待办）。
      onPressed: () {},
      icon: const Icon(Icons.check_box_outlined),
    );
  }
}

/// 搜索框：收起时只是一个搜索图标按钮，展开时露出输入框和清除按钮。
class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double searchBarPadding;
  final bool extended;
  final double progress;

  const new({
    required this.controller,
    required this.focusNode,
    required this.searchBarPadding,
    required this.extended,
    required this.progress,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _groupId = Object();

  final _iconKey = GlobalKey();
  double _iconWidth = 48; // 首帧的估计值，量到真实值后替换

  void _measureIcon() {
    final w = _iconKey.currentContext?.size?.width;
    if (mounted && w != null && w != _iconWidth) setState(() => _iconWidth = w);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureIcon());
  }

  @override
  Widget build(BuildContext context) {
    final fieldWidth = context.layout == WindowLayout.phone
        ? MediaQuery.sizeOf(context).width -
              widget.searchBarPadding * 2 -
              _iconWidth
        : 240.0;
    // TapRegion 的 groupId 与 TextField 相同，所以点击搜索框内部（含图标、清除按钮）
    // 不算"点击外部"；点击外部则失焦（文本为空时随之收起）。
    return TapRegion(
      groupId: _groupId,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer
              .withAlpha((255 * widget.progress).toInt().clamp(0, 255)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // 收起时宽度 = 一个按钮
          children: [
            IconButton(
              key: _iconKey,
              onPressed: () => widget.focusNode.requestFocus(),
              icon: const Icon(Icons.search),
            ),
            ClipRect(
              child: Align(
                heightFactor: 1,
                alignment: Alignment.centerLeft,
                widthFactor: widget.progress, // 0 → 1：这一段宽度从 0 长到 fieldWidth
                child: SizedBox(
                  width: fieldWidth,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          groupId: _groupId,
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          onTapOutside: (_) => widget.focusNode.unfocus(),
                          decoration: InputDecoration(
                            hintText: '搜索',
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface
                                  .withAlpha((160 * widget.progress).toInt()),
                              fontSize: 16,
                              overflow: TextOverflow.ellipsis,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Opacity(
                        // 清除按钮只在动画后半段（progress 0.5→1）淡入；前半段不响应点击。
                        opacity: ((widget.progress - 0.5) / 0.5).clamp(0, 1),
                        child: IgnorePointer(
                          ignoring: widget.progress < 0.5,
                          child: IconButton(
                            onPressed: () {
                              if (widget.controller.text.isEmpty) {
                                widget.focusNode.unfocus();
                              } else {
                                widget.controller.clear();
                                widget.focusNode.requestFocus();
                              }
                            },
                            icon: const Icon(Icons.clear),
                          ),
                        ),
                      ), // 原来 Positioned 的清除按钮
                    ],
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
