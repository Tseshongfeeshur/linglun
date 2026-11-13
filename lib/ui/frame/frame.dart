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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 600)
            _AppDrawer(
              pageIndex: pageIndex,
              pages: pages,
              onSelected: onPageSwitched,
              extended: MediaQuery.sizeOf(context).width >= 840,
            ),
          Expanded(
            child: IndexedStack(
              index: pageIndex,
              children: pages.map((pageInfo) => pageInfo.page).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 600
          ? AppNavBar(
              pageIndex: pageIndex,
              pages: pages,
              onDestinationSelected: onPageSwitched,
            )
          : null,
    );
  }
}

class _AppDrawer extends StatefulWidget {
  final int pageIndex;
  final List<PageInfo> pages;
  final ValueChanged<int> onSelected;
  final bool extended;

  const new({
    required this.pageIndex,
    required this.pages,
    required this.onSelected,
    required this.extended,
  });

  @override
  State<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<_AppDrawer> {
  // TODO: 让 laptop 时展开动作浮动，desktop 时展开常驻
  bool _isExtended = true;

  @override
  Widget build(BuildContext context) {
    return Animate(target: _isExtended ? 1 : 0).custom(
      duration: 200.ms,
      curve: Curves.easeInOutCubic,
      builder: (context, animationProgress, child) => Drawer(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        width: (16 * 2 + 24) + (220 - (16 * 2 + 24)) * animationProgress,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  onPressed: () => setState(() => _isExtended = !_isExtended),
                  icon: RevealIcon(
                    isFilled: _isExtended,
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
    );
  }
}

class AppNavBar extends StatelessWidget {
  final int pageIndex;
  final List<PageInfo> pages;
  final ValueChanged<int> onDestinationSelected;

  const new({
    super.key,
    required this.pageIndex,
    required this.pages,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: pageIndex,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      onDestinationSelected: onDestinationSelected,
      destinations: List.generate(
        pages.length,
        (currentIndex) => NavigationDestination(
          icon: RevealIcon(
            isFilled: pageIndex == currentIndex,
            outlineIcon: pages[currentIndex].icon,
            filledIcon: pages[currentIndex].selectedIcon,
          ),
          label: pages[currentIndex].title,
        ),
      ),
    );
  }
}
