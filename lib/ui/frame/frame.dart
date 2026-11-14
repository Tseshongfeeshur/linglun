import 'package:flutter_animate/flutter_animate.dart';
import 'package:linglun/ui/widgets/reveal_icon.dart';
import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/frame/page_info.dart';

import 'package:linglun/ui/pages/album_lib.dart';
import 'package:linglun/ui/pages/artist_lib.dart';
import 'package:linglun/ui/pages/track_lib/track_lib.dart';
import 'package:linglun/ui/pages/track_sources/track_sources.dart';
import 'package:linglun/ui/pages/playlist.dart';
import 'package:linglun/ui/pages/settings.dart';

class Frame extends StatefulWidget {
  const new({super.key});

  @override
  State<Frame> createState() => _FrameState();
}

class _FrameState extends State<Frame> {
  int pageIndex = 0;
  bool drawerExtended = false;
  void onExtendingChange([bool? value]) =>
      setState(() => drawerExtended = value ?? !drawerExtended);
  void onPageSwitched(int index) => setState(() => pageIndex = index);

  final List<PageInfo> pages = [
    PageInfo(
      title: '曲库',
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music,
      page: const TrackLib(),
    ),
    PageInfo(
      title: '专辑',
      icon: Icons.album_outlined,
      selectedIcon: Icons.album,
      page: const AlbumLib(),
    ),
    PageInfo(
      title: '艺术家',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      page: const ArtistLib(),
    ),
    PageInfo(
      title: '播放列表',
      icon: Icons.queue_music_outlined,
      selectedIcon: Icons.queue_music,
      page: const Playlist(),
    ),
    PageInfo(
      title: '歌曲来源',
      icon: Icons.folder_special_outlined,
      selectedIcon: Icons.folder_special,
      page: const TrackSources(),
    ),
    PageInfo(
      title: '设置',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      page: const Settings(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          children: [
            if (MediaQuery.sizeOf(context).width >= 600)
              if (MediaQuery.sizeOf(context).width >= 840)
                _DesktopDrawer(
                  pageIndex: pageIndex,
                  pages: pages,
                  onSelected: onPageSwitched,
                  extended: drawerExtended,
                  isWideScreen: true,
                  onExtendingChange: onExtendingChange,
                )
              else
                const SizedBox(width: 16 * 2 + 24),
            Expanded(
              child: IndexedStack(
                index: pageIndex,
                children: pages.map((pageInfo) => pageInfo.page).toList(),
              ),
            ),
          ],
        ),
        if (MediaQuery.sizeOf(context).width >= 600 &&
            MediaQuery.sizeOf(context).width <= 840)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _TabletDrawer(
              pageIndex: pageIndex,
              pages: pages,
              onSelected: onPageSwitched,
              extended: drawerExtended,
              isWideScreen: false,
              onExtendingChange: onExtendingChange,
            ),
          ),
      ],
    );
  }
}

class _PhoneDrawer extends StatefulWidget {
  final int pageIndex;
  final List<PageInfo> pages;
  final ValueChanged<int> onSelected;

  const new({
    required this.pageIndex,
    required this.pages,
    required this.onSelected,
  });

  @override
  State<_PhoneDrawer> createState() => _PhoneDrawerState();
}

class _PhoneDrawerState extends State<_PhoneDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 220,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.menu_open),
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
                  onTap: () => widget.onSelected(currentIndex),
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
    );
  }
}

class _TabletDrawer extends StatefulWidget {
  final int pageIndex;
  final List<PageInfo> pages;
  final ValueChanged<int> onSelected;
  final bool extended;
  final bool isWideScreen;
  final Function onExtendingChange;

  const new({
    required this.pageIndex,
    required this.pages,
    required this.onSelected,
    required this.extended,
    required this.isWideScreen,
    required this.onExtendingChange,
  });

  @override
  State<_PhoneDrawer> createState() => _PhoneDrawerState();
}

class _TabletDrawerState extends State<_TabletDrawer> {
  // TODO: 使用 provider 重构 drawer

  @override
  Widget build(BuildContext context) {
    return Animate(
      onInit: (controller) => controller.value = widget.extended ? 1 : 0,
      target: widget.extended ? 1 : 0,
    ).custom(
      duration: 200.ms,
      curve: Curves.easeInOutCubic,
      builder: (context, animationProgress, child) => Stack(
        children: [
          if (!widget.isWideScreen)
            IgnorePointer(
              ignoring: true,
              child: Container(
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height,
                color: Theme.of(context).colorScheme.onSurface
                    .withAlpha((100 * animationProgress).toInt().clamp(0, 100)),
              ),
            ),
          TapRegion(
            onTapOutside: widget.isWideScreen
                ? null
                : (event) => widget.onExtendingChange(false),
            child: Drawer(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              width: (16 * 2 + 24) + (220 - (16 * 2 + 24)) * animationProgress,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        onPressed: () => widget.onExtendingChange(),
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
                              style: const TextStyle(
                                overflow: TextOverflow.clip,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          onTap: () => widget.onSelected(currentIndex),
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
        ],
      ),
    );
  }
}

class _DesktopDrawer extends StatefulWidget {
  final int pageIndex;
  final List<PageInfo> pages;
  final ValueChanged<int> onSelected;
  final bool extended;
  final bool isWideScreen;
  final Function onExtendingChange;

  const new({
    required this.pageIndex,
    required this.pages,
    required this.onSelected,
    required this.extended,
    required this.isWideScreen,
    required this.onExtendingChange,
  });

  @override
  State<_PhoneDrawer> createState() => _PhoneDrawerState();
}

class _DesktopDrawerState extends State<_TabletDrawer> {
  // TODO: 让 laptop 时展开动作浮动，desktop 时展开常驻

  @override
  Widget build(BuildContext context) {
    return Animate(
      onInit: (controller) => controller.value = widget.extended ? 1 : 0,
      target: widget.extended ? 1 : 0,
    ).custom(
      duration: 200.ms,
      curve: Curves.easeInOutCubic,
      builder: (context, animationProgress, child) => Stack(
        children: [
          if (!widget.isWideScreen)
            IgnorePointer(
              ignoring: true,
              child: Container(
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height,
                color: Theme.of(context).colorScheme.onSurface
                    .withAlpha((100 * animationProgress).toInt().clamp(0, 100)),
              ),
            ),
          TapRegion(
            onTapOutside: widget.isWideScreen
                ? null
                : (event) => widget.onExtendingChange(false),
            child: Drawer(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              width: (16 * 2 + 24) + (220 - (16 * 2 + 24)) * animationProgress,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        onPressed: () => widget.onExtendingChange(),
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
                              style: const TextStyle(
                                overflow: TextOverflow.clip,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          onTap: () => widget.onSelected(currentIndex),
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
        ],
      ),
    );
  }
}
