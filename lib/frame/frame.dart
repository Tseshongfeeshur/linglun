import 'package:flutter/material.dart';

import 'package:linglun/pages/album_lib.dart';
import 'package:linglun/pages/artist_lib.dart';
import 'package:linglun/pages/music_lib.dart';
import 'package:linglun/pages/music_sources.dart';
import 'package:linglun/pages/playlist.dart';
import 'package:linglun/pages/settings.dart';

import 'package:linglun/utils/window_info.dart';

class Frame extends StatefulWidget {
  const Frame({super.key});

  @override
  State<Frame> createState() => _FrameState();
}

class PageItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  const PageItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });
}

class _FrameState extends State<Frame> {
  int pageIndex = 0;
  final List<PageItem> pages = [
    PageItem(
      title: '曲库',
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music,
      page: MusicLib(),
    ),
    PageItem(
      title: '专辑',
      icon: Icons.album_outlined,
      selectedIcon: Icons.album,
      page: AlbumLib(),
    ),
    PageItem(
      title: '艺术家',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      page: ArtistLib(),
    ),
    PageItem(
      title: '播放列表',
      icon: Icons.queue_music_outlined,
      selectedIcon: Icons.queue_music,
      page: Playlist(),
    ),
    PageItem(
      title: '歌曲来源',
      icon: Icons.folder_special_outlined,
      selectedIcon: Icons.folder_special,
      page: MusicSource(),
    ),
    PageItem(
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
        context.isLandscape
            ? NavigationRail(
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
              )
            : SizedBox.shrink(),
        Expanded(
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              // leading: Icon(
              //   pages[pageIndex].icon,
              //   color: Theme.of(context).colorScheme.primary,
              // ),
              title: Text(pages[pageIndex].title),
            ),
            body: pages[pageIndex].page,
            bottomNavigationBar: context.isLandscape
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
                        icon: pageIndex == currentIndex
                            ? Icon(pages[currentIndex].selectedIcon)
                            : Icon(pages[currentIndex].icon),
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
