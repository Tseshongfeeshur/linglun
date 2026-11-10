import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/utils/window_info.dart';

import 'package:linglun/ui/frame/page_info.dart';

import 'package:linglun/ui/pages/album_lib.dart';
import 'package:linglun/ui/pages/artist_lib.dart';
import 'package:linglun/ui/pages/track_lib/track_lib.dart';
import 'package:linglun/ui/pages/track_sources.dart';
import 'package:linglun/ui/pages/playlist.dart';
import 'package:linglun/ui/pages/settings.dart';

class Frame extends StatefulWidget {
  const Frame({super.key});

  @override
  State<Frame> createState() => _FrameState();
}

class _FrameState extends State<Frame> {
  int pageIndex = 0;
  final List<PageInfo> pages = [
    PageInfo(
      title: '曲库',
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music,
      page: TrackLib(),
    ),
    PageInfo(
      title: '专辑',
      icon: Icons.album_outlined,
      selectedIcon: Icons.album,
      page: AlbumLib(),
    ),
    PageInfo(
      title: '艺术家',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      page: ArtistLib(),
    ),
    PageInfo(
      title: '播放列表',
      icon: Icons.queue_music_outlined,
      selectedIcon: Icons.queue_music,
      page: Playlist(),
    ),
    PageInfo(
      title: '歌曲来源',
      icon: Icons.folder_special_outlined,
      selectedIcon: Icons.folder_special,
      page: TrackSources(),
    ),
    PageInfo(
      title: '设置',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      page: Settings(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (context.isTablet)
          NavigationRail(
            selectedIndex: pageIndex,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            mainAxisAlignment: MainAxisAlignment.center,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (value) => setState(() {
              pageIndex = value;
            }),
            destinations: List.generate(
              pages.length,
              (currentIndex) => NavigationRailDestination(
                icon: pageIndex == currentIndex
                    ? Icon(pages[currentIndex].selectedIcon)
                    : Icon(pages[currentIndex].icon),
                label: Text(pages[currentIndex].title),
              ),
            ),
          ),
        Expanded(
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: IndexedStack(
              index: pageIndex,
              children: pages.map((pageInfo) => pageInfo.page).toList(),
            ),
            bottomNavigationBar: context.isTablet
                ? null
                : NavigationBar(
                    selectedIndex: pageIndex,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    onDestinationSelected: (value) => setState(() {
                      pageIndex = value;
                    }),
                    destinations: List.generate(
                      pages.length,
                      (currentIndex) => NavigationDestination(
                        icon: Icon(pages[currentIndex].icon),
                        selectedIcon: Icon(pages[currentIndex].selectedIcon),
                        label: pages[currentIndex].title,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
